// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Passport} from "@protocol/Passport.sol";

import {Metta} from "./Metta.sol";

contract NiftyOmnifity is Metta {
  Passport internal pass;

  constructor(
    address _authority,
    address _note,
    address _passport
  ) Metta(_authority, _note) {
    pass = Passport(_passport);
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
    uint256 passId = pass.findOrMintFor(msg.sender);

    pass.sendData{value: msg.value}(
      uint16(block.chainid),
      passId,
      pass.TOKENURI_CHANNEL(),
      bytes(IERC721Metadata(token).tokenURI(id)),
      address(0),
      ""
    );

    return (passId, earnEDN(msg.sender, msg.value));
  }
}
