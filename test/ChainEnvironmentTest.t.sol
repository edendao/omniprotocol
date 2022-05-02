// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";

import {Proxy} from "@protocol/auth/Proxy.sol";
import {Comptroller} from "@protocol/auth/Comptroller.sol";

import {Passport} from "@protocol/omnicast/Passport.sol";
import {Space} from "@protocol/omnicast/Space.sol";
import {Omnicast} from "@protocol/omnicast/Omnicast.sol";

import {Note} from "@protocol/omnibridge/Note.sol";
import {Reserve} from "@protocol/omnibridge/Reserve.sol";
import {Omnibridge} from "@protocol/omnibridge/Omnibridge.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public myAddress = address(this);
  address public ownerAddress = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  LZEndpointMock public layerZeroEndpoint = new LZEndpointMock(currentChainId);

  Proxy public proxy = new Proxy();

  Comptroller public comptroller = new Comptroller();

  Note public noteImplementation = new Note();
  Note public note;

  Reserve public reserveImplementation = new Reserve();
  Reserve public reserve;

  Omnicast internal omnicast =
    new Omnicast(address(layerZeroEndpoint), address(comptroller));

  Space public space =
    new Space(address(comptroller), address(omnicast), currentChainId);

  Passport public passport =
    new Passport(address(comptroller), address(omnicast));

  Omnibridge public bridge =
    new Omnibridge(
      address(layerZeroEndpoint),
      address(comptroller),
      address(noteImplementation),
      address(reserveImplementation)
    );

  function setUp() public virtual {
    comptroller.initialize(address(0), abi.encode(address(this)));
    hevm.label(address(comptroller), "COMPTROLLER");
    note = bridge.createNote(
      address(comptroller),
      "Frontier Carbon",
      "TIME",
      3
    );
    hevm.label(address(note), "TIME");
    reserve = bridge.createReserve(
      address(comptroller),
      address(note),
      "Frontier Carbon",
      "TIME"
    );
    hevm.label(address(reserve), "edn-TIME");

    omnicast.setContracts(address(space), address(passport));
  }
}
