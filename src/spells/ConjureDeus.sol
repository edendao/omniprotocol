// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";

import { Domain } from "@protocol/Domain.sol";

import { ManifestDestiny } from "./ManifestDestiny.sol";

contract ConjureDeus is ManifestDestiny {
  Domain public immutable domain;

  constructor(
    address _authority,
    address _edn,
    address _nifty,
    address _domain
  ) ManifestDestiny(_authority, _edn, _nifty) {
    domain = Domain(_domain);
  }

  modifier canMint() {
    require(msg.value >= 0.01 ether, "ManifestDeus: 0.01 ETH minimum");
    require(domain.balanceOf(msg.sender) == 0, "ManifestDeus: 1 per address");
    _;
  }

  function cast(uint256 domainId, bytes memory tokenURI)
    external
    payable
    canMint
    returns (uint256, uint256)
  {
    domain.mintTo(msg.sender, domainId);

    return (
      nifty.cast(msg.sender, tokenURI),
      edn.mintTo(msg.sender, preview(msg.value))
    );
  }

  receive() external payable override canMint {
    domain.mintTo(msg.sender, nifty.cast(msg.sender, ""));
    edn.mintTo(msg.sender, preview(msg.value));
  }
}
