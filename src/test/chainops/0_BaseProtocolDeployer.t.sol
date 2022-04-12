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

  BaseProtocolDeployer internal base =
    new BaseProtocolDeployer(owner, address(layerZeroEndpoint), primaryChainId);

  Comptroller internal comptroller = base.comptroller();
  Note internal note = base.note();
  Omnicast internal omnicast = base.omnicast();
  Omnichannel internal omnichannel = base.omnichannel();

  function setUp() public {
    hevm.startPrank(owner);

    uint8 noteMinter = 0;
    comptroller.setRoleCapability(noteMinter, note.mintTo.selector, true);
    comptroller.setUserRole(address(omnichannel), noteMinter, true);
    comptroller.setUserRole(address(omnicast), noteMinter, true);

    hevm.stopPrank();
  }
}
