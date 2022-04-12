// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import {LayerZeroEndpointMock} from "@protocol/test/mocks/LayerZeroEndpointMock.sol";

import {BaseProtocolDeployer} from "@protocol/chainops/0_BaseProtocolDeployer.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Note} from "@protocol/Note.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Omnichannel} from "@protocol/Omnichannel.sol";

contract BaseProtocolDeployerTest is DSTestPlus {
  address internal myAddress = address(this);
  address internal owner = hevm.addr(42);

  uint16 internal primaryChainId = uint16(block.chainid);
  LayerZeroEndpointMock internal layerZeroEndpoint =
    new LayerZeroEndpointMock(primaryChainId);

  BaseProtocolDeployer internal protocol =
    new BaseProtocolDeployer(owner, address(layerZeroEndpoint), primaryChainId);

  Comptroller internal comptroller = protocol.comptroller();
  Note internal note = protocol.note();
  Omnicast internal omnicast = protocol.omnicast();
  Omnichannel internal omnichannel = protocol.omnichannel();
}
