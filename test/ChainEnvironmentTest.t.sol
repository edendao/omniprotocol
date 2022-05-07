// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";
import {NoteMock} from "@test/mocks/NoteMock.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Note} from "@protocol/Note.sol";
import {Omnibridge} from "@protocol/Omnibridge.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Passport} from "@protocol/Passport.sol";
import {Reserve} from "@protocol/Reserve.sol";
import {Space} from "@protocol/Space.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public ownerAddress = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  NoteMock public dai = new NoteMock("DAI", "DAI", 18);
  LZEndpointMock public layerZeroEndpoint = new LZEndpointMock(currentChainId);

  Comptroller public comptroller = new Comptroller();

  Omnicast internal omnicast =
    new Omnicast(address(layerZeroEndpoint), address(comptroller));
  Space public space =
    new Space(address(comptroller), address(omnicast), currentChainId);
  Passport public passport =
    new Passport(address(comptroller), address(omnicast));

  Note public noteImplementation = new Note();
  Reserve public reserveImplementation = new Reserve();
  Omnibridge public bridge =
    new Omnibridge(
      address(layerZeroEndpoint),
      address(comptroller),
      address(noteImplementation),
      address(reserveImplementation)
    );

  function setUp() public virtual {
    comptroller.initialize(address(0), abi.encode(address(this)));
    omnicast.setContracts(address(space), address(passport));
  }
}
