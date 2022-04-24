// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Comptroller} from "@protocol/test/ChainEnvironment.t.sol";

import {MockERC20} from "@rari-capital/solmate/test/utils/mocks/MockERC20.sol";

import {Vault} from "@protocol/mint/Vault.sol";

contract VaultTest is ChainEnvironmentTest {
  MockERC20 internal fwaum =
    new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
  Vault internal vault = new Vault(address(comptroller), fwaum);

  function testMetadata() public {
    assertEq(
      vault.name(),
      "eden dao vault of Friends with Assets Under Management"
    );
    assertEq(vault.symbol(), "edv-FWAUM");
    assertEq(vault.decimals(), fwaum.decimals());
  }
}
