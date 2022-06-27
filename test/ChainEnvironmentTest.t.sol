// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "./mocks/LZEndpointMock.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

import {Factory} from "@omniprotocol/Factory.sol";
import {Omnibridge} from "@omniprotocol/Omnibridge.sol";
import {Omnicast} from "@omniprotocol/Omnicast.sol";
import {Omnitoken} from "@omniprotocol/Omnitoken.sol";
import {Passport} from "@omniprotocol/Passport.sol";
import {Space} from "@omniprotocol/Space.sol";
import {Steward} from "@omniprotocol/Steward.sol";

import {BaseDeployment} from "../script/BaseDeployment.sol";

contract ChainEnvironmentTest is DSTestPlus, BaseDeployment {
    bool public isPrimaryChain = true;
    address public beneficiary = hevm.addr(42);
    address public owner = address(this);

    function setUp() public virtual {
        _deploy(owner, address(lzEndpoint), isPrimaryChain);

        steward.setPublicCapability(token.transferFrom.selector, true);
    }

    MockERC20 public dai = new MockERC20("DAI", "DAI", 18);
    LZEndpointMock public lzEndpoint =
        new LZEndpointMock(uint16(block.chainid));
}
