// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "@layerzerolabs/contracts/interfaces/ILayerZeroReceiver.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract Omnichain is Comptrolled, ILayerZeroReceiver {
  ILayerZeroEndpoint public immutable lzEndpoint;
  mapping(uint16 => bytes) public remoteContracts;
  uint16 public immutable currentChainId;

  mapping(uint16 => mapping(bytes => mapping(uint256 => FailedMessage)))
    public failedMessages;

  struct FailedMessage {
    uint256 payloadLength;
    bytes32 payloadHash;
  }

  event LayerZeroReceiveFailed(
    uint16 fromChainId,
    bytes fromContractAddress,
    uint64 nonce,
    bytes payload
  );

  constructor(address _authority, address _lzEndpoint) Comptrolled(_authority) {
    lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    currentChainId = uint16(block.chainid);
  }

  function estimateLzSendGas(
    uint16 toChainId,
    bytes memory payload,
    bool useZRO,
    bytes memory adapterParams
  ) public view returns (uint256 nativeFee, uint256 zroFee) {
    return
      lzEndpoint.estimateFees(
        toChainId,
        address(this),
        payload,
        useZRO,
        adapterParams
      );
  }

  function setTrustedRemoteContract(uint16 onChainId, address contractAddress)
    external
    requiresAuth
  {
    require(onChainId != currentChainId, "Omnichain: INVALID_CHAIN");
    remoteContracts[onChainId] = abi.encode(contractAddress);
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

  function lzSend(uint16 toChainId, bytes memory payload) internal {
    (uint256 nativeFee, ) = estimateLzSendGas(toChainId, payload, false, "");
    require(msg.value >= nativeFee, "Omnichain: INSUFFICIENT_VALUE");

    // solhint-disable-next-line check-send-result
    lzEndpoint.send{value: msg.value}(
      toChainId,
      remoteContracts[toChainId],
      payload,
      payable(msg.sender),
      comptrollerAddress(),
      comptroller().layerZeroTransactionParams()
    );
  }

  function lzReceive(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64 nonce,
    bytes memory payload
  ) external override {
    require(
      msg.sender == address(lzEndpoint) &&
        fromContractAddress.length == remoteContracts[fromChainId].length &&
        keccak256(fromContractAddress) ==
        keccak256(remoteContracts[fromChainId]),
      "Omnichain: INVALID_LZ_RECEIVE_CALLER"
    );

    // solhint-disable-next-line no-empty-blocks
    try this.selfReceive(fromChainId, fromContractAddress, nonce, payload) {
      // do nothing
    } catch {
      // error / exception
      failedMessages[fromChainId][fromContractAddress][nonce] = FailedMessage(
        payload.length,
        keccak256(payload)
      );
      emit LayerZeroReceiveFailed(
        fromChainId,
        fromContractAddress,
        nonce,
        payload
      );
    }
  }

  // Try can only be used with external function calls
  function selfReceive(
    uint16 fromChainId,
    bytes memory fromContractAddress,
    uint64 nonce,
    bytes memory payload
  ) public {
    require(msg.sender == address(this), "Omnichain: ONLY_SELF");
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
  ) external payable {
    // assert there is message to retry
    FailedMessage storage message = failedMessages[fromChainId][
      fromContractAddress
    ][nonce];
    require(message.payloadHash != bytes32(0), "Omnichain: MESSAGE_NOT_FOUND");
    require(
      payload.length == message.payloadLength &&
        keccak256(payload) == message.payloadHash,
      "LayerZero: INVALID_PAYLOAD"
    );
    // clear the stored message
    message.payloadLength = 0;
    message.payloadHash = bytes32(0);
    // execute the message. revert if it fails again
    this.selfReceive(fromChainId, fromContractAddress, nonce, payload);
  }
}
