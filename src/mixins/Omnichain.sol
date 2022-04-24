// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "@layerzerolabs/contracts/interfaces/ILayerZeroReceiver.sol";

import {Pausable} from "@protocol/mixins/Pausable.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract Omnichain is Comptrolled, Pausable, ILayerZeroReceiver {
  ILayerZeroEndpoint public immutable lzEndpoint;
  uint16 public immutable currentChainId;

  constructor(address _comptroller, address _lzEndpoint)
    Comptrolled(_comptroller)
  {
    lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    currentChainId = uint16(block.chainid);
  }

  function addressFromPackedBytes(bytes memory toAddressBytes)
    public
    pure
    returns (address toAddress)
  {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      toAddress := mload(add(toAddressBytes, 20))
    }
  }

  // =============================
  // ======= REMOTE CONFIG =======
  // =============================
  mapping(uint16 => bytes) public remoteContracts;

  event SetTrustedRemote(uint16 onChainId, bytes contractAddress);

  function setTrustedRemoteContract(
    uint16 onChainId,
    bytes calldata contractAddress
  ) external requiresAuth {
    remoteContracts[onChainId] = contractAddress;
    emit SetTrustedRemote(onChainId, contractAddress);
  }

  function isTrustedRemoteContract(
    uint16 onChainId,
    bytes calldata contractAddress
  ) public view returns (bool) {
    return keccak256(contractAddress) == keccak256(remoteContracts[onChainId]);
  }

  // ===============================
  // ======= LAYER ZERO SEND =======
  // ===============================
  function lzEstimateSendGas(
    uint16 toChainId,
    bytes memory payload,
    bool useZRO,
    bytes memory adapterParams
  ) internal view returns (uint256, uint256) {
    return
      lzEndpoint.estimateFees(
        toChainId,
        address(this),
        payload,
        useZRO,
        adapterParams
      );
  }

  function lzSend(
    uint16 toChainId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) internal whenNotPaused {
    bytes memory remoteContract = remoteContracts[toChainId];
    require(remoteContract.length != 0, "Omnichain: INVALID_DESTINATION");

    // solhint-disable-next-line check-send-result
    lzEndpoint.send{value: msg.value}(
      toChainId,
      remoteContract,
      payload,
      payable(msg.sender),
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  // ==================================
  // ======= LAYER ZERO RECEIVE =======
  // ==================================
  mapping(uint16 => mapping(bytes => mapping(uint256 => bytes32)))
    public failedMessagesHash;

  event MessageFailed(
    uint16 indexed fromChainId,
    bytes indexed fromContract,
    uint64 nonce,
    bytes payload
  );

  function lzReceive(
    uint16 fromChainId,
    bytes calldata fromContract,
    uint64 nonce,
    bytes calldata payload
  ) external override {
    require(
      msg.sender == address(lzEndpoint) &&
        isTrustedRemoteContract(fromChainId, fromContract),
      "Omnichain: INVALID_CALLER"
    );

    try this.lzTryReceive(fromChainId, fromContract, nonce, payload) {
      this;
    } catch {
      failedMessagesHash[fromChainId][fromContract][nonce] = keccak256(payload);
      emit MessageFailed(fromChainId, fromContract, nonce, payload);
    }
  }

  function lzTryReceive(
    uint16 fromChainId,
    bytes calldata fromContract,
    uint64 nonce,
    bytes calldata payload
  ) external {
    require(msg.sender == address(this), "Omnichain: INTERNAL");
    receiveMessage(fromChainId, fromContract, nonce, payload);
  }

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata fromContract,
    uint64 nonce,
    bytes calldata payload
  ) internal virtual;

  function retryMessage(
    uint16 fromChainId,
    bytes calldata fromContract,
    uint64 nonce,
    bytes calldata payload
  ) external {
    // assert there is message to retry
    bytes32 payloadHash = failedMessagesHash[fromChainId][fromContract][nonce];
    require(payloadHash != bytes32(0), "Omnichain: MESSAGE_NOT_FOUND");
    require(keccak256(payload) == payloadHash, "Omnichain: INVALID_PAYLOAD");
    // clear the stored message
    failedMessagesHash[fromChainId][fromContract][nonce] = bytes32(0);
    // execute the message, revert if it fails again
    receiveMessage(fromChainId, fromContract, nonce, payload);
  }

  // =================================
  // ======= LAYER ZERO CONFIG =======
  // =================================
  function lzGetConfig(uint16 chainId, uint256 configType)
    public
    view
    returns (bytes memory)
  {
    return
      lzEndpoint.getConfig(
        lzEndpoint.getSendVersion(address(this)),
        chainId,
        address(this),
        configType
      );
  }

  function lzSetConfig(
    uint16 version,
    uint16 chainId,
    uint256 configType,
    bytes calldata config
  ) external requiresAuth {
    lzEndpoint.setConfig(version, chainId, configType, config);
  }

  function lzSetSendVersion(uint16 version) external requiresAuth {
    lzEndpoint.setSendVersion(version);
  }

  function lzSetReceiveVersion(uint16 version) external requiresAuth {
    lzEndpoint.setReceiveVersion(version);
  }

  function lzForceResumeReceive(uint16 srcChainId, bytes calldata srcAddress)
    external
    requiresAuth
  {
    lzEndpoint.forceResumeReceive(srcChainId, srcAddress);
  }
}
