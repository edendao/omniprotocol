// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {EdenDaoNS} from "@protocol/libraries/EdenDaoNS.sol";

import {Channel} from "@protocol/Channel.sol";

import {Metta} from "./Metta.sol";

contract ChannelAttunement is Metta {
  Channel public immutable dns;
  mapping(address => uint8) public performancesOf;

  constructor(
    address _authority,
    address _edn,
    address _channel
  ) Metta(_authority, _edn) {
    dns = Channel(_channel);
  }

  // Linearly increasing price, up to 15 channels
  function giftRequired(address forAddress) public view returns (uint256) {
    return (performancesOf[forAddress] + 1) * 0.05 ether;
  }

  function canPerform(address sender) public view returns (bool) {
    return performancesOf[sender] < 16;
  }

  function canPerform(uint256 domainId) public view returns (bool) {
    return dns.ownerOf(domainId) == address(0);
  }

  function canPerform(string memory node) public view returns (bool) {
    return canPerform(EdenDaoNS.namehash(node));
  }

  function perform(uint256 domainId) external payable returns (uint256) {
    return _perform(msg.sender, domainId, msg.value);
  }

  function perform(string memory node) external payable returns (uint256) {
    return _perform(msg.sender, EdenDaoNS.namehash(node), msg.value);
  }

  receive() external payable {
    _perform(msg.sender, uint256(uint160(msg.sender)), msg.value);
  }

  // ===================
  // ===== PRIVATE =====
  // ===================
  function _perform(
    address forAddress,
    uint256 domainId,
    uint256 giftInWei
  ) private returns (uint256) {
    require(canPerform(forAddress), "ChannelAttunement: LIMIT_REACHED");
    require(
      giftInWei >= giftRequired(forAddress),
      "ChannelAttunement: INSUFFICIENT_FUNDS" // minimumResonance
    );

    dns.mintTo(forAddress, domainId);
    performancesOf[forAddress] += 1;

    return earnEDN(msg.sender, msg.value);
  }
}
