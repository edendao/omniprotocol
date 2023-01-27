// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {ERC20} from "./mixins/ERC20.sol";
import {Omnichain} from "./mixins/Omnichain.sol";

error InvalidAsset();
error Unauthorized();

contract ERC20Vault is Omnichain {
    ERC20 public asset;

    // =============================
    // ======== PublicGood =========
    // =============================
    function _initialize(bytes memory _params) internal override {
        (address _lzEndpoint, address _steward, address _asset) = abi.decode(
            _params,
            (address, address, address)
        );

        if (_asset.code.length == 0) {
            revert InvalidAsset();
        }

        asset = ERC20(_asset);
        __initOmnichain(_lzEndpoint);
        __initStewarded(_steward);
    }

    function circulatingSupply() public view returns (uint256) {
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
    ) external view returns (uint256 nativeFee, uint256 lzFee) {
        (nativeFee, lzFee) = lzEndpoint.estimateFees(
            toChainId,
            address(this),
            abi.encode(toAddress, amount),
            useZRO,
            adapterParams
        );
    }

    event SendToChain(
        address indexed fromAddress,
        uint16 indexed toChainId,
        bytes indexed toAddress,
        uint256 amount,
        uint64 nonce
    );

    function sendFrom(
        address fromAddress,
        uint16 toChainId,
        bytes memory toAddress,
        uint256 amount,
        // solhint-disable-next-line no-unused-vars
        address payable,
        address lzPaymentAddress,
        bytes calldata lzAdapterParams
    ) external payable {
        SafeTransferLib.safeTransferFrom(
            address(asset),
            fromAddress,
            address(this),
            amount
        );

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

    event ReceiveFromChain(
        uint16 indexed fromChainId,
        bytes indexed fromContractAddress,
        address indexed toAddress,
        uint256 amount,
        uint64 nonce
    );

    function receiveMessage(
        uint16 fromChainId,
        bytes calldata fromContractAddress,
        uint64 nonce,
        bytes calldata payload
    ) internal override {
        (bytes memory toAddressB, uint256 amount) = abi.decode(
            payload,
            (bytes, uint256)
        );
        address toAddress = _addressFromPackedBytes(toAddressB);

        SafeTransferLib.safeTransfer(address(asset), toAddress, amount);

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
        if (address(token) == address(asset)) {
            revert Unauthorized();
        }
        super.withdrawToken(token, to, amount);
    }
}
