// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

// import {ChainEnvironmentTest, Comptroller, console} from "@test/ChainEnvironmentTest.t.sol";

// import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

// import {Omnibridge} from "@protocol/omnibridge/Omnibridge.sol";
// import {Omnitoken} from "@protocol/omnibridge/Omnitoken.sol";

// contract OmnibridgeTest is ChainEnvironmentTest {
//   MockERC20 public fwaum =
//     new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
//   Omnitoken public fwaumOmnitoken =
//     new Omnitoken(
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
//     selectors[0] = Omnitoken.bridgeTo.selector;
//     selectors[1] = Omnitoken.bridgeFrom.selector;

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

//     fwaumOmnitoken.setRemoteContract(
//       bridgeToChainId,
//       abi.encodePacked(address(fwaumOmnitoken))
//     );
//     fwaumOmnitoken.setRemoteContract(
//       currentChainId,
//       abi.encodePacked(address(fwaumOmnitoken))
//     );
//   }

//   function xtestMessaging() public {
//     uint256 amount = 42e18;

//     fwaum.mint(address(this), amount);
//     assertEq(fwaum.balanceOf(address(this)), amount);

//     fwaum.approve(address(fwaumOmnitoken), amount);
//     fwaumOmnitoken.bridgeTo(address(this), amount);
//     assertEq(fwaumOmnitoken.balanceOf(address(this)), amount);

//     bridge.sendOmnitoken{value: 1 ether}(
//       address(fwaumOmnitoken),
//       amount,
//       bridgeToChainId,
//       abi.encodePacked(address(this)),
//       address(0),
//       bytes("")
//     );

//     assertEq(fwaumOmnitoken.balanceOf(address(this)), amount);
//   }
// }
