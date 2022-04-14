// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, console} from "@protocol/test/ChainEnvironment.t.sol";

contract OmnicasterTest is ChainEnvironmentTest {
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

  function testSendingOmniMessage(
    uint16 chainId,
    address to,
    bytes memory payload
  ) public {
    hevm.assume(to != address(0) && chainId != 0);

    bytes memory remoteAddressBytes = abi.encodePacked(address(omnicast));
    omnicast.setTrustedRemoteContract(chainId, remoteAddressBytes);
    omnicast.setTrustedRemoteContract(currentChainId, remoteAddressBytes);
    layerZeroEndpoint.setDestLzEndpoint(
      address(omnicast),
      address(layerZeroEndpoint)
    );

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

    assertEq(1, omnicast.receivedMessagesCount(receiverId, senderId));
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
