// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import {LayerZeroEndpointMock} from "@protocol/test/mocks/LayerZeroEndpointMock.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Note} from "@protocol/Note.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Omnichannel} from "@protocol/Omnichannel.sol";

contract TestEnvironment is DSTestPlus {
  address internal myAddress = address(this);
  address internal ownerAddress = hevm.addr(42);

  uint16 internal currentChainId = uint16(block.chainid);
  LayerZeroEndpointMock internal layerZeroEndpoint =
    new LayerZeroEndpointMock(currentChainId);

  Comptroller internal comptroller = new Comptroller(address(this));

  Note internal note =
    new Note(address(comptroller), address(layerZeroEndpoint));

  Omnichannel internal omnichannel =
    new Omnichannel(
      address(comptroller),
      address(layerZeroEndpoint),
      currentChainId
    );

  Omnicast internal omnicast =
    new Omnicast(
      address(comptroller),
      address(layerZeroEndpoint),
      address(omnichannel)
    );
}
