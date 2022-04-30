// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Comptroller} from "@test/ChainEnvironmentTest.t.sol";

import {Note, NoteFactory} from "@protocol/omnibridge/NoteFactory.sol";

contract NoteFactoryTest is ChainEnvironmentTest {
  NoteFactory internal factory = new NoteFactory(address(comptroller));

  function _deploy() internal returns (Note note) {
    note = factory.deployNote(
      address(comptroller),
      "Friends with Assets Under Management",
      "FWAUM",
      18
    );
  }

  function testDeploy() public {
    note = _deploy();
    assertEq("Friends with Assets Under Management", note.name());
    assertEq("FWAUM", note.symbol());
    assertEq(18, note.decimals());
  }

  function testFailDuplicateDeploy() public {
    _deploy();
    _deploy();
  }
}
