// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "@layerzerolabs/contracts/interfaces/ILayerZeroReceiver.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract Omnichain is Comptrolled, ILayerZeroReceiver {
  ILayerZeroEndpoint public immutable lzEndpoint;
  uint16 public immutable currentChainId;

  mapping(uint16 => bytes) public remoteContracts;

  constructor(address _comptroller, address _lzEndpoint)
    Comptrolled(_comptroller)
  {
    lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    currentChainId = uint16(block.chainid);
  }

  function setTrustedRemoteContract(uint16 onChainId, address contractAddress)
    external
    requiresAuth
  {
    remoteContracts[onChainId] = abi.encodePacked(contractAddress);
  }

  function setLzConfig(
    uint16 version,
    uint16 chainId,
    uint256 configType,
    bytes calldata config
  ) external requiresAuth {
    lzEndpoint.setConfig(version, chainId, configType, config);
  }

  function setLzSendVersion(uint16 version) external requiresAuth {
    lzEndpoint.setSendVersion(version);
  }

  function setLzReceiveVersion(uint16 version) external requiresAuth {
    lzEndpoint.setReceiveVersion(version);
  }

  function forceLzResumeReceive(uint16 srcChainId, bytes calldata srcAddress)
    external
    requiresAuth
  {
    lzEndpoint.forceResumeReceive(srcChainId, srcAddress);
  }

  function estimateLzSendGas(
    uint16 toChainId,
    bytes memory payload,
    bool useZRO,
    bytes memory adapterParams
  ) public view returns (uint256 nativeFee, uint256 zroFee) {
    if (toChainId == currentChainId) {
      (nativeFee = 0, zroFee = 0);
    } else {
      (nativeFee, zroFee) = lzEndpoint.estimateFees(
        toChainId,
        address(this),
        payload,
        useZRO,
        adapterParams
      );
    }
  }

  function lzSend(
    uint16 toChainId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) internal {
    (uint256 nativeFee, ) = estimateLzSendGas(toChainId, payload, false, "");
    require(msg.value >= nativeFee, "Omnichain: INSUFFICIENT_VALUE");

    // solhint-disable-next-line check-send-result
    lzEndpoint.send{value: msg.value}(
      toChainId,
      remoteContracts[toChainId],
      payload,
      payable(msg.sender),
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  mapping(uint16 => mapping(bytes => mapping(uint256 => FailedMessage)))
    public failedMessages;

  struct FailedMessage {
    uint256 length;
    bytes32 keccak;
  }

  event MessageFailed(
    uint16 fromChainId,
    bytes fromContractAddress,
    uint64 nonce,
    bytes payload
  );

  function lzReceive(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64 nonce,
    bytes memory payload
  ) external override {
    require(msg.sender == address(lzEndpoint), "Omnichain: INVALID_CALLER");
    require(
      fromContractAddress.length == remoteContracts[fromChainId].length &&
        keccak256(fromContractAddress) ==
        keccak256(remoteContracts[fromChainId]),
      "Omnichain: INVALID_REMOTE_CONTRACT"
    );

    // solhint-disable-next-line no-empty-blocks
    try this.internalReceive(fromChainId, fromContractAddress, nonce, payload) {
      // do nothing
    } catch {
      // error / exception
      failedMessages[fromChainId][fromContractAddress][nonce] = FailedMessage(
        payload.length,
        keccak256(payload)
      );
      emit MessageFailed(fromChainId, fromContractAddress, nonce, payload);
    }
  }

  function internalReceive(
    uint16 fromChainId,
    bytes memory fromContractAddress,
    uint64 nonce,
    bytes memory payload
  ) external {
    require(msg.sender == address(this), "Omnichain: UNAUTHORIZED");
    receiveMessage(fromChainId, fromContractAddress, nonce, payload);
  }

  function receiveMessage(
    uint16 fromChainId,
    bytes memory fromContractAddress,
    uint64 nonce,
    bytes memory payload
  ) internal virtual;

  function retryMessage(
    uint16 fromChainId,
    bytes memory fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) external {
    // assert there is message to retry
    FailedMessage storage message = failedMessages[fromChainId][
      fromContractAddress
    ][nonce];
    require(message.keccak != bytes32(0), "Omnichain: MESSAGE_NOT_FOUND");
    require(
      payload.length == message.length && keccak256(payload) == message.keccak,
      "Omnichain: INVALID_PAYLOAD"
    );
    // clear the stored message
    message.length = 0;
    message.keccak = bytes32(0);
    // execute the message, revert if it fails again
    this.internalReceive(fromChainId, fromContractAddress, nonce, payload);
  }
}
