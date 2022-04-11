// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

import {Note} from "@protocol/Note.sol";

abstract contract Metta is Comptrolled {
  Note public immutable edn;

  constructor(address _note) {
    edn = Note(_note);
  }

  function previewEDN(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * Note.decimals()
    return valueInWei / 10**12;
  }
}
