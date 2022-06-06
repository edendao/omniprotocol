// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {IOmnitoken} from "./interfaces/IOmnitoken.sol";

import {ERC20} from "./mixins/ERC20.sol";
import {Omnichain} from "./mixins/Omnichain.sol";

contract Omnibridge is Omnichain, IOmnitoken {
  using SafeTransferLib for ERC20;
  ERC20 public asset;

  // =============================
  // ======== PublicGood =========
  // =============================
  function _initialize(bytes memory _params) internal override {
    (address _lzEndpoint, address _steward, address _asset) = abi.decode(
      _params,
      (address, address, address)
    );

    __initOmnichain(_lzEndpoint);
    __initStewarded(_steward);

    asset = ERC20(_asset);
  }

  // ===============================
  // ========= IOmnitoken ==========
  // ===============================
  function circulatingSupply() public view virtual override returns (uint256) {
    unchecked {
      return asset.totalSupply() - asset.balanceOf(address(this));
    }
  }

  function estimateSendFee(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    bool useZRO,
    bytes calldata adapterParams
  ) external view override returns (uint256 nativeFee, uint256 lzFee) {
    (nativeFee, lzFee) = lzEndpoint.estimateFees(
      toChainId,
      address(this),
      abi.encode(toAddress, amount),
      useZRO,
      adapterParams
    );
  }

  function sendFrom(
    address fromAddress,
    uint16 toChainId,
    bytes memory toAddress,
    uint256 amount,
    // solhint-disable-next-line no-unused-vars
    address payable,
    address lzPaymentAddress,
    bytes calldata lzAdapterParams
  ) external payable override {
    asset.safeTransferFrom(fromAddress, address(this), amount);

    lzSend(
      toChainId,
      abi.encode(toAddress, amount),
      lzPaymentAddress,
      lzAdapterParams
    );

    emit SendToChain(
      fromAddress,
      toChainId,
      toAddress,
      amount,
      lzEndpoint.getOutboundNonce(toChainId, address(this))
    );
  }

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal virtual override {
    (bytes memory toAddressB, uint256 amount) = abi.decode(
      payload,
      (bytes, uint256)
    );
    address toAddress = _addressFromPackedBytes(toAddressB);

    asset.safeTransferFrom(address(this), toAddress, amount);

    emit ReceiveFromChain(
      fromChainId,
      fromContractAddress,
      toAddress,
      amount,
      nonce
    );
  }

  // ==============================
  // ========= Stewarded ==========
  // ==============================
  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) public override {
    require(address(token) != address(asset), "Omnibridge: INVALID_TOKEN");
    super.withdrawToken(token, to, amount);
  }
}
