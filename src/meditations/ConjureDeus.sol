// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Meditation} from "@protocol/mixins/Meditation.sol";

import {Domain} from "@protocol/Domain.sol";

contract ConjureDeus is Meditation {
  Domain public immutable dns;

  constructor(
    address _authority,
    address _edn,
    address _domain
  ) Meditation(_authority, _edn) {
    dns = Domain(_domain);
  }

  function perform(uint256 domainId) external payable returns (uint256) {
    return _perform(msg.sender, domainId, msg.value);
  }

  receive() external payable {
    _perform(msg.sender, uint256(uint160(msg.sender)), msg.value);
  }

  uint64 public constant minimumResonance = 0.05 ether;

  function _perform(
    address forAddress,
    uint256 domainId,
    uint256 giftInWei
  ) private returns (uint256) {
    require(
      giftInWei >= minimumResonance,
      "ConjureDeus: >=0.05 ETH" // minimumResonance
    );
    require(dns.balanceOf(forAddress) < 5, "ConjureDeus: Max 5 per address");

    dns.mintTo(forAddress, domainId);
    return earnXP(msg.sender, msg.value);
  }
}
