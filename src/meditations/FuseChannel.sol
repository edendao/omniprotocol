// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Channel} from "@protocol/Channel.sol";
import {Passport} from "@protocol/Passport.sol";

import {Metta} from "./Metta.sol";

contract FuseChannel is Metta {
  Passport internal pass;
  Channel internal dns;

  constructor(
    address _authority,
    address _note,
    address _passport,
    address _dns
  ) Metta(_authority, _note) {
    pass = Passport(_passport);
    dns = Channel(_dns);
  }

  function perform(uint256 channelId, string memory name)
    external
    payable
    whenNotPaused
    returns (uint256)
  {
    uint256 passId = pass.idOf(msg.sender);
    (uint256 fusedChannelId, ) = pass.fusedChannelOf(passId);

    if (channelId != fusedChannelId) {
      dns.transferFrom(msg.sender, address(this), channelId);
    }

    pass.sendData{value: msg.value}(
      uint16(block.chainid),
      passId,
      pass.PASSPORT_CHANNEL(),
      abi.encode(channelId, name),
      address(0),
      ""
    );

    return earnEDN(msg.sender, msg.value);
  }
}
