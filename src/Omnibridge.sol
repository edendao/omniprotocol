// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "@omniprotocol/libraries/SafeTransferLib.sol";
import {IOmnitoken} from "@omniprotocol/interfaces/IOmnitoken.sol";

import {Cloneable} from "@omniprotocol/mixins/Cloneable.sol";
import {Stewarded} from "@omniprotocol/mixins/Stewarded.sol";
import {ERC20} from "@omniprotocol/mixins/ERC20.sol";
import {Omnichain} from "@omniprotocol/mixins/Omnichain.sol";
import {PublicGood} from "@omniprotocol/mixins/PublicGood.sol";

contract Omnibridge is PublicGood, Stewarded, IOmnitoken, Omnichain, Cloneable {
  using SafeTransferLib for ERC20;
  ERC20 public asset;

  constructor(address _beneficiary, address _lzEndpoint) {
    __initPublicGood(_beneficiary);
    __initOmnichain(_lzEndpoint);
  }

  // ================================
  // ========== Cloneable ===========
  // ================================
  function initialize(address _beneficiary, bytes calldata _params)
    external
    override
    initializer
  {
    __initPublicGood(_beneficiary);

    (address _lzEndpoint, address _steward, address _asset) = abi.decode(
      _params,
      (address, address, address)
    );

    __initOmnichain(_lzEndpoint);
    __initStewarded(_steward);

    asset = ERC20(_asset);
  }

  function clone(address _steward, address _asset)
    external
    payable
    returns (address bridgeAddress)
  {
    bridgeAddress = clone(keccak256(abi.encode(_asset)));
    Cloneable(bridgeAddress).initialize(
      beneficiary,
      abi.encode(address(lzEndpoint), _steward, _asset)
    );
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

    asset.safeTransfer(toAddress, amount);

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
  function withdrawToken(address token, uint256 amount) public override {
    require(address(token) != address(asset), "Omnibridge: INVALID_TOKEN");
    super.withdrawToken(token, amount);
  }
}
