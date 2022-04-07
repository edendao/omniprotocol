// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";

import { NiftyOmnifity } from "@protocol/spells/NiftyOmnifity.sol";
import { Note } from "@protocol/Note.sol";

contract ManifestDestiny is Authenticated {
  Note public immutable edn;
  NiftyOmnifity public immutable nifty;

  constructor(
    address _authority,
    address _edn,
    address _nifty
  ) Authenticated(_authority) {
    edn = Note(_edn);
    nifty = NiftyOmnifity(_nifty);
  }

  function preview(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * Note.decimals()
    return valueInWei / 10**12;
  }

  function cast(bytes calldata uri)
    external
    payable
    virtual
    returns (uint256, uint256)
  {
    uint256 passportId = nifty.cast(msg.sender, uri);
    uint256 notesReceived = edn.mintTo(msg.sender, preview(msg.value));
    return (passportId, notesReceived);
  }

  receive() external payable virtual {
    nifty.cast(msg.sender, "");
    edn.mintTo(msg.sender, preview(msg.value));
  }

  function withdraw() external {
    payable(owner).transfer(address(this).balance);
  }
}
