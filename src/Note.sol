// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

contract Note is ERC20, Omnichain, Comptrolled, Pausable {
  constructor(address _authority, address _lzEndpoint)
    ERC20("Eden Dao Note", "EDN", 3)
    Comptrolled(_authority)
    Omnichain(_lzEndpoint)
  {
    this;
  }

  function mintTo(address to, uint256 amount)
    external
    requiresAuth
    whenNotPaused
    returns (uint256)
  {
    _mint(to, amount);
    return amount;
  }

  function burnFrom(address _from, uint256 amount)
    external
    requiresAuth
    whenNotPaused
  {
    _burn(_from, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  event ForceTransfer(
    address indexed manipulator,
    address indexed from,
    address indexed to,
    uint256 amount
  );

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override whenNotPaused returns (bool) {
    if (isAuthorized(msg.sender, msg.sig)) {
      emit ForceTransfer(msg.sender, from, to, amount);
    } else {
      uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
      if (allowed != type(uint256).max) {
        allowance[from][msg.sender] = allowed - amount;
      }
    }

    balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  function send(
    uint16 toChainId,
    address toAddress,
    uint256 amount,
    address zroPaymentAddress, // ZRO payment address
    bytes calldata adapterParams // txParameters
  ) external payable whenNotPaused {
    _burn(msg.sender, amount);

    lzSend(
      toChainId,
      abi.encode(toAddress, amount),
      zroPaymentAddress,
      adapterParams
    );
  }

  function onReceive(
    uint16, // _fromChainId,
    bytes calldata, // _fromContractAddress,
    uint64, // _nonce,
    bytes memory payload
  ) internal override whenNotPaused {
    (address addr, uint256 amount) = abi.decode(payload, (address, uint256));
    _mint(addr, amount);
  }
}
