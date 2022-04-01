// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { Auth } from "@rari-capital/solmate/auth/Auth.sol";
import { ILayerZeroEndpoint } from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";
import { ILayerZeroReceiver } from "@layerzerolabs/contracts/interfaces/ILayerZeroReceiver.sol";

abstract contract Omnichain is Auth, ILayerZeroReceiver {
  ILayerZeroEndpoint public immutable lzEndpoint;
  mapping(uint16 => bytes) public chainContracts;

  constructor(address _lzEndpoint) {
    lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
  }

  function estimateSendFee(
    uint16 _toChainId,
    bool _useZro,
    bytes calldata txParameters
  ) external view returns (uint256 nativeFee, uint256 zroFee) {
    return
      lzEndpoint.estimateFees(
        _toChainId,
        address(this),
        bytes(""),
        _useZro,
        txParameters
      );
  }

  function setChainContract(uint16 _dstChainId, address _address)
    external
    requiresAuth
  {
    chainContracts[_dstChainId] = abi.encode(_address);
  }

  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint256 _configType,
    bytes calldata _config
  ) external requiresAuth {
    lzEndpoint.setConfig(_version, _chainId, _configType, _config);
  }

  function setSendVersion(uint16 version) external requiresAuth {
    lzEndpoint.setSendVersion(version);
  }

  function setReceiveVersion(uint16 version) external requiresAuth {
    lzEndpoint.setReceiveVersion(version);
  }

  function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    requiresAuth
  {
    lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
  }
}
