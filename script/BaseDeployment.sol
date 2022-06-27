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

contract BaseDeployment is Script {
    function run() public {
        address owner = vm.envAddress("ETH_FROM");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        bool isPrimary = vm.envBool("PRIMARY");

        vm.startBroadcast(owner);
        run(owner, lzEndpoint, isPrimary);
        vm.stopBroadcast();
    }

    Steward public steward; // Owner & Authority
    Omnitoken internal token; // New, mintable ERC20s
    Omnibridge internal bridge; // Bridge existing ERC20s
    Factory public factory; // Launch new stewards, tokens, and bridges

    Omnicast public omnicast; // Cross-chain Messaging Bridge
    Space public space; // Vanity Namespaces
    Passport public passport; // Identity NFTs

    function run(
        address owner,
        address lzEndpoint,
        bool isPrimary
    ) public {
        steward = new Steward(owner);

        token = new Omnitoken();
        bridge = new Omnibridge();
        factory = new Factory(
            address(steward),
            address(token),
            address(bridge),
            lzEndpoint
        );

        steward.setPublicCapability(token.transferFrom.selector, true);

        omnicast = new Omnicast(address(steward), lzEndpoint);

        space = new Space(address(steward), address(omnicast), isPrimary);
        if (isPrimary) {
            space.mint(owner, "account");
            space.mint(owner, "id");
            space.mint(owner, "passport");
            space.mint(owner, "profile");
            space.mint(owner, "refi");
            space.mint(owner, "tokenuri");
        }

        passport = new Passport(address(steward), address(omnicast));

        omnicast.initialize(
            address(steward),
            abi.encode(address(space), address(passport))
        );
    }
}
