// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

import {Note} from "@protocol/Note.sol";
import {Omnichannel} from "@protocol/Omnichannel.sol";

contract OmnichannelMinter is Comptrolled {
  Omnichannel public omnichannel;
  Note public note;

  mapping(address => uint256) public amountMintedBy;

  constructor(
    address _comptroller,
    address _omnichannel,
    address _note
  ) Comptrolled(_comptroller) {
    omnichannel = Omnichannel(_omnichannel);
    note = Note(_note);
  }

  function optimismNotes(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * Note.decimals()
    return valueInWei / 10**12;
  }

  function claimRequirement() public view returns (uint256) {
    return (amountMintedBy[msg.sender] + 1) * 0.05 ether;
  }

  function claim(string memory node) public payable returns (uint256, uint256) {
    return claim(omnichannel.idOf(node));
  }

  function claim(uint256 omnichannelId)
    public
    payable
    returns (uint256, uint256)
  {
    require(amountMintedBy[msg.sender] < 10, "OmnichannelMinter: MINT_LIMIT");
    require(
      msg.value >= claimRequirement(),
      "OmnichannelMinter: INSUFFICIENT_VALUE"
    );

    amountMintedBy[msg.sender] += 1;
    omnichannel.mintTo(msg.sender, omnichannelId);
    return (omnichannelId, note.mintTo(msg.sender, optimismNotes(msg.value)));
  }
}
