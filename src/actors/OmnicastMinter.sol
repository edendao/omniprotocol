// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

import {Note} from "@protocol/Note.sol";
import {Omnicast} from "@protocol/Omnicast.sol";

contract OmnicastMinter is Comptrolled {
  Omnicast public omnicast;
  Note public note;

  constructor(
    address _comptroller,
    address _omnicast,
    address _note
  ) Comptrolled(_comptroller) {
    omnicast = Omnicast(_omnicast);
    note = Note(_note);
  }

  uint256 public constant claimRequirement = 0.01 ether;

  function optimismNotes(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * Note.decimals()
    return valueInWei / 10**12;
  }

  function claim()
    public
    payable
    returns (uint256 omnicastId, uint256 notesReceived)
  {
    require(
      msg.value >= claimRequirement,
      "OmnicastMinter: INSUFFICIENT_VALUE"
    );
    omnicastId = omnicast.mintTo(msg.sender);
    notesReceived = note.mintTo(msg.sender, optimismNotes(msg.value));
  }

  receive() external payable {
    claim();
  }
}
