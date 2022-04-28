// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "@rari-capital/solmate/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/utils/ReentrancyGuard.sol";

import {INote} from "@protocol/interfaces/INote.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

contract Note is INote, PublicGood, ERC20, Pausable, ReentrancyGuard {
  using SafeTransferLib for ERC20;

  constructor(
    address _comptroller,
    address _beneficiary,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  )
    Comptrolled(_comptroller)
    PublicGood(_beneficiary)
    ERC20(_name, string(abi.encodePacked("edn-", _symbol)), _decimals)
  {
    this;
  }

  function mint(address to, uint256 amount)
    external
    nonReentrant
    whenNotPaused
    requiresAuth
    returns (uint256)
  {
    _mint(to, amount);
    _mint(beneficiary, _mulDivDown(amount, goodPercent, 1e18));
    return amount;
  }

  function burn(address from, uint256 amount)
    external
    nonReentrant
    whenNotPaused
    requiresAuth
    returns (uint256)
  {
    _burn(from, amount);
    return amount;
  }

  // ==========================
  // ======= OMNIBRIDGE =======
  // ==========================
  mapping(uint16 => bytes) public remoteNote;

  function setRemoteNote(uint16 onChainId, bytes memory remoteNoteAddressB)
    external
    requiresAuth
  {
    remoteNote[onChainId] = remoteNoteAddressB;
  }
}
