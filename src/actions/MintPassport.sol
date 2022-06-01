// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IPassport {
  function mint(address to) external payable returns (uint256);
}

interface IERC20Mintable {
  function mint(address to, uint256 amount) external returns (uint256);
}

contract MintPassport {
  address public passport;
  address public reward;

  constructor(address _passport, address _reward) {
    passport = _passport;
    reward = _reward;
  }

  receive() external payable {
    IPassport(passport).mint{value: msg.value}(msg.sender);
    IERC20Mintable(reward).mint(msg.sender, msg.value / 1000);
  }
}
