// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "./mixins/ERC721.sol";
import {Stewarded} from "./mixins/Stewarded.sol";
import {Omnichain} from "./mixins/Omnichain.sol";
import {PublicGood} from "./mixins/PublicGood.sol";

contract ERC721Note is ERC721, Omnichain {
    // ================================
    // ======== Initializable =========
    // ================================
    function _initialize(bytes memory _params) internal virtual override {
        (
            address _lzEndpoint,
            address _steward,
            string memory _name,
            string memory _symbol
        ) = abi.decode(_params, (address, address, string, string));

        __initOmnichain(_lzEndpoint);
        __initStewarded(_steward);
        __initERC721(_name, _symbol);
    }

    // ================================
    // ============ ERC721 =============
    // ================================
    mapping(uint256 => string) internal _tokenURI;

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _tokenURI[id];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 id
    ) public override {
        require(
            // transferFrom.selector
            isAuthorized(sender, 0x23b872dd) &&
                isAuthorized(recipient, 0x23b872dd),
            "UNAUTHORIZED"
        );
        super.transferFrom(sender, recipient, id);
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
            abi.encode(toAddress, id),
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
        require(
            msg.sender == fromAddress ||
                isApprovedForAll[fromAddress][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        _burn(id);
        _tokenURI[id] = "";

        lzSend(
            toChainId,
            abi.encode(toAddress, id),
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
        (bytes memory toAddressB, uint256 id, string memory uri) = abi.decode(
            payload,
            (bytes, uint256, string)
        );
        address toAddress = _addressFromPackedBytes(toAddressB);

        _mint(toAddress, id);
        _tokenURI[id] = uri;

        emit ReceiveFromChain(
            fromChainId,
            fromContractAddress,
            toAddress,
            id,
            nonce
        );
    }
}
