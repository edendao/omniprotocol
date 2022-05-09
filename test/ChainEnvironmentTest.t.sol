// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";
import {MockERC20} from "@test/mocks/MockERC20.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Omnitoken} from "@protocol/Omnitoken.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Passport} from "@protocol/Passport.sol";
import {Space} from "@protocol/Space.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public beneficiary = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  MockERC20 public dai = new MockERC20("DAI", "DAI", 18);
  LZEndpointMock public layerZeroEndpoint = new LZEndpointMock(currentChainId);

  Comptroller public comptroller = new Comptroller();
  Omnicast internal omnicast = new Omnicast();
  Space public space =
    new Space(
      address(comptroller),
      address(layerZeroEndpoint),
      address(omnicast),
      currentChainId
    );
  Passport public passport =
    new Passport(address(comptroller), address(omnicast));

  Omnitoken public token = new Omnitoken();

  function setUp() public virtual {
    comptroller.initialize(address(0), abi.encode(address(this)));
    omnicast.initialize(
      beneficiary,
      abi.encode(
        address(comptroller),
        address(layerZeroEndpoint),
        address(space),
        address(passport),
        uint16(block.chainid)
      )
    );
  }
}
