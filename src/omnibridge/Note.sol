// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omninote} from "@protocol/mixins/Omninote.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

contract Note is PublicGood, Omninote, Pausable, ReentrancyGuard, ERC20 {
  constructor(
    address _comptroller,
    address _beneficiary,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  )
    PublicGood(_beneficiary)
    Comptrolled(_comptroller)
    ERC20(_name, _symbol, _decimals)
  {
    this;
  }

  function mintTo(address to, uint256 amount)
    public
    override
    nonReentrant
    whenNotPaused
    requiresAuth
    returns (uint256)
  {
    _mint(to, amount);
    return amount;
  }

  function burnFrom(address from, uint256 amount)
    public
    override
    nonReentrant
    whenNotPaused
    requiresAuth
    returns (uint256)
  {
    _burn(from, amount);
    return amount;
  }

  function _mint(address to, uint256 amount) internal virtual override {
    super._mint(to, amount);
    super._mint(beneficiary, _mulDivDown(amount, goodBasisPoints, MAX_BPS));
  }
}
