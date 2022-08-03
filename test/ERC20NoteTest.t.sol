// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, ERC20Note} from "./ChainEnvironmentTest.t.sol";

contract ERC20NoteTest is ChainEnvironmentTest {
    ERC20Note public note;

    function setUp() public override {
        super.setUp();

        note = ERC20Note(
            factory.createERC20Note(
                address(steward),
                "Frontier Carbon",
                "TIME",
                3
            )
        );
    }

    function testCloneGas() public returns (ERC20Note n) {
        n = ERC20Note(
            factory.createERC20Note(
                address(steward),
                "Frontier Carbon 2",
                "TIME2",
                3
            )
        );
    }

    function testMintGas() public {
        note.mint(address(this), 10_000_000);
    }

    function testMint(address to, uint128 amount) public {
        hevm.assume(to != address(0) && note.balanceOf(to) == 0);
        note.mint(to, amount);

        assertEq(note.balanceOf(to), amount);
    }

    function testMintRequiresAuth(address to, uint128 amount) public {
        hevm.assume(
            to != address(0) && to != address(this) && note.balanceOf(to) == 0
        );
        hevm.expectRevert("UNAUTHORIZED");
        hevm.prank(to);
        note.mint(to, amount);
    }

    function testSenderSanctions(address sender, uint128 amount) public {
        hevm.assume(sender != address(0) && sender != address(this));
        note.mint(sender, amount);
        steward.sanction(sender, true);

        hevm.expectRevert("UNAUTHORIZED");
        hevm.prank(sender);
        note.transfer(beneficiary, amount);
    }

    function testRecipientSanctions(address recipient, uint128 amount) public {
        hevm.assume(recipient != address(0) && recipient != address(this));
        note.mint(address(this), amount);
        steward.sanction(recipient, true);

        hevm.expectRevert("UNAUTHORIZED");
        note.transfer(recipient, amount);
    }
}
