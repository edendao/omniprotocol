// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";
import {MockERC20} from "@test/mocks/MockERC20.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Omnitoken} from "@protocol/Omnitoken.sol";
import {Omnibridge} from "@protocol/Omnibridge.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Passport} from "@protocol/Passport.sol";
import {Space} from "@protocol/Space.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public beneficiary = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  MockERC20 public dai = new MockERC20("DAI", "DAI", 18);
  LZEndpointMock public lzEndpoint = new LZEndpointMock(currentChainId);

  Comptroller public comptroller = new Comptroller(beneficiary, address(this));

  Omnibridge public bridge = new Omnibridge(beneficiary, address(lzEndpoint));
  Omnitoken public token = new Omnitoken(beneficiary, address(lzEndpoint));

  Omnicast public omnicast =
    new Omnicast(
      address(comptroller),
      address(lzEndpoint),
      lzEndpoint.getChainId()
    );

  Space public space = new Space(address(comptroller), address(omnicast), true);

  Passport public passport =
    new Passport(address(comptroller), address(omnicast));

  function setUp() public virtual {
    omnicast.initialize(
      beneficiary,
      abi.encode(address(space), address(passport))
    );
  }
}
