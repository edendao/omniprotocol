// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC20} from "./interfaces/IERC20.sol";
import {Stewarded} from "./mixins/Stewarded.sol";

interface Bridge {
    function asset() external view returns (IERC20);
}

contract Registry is Stewarded {
    constructor(address _steward) {
        __initStewarded(_steward);
    }

    mapping(string => address) public tokenForSymbol;
    event TokenUpdated(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals
    );

    function registerToken(address _token) public requiresAuth {
        IERC20 token = IERC20(_token);
        tokenForSymbol[token.symbol()] = _token;
        emit TokenUpdated(
            _token,
            token.name(),
            token.symbol(),
            token.decimals()
        );
    }

    mapping(address => address) public bridgeForAsset;
    event BridgeUpdated(
        address indexed asset,
        address indexed bridge,
        string name,
        string symbol,
        uint8 decimals
    );

    function registerBridge(address _bridge) public requiresAuth {
        Bridge bridge = Bridge(_bridge);
        address assetAddress = address(bridge.asset());
        bridgeForAsset[assetAddress] = _bridge;
        emit BridgeUpdated(
            assetAddress,
            _bridge,
            bridge.asset().name(),
            bridge.asset().symbol(),
            bridge.asset().decimals()
        );
    }
}
