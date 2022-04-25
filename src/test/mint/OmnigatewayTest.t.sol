// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Comptroller, console} from "@protocol/test/ChainEnvironmentTest.t.sol";

import {MockERC20} from "@rari-capital/solmate/test/utils/mocks/MockERC20.sol";

import {Omnigateway} from "@protocol/mint/Omnigateway.sol";
import {Note} from "@protocol/mint/Note.sol";

contract OmnigatewayTest is ChainEnvironmentTest {
  Omnigateway public gateway =
    new Omnigateway(address(comptroller), address(layerZeroEndpoint));

  MockERC20 public fwaum =
    new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
  Note public fwaumNote =
    new Note(
      address(fwaum),
      address(comptroller),
      "Friends with Assets Under Management",
      "FWAUM",
      fwaum.decimals()
    );

  uint16 public constant bridgeToChainId = 10010; // rinkarby

  function setUp() public {
    bytes memory command = gateway.capabilities(0);

    // emit log_named_bytes("[OMNIGATEWAY CAPABILITIES]", command);
    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, ) = address(comptroller).call(command);
    require(ok, "Failed to permission Omnigateway");

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

    fwaumNote.setRemoteNote(
      bridgeToChainId,
      abi.encodePacked(address(fwaumNote))
    );
    fwaumNote.setRemoteNote(
      currentChainId,
      abi.encodePacked(address(fwaumNote))
    );
  }

  function testMessaging() public {
    uint256 amount = 42e18;

    fwaum.mint(address(this), amount);
    assertEq(fwaum.balanceOf(address(this)), amount);

    fwaum.approve(address(fwaumNote), amount);
    fwaumNote.wrap(amount);
    assertEq(fwaumNote.balanceOf(address(this)), amount);

    gateway.sendNote{value: 1 ether}(
      address(fwaumNote),
      amount,
      bridgeToChainId,
      abi.encodePacked(address(this)),
      address(0),
      bytes("")
    );

    uint256 fee = (amount * gateway.feePercent()) / 1e18;

    assertEq(fwaumNote.balanceOf(address(this)), amount - fee);
    assertEq(fwaumNote.balanceOf(address(gateway)), fee);

    gateway.withdrawToken(address(fwaumNote), fee);
    assertEq(fwaumNote.balanceOf(address(comptroller)), fee);
  }
}
