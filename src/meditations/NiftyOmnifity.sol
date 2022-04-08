// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Meditation} from "@protocol/mixins/Meditation.sol";

import {Passport} from "@protocol/Passport.sol";

contract NiftyOmnifity is Meditation {
  Passport internal pass;

  constructor(
    address _authority,
    address _note,
    address _passport
  ) Meditation(_authority, _note) {
    pass = Passport(_passport);
  }

  function perform(address token, uint256 id)
    external
    payable
    returns (uint256, uint256)
  {
    require(
      IERC721(token).ownerOf(id) == msg.sender,
      "NiftyOmnifity: May only cast owned token"
    );
    uint256 passId = pass.findOrMintFor(msg.sender);
    pass.setTokenURI(passId, bytes(IERC721Metadata(token).tokenURI(id)));
    return (passId, earnXP(msg.sender, msg.value));
  }

  function perform(address to, bytes memory data)
    external
    payable
    returns (uint256, uint256)
  {
    require(
      msg.sender == to || isAuthorized(msg.sender, msg.sig),
      "UNAUTHORIZED"
    );
    uint256 passId = pass.findOrMintFor(to);
    pass.setTokenURI(passId, data);
    return (passId, earnXP(to, msg.value));
  }

  receive() external payable {
    pass.findOrMintFor(msg.sender);
    earnXP(msg.sender, msg.value);
  }
}
