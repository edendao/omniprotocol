// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Omnitoken} from "@test/ChainEnvironmentTest.t.sol";

import {Tokenbridge} from "@protocol/Tokenbridge.sol";

contract TokenbridgeTest is ChainEnvironmentTest {
  Tokenbridge public tokenbridge =
    Tokenbridge(bridge.clone(address(comptroller), address(dai)));
  Omnitoken public omnitoken =
    Omnitoken(token.clone(address(comptroller), "DAI", "DAI", dai.decimals()));

  function testCloneGas() public {
    Tokenbridge(bridge.clone(address(comptroller), address(omnitoken)));
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
    tokenbridge.setTrustedRemote(
      toChainId,
      abi.encodePacked(address(omnitoken))
    );
    omnitoken.setTrustedRemote(
      currentChainId,
      abi.encodePacked(address(tokenbridge))
    );

    dai.mint(address(this), amount);
    dai.approve(address(tokenbridge), amount);

    (uint256 nativeFee, ) = tokenbridge.estimateSendFee(
      toChainId,
      abi.encodePacked(toAddress),
      amount,
      false,
      ""
    );

    tokenbridge.sendFrom{value: nativeFee}(
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
