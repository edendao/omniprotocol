// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";
import {Auth, Authority} from "@rari-capital/solmate/auth/Auth.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/utils/FixedPointMathLib.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";

import {Comptroller} from "@protocol/auth/Comptroller.sol";

import {Note} from "./Note.sol";

/// @title Eden Dao Omnibank
/// @author Cyrus, Transmissions11, and JetJadeja
/// @notice Factory which enables deploying a Note or a Vault for any ERC20 token.
contract Omniportal is Omnichain {
  using FixedPointMathLib for uint256;

  constructor(address _comptroller, address _lzEndpoint)
    Omnichain(_comptroller, _lzEndpoint)
  {
    this;
  }

  // Send notes into omnispace
  event SendMessage(
    uint16 indexed toChainId,
    uint64 nonce,
    address indexed noteAddress,
    address indexed fromAddress,
    bytes toAddress,
    uint256 amount
  );

  function sendMessage(
    uint16 toChainId,
    address noteAddress,
    bytes calldata toAddress,
    uint256 amount,
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) external payable {
    Note note = Note(payable(noteAddress));
    note.burnFrom(msg.sender, amount);
    uint256 fee = amount.mulDivDown(sendFeePercent, 1e18);
    note.mintTo(address(this), fee);

    lzSend(
      toChainId,
      abi.encode(note.remoteNote(toChainId), toAddress, amount - fee),
      lzPaymentAddress,
      lzTransactionParams
    );

    emit SendMessage(
      toChainId,
      lzEndpoint.getOutboundNonce(toChainId, address(this)),
      noteAddress,
      msg.sender,
      toAddress,
      amount - fee
    );
  }

  // Receive notes from omnispace
  event ReceiveMessage(
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

    emit ReceiveMessage(fromChainId, nonce, noteAddress, toAddress, amount);
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

  /// @notice The percentage of value recognized each transfer to reserve as fees.
  /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
  uint256 public sendFeePercent = 1e15; // 0.1% for public goods

  /// @notice Emitted when the fee percentage is updated.
  /// @param user The authorized user who triggered the update.
  /// @param newFeePercent The new fee percentage.
  event SendFeePercentUpdated(address indexed user, uint256 newFeePercent);

  /// @notice Sets a new fee percentage.
  /// @param newFeePercent The new fee percentage.
  function setSendFeePercent(uint256 newFeePercent) external requiresAuth {
    require(newFeePercent <= 1e16, "FEE_TOO_HIGH"); // 1% or less

    // Update the fee percentage.
    sendFeePercent = newFeePercent;

    emit SendFeePercentUpdated(msg.sender, newFeePercent);
  }
}
