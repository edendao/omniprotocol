// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment, console} from "@protocol/test/TestEnvironment.t.sol";

contract OmnicasterTest is TestEnvironment {
  function testLocalSendGas() public {
    omnicast.sendMessage(
      uint16(block.chainid),
      omnicast.idOf(ownerAddress),
      omnicast.idOf(myAddress),
      "prosperity",
      address(0),
      ""
    );
  }

  function testLocalSendAndRead(address to, bytes memory payload) public {
    hevm.assume(to != address(0));

    uint256 receiverId = omnicast.idOf(to);
    uint256 senderId = omnicast.idOf(myAddress);

    omnicast.sendMessage(
      currentChainId,
      receiverId,
      senderId,
      payload,
      address(0),
      ""
    );

    assertEq0(payload, omnicast.readMessage(receiverId, senderId));
  }

  function xtestRemoteSendAndRead(
    uint16 chainId,
    address to,
    bytes memory payload
  ) public {
    hevm.assume(to != address(0) && chainId != 0);

    hevm.startPrank(ownerAddress);
    omnicast.setTrustedRemoteContract(chainId, address(omnicast));
    omnicast.setTrustedRemoteContract(currentChainId, address(omnicast));
    hevm.stopPrank();

    uint256 receiverId = omnicast.idOf(to);
    uint256 senderId = omnicast.idOf(myAddress);

    omnicast.sendMessage{value: 0.1 ether}(
      chainId,
      receiverId,
      senderId,
      payload,
      address(0),
      ""
    );

    assertEq0(payload, omnicast.readMessage(receiverId, senderId));
  }

  function testUnauthorizedSend(
    address receiverAddress,
    address senderAddress,
    bytes memory payload
  ) public {
    hevm.assume(
      receiverAddress != address(0) &&
        senderAddress != address(0) &&
        receiverAddress != myAddress &&
        senderAddress != myAddress
    );

    uint256 receiverId = omnicast.idOf(receiverAddress);
    uint256 senderId = omnicast.idOf(senderAddress);

    hevm.expectRevert("Omnicaster: UNAUTHORIZED_CHANNEL");
    omnicast.sendMessage(
      currentChainId,
      receiverId,
      senderId,
      payload,
      address(0),
      ""
    );
  }
}
