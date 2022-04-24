// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Comptroller} from "@protocol/test/ChainEnvironmentTest.t.sol";

import {MockERC20} from "@rari-capital/solmate/test/utils/mocks/MockERC20.sol";

import {Omnivault} from "@protocol/mint/Omnivault.sol";

contract OmnivaultTest is ChainEnvironmentTest {
  MockERC20 internal fwaum =
    new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
  Omnivault internal vault = new Omnivault(address(comptroller), fwaum);

  function testMetadata() public {
    assertEq(
      vault.name(),
      "eden dao vault of Friends with Assets Under Management"
    );
    assertEq(vault.symbol(), "edv-FWAUM");
    assertEq(vault.decimals(), fwaum.decimals());
  }
}