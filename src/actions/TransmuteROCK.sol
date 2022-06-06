// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20, SafeTransferLib} from "../libraries/SafeTransferLib.sol";
import {Stewarded} from "../mixins/Stewarded.sol";

interface Mintable {
  function mint(address to, uint256 amount) external;
}

contract TransmuteROCK is Stewarded {
  using SafeTransferLib for ERC20;

  ERC20 public immutable edn;
  ERC20 public immutable work;
  address public immutable juicebox;

  constructor(
    address _steward,
    address _edn,
    address _work,
    address _juicebox
  ) {
    __initStewarded(_steward);

    edn = ERC20(_edn);
    work = ERC20(_work);
    juicebox = _juicebox;
  }

  function perform(uint256 amount) external returns (uint256 xp) {
    work.safeTransferFrom(msg.sender, address(this), amount);

    xp = (amount * 10**edn.decimals()) / 10**work.decimals();
    _mint(msg.sender, xp);
  }

  receive() external payable {
    SafeTransferLib.safeTransferETH(juicebox, msg.value);

    uint256 xp = (msg.value * 10**edn.decimals()) / 1e18;
    _mint(msg.sender, xp);
  }

  function _mint(address to, uint256 amount) private returns (uint256) {
    Mintable(address(edn)).mint(to, amount);
    return amount;
  }
}
