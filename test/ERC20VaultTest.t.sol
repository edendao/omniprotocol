// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, ERC20Note} from "./ChainEnvironmentTest.t.sol";

import {ERC20Vault, InvalidAsset, Unauthorized} from "@omniprotocol/ERC20Vault.sol";

contract ERC20VaultTest is ChainEnvironmentTest {
    uint16 public currentChainId = uint16(block.chainid);
    ERC20Vault public vault;
    ERC20Note public note;

    function setUp() public override {
        super.setUp();

        vault = ERC20Vault(
            factory.createERC20Vault(address(steward), address(dai))
        );
        note = ERC20Note(
            factory.createERC20Note(
                address(steward),
                dai.name(),
                dai.symbol(),
                dai.decimals()
            )
        );
    }

    function testFailDeployingDuplicateAsset() public {
        ERC20Vault(factory.createERC20Vault(address(steward), address(dai)));
    }

    function testCloneGas() public {
        ERC20Vault(factory.createERC20Vault(address(steward), address(note)));
    }

    function testCannotWithdrawAsset() public {
        hevm.expectRevert(Unauthorized.selector);
        vault.withdrawToken(address(dai), address(this), 10_000);
    }

    function testWithdrawingAccidentalTokensRequiresAuth(address caller)
        public
    {
        hevm.assume(caller != owner);
        hevm.expectRevert(Unauthorized.selector);
        hevm.prank(caller);
        vault.withdrawToken(address(0), address(this), 10_000);
    }

    function testSendFrom(
        uint16 toChainId,
        address toAddress,
        uint256 amount
    ) public {
        hevm.assume(
            amount != 0 &&
                toAddress != address(0) &&
                toChainId != 0 &&
                toChainId != currentChainId
        );

        lzEndpoint.setDestLzEndpoint(address(note), address(lzEndpoint));
        vault.connect(toChainId, abi.encodePacked(address(note)));
        note.connect(currentChainId, abi.encodePacked(address(vault)));

        dai.mint(address(this), amount);
        dai.approve(address(vault), amount);

        (uint256 nativeFee, ) = vault.estimateSendFee(
            toChainId,
            abi.encodePacked(toAddress),
            amount,
            false,
            ""
        );

        vault.sendFrom{value: nativeFee}(
            address(this),
            toChainId,
            abi.encodePacked(toAddress),
            amount,
            payable(address(0)),
            address(0),
            ""
        );

        assertEq(dai.balanceOf(address(this)), 0);
        assertEq(note.balanceOf(toAddress), amount);
    }
}
