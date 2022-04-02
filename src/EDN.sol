// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { ERC20 } from "@rari-capital/solmate/tokens/ERC20.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Pausable } from "@protocol/mixins/Pausable.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

contract EDN is ERC20, Authenticated, Omnichain, Pausable {
  constructor(address _authority, address _lzEndpoint)
    ERC20("Eden Dao Note", "EDN", 3)
    Omnichain(_lzEndpoint)
    Authenticated(_authority)
  {
    this;
  }

  function mintTo(address to, uint256 amount) external requiresAuth {
    _mint(to, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function burnFrom(address _from, uint256 amount) external requiresAuth {
    _burn(_from, amount);
  }

  function lzSend(
    uint16 toChainId,
    address toAddress,
    uint256 amount,
    address _zroPaymentAddress, // ZRO payment address
    bytes calldata _adapterParams // txParameters
  ) external payable {
    _burn(msg.sender, amount);

    lzEndpoint.send{ value: msg.value }(
      toChainId,
      chainContracts[toChainId], // destination contract address
      abi.encode(toAddress, amount), // payload
      payable(msg.sender), // refund unused gas
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function lzReceive(
    uint16 fromChainId,
    bytes calldata _fromAddress,
    uint64, // _nonce
    bytes memory _payload
  ) external {
    require(
      msg.sender == address(lzEndpoint) &&
        _fromAddress.length == chainContracts[fromChainId].length &&
        keccak256(_fromAddress) == keccak256(chainContracts[fromChainId]),
      "EDN: Invalid caller for lzReceive"
    );

    (address toAddress, uint256 amount) = abi.decode(
      _payload,
      (address, uint256)
    );

    _mint(toAddress, amount);
  }
}
