// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/utils/ReentrancyGuard.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omninote} from "@protocol/mixins/Omninote.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

contract Note is PublicGood, ERC20, Omninote, Pausable, ReentrancyGuard {
  constructor(
    address _comptroller,
    address _beneficiary,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  )
    PublicGood(_beneficiary)
    ERC20(_name, _symbol, _decimals)
    Comptrolled(_comptroller)
  {
    this;
  }

  function mint(address to, uint256 amount)
    public
    override
    nonReentrant
    whenNotPaused
    requiresAuth
    returns (uint256)
  {
    _mint(to, amount);
    _mint(beneficiary, _mulDivDown(amount, goodPercent, 1e18));
    return amount;
  }

  function burn(address from, uint256 amount)
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
}
