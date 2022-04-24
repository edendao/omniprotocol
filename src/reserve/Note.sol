// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/utils/ReentrancyGuard.sol";

import {Pausable} from "@protocol/mixins/Pausable.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

contract Note is ERC20, Comptrolled, Pausable, ReentrancyGuard {
  constructor(
    address _comptroller,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) Comptrolled(_comptroller) ERC20(name, symbol, decimals) {
    this;
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
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

  // To get the authority to call these functions, reach out to us
  function mintTo(address to, uint256 amount)
    external
    requiresAuth
    whenNotPaused
    nonReentrant
    returns (uint256)
  {
    _mint(to, amount);
    return amount;
  }

  function burnFrom(address from, uint256 amount)
    external
    requiresAuth
    nonReentrant
    whenNotPaused
  {
    _burn(from, amount);
  }
}
