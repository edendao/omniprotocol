// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Stewarded} from "./mixins/Stewarded.sol";
import {EdenDaoNS} from "./mixins/EdenDaoNS.sol";

contract Registry is Stewarded, EdenDaoNS {
  constructor(address _steward) {
    __initStewarded(_steward);
  }

  mapping(string => address) public tokenForSymbol;

  function setTokenForSymbol(string memory symbol, address token)
    public
    requiresAuth
  {
    tokenForSymbol[symbol] = token;
  }

  mapping(address => address) public bridgeForAsset;

  function setBridgeForAsset(address asset, address bridge)
    public
    requiresAuth
  {
    bridgeForAsset[asset] = bridge;
  }
}
