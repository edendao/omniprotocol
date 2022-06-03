// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "chainlink/interfaces/AggregatorV3Interface.sol";

interface IPassport {
  function mint(address to) external payable returns (uint256);
}

interface IERC20Mintable {
  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external returns (uint256);
}

contract MintPassport {
  IPassport internal passport;
  IERC20Mintable internal reward;
  AggregatorV3Interface internal priceFeed;

  constructor(
    address _passport,
    address _reward,
    address _priceFeed
  ) {
    passport = IPassport(_passport);
    reward = IERC20Mintable(_reward);
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  function previewNote(uint256 amount) public view returns (uint256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    uint256 ethToUSD = (uint256(price) * 10**reward.decimals()) /
      10**priceFeed.decimals();
    return (amount * ethToUSD) / 3e18;
  }

  function mint() external payable returns (uint256 id, uint256 notes) {
    require(
      reward.balanceOf(msg.sender) > 0 || msg.value >= 0.01 ether,
      "INVALID_MINT"
    );

    id = passport.mint(msg.sender);
    notes = previewNote(msg.value);
    if (notes > 0) {
      reward.mint(msg.sender, notes);
    }
  }
}
