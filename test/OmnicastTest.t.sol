// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, console} from "@test/ChainEnvironmentTest.t.sol";
import {IOFT} from "@protocol/interfaces/IOFT.sol";

contract OmnicastTest is ChainEnvironmentTest {
  function testSetTokenURI(address caller, string memory uri) public {
    hevm.assume(
      caller != address(0) &&
        caller != address(this) &&
        caller != address(comptroller)
    );

    uint256 passportId = passport.mint{value: 0.1 ether}(caller);
    uint256 tokenuriSpace = omnicast.idOf("tokenuri");

    hevm.prank(caller);
    omnicast.writeMessage(
      passportId,
      tokenuriSpace,
      bytes(uri),
      currentChainId,
      address(0),
      ""
    );

    assertEq(uri, passport.tokenURI(passportId));
  }

  function testFailUnauthorizedSetTokenURI(address caller, string memory uri)
    public
  {
    hevm.assume(
      caller != address(0) &&
        caller != address(this) &&
        caller != address(comptroller)
    );

    uint256 passportId = omnicast.idOf(address(this));
    passport.mint(address(this));
    uint256 tokenuriSpace = omnicast.idOf("tokenuri");

    hevm.prank(caller);
    omnicast.writeMessage(
      passportId,
      tokenuriSpace,
      bytes(uri),
      currentChainId,
      address(0),
      ""
    );
  }

  function testMessageGas() public {
    omnicast.writeMessage(
      omnicast.idOf(ownerAddress),
      omnicast.idOf(address(this)),
      "prosperity",
      currentChainId,
      address(0),
      ""
    );

    assertEq(
      "prosperity",
      string(
        omnicast.readMessage(
          omnicast.idOf(ownerAddress),
          omnicast.idOf(address(this))
        )
      )
    );
  }

  function testLocalSendAndRead(address to, bytes memory payload) public {
    hevm.assume(to != address(0));

    uint256 receiverId = omnicast.idOf(to);
    uint256 senderId = omnicast.idOf(address(this));

    omnicast.writeMessage(
      receiverId,
      senderId,
      payload,
      currentChainId,
      address(0),
      ""
    );

    assertEq0(payload, omnicast.readMessage(receiverId, senderId));
  }

  function testRemoteSendAndRead(
    uint16 chainId,
    address to,
    bytes memory payload
  ) public {
    hevm.assume(to != address(0) && chainId != 0 && chainId != currentChainId);

    bytes memory remoteAddressBytes = abi.encodePacked(address(omnicast));
    omnicast.setTrustedRemoteContract(chainId, remoteAddressBytes);
    omnicast.setTrustedRemoteContract(currentChainId, remoteAddressBytes);
    layerZeroEndpoint.setDestLzEndpoint(
      address(omnicast),
      address(layerZeroEndpoint)
    );

    uint256 receiverId = omnicast.idOf(to);
    uint256 senderId = omnicast.idOf(address(this));

    omnicast.writeMessage{value: 0.1 ether}(
      receiverId,
      senderId,
      payload,
      chainId,
      address(0),
      ""
    );

    assertEq(1, omnicast.receivedMessagesCount(receiverId, senderId));
    assertEq0(payload, omnicast.readMessage(receiverId, senderId));
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

    uint256 receiverId = omnicast.idOf(receiverAddress);
    uint256 senderId = omnicast.idOf(senderAddress);

    omnicast.writeMessage(
      receiverId,
      senderId,
      payload,
      currentChainId,
      address(0),
      ""
    );
  }
}
