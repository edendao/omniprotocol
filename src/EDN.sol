// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { ERC20 } from "@rari-capital/solmate/tokens/ERC20.sol";

import { IMasterContract } from "@boring/interfaces/IMasterContract.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

contract EDN is ERC20, Authenticated, Omnichain {
  constructor(address _authority, address _lzEndpoint)
    ERC20("Eden Dao Note", "EDN", 3)
    Authenticated(_authority)
    Omnichain(_lzEndpoint)
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
    address zroPaymentAddress, // ZRO payment address
    bytes calldata adapterParams // txParameters
  ) external payable {
    _burn(msg.sender, amount);

    lzEndpoint.send{ value: msg.value }(
      toChainId,
      chainContracts[toChainId], // destination contract address
      abi.encode(toAddress, amount), // payload
      payable(msg.sender), // refund unused gas
      zroPaymentAddress,
      adapterParams
    );
  }

  function lzReceive(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64, // _nonce
    bytes memory payload
  ) external onlyRelayer(fromChainId, fromContractAddress) {
    (address addr, uint256 amount) = abi.decode(payload, (address, uint256));
    _mint(addr, amount);
  }
}
