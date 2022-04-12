// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {BaseProtocolDeployerTest} from "@protocol/test/chainops/0_BaseProtocolDeployer.t.sol";

contract NoteTest is BaseProtocolDeployerTest {
  function testMintRequiresAuth(address to, uint256 amount) public {
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    note.mintTo(to, amount);
  }

  function testBurnRequiresAuth(address from, uint256 amount) public {
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    note.burnFrom(from, amount);
  }
}
