// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { Pausable } from "@protocol/mixins/Pausable.sol";
import { Payable } from "@protocol/mixins/Payable.sol";

import { Note } from "@protocol/Note.sol";

contract Meditation is Pausable, Payable {
  event InsightAchieved(address indexed actor, uint256 indexed amount);
  Note public immutable edn;

  constructor(address _authority, address _note) Payable(_authority) {
    edn = Note(_note);
  }

  function previewXP(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * Note.decimals()
    return valueInWei / 10**12;
  }

  function earnXP(address to, uint256 amountInWei)
    internal
    whenNotPaused
    returns (uint256)
  {
    uint256 insight = previewXP(amountInWei);

    emit InsightAchieved(to, insight);

    return edn.mintTo(to, insight);
  }
}
