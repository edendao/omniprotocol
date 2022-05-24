// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Omnitoken} from "@test/ChainEnvironmentTest.t.sol";

import {Omnibridge} from "@omniprotocol/Omnibridge.sol";

contract OmnibridgeTest is ChainEnvironmentTest {
  Omnibridge public omnibridge =
    Omnibridge(bridge.clone(address(steward), address(dai)));
  Omnitoken public omnitoken =
    Omnitoken(token.clone(address(steward), "DAI", "DAI", dai.decimals()));

  function testFailDeployingDuplicateAsset() public {
    Omnibridge(bridge.clone(address(steward), address(dai)));
  }

  function testCloneGas() public {
    Omnibridge(bridge.clone(address(steward), address(omnitoken)));
  }

  function testCannotWithdrawAsset() public {
    hevm.expectRevert("Omnibridge: INVALID_TOKEN");
    omnibridge.withdrawToken(address(dai), 10_000);
  }

  function testSendFrom(
    uint16 toChainId,
    address toAddress,
    uint256 amount
  ) public {
    hevm.assume(
      amount != 0 &&
        toAddress != address(0) &&
        toChainId != 0 &&
        toChainId != currentChainId
    );

    lzEndpoint.setDestLzEndpoint(address(omnitoken), address(lzEndpoint));
    omnibridge.connect(toChainId, abi.encodePacked(address(omnitoken)));
    omnitoken.connect(currentChainId, abi.encodePacked(address(omnibridge)));

    dai.mint(address(this), amount);
    dai.approve(address(omnibridge), amount);

    (uint256 nativeFee, ) = omnibridge.estimateSendFee(
      toChainId,
      abi.encodePacked(toAddress),
      amount,
      false,
      ""
    );

    omnibridge.sendFrom{value: nativeFee}(
      address(this),
      toChainId,
      abi.encodePacked(toAddress),
      amount,
      payable(address(0)),
      address(0),
      ""
    );

    assertEq(dai.balanceOf(address(this)), 0);
    assertEq(omnitoken.balanceOf(toAddress), amount);
  }
}
