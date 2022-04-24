// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import {LZEndpointMock} from "@protocol/test/mocks/LZEndpointMock.sol";

import {Note} from "@protocol/mint/Note.sol";
import {Omnicast} from "@protocol/omnicast/Omnicast.sol";
import {Omnichannel} from "@protocol/omnicast/Omnichannel.sol";

import {Proxy} from "@protocol/auth/Proxy.sol";
import {Comptroller} from "@protocol/auth/Comptroller.sol";

contract ChainEnvironmentTest is DSTestPlus {
  address public myAddress = address(this);
  address public ownerAddress = hevm.addr(42);

  uint16 public currentChainId = uint16(block.chainid);

  LZEndpointMock public layerZeroEndpoint = new LZEndpointMock(currentChainId);

  Proxy public proxy = new Proxy();

  Comptroller public comptroller = new Comptroller(address(this));

  Note public note = new Note(address(comptroller), "Eden Dao", "EDN", 3);

  Omnichannel public omnichannel =
    new Omnichannel(
      address(comptroller),
      address(layerZeroEndpoint),
      currentChainId
    );

  Omnicast public omnicast =
    new Omnicast(
      address(comptroller),
      address(layerZeroEndpoint),
      address(omnichannel)
    );
}
