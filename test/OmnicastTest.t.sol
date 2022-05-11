// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, console} from "@test/ChainEnvironmentTest.t.sol";
import {IOmnitoken} from "@protocol/interfaces/IOmnitoken.sol";

contract OmnicastTest is ChainEnvironmentTest {
  uint256 public passportId;

  function setUp() public override {
    super.setUp();

    passportId = passport.mint{value: 0.1 ether}();
  }

  function testSetOwnData(address caller, uint256 spaceId) public {
    hevm.assume(
      caller != address(0) &&
        caller != address(this) &&
        caller != address(steward)
    );

    uint256 callerPassportId = passport.mint{value: 0.1 ether}(caller);

    bytes memory data = abi.encodePacked(spaceId, "data");

    hevm.prank(caller);
    omnicast.writeMessage(
      spaceId,
      currentChainId,
      callerPassportId,
      data,
      address(0),
      ""
    );

    assertEq0(data, omnicast.readMessage(spaceId, callerPassportId));
  }

  function testFailUnauthorizedSetTokenURI(address caller, string memory uri)
    public
  {
    hevm.assume(
      caller != address(0) &&
        caller != address(this) &&
        caller != address(steward)
    );

    uint256 tokenuriSpace = omnicast.idOf("tokenuri");

    hevm.prank(caller);
    omnicast.writeMessage(
      tokenuriSpace,
      currentChainId,
      passportId,
      bytes(uri),
      address(0),
      ""
    );
  }

  function testMessageGas() public {
    omnicast.writeMessage(
      passportId,
      currentChainId,
      omnicast.idOf(beneficiary),
      "prosperity",
      address(0),
      ""
    );

    assertEq(
      "prosperity",
      string(
        omnicast.readMessage(
          omnicast.idOf(address(this)),
          omnicast.idOf(beneficiary)
        )
      )
    );
  }

  function testLocalSendAndRead(address to, bytes memory payload) public {
    hevm.assume(to != address(0));

    uint256 receiverId = omnicast.idOf(to);

    omnicast.writeMessage(
      passportId,
      currentChainId,
      receiverId,
      payload,
      address(0),
      ""
    );

    assertEq0(payload, omnicast.readMessage(passportId, receiverId));
  }

  function testRemoteSendAndRead(
    uint16 chainId,
    address to,
    bytes memory payload
  ) public {
    hevm.assume(to != address(0) && chainId != 0 && chainId != currentChainId);

    bytes memory remoteAddressBytes = abi.encodePacked(address(omnicast));
    omnicast.setTrustedRemote(chainId, remoteAddressBytes);
    omnicast.setTrustedRemote(currentChainId, remoteAddressBytes);
    lzEndpoint.setDestLzEndpoint(address(omnicast), address(lzEndpoint));

    uint256 receiverId = omnicast.idOf(to);

    omnicast.writeMessage{value: 0.1 ether}(
      passportId,
      chainId,
      receiverId,
      payload,
      address(0),
      ""
    );

    assertEq(1, omnicast.receivedMessageCount(passportId, receiverId));
    assertEq0(payload, omnicast.readMessage(passportId, receiverId));
  }

  function testFailUnauthorizedWrite(
    address receiverAddress,
    address senderAddress,
    bytes memory payload
  ) public {
    hevm.assume(
      receiverAddress != address(0) &&
        senderAddress != address(0) &&
        receiverAddress != address(this) &&
        senderAddress != address(this)
    );

    uint256 receiverId = passport.mint{value: 0.1 ether}(receiverAddress);
    uint256 senderId = passport.mint{value: 0.1 ether}(senderAddress);

    omnicast.writeMessage(
      senderId,
      currentChainId,
      receiverId,
      payload,
      address(0),
      ""
    );
  }
}
