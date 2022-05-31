// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";

import {Factory} from "@omniprotocol/Factory.sol";
import {Omnibridge} from "@omniprotocol/Omnibridge.sol";
import {Omnicast} from "@omniprotocol/Omnicast.sol";
import {Omnitoken} from "@omniprotocol/Omnitoken.sol";
import {Passport} from "@omniprotocol/Passport.sol";
import {Space} from "@omniprotocol/Space.sol";
import {Steward} from "@omniprotocol/Steward.sol";

contract ChainDeployment is Script {
  function run() public {
    address owner = vm.envAddress("ETH_FROM");
    _deploy(vm.envAddress("BENEFICIARY"), owner, vm.envAddress("LZ_ENDPOINT"));
  }

  Steward public steward; // Owner & Authority
  Omnitoken internal token; // New, mintable ERC20s
  Omnibridge internal bridge; // Bridge existing ERC20s
  Factory public factory; // Launch new stewards, tokens, and bridges

  Omnicast public omnicast; // Cross-chain Messaging Bridge
  Space public space; // Vanity Namespaces
  Passport public passport; // Identity NFTs

  function _deploy(
    address beneficiary,
    address owner,
    address lzEndpoint
  ) internal {
    vm.startBroadcast(owner);

    steward = new Steward(beneficiary, owner);

    token = new Omnitoken();
    bridge = new Omnibridge();
    factory = new Factory(
      beneficiary,
      address(lzEndpoint),
      address(steward),
      address(token),
      address(bridge)
    );

    omnicast = new Omnicast(
      address(steward),
      address(lzEndpoint),
      ILayerZeroEndpoint(lzEndpoint).getChainId()
    );

    space = new Space(beneficiary, address(steward), address(omnicast), true);
    passport = new Passport(address(steward), address(omnicast));

    omnicast.initialize(
      beneficiary,
      abi.encode(address(space), address(passport))
    );

    vm.stopBroadcast();
  }
}
