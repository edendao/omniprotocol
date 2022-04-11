// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

contract Note is ERC20, Omnichain, Pausable {
  constructor(address _authority, address _lzEndpoint)
    ERC20("Eden Dao Note", "EDN", 3)
    Omnichain(_authority, _lzEndpoint)
  {
    this;
  }

  // =========================
  // ========= TOKEN =========
  // =========================
  function mintTo(address to, uint256 amount)
    external
    requiresAuth
    whenNotPaused
    returns (uint256)
  {
    _mint(to, amount);
    return amount;
  }

  function burnFrom(address _from, uint256 amount)
    external
    requiresAuth
    whenNotPaused
  {
    _burn(_from, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  event ForceTransfer(
    address indexed manipulator,
    address indexed from,
    address indexed to,
    uint256 amount
  );

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override whenNotPaused returns (bool) {
    if (isAuthorized(msg.sender, msg.sig)) {
      emit ForceTransfer(msg.sender, from, to, amount);
    } else {
      uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
      if (allowed != type(uint256).max) {
        allowance[from][msg.sender] = allowed - amount;
      }
    }

    balanceOf[from] -= amount;
    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);
    return true;
  }

  // ===========================
  // ======== Omnichain ========
  // ===========================
  event Noted(
    uint16 indexed chainId,
    address indexed sender,
    address indexed recipient,
    uint256 amount
  );

  function omniTransfer(
    uint16 toChainId,
    address toAddress,
    uint256 amount
  ) external payable whenNotPaused {
    bytes memory data = abi.encode(toAddress, amount);
    (uint256 nativeFee, ) = estimateLzSendGas(toChainId, data, false, "");
    require(msg.value >= nativeFee, "Note: INSUFFICIENT_SEND_VALUE");

    _burn(msg.sender, amount);

    // solhint-disable-next-line check-send-result
    lzEndpoint.send{value: msg.value}(
      toChainId,
      remoteContracts[toChainId],
      data,
      payable(msg.sender),
      comptrollerAddress(),
      ""
    );

    emit Noted(toChainId, msg.sender, toAddress, amount);
  }

  function onMessage(
    uint16 fromChainId,
    bytes calldata, // _fromContractAddress,
    uint64, // _nonce,
    bytes memory payload
  ) internal override whenNotPaused {
    (address toAddress, uint256 amount) = abi.decode(
      payload,
      (address, uint256)
    );

    _mint(toAddress, amount);
    emit Noted(fromChainId, msg.sender, toAddress, amount);
  }
}
