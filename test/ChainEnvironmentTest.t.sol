// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";
import {MockERC20} from "@test/mocks/MockERC20.sol";

import {Steward} from "@omniprotocol/Steward.sol";
import {Omnitoken} from "@omniprotocol/Omnitoken.sol";
import {Omnibridge} from "@omniprotocol/Omnibridge.sol";
import {Omnicast} from "@omniprotocol/Omnicast.sol";
import {Passport} from "@omniprotocol/Passport.sol";
import {Space} from "@omniprotocol/Space.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public beneficiary = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  MockERC20 public dai = new MockERC20("DAI", "DAI", 18);
  LZEndpointMock public lzEndpoint = new LZEndpointMock(currentChainId);

  Steward public steward = new Steward(beneficiary, address(this));

  Omnibridge public bridge = new Omnibridge(beneficiary, address(lzEndpoint));
  Omnitoken public token = new Omnitoken(beneficiary, address(lzEndpoint));

  Omnicast public omnicast =
    new Omnicast(
      address(steward),
      address(lzEndpoint),
      lzEndpoint.getChainId()
    );

  Space public space = new Space(address(steward), address(omnicast), true);

  Passport public passport = new Passport(address(steward), address(omnicast));

  function setUp() public virtual {
    omnicast.initialize(
      beneficiary,
      abi.encode(address(space), address(passport))
    );

    steward.setPublicCapability(token.transferFrom.selector, true);
  }
}
