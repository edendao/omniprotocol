// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

import {Steward} from "@omniprotocol/Steward.sol";

contract AssignCapabilities is Script {
    function run() public {
        address owner = vm.envAddress("ETH_FROM");
        Steward s = Steward(payable(vm.envAddress("STEWARD")));
        address assignee = vm.envAddress("ACCOUNT");
        uint8 withRoleId = uint8(vm.envUint("ROLE_ID"));
        bytes4[] memory signatures = abi.decode(
            vm.envBytes("SIGNATURES"),
            (bytes4[])
        );
        bool enabled = vm.envBool("ENABLED");

        vm.broadcast(owner);
        s.setCapabilitiesTo(assignee, withRoleId, signatures, enabled);
    }
}
