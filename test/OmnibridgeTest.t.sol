// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

// import {ChainEnvironmentTest, Comptroller, console} from "@test/ChainEnvironmentTest.t.sol";

// import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

// import {Omnibridge} from "@protocol/omnibridge/Omnibridge.sol";
// import {Note} from "@protocol/omnibridge/Note.sol";

// contract OmnibridgeTest is ChainEnvironmentTest {
//   MockERC20 public fwaum =
//     new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
//   Note public fwaumNote =
//     new Note(
//       address(comptroller),
//       address(comptroller),
//       "Friends with Assets Under Management",
//       "FWAUM",
//       fwaum.decimals()
//     );

//   uint16 public constant bridgeToChainId = 10010; // rinkarby

//   function setUp() public override {
//     super.setUp();

//     uint8 bridgeRole = 0;
//     bytes4[] memory selectors = new bytes4[](2);
//     selectors[0] = Note.mintTo.selector;
//     selectors[1] = Note.burnFrom.selector;

//     bytes memory command = abi.encodeWithSelector(
//       comptroller.setCapabilitiesTo.selector,
//       address(bridge),
//       bridgeRole,
//       selectors,
//       true
//     );

//     // emit log_named_bytes("[OMNIBRIDGE CAPABILITIES]", command);
//     // solhint-disable-next-line avoid-low-level-calls
//     (bool ok, ) = address(comptroller).call(command);
//     require(ok, "Failed to permission Omnibridge");

//     layerZeroEndpoint.setDestLzEndpoint(
//       address(bridge),
//       address(layerZeroEndpoint)
//     );
//     bridge.setTrustedRemoteContract(
//       currentChainId,
//       abi.encodePacked(address(bridge))
//     );
//     bridge.setTrustedRemoteContract(
//       bridgeToChainId,
//       abi.encodePacked(address(bridge))
//     );

//     fwaumNote.setRemoteNote(
//       bridgeToChainId,
//       abi.encodePacked(address(fwaumNote))
//     );
//     fwaumNote.setRemoteNote(
//       currentChainId,
//       abi.encodePacked(address(fwaumNote))
//     );
//   }

//   function xtestMessaging() public {
//     uint256 amount = 42e18;

//     fwaum.mint(address(this), amount);
//     assertEq(fwaum.balanceOf(address(this)), amount);

//     fwaum.approve(address(fwaumNote), amount);
//     fwaumNote.mintTo(address(this), amount);
//     assertEq(fwaumNote.balanceOf(address(this)), amount);

//     bridge.sendNote{value: 1 ether}(
//       address(fwaumNote),
//       amount,
//       bridgeToChainId,
//       abi.encodePacked(address(this)),
//       address(0),
//       bytes("")
//     );

//     assertEq(fwaumNote.balanceOf(address(this)), amount);
//   }
// }
