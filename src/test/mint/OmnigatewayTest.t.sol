// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Comptroller} from "@protocol/test/ChainEnvironmentTest.t.sol";

import {MockERC20} from "@rari-capital/solmate/test/utils/mocks/MockERC20.sol";

import {Omnigateway} from "@protocol/mint/Omnigateway.sol";
import {Note} from "@protocol/mint/Note.sol";
import {Omnivault} from "@protocol/mint/Omnivault.sol";

contract OmnigatewayTest is ChainEnvironmentTest {
  Omnigateway public gateway =
    new Omnigateway(address(comptroller), address(layerZeroEndpoint));

  MockERC20 public fwaum =
    new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
  Omnivault public fwaumOmnivault = new Omnivault(address(comptroller), fwaum);
  Note public fwaumNote =
    new Note(
      address(comptroller),
      "eden dao note of Friends with Assets Under Management",
      "edn-FWAUM",
      fwaum.decimals()
    );

  uint16 public constant bridgeToChainId = 10010; // rinkarby

  function setUp() public {
    comptroller.multicall(gateway.permissionsCalldataFor(0, address(gateway)));

    layerZeroEndpoint.setDestLzEndpoint(
      address(gateway),
      address(layerZeroEndpoint)
    );
    gateway.setTrustedRemoteContract(
      currentChainId,
      abi.encodePacked(address(gateway))
    );
    gateway.setTrustedRemoteContract(
      bridgeToChainId,
      abi.encodePacked(address(gateway))
    );

    fwaumOmnivault.setRemoteNote(
      bridgeToChainId,
      abi.encodePacked(address(fwaumNote))
    );
    fwaumNote.setRemoteNote(
      currentChainId,
      abi.encodePacked(address(fwaumOmnivault))
    );
  }

  function testMessaging() public {
    uint256 amount = 42e18;

    fwaum.mint(address(this), amount);
    assertEq(fwaum.balanceOf(address(this)), amount);

    fwaum.approve(address(fwaumOmnivault), amount);
    fwaumOmnivault.deposit(amount, address(this));
    assertEq(fwaumOmnivault.balanceOf(address(this)), amount);

    gateway.sendNote{value: 1 ether}(
      address(fwaumOmnivault),
      amount,
      bridgeToChainId,
      abi.encodePacked(address(this)),
      address(0),
      bytes("")
    );

    uint256 fee = (amount * gateway.feePercent()) / 1e18;

    assertEq(fwaumNote.balanceOf(address(this)), amount - fee);
    assertEq(fwaumOmnivault.balanceOf(address(gateway)), fee);

    gateway.withdrawToken(address(fwaumOmnivault), fee);
    assertEq(fwaumOmnivault.balanceOf(address(comptroller)), fee);
  }
}
