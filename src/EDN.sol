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

  function mintTo(address _to, uint256 _amount) external requiresAuth {
    _mint(_to, _amount);
  }

  function burn(uint256 _amount) external {
    _burn(msg.sender, _amount);
  }

  function burnFrom(address _from, uint256 _amount) external requiresAuth {
    _burn(_from, _amount);
  }

  function lzSend(
    uint16 _toChainId,
    address _toAddress,
    uint256 _amount,
    address _zroPaymentAddress, // ZRO payment address
    bytes calldata _adapterParams // txParameters
  ) external payable {
    _burn(msg.sender, _amount);

    lzEndpoint.send{ value: msg.value }(
      _toChainId, // destination chainId
      chainContracts[_toChainId], // destination UA address
      abi.encode(_toAddress, _amount), // abi.encode()'ed bytes
      payable(msg.sender), // refund address (LayerZero will refund any extra gas back to caller of send()
      _zroPaymentAddress, // 'zroPaymentAddress' unused for this mock/example
      _adapterParams
    );
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _fromAddress,
    uint64, // _nonce
    bytes memory _payload
  ) external {
    require(
      msg.sender == address(lzEndpoint) &&
        _fromAddress.length == chainContracts[_srcChainId].length &&
        keccak256(_fromAddress) == keccak256(chainContracts[_srcChainId]),
      "EDN: Invalid caller for lzReceive"
    );

    (address _toAddress, uint256 _amount) = abi.decode(
      _payload,
      (address, uint256)
    );

    _mint(_toAddress, _amount);
  }
}
