// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Omnicast} from "@protocol/Omnicast.sol";

import {Metta, Comptrolled} from "@protocol/mixins/Metta.sol";

contract NiftyOmnifity is Metta {
  Omnicast internal omnicast;

  constructor(
    address _authority,
    address _note,
    address _omnicast
  ) Comptrolled(_authority) Metta(_note) {
    omnicast = Omnicast(_omnicast);
  }

  function perform(address token, uint256 id)
    external
    payable
    whenNotPaused
    returns (uint256, uint256)
  {
    require(
      IERC721(token).ownerOf(id) == msg.sender,
      "NiftyOmnifity: INVALID_TOKEN"
    );

    if (omnicast.balanceOf(msg.sender) == 0) {
      omnicast.mintTo(msg.sender);
    }

    uint256 omnicastId = omnicast.idOf(msg.sender);
    omnicast.sendMessage{value: msg.value}(
      uint16(block.chainid),
      omnicastId,
      omnicast.TOKENURI_CHANNEL(),
      bytes(IERC721Metadata(token).tokenURI(id))
    );

    return (omnicastId, channelEDN(msg.sender, msg.value));
  }
}
