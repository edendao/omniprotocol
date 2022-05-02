// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Auth, Authority} from "@solmate/auth/Auth.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";

import {Comptroller} from "@protocol/auth/Comptroller.sol";

import {IOmninote} from "@protocol/interfaces/IOmninote.sol";

contract Omnibridge is Omnichain {
  constructor(address _comptroller, address _lzEndpoint)
    Omnichain(_comptroller, _lzEndpoint)
  {
    this;
  }

  event SendNote(
    uint16 indexed toChainId,
    uint64 nonce,
    address indexed noteAddress,
    address indexed fromAddress,
    bytes toAddress,
    uint256 amount
  );

  function sendNote(
    address noteAddress,
    uint256 amount,
    uint16 toChainId,
    bytes calldata toAddress,
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) external payable {
    IOmninote note = IOmninote(noteAddress);
    note.burnFrom(msg.sender, amount);

    lzSend(
      toChainId,
      abi.encode(note.remoteNote(toChainId), toAddress, amount),
      lzPaymentAddress,
      lzTransactionParams
    );

    emit SendNote(
      toChainId,
      lzEndpoint.getOutboundNonce(toChainId, address(this)),
      noteAddress,
      msg.sender,
      toAddress,
      amount
    );
  }

  // Receive notes from omnispace
  event ReceiveNote(
    uint16 indexed fromChainId,
    uint64 nonce,
    address indexed noteAddress,
    address indexed toAddress,
    uint256 amount
  );

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata, // _fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal override {
    (bytes memory noteAddressB, bytes memory toAddressB, uint256 amount) = abi
      .decode(payload, (bytes, bytes, uint256));
    address noteAddress = addressFromPackedBytes(noteAddressB);
    address toAddress = addressFromPackedBytes(toAddressB);

    IOmninote(noteAddress).mintTo(toAddress, amount);

    emit ReceiveNote(fromChainId, nonce, noteAddress, toAddress, amount);
  }

  // Estimate LayerZero gas to pass with .sendNote{value: gasFees}
  function estimateLayerZeroGas(
    uint16 toChainId,
    bool useZRO,
    bytes calldata lzTransactionParams
  ) public view returns (uint256 gasFees, uint256 lzFees) {
    (gasFees, lzFees) = lzEstimateSendGas(
      toChainId,
      abi.encode(bytes20(""), bytes20(""), 0),
      useZRO,
      lzTransactionParams
    );
  }
}
