// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { SafeTransferLib } from "@rari-capital/solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "@rari-capital/solmate/tokens/ERC20.sol";
import { EDN } from "../tokens/EDN.sol";

contract AngelMint {
  using SafeTransferLib for ERC20;
  ERC20 internal immutable usdc;
  EDN internal immutable edn;

  constructor(address _usdc, address _edn) {
    usdc = ERC20(_usdc);
    edn = EDN(_edn);
  }

  function previewMint(uint256 deposit) public pure returns (uint256) {
    // exchange rate is $0.6 USDC = 1 EDN
    return (deposit * 6) / 10**4; // EDN has 3 decimals, USDC has 6
  }

  function mint(uint256 deposit) external returns (uint256 minted) {
    minted = previewMint(deposit);
    require(minted > 0, "Minimum mint of 1 EDN");

    usdc.safeTransferFrom(msg.sender, address(this), deposit);
    edn.mint(msg.sender, minted);
  }

  function withdraw() external {
    usdc.safeTransferFrom(
      address(this),
      msg.sender,
      usdc.balanceOf(address(this))
    );
  }
}
