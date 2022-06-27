// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "@layerzerolabs/contracts/interfaces/ILayerZeroReceiver.sol";

import {Stewarded} from "./Stewarded.sol";
import {Pausable} from "./Pausable.sol";
import {PublicGood} from "./PublicGood.sol";

abstract contract Omnichain is
    Stewarded,
    PublicGood,
    Pausable,
    ILayerZeroReceiver
{
    ILayerZeroEndpoint public lzEndpoint;

    function __initOmnichain(address _lzEndpoint) internal {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function _addressFromPackedBytes(bytes memory toAddressBytes)
        internal
        pure
        returns (address toAddress)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }
    }

    // ===================================
    // ========= LAYER ZERO SEND =========
    // ===================================
    mapping(uint16 => bytes) public connections;

    event SetConnection(uint16 onChainId, bytes contractAddress);

    function connect(uint16 onChainId, bytes calldata contractAddress)
        external
        requiresAuth
    {
        connections[onChainId] = contractAddress;
        emit SetConnection(onChainId, contractAddress);
    }

    function isConnection(uint16 onChainId, bytes calldata remote)
        public
        view
        returns (bool)
    {
        return keccak256(remote) == keccak256(connections[onChainId]);
    }

    function lzSend(
        uint16 toChainId,
        bytes memory payload,
        address lzPaymentAddress,
        bytes calldata lzAdapterParams
    ) internal whenNotPaused {
        bytes memory remoteContract = connections[toChainId];
        require(remoteContract.length != 0, "Omnichain: NOT_CONNECTED");

        // solhint-disable-next-line check-send-result
        lzEndpoint.send{value: msg.value}(
            toChainId,
            remoteContract,
            payload,
            payable(beneficiary),
            lzPaymentAddress,
            lzAdapterParams
        );
    }

    // ====================================
    // ======= NONBLOCKING RECEIVER =======
    // ====================================
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
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
                isConnection(fromChainId, fromContract),
            "Omnichain: INVALID_CALLER"
        );

        try this.lzTryReceive(fromChainId, fromContract, nonce, payload) {
            this;
        } catch {
            failedMessagesHash[fromChainId][fromContract][nonce] = keccak256(
                payload
            );
            emit MessageFailed(fromChainId, fromContract, nonce, payload);
        }
    }

    function lzTryReceive(
        uint16 fromChainId,
        bytes calldata fromContract,
        uint64 nonce,
        bytes calldata payload
    ) external {
        require(msg.sender == address(this), "Omnichain: INVALID_CALLER");
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
    ) external whenNotPaused {
        bytes32 payloadHash = failedMessagesHash[fromChainId][fromContract][
            nonce
        ];
        require(payloadHash != bytes32(0), "Omnichain: MESSAGE_NOT_FOUND");
        require(
            keccak256(payload) == payloadHash,
            "Omnichain: INVALID_PAYLOAD"
        );
        // clear the stored message
        failedMessagesHash[fromChainId][fromContract][nonce] = bytes32(0);
        // execute the message, revert if it fails again
        receiveMessage(fromChainId, fromContract, nonce, payload);
    }

    // =================================
    // ======= LAYER ZERO CONFIG =======
    // =================================
    function getConfig(uint16 chainId, uint256 configType)
        public
        view
        returns (bytes memory config)
    {
        config = lzEndpoint.getConfig(
            lzEndpoint.getSendVersion(address(this)),
            chainId,
            address(this),
            configType
        );
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
