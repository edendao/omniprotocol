// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, ERC721Note} from "./ChainEnvironmentTest.t.sol";

contract ERC721NoteTest is ChainEnvironmentTest {
    ERC721Note public note;

    function setUp() public override {
        super.setUp();

        note = ERC721Note(
            factory.createERC721Note(
                address(steward),
                "Frontier Carbon",
                "TIME"
            )
        );
    }

    function testERC721CloneGas() public returns (ERC721Note n) {
        n = ERC721Note(
            factory.createERC721Note(
                address(steward),
                "Frontier Carbon 2",
                "TIME2"
            )
        );
    }
}
