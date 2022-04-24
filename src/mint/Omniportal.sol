// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";
import {Auth, Authority} from "@rari-capital/solmate/auth/Auth.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/utils/FixedPointMathLib.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";

import {Comptroller} from "@protocol/auth/Comptroller.sol";

import {Note} from "./Note.sol";

contract Omniportal is Omnichain {
  using FixedPointMathLib for uint256;

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
    Note note = Note(payable(noteAddress));
    note.burnFrom(msg.sender, amount);

    uint256 fee = amount.mulDivDown(feePercent, 1e18);
    note.mintTo(address(this), fee);

    amount -= fee;

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

    Note(payable(noteAddress)).mintTo(toAddress, amount);

    emit ReceiveNote(fromChainId, nonce, noteAddress, toAddress, amount);
  }

  // Estimate LayerZero gas associated with .sendMessage
  function estimateLayerZeroGas(
    uint16 toChainId,
    bool useZRO,
    bytes calldata adapterParams
  ) public view returns (uint256, uint256) {
    return
      lzEstimateSendGas(
        toChainId,
        abi.encode(bytes20(""), bytes20(""), 0),
        useZRO,
        adapterParams
      );
  }

  uint256 public feePercent = 1e15; // 0.1% for public goods

  event FeePercentUpdated(address indexed user, uint256 newFeePercent);

  function setFeePercent(uint256 newFeePercent) external requiresAuth {
    require(newFeePercent <= 1e16, "Omniportal: INVALID_FEE"); // 1% or less
    feePercent = newFeePercent;
    emit FeePercentUpdated(msg.sender, newFeePercent);
  }
}
