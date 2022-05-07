// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmninote} from "@protocol/interfaces/IOmninote.sol";
import {ERC20} from "@protocol/mixins/ERC20.sol";

contract NoteMock is IOmninote, ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    __initERC20(_name, _symbol, _decimals);
  }

  function mintTo(address receiver, uint256 amount) public {
    _mint(receiver, amount);
  }

  function burnFrom(address account, uint256 amount) public {
    _burn(account, amount);
  }

  function controllerTransferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool) {
    balanceOf[from] -= amount;

    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  function remoteContract(uint16) public pure returns (bytes memory) {
    return bytes("");
  }
}
