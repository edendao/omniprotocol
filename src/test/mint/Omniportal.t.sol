// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Comptroller} from "@protocol/test/ChainEnvironment.t.sol";

import {MockERC20} from "@rari-capital/solmate/test/utils/mocks/MockERC20.sol";

import {Omniportal} from "@protocol/mint/Omniportal.sol";
import {Note} from "@protocol/mint/Note.sol";
import {Vault} from "@protocol/mint/Vault.sol";

contract OmniportalTest is ChainEnvironmentTest {
  Omniportal public portal =
    new Omniportal(address(comptroller), address(layerZeroEndpoint));

  MockERC20 public fwaum =
    new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
  Vault public fwaumVault = new Vault(address(comptroller), fwaum);
  Note public fwaumNote =
    new Note(
      address(comptroller),
      "eden dao note of Friends with Assets Under Management",
      "edn-FWAUM",
      fwaum.decimals()
    );

  uint16 public constant bridgeToChainId = 10010; // rinkarby

  function setUp() public {
    uint8 portalRole = 0;
    comptroller.setRoleCapability(portalRole, Note.mintTo.selector, true);
    comptroller.setRoleCapability(portalRole, Note.burnFrom.selector, true);
    comptroller.setUserRole(address(portal), portalRole, true);

    layerZeroEndpoint.setDestLzEndpoint(
      address(portal),
      address(layerZeroEndpoint)
    );
    portal.setTrustedRemoteContract(
      currentChainId,
      abi.encodePacked(address(portal))
    );
    portal.setTrustedRemoteContract(
      bridgeToChainId,
      abi.encodePacked(address(portal))
    );

    fwaumVault.setRemoteNote(
      bridgeToChainId,
      abi.encodePacked(address(fwaumNote))
    );
    fwaumNote.setRemoteNote(
      currentChainId,
      abi.encodePacked(address(fwaumVault))
    );
  }

  function testMessaging() public {
    uint256 amount = 42e18;

    fwaum.mint(address(this), amount);
    assertEq(fwaum.balanceOf(address(this)), amount);

    fwaum.approve(address(fwaumVault), amount);
    fwaumVault.deposit(amount, address(this));
    assertEq(fwaumVault.balanceOf(address(this)), amount);

    portal.sendNote{value: 1 ether}(
      address(fwaumVault),
      amount,
      bridgeToChainId,
      abi.encodePacked(address(this)),
      address(0),
      bytes("")
    );

    uint256 fee = (amount * portal.feePercent()) / 1e18;

    assertEq(fwaumNote.balanceOf(address(this)), amount - fee);
    assertEq(fwaumVault.balanceOf(address(portal)), fee);

    portal.withdrawToken(address(fwaumVault), fee);
    assertEq(fwaumVault.balanceOf(address(comptroller)), fee);
  }
}
