// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";
import {Auth, Authority} from "@rari-capital/solmate/auth/Auth.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

import {Comptroller} from "@protocol/auth/Comptroller.sol";

interface INote {
  function mint(address receiver, uint256 amount) external returns (uint256);

  function burn(address owner, uint256 amount) external;

  function remoteNote(uint16 onChainId) external view returns (bytes memory);
}

contract Omnigateway is Omnichain, PublicGood {
  constructor(address _comptroller, address _lzEndpoint)
    Omnichain(_comptroller, _lzEndpoint)
  {
    this;
  }

  function capabilities(uint8 role) public view returns (bytes memory) {
    bytes4[] memory selectors = new bytes4[](2);
    selectors[0] = INote.mint.selector;
    selectors[1] = INote.burn.selector;

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
  ) external payable returns (uint256 flowAmount, uint256 goodAmount) {
    INote note = INote(payable(noteAddress));

    note.burn(msg.sender, amount);

    (flowAmount, goodAmount) = goodAmounts(amount);
    note.mint(address(this), goodAmount);

    lzSend(
      toChainId,
      abi.encode(note.remoteNote(toChainId), toAddress, flowAmount),
      lzPaymentAddress,
      lzTransactionParams
    );

    emit DidGood(msg.sender, flowAmount, goodAmount);

    emit SendNote(
      toChainId,
      lzEndpoint.getOutboundNonce(toChainId, address(this)),
      noteAddress,
      msg.sender,
      toAddress,
      flowAmount
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

    INote(payable(noteAddress)).mint(toAddress, amount);

    emit ReceiveNote(fromChainId, nonce, noteAddress, toAddress, amount);
  }

  // Estimate LayerZero gas associated with .sendMessage
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
