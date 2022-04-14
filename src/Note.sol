// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";

contract Note is ERC20, Omnichain {
  constructor(address _comptroller, address _lzEndpoint)
    ERC20("Eden Dao Note", "EDN", 3)
    Omnichain(_comptroller, _lzEndpoint)
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

  function burnFrom(address from, uint256 amount)
    external
    requiresAuth
    whenNotPaused
  {
    _burn(from, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  // ===========================
  // ======== OMNICHAIN ========
  // ===========================
  event ReceiveFromChain(
    uint16 indexed fromChainId,
    address indexed toAddress,
    uint256 amount,
    uint64 nonce
  );

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata, // _fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal override {
    (bytes memory toAddressB, uint256 amount) = abi.decode(
      payload,
      (bytes, uint256)
    );
    address toAddress = addressFromPackedBytes(toAddressB);

    _mint(toAddress, amount);
    emit ReceiveFromChain(fromChainId, toAddress, amount, nonce);
  }

  function estimateSendFee(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    bool useZRO,
    bytes calldata adapterParams
  ) public view returns (uint256, uint256) {
    return
      lzEstimateSendGas(
        toChainId,
        abi.encode(toAddress, amount),
        useZRO,
        adapterParams
      );
  }

  event SendToChain(
    address indexed fromAddress,
    uint16 indexed toChainId,
    bytes indexed toAddress,
    uint256 amount,
    uint64 nonce
  );

  function send(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) external payable {
    omniTransferFrom(
      msg.sender,
      toChainId,
      toAddress,
      amount,
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  function sendFrom(
    address fromAddress,
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) external payable {
    uint256 allowed = allowance[fromAddress][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max) {
      allowance[fromAddress][msg.sender] = allowed - amount;
    }

    omniTransferFrom(
      fromAddress,
      toChainId,
      toAddress,
      amount,
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  function omniTransferFrom(
    address fromAddress,
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) internal {
    _burn(fromAddress, amount);

    lzSend(
      toChainId,
      abi.encode(toAddress, amount),
      lzPaymentAddress,
      lzTransactionParams
    );

    emit SendToChain(
      fromAddress,
      toChainId,
      toAddress,
      amount,
      lzEndpoint.getOutboundNonce(toChainId, address(this))
    );
  }
}
