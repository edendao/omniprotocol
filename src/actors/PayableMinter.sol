// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { EDN } from "@protocol/EDN.sol";
import { Authenticated } from "@protocol/mixins/Authenticated.sol";

abstract contract PayableMinter is Authenticated {
  EDN public immutable edn;

  constructor(address _edn) {
    edn = EDN(_edn);
  }

  function previewMint(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * EDN.decimals()
    return valueInWei / 10**12;
  }

  function _mint(uint256 value) internal {
    edn.mintTo(msg.sender, previewMint(value));
  }

  function withdraw() external {
    payable(owner).transfer(address(this).balance);
  }
}
