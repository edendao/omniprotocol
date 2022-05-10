// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";
import {MockERC20} from "@test/mocks/MockERC20.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Omnitoken} from "@protocol/Omnitoken.sol";
import {Tokenbridge} from "@protocol/Tokenbridge.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Passport} from "@protocol/Passport.sol";
import {Space} from "@protocol/Space.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public beneficiary = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  MockERC20 public dai = new MockERC20("DAI", "DAI", 18);
  LZEndpointMock public lzEndpoint = new LZEndpointMock(currentChainId);

  Comptroller public comptroller = new Comptroller(beneficiary, address(this));

  Tokenbridge public bridge = new Tokenbridge(beneficiary, address(lzEndpoint));
  Omnitoken public token = new Omnitoken(beneficiary, address(lzEndpoint));

  Omnicast public omnicast =
    new Omnicast(
      address(lzEndpoint),
      address(comptroller),
      lzEndpoint.getChainId()
    );

  Space public space =
    new Space(
      address(lzEndpoint),
      address(comptroller),
      address(omnicast),
      true
    );

  Passport public passport =
    new Passport(address(comptroller), address(omnicast));

  function setUp() public virtual {
    omnicast.initialize(
      beneficiary,
      abi.encode(address(space), address(passport))
    );
  }
}
