// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@protocol/mixins/ERC20.sol";
import {Omninote} from "@protocol/mixins/Omninote.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";
import {ReentrancyGuard} from "@protocol/mixins/ReentrancyGuard.sol";

contract Note is PublicGood, Omninote, Pausable, ReentrancyGuard, ERC20 {
  function initialize(address _beneficiary, bytes calldata params)
    external
    virtual
    override
    initializer
  {
    (
      address _comptroller,
      string memory _name,
      string memory _symbol,
      uint8 _decimals
    ) = abi.decode(params, (address, string, string, uint8));

    __initPublicGood(_beneficiary);
    __initReentrancyGuard();
    __initERC20(_name, _symbol, _decimals);
    __initComptrolled(_comptroller);
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
    super._mint(beneficiary, _mulDivDown(amount, goodPoints, MAX_BPS));
  }
}
