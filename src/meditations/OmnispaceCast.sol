// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Channel} from "@protocol/Channel.sol";
import {Passport} from "@protocol/Passport.sol";

import {Metta} from "./Metta.sol";

contract OmnispaceCast is Metta {
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

  function perform(
    uint16 toChainId,
    uint256 passportId,
    uint256 channelId,
    bytes memory data,
    address layerZeroAddress,
    bytes calldata adapterParams
  ) external payable whenNotPaused returns (uint256) {
    (uint256 fusedChannelId, ) = pass.fusedChannelOf(pass.idOf(msg.sender));
    require(
      dns.ownerOf(channelId) == msg.sender || channelId == fusedChannelId,
      "OmnispaceCast: UNAUTHORIZED"
    );

    pass.sendData{value: msg.value}(
      toChainId,
      passportId,
      channelId,
      data,
      layerZeroAddress,
      adapterParams
    );

    return earnEDN(msg.sender, msg.value);
  }
}
