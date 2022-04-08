// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Auth} from "@rari-capital/solmate/auth/Auth.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "@layerzerolabs/contracts/interfaces/ILayerZeroReceiver.sol";

abstract contract Omnichain is Auth, ILayerZeroReceiver {
  ILayerZeroEndpoint public immutable lzEndpoint;
  mapping(uint16 => bytes) public remoteContracts;
  uint16 public immutable currentChainId;

  mapping(uint16 => mapping(bytes => mapping(uint256 => FailedMessages)))
    public failedMessages;

  struct FailedMessages {
    uint256 payloadLength;
    bytes32 payloadHash;
  }

  event LayerZeroReceiveFailed(
    uint16 fromChainId,
    bytes fromContractAddress,
    uint64 nonce,
    bytes payload
  );

  constructor(address _lzEndpoint) {
    lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    currentChainId = uint16(block.chainid);
  }

  function estimateLayerZeroSendFee(
    uint16 toChainId,
    bool useZRO,
    bytes calldata payload,
    bytes calldata adapterParams
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
    require(onChainId != currentChainId, "Omnichain: Current Chain");
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

  function lzSend(
    uint16 toChainId,
    bytes memory payload,
    address zroPaymentAddress,
    bytes memory adapterParams
  ) internal {
    // solhint-disable-next-line
    lzEndpoint.send{value: msg.value}(
      toChainId,
      remoteContracts[toChainId],
      payload,
      payable(address(authority)),
      zroPaymentAddress,
      adapterParams
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
      "Omnichain: Invalid caller for lzReceive"
    );

    // solhint-disable-next-line no-empty-blocks
    try this.selfReceive(fromChainId, fromContractAddress, nonce, payload) {
      // do nothing
    } catch {
      // error / exception
      failedMessages[fromChainId][fromContractAddress][nonce] = FailedMessages(
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

  function selfReceive(
    uint16 fromChainId,
    bytes memory fromContractAddress,
    uint64 nonce,
    bytes memory payload
  ) public {
    require(msg.sender == address(this), "UNAUTHENTICATED");
    onReceive(fromChainId, fromContractAddress, nonce, payload);
  }

  function onReceive(
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
    FailedMessages storage message = failedMessages[fromChainId][
      fromContractAddress
    ][nonce];
    require(
      message.payloadHash != bytes32(0),
      "NonblockingReceiver: no stored message"
    );
    require(
      payload.length == message.payloadLength &&
        keccak256(payload) == message.payloadHash,
      "LayerZero: Invalid Payload"
    );
    // clear the stored message
    message.payloadLength = 0;
    message.payloadHash = bytes32(0);
    // execute the message. revert if it fails again
    this.selfReceive(fromChainId, fromContractAddress, nonce, payload);
  }
}
