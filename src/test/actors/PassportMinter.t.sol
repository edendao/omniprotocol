// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import { TreasuryAuthority } from "@protocol/TreasuryAuthority.sol";
import { EDN, Passport, PassportMinter } from "@protocol/actors/PassportMinter.sol";

contract PassportMinterTest is DSTestPlus {
  address internal owner = hevm.addr(42);

  TreasuryAuthority internal authority =
    new TreasuryAuthority(address(owner), address(0));

  EDN internal edn = new EDN(address(authority), address(0));
  Passport internal passport = new Passport(address(authority), address(0));

  PassportMinter internal minter =
    new PassportMinter(address(edn), address(passport));

  function setUp() public {
    uint8 minterRole = 0;
    hevm.startPrank(owner);
    authority.setRoleCapability(minterRole, edn.mintTo.selector, true);
    authority.setRoleCapability(minterRole, passport.mintTo.selector, true);
    authority.setUserRole(address(minter), minterRole, true);
    hevm.stopPrank();
  }

  function testOwnerCanMint(address _to, uint256 _amount) public {
    hevm.startPrank(owner);
    edn.mintTo(_to, _amount);
    hevm.stopPrank();
    assertEq(edn.balanceOf(_to), _amount);
  }

  function testPassportMinterCall(uint256 _amountInWei) public {
    if (address(this).balance < _amountInWei) return;

    (bool success, bytes memory returndata) = address(minter).call{
      value: _amountInWei
    }("");
    require(success, string(returndata));
    assertEq(passport.ownerOf(passport.totalSupply() - 1), address(this));
    assertEq(edn.balanceOf(address(this)), minter.previewMint(_amountInWei));
  }

  function testFailEDNMintTo(address _to, uint256 _amount) public {
    edn.mintTo(_to, _amount);
  }

  function testFailPassportMintTo(address _to) public {
    passport.mintTo(_to);
  }
}
