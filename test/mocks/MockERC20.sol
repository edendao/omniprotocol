// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@protocol/mixins/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    __initERC20(_name, _symbol, _decimals);
  }

  function mint(address receiver, uint256 amount) public {
    _mint(receiver, amount);
  }

  function burn(address account, uint256 amount) public {
    _burn(account, amount);
  }
}
