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

  modifier onlyRelayer(uint16 fromChainId, bytes calldata fromContractAddress) {
    require(
      msg.sender == address(lzEndpoint) &&
        fromContractAddress.length == chainContracts[fromChainId].length &&
        keccak256(fromContractAddress) ==
        keccak256(chainContracts[fromChainId]),
      "Omnichain: Invalid caller for lzReceive"
    );
    _;
  }

  function estimateSendFee(
    uint16 toChainId,
    bool useZro,
    bytes calldata txParameters
  ) public view returns (uint256 nativeFee, uint256 zroFee) {
    return
      lzEndpoint.estimateFees(
        toChainId,
        address(this),
        bytes(""),
        useZro,
        txParameters
      );
  }

  function setChainContract(uint16 toChainId, address contractAddress)
    external
    requiresAuth
  {
    require(
      toChainId != block.chainid,
      "Omnichain: Cannot set contract for deployed chain"
    );
    chainContracts[toChainId] = abi.encode(contractAddress);
  }

  function setConfig(
    uint16 version,
    uint16 chainId,
    uint256 configType,
    bytes calldata config
  ) external requiresAuth {
    lzEndpoint.setConfig(version, chainId, configType, config);
  }

  function setSendVersion(uint16 version) external requiresAuth {
    lzEndpoint.setSendVersion(version);
  }

  function setReceiveVersion(uint16 version) external requiresAuth {
    lzEndpoint.setReceiveVersion(version);
  }

  function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress)
    external
    requiresAuth
  {
    lzEndpoint.forceResumeReceive(srcChainId, srcAddress);
  }
}
