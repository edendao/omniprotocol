// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, ERC721Note} from "./ChainEnvironmentTest.t.sol";

import {ERC721Vault} from "@omniprotocol/ERC721Vault.sol";

import {MockERC721} from "./mocks/MockERC721.sol";

contract ERC721VaultTest is ChainEnvironmentTest {
    uint16 public currentChainId = uint16(block.chainid);

    MockERC721 public mock = new MockERC721("TEST", "TEST");
    ERC721Vault public vault;
    ERC721Note public note;

    function setUp() public override {
        super.setUp();

        vault = ERC721Vault(
            factory.createERC721Vault(address(steward), address(mock))
        );
        note = ERC721Note(
            factory.createERC721Note(address(steward), "TEST", "TEST")
        );
    }

    function testFailDeployingDuplicateAsset() public {
        ERC721Vault(factory.createERC721Vault(address(steward), address(mock)));
    }

    function testCloneGas() public {
        ERC721Vault(factory.createERC721Vault(address(steward), address(note)));
    }

    function testSendFrom(
        uint16 toChainId,
        address toAddress,
        uint256 id
    ) public {
        hevm.assume(
            id != 0 &&
                toAddress != address(0) &&
                toChainId != 0 &&
                toChainId != currentChainId
        );

        lzEndpoint.setDestLzEndpoint(address(note), address(lzEndpoint));
        vault.connect(toChainId, abi.encodePacked(address(note)));
        note.connect(currentChainId, abi.encodePacked(address(vault)));

        mock.mint(address(this), id);
        mock.approve(address(vault), id);

        (uint256 nativeFee, ) = vault.estimateSendFee(
            toChainId,
            abi.encodePacked(toAddress),
            id,
            false,
            ""
        );

        vault.sendFrom{value: nativeFee}(
            address(this),
            toChainId,
            abi.encodePacked(toAddress),
            id,
            payable(address(0)),
            address(0),
            ""
        );

        assertEq(mock.balanceOf(address(this)), 0);
        assertEq(note.balanceOf(toAddress), 1);
        assertEq(note.tokenURI(id), mock.tokenURI(id));
    }
}
