// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest} from "@protocol/test/ChainEnvironment.t.sol";

contract NoteTest is ChainEnvironmentTest {
  function testMintGas() public {
    note.mintTo(address(this), 10_000_000);
  }

  function testMintTo(address to, uint256 amount) public {
    hevm.assume(to != address(0));
    note.mintTo(to, amount);

    assertEq(note.balanceOf(to), amount);
  }

  function testMintRequiresAuth(address caller, uint256 amount) public {
    hevm.assume(caller != address(this));
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    note.mintTo(caller, amount);
  }

  function testBurnRequiresAuth(address caller, uint256 amount) public {
    hevm.assume(caller != address(this));
    note.mintTo(caller, amount);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    note.burnFrom(caller, amount);
  }

  function testOmniTransferFrom(
    address sender,
    uint16 toChainId,
    uint256 amount,
    address receiver
  ) public {
    hevm.assume(
      sender != address(0) &&
        receiver != address(0) &&
        sender != receiver &&
        toChainId != 0 &&
        toChainId != currentChainId &&
        amount != 0
    );

    bytes memory remoteAddressBytes = abi.encodePacked(address(note));
    note.setTrustedRemoteContract(toChainId, remoteAddressBytes);
    note.setTrustedRemoteContract(currentChainId, remoteAddressBytes);
    layerZeroEndpoint.setDestLzEndpoint(
      address(note),
      address(layerZeroEndpoint)
    );

    hevm.deal(sender, 1 ether);
    note.mintTo(sender, amount);

    bytes memory toAddress = abi.encodePacked(receiver);

    hevm.prank(sender);
    note.approve(address(this), amount);
    note.sendFrom{value: 1 ether}(
      sender,
      toChainId,
      toAddress,
      amount,
      address(0),
      ""
    );

    assertEq(amount, note.balanceOf(receiver));
  }
}
