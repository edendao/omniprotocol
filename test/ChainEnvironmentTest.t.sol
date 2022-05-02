// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@test/mocks/LZEndpointMock.sol";

import {Note} from "@protocol/omnibridge/Note.sol";
import {Passport} from "@protocol/omnicast/Passport.sol";
import {Space} from "@protocol/omnicast/Space.sol";
import {Omnicast} from "@protocol/omnicast/Omnicast.sol";

import {Proxy} from "@protocol/auth/Proxy.sol";
import {Comptroller} from "@protocol/auth/Comptroller.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public myAddress = address(this);
  address public ownerAddress = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  LZEndpointMock public layerZeroEndpoint = new LZEndpointMock(currentChainId);

  Proxy public proxy = new Proxy();

  Comptroller public comptroller = new Comptroller(address(this));

  Omnicast internal omnicast =
    new Omnicast(address(comptroller), address(layerZeroEndpoint));

  Note public note =
    new Note(address(comptroller), address(comptroller), "Eden Dao", "EDN", 3);

  Space public space =
    new Space(address(comptroller), address(omnicast), currentChainId);

  Passport public passport =
    new Passport(address(comptroller), address(omnicast));

  function setUp() public virtual {
    omnicast.setSpace(address(space));
    omnicast.setPassport(address(passport));
  }
}
