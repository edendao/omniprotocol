// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

import {Note} from "@protocol/Note.sol";

abstract contract Metta {
  Note public immutable note;

  constructor(address _note) {
    note = Note(_note);
  }

  function previewNote(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * Note.decimals()
    return valueInWei / 10**12;
  }
}
