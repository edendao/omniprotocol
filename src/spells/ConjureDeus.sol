// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { Spell } from "@protocol/mixins/Spell.sol";

import { Domain } from "@protocol/Domain.sol";

contract ConjureDeus is Spell {
  Domain public immutable dns;

  constructor(
    address _authority,
    address _edn,
    address _domain
  ) Spell(_authority, _edn) {
    dns = Domain(_domain);
  }

  function cast(uint256 tld) external payable returns (uint256) {
    _mint(msg.sender, tld, msg.value);
    return earnXP(msg.sender, msg.value);
  }

  receive() external payable {
    _mint(msg.sender, uint256(uint160(msg.sender)), msg.value);
    earnXP(msg.sender, msg.value);
  }

  function _mint(
    address to,
    uint256 domainId,
    uint256 giftInWei
  ) private returns (uint256) {
    require(giftInWei >= 0.01 ether, "ConjureDeus: Minting needs >=0.01 ETH");
    require(dns.balanceOf(to) < 8, "ConjureDeus: Max 8 per address");

    dns.mintTo(to, domainId);
  }
}
