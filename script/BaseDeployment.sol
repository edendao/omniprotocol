// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";

import {ERC20Note} from "@omniprotocol/ERC20Note.sol";
import {ERC20Vault} from "@omniprotocol/ERC20Vault.sol";
import {ERC721Note} from "@omniprotocol/ERC721Note.sol";
import {ERC721Vault} from "@omniprotocol/ERC721Vault.sol";
import {Factory} from "@omniprotocol/Factory.sol";
import {Omnicast} from "@omniprotocol/Omnicast.sol";
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
    ERC20Note internal erc20note; // New, mintable ERC20s
    ERC20Vault internal erc20vault; // erc20vault existing ERC20s
    ERC721Note internal erc721note; // New, mintable ERC721s
    ERC721Vault internal erc721vault; // erc721vault existing ERC721s
    Factory public factory; // Launch new stewards, erc20notes, and erc20vaults

    Omnicast public omnicast; // Cross-chain Messagingerc20vault
    Space public space; // Vanity Namespaces
    Passport public passport; // Identity NFTs

    function run(
        address owner,
        address lzEndpoint,
        bool isPrimary
    ) public {
        steward = new Steward(owner);

        erc20note = new ERC20Note();
        erc20vault = new ERC20Vault();
        erc721note = new ERC721Note();
        erc721vault = new ERC721Vault();
        factory = new Factory(
            address(steward),
            address(erc20note),
            address(erc20vault),
            address(erc721note),
            address(erc721vault),
            lzEndpoint
        );

        steward.setPublicCapability(erc20note.transferFrom.selector, true);

        omnicast = new Omnicast(address(steward), lzEndpoint);

        space = new Space(address(steward), address(omnicast), isPrimary);
        if (isPrimary) {
            space.mint(owner, "account");
            space.mint(owner, "id");
            space.mint(owner, "passport");
            space.mint(owner, "profile");
            space.mint(owner, "refi");
            space.mint(owner, "erc20noteuri");
        }

        passport = new Passport(address(steward), address(omnicast));

        omnicast.initialize(
            address(steward),
            abi.encode(address(space), address(passport))
        );
    }
}
