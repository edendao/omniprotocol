// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Note} from "@protocol/Note.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Channel} from "@protocol/Channel.sol";

import {LayerZeroEndpointMock} from "./mocks/LayerZeroEndpointMock.sol";

contract TestBase is DSTestPlus {
  address internal myAddress = address(this);
  address internal owner = hevm.addr(42);

  LayerZeroEndpointMock internal lz =
    new LayerZeroEndpointMock(uint16(block.chainid));

  Comptroller internal authority = new Comptroller(address(owner));

  Note internal edn = new Note(address(authority), address(lz));

  Channel internal channel =
    new Channel(
      address(authority),
      address(lz),
      address(edn),
      uint16(block.chainid)
    );

  Omnicast internal omnicast =
    new Omnicast(
      address(authority),
      address(lz),
      address(edn),
      address(channel)
    );
}
