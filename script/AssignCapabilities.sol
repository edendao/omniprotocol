// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

import {Steward} from "@omniprotocol/Steward.sol";

contract AssignCapabilities is Script {
  function run() public {
    address owner = address(0x0);
    Steward s = Steward(payable(address(0x0)));
    address assignee = address(0x0);
    uint8 withRoleId = 0;
    bytes4[] memory signatures = new bytes4[](2);
    bool enabled = true;

    vm.broadcast(owner);
    s.setCapabilitiesTo(assignee, withRoleId, signatures, enabled);
  }
}
