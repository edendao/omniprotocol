// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

interface Connectable {
  function connect(uint16 toChainId, bytes memory contractAddress) external;
}

struct Connection {
  uint16 toChainID;
  address toContractAddress;
}

contract RemoteConnection is Script {
  function run() public {
    address owner = address(0x0);
    address connectable = address(0x0);
    Connection[] memory connections = new Connection[](5);
    connections[0] = Connection({
      toChainID: 1,
      toContractAddress: address(0x0)
    });

    run(owner, connectable, connections);
  }

  function run(
    address owner,
    address connectable,
    Connection[] memory connections
  ) public {
    Connectable c = Connectable(connectable);

    vm.startBroadcast(owner);

    for (uint8 i = 0; i < connections.length; ++i) {
      if (connections[i].toContractAddress != address(0)) {
        c.connect(
          connections[i].toChainID,
          abi.encodePacked(connections[i].toContractAddress)
        );
      }
    }

    vm.stopBroadcast();
  }
}
