// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";

import {ERC721} from "./mixins/ERC721.sol";
import {Omnichain} from "./mixins/Omnichain.sol";

contract ERC721Vault is ERC721, Omnichain {
    ERC721 public asset;
    mapping(uint256 => string) internal _tokenURI;

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

        asset = ERC721(_asset);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _tokenURI[id];
    }

    function estimateSendFee(
        uint16 toChainId,
        bytes calldata toAddress,
        uint256 id,
        bool useZRO,
        bytes calldata adapterParams
    ) external view returns (uint256 nativeFee, uint256 lzFee) {
        (nativeFee, lzFee) = lzEndpoint.estimateFees(
            toChainId,
            address(this),
            abi.encode(toAddress, id, asset.tokenURI(id)),
            useZRO,
            adapterParams
        );
    }

    event SendToChain(
        address indexed fromAddress,
        uint16 indexed toChainId,
        bytes indexed toAddress,
        uint256 id,
        uint64 nonce
    );

    event ReceiveFromChain(
        uint16 indexed fromChainId,
        bytes indexed fromContractAddress,
        address indexed toAddress,
        uint256 id,
        uint64 nonce
    );

    function sendFrom(
        address fromAddress,
        uint16 toChainId,
        bytes memory toAddress,
        uint256 id,
        // solhint-disable-next-line no-unused-vars
        address payable,
        address lzPaymentAddress,
        bytes calldata lzAdapterParams
    ) external payable {
        asset.transferFrom(fromAddress, address(this), id);

        lzSend(
            toChainId,
            abi.encode(toAddress, id, asset.tokenURI(id)),
            lzPaymentAddress,
            lzAdapterParams
        );

        emit SendToChain(
            fromAddress,
            toChainId,
            toAddress,
            id,
            lzEndpoint.getOutboundNonce(toChainId, address(this))
        );
    }

    function receiveMessage(
        uint16 fromChainId,
        bytes calldata fromContractAddress,
        uint64 nonce,
        bytes calldata payload
    ) internal override {
        (bytes memory toAddressB, uint256 id) = abi.decode(
            payload,
            (bytes, uint256)
        );
        address toAddress = _addressFromPackedBytes(toAddressB);

        asset.safeTransferFrom(address(this), toAddress, id);

        _burn(id);
        _tokenURI[id] = "";

        emit ReceiveFromChain(
            fromChainId,
            fromContractAddress,
            toAddress,
            id,
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
        require(address(token) != address(asset), "ERC721Vault: INVALID_TOKEN");
        super.withdrawToken(token, to, amount);
    }
}
