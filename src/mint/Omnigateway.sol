// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";
import {Auth, Authority} from "@rari-capital/solmate/auth/Auth.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";

import {Comptroller} from "@protocol/auth/Comptroller.sol";

interface INote {
  function mintTo(address receiver, uint256 amount) external returns (uint256);

  function burnFrom(address owner, uint256 amount) external;

  function remoteNote(uint16 onChainId) external view returns (bytes memory);
}

contract Omnigateway is Omnichain {
  constructor(address _comptroller, address _lzEndpoint)
    Omnichain(_comptroller, _lzEndpoint)
  {
    this;
  }

  function capabilities(uint8 role) public view returns (bytes memory) {
    bytes4[] memory selectors = new bytes4[](2);
    selectors[0] = INote.mintTo.selector;
    selectors[1] = INote.burnFrom.selector;

    return
      abi.encodeWithSelector(
        comptroller.setCapabilitiesTo.selector,
        address(this),
        role,
        selectors,
        true
      );
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
    INote note = INote(payable(noteAddress));

    note.burnFrom(msg.sender, amount);
    amount -= note.mintTo(address(this), _mulDivDown(amount, feePercent, 1e18));

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

    INote(payable(noteAddress)).mintTo(toAddress, amount);

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

  // From Solmate
  function _mulDivDown(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(
        and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))
      ) {
        revert(0, 0)
      }

      // Divide z by the denominator.
      z := div(z, denominator)
    }
  }
}
