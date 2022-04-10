// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Pausable} from "@protocol/mixins/Pausable.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

import {Note} from "@protocol/Note.sol";

contract Metta is Comptrolled, Pausable {
  Note public immutable edn;

  constructor(address _authority, address _note) Comptrolled(_authority) {
    edn = Note(_note);
  }

  function previewEDN(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * Note.decimals()
    return valueInWei / 10**12;
  }

  function earnEDN(address to, uint256 amountInWei)
    internal
    whenNotPaused
    returns (uint256)
  {
    return edn.mintTo(to, previewEDN(amountInWei));
  }
}
