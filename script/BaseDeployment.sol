// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";

import {ERC20Note} from "@omniprotocol/ERC20Note.sol";
import {ERC20Vault} from "@omniprotocol/ERC20Vault.sol";
import {Factory} from "@omniprotocol/Factory.sol";
import {Steward} from "@omniprotocol/Steward.sol";

contract BaseDeployment is Script {
    function run() public {
        address owner = vm.envAddress("ETH_FROM");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");

        vm.startBroadcast(owner);
        run(owner, lzEndpoint);
        vm.stopBroadcast();
    }

    Steward public steward; // Owner & Authority
    ERC20Note internal erc20note; // New, mintable ERC20s
    ERC20Vault internal erc20vault; // erc20vault existing ERC20s
    Factory public factory; // Launch new stewards, erc20notes, and erc20vaults

    function run(address owner, address lzEndpoint) public {
        steward = new Steward(owner);

        erc20note = new ERC20Note();
        erc20vault = new ERC20Vault();
        factory = new Factory(
            address(steward),
            address(erc20note),
            address(erc20vault),
            lzEndpoint
        );

        steward.setPublicCapability(erc20note.transferFrom.selector, true);
    }
}
