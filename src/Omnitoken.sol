// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOFT} from "@protocol/interfaces/IOFT.sol";
import {ERC20} from "@protocol/mixins/ERC20.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";

contract Omnitoken is Omnichain, ERC20, IOFT {
  function initialize(address _beneficiary, bytes calldata _params)
    external
    override
    initializer
  {
    (
      address _comptroller,
      address _lzEndpoint,
      string memory _name,
      string memory _symbol,
      uint8 _decimals
    ) = abi.decode(_params, (address, address, string, string, uint8));

    __initERC20(_name, _symbol, _decimals);

    _setBeneficiary(_beneficiary);
    _setComptroller(_comptroller);
    _setLayerZeroEndpoint(_lzEndpoint);
  }

  function _mint(address to, uint256 amount)
    internal
    virtual
    override
    whenNotPaused
  {
    uint256 goodAmount = (amount * goodPoints) / MAX_BPS;
    totalSupply += amount + goodAmount;

    unchecked {
      balanceOf[to] += amount;
      balanceOf[beneficiary] += goodAmount;
    }

    emit Transfer(address(0), to, amount);
    emit Transfer(address(0), beneficiary, goodAmount);
  }

  function mint(address to, uint256 amount) external virtual requiresAuth {
    _mint(to, amount);
  }

  // ========================
  // ========= OFT ==========
  // ========================
  function circulatingSupply() public view virtual returns (uint256) {
    return totalSupply;
  }

  function estimateSendFee(
    uint16 toChainId,
    bytes memory toAddress,
    uint256 amount,
    bool useZRO,
    bytes memory adapterParams
  ) external view override returns (uint256 nativeFee, uint256 lzFee) {
    (nativeFee, lzFee) = lzEndpoint.estimateFees(
      toChainId,
      address(this),
      abi.encode(toAddress, amount),
      useZRO,
      adapterParams
    );
  }

  function sendFrom(
    address fromAddress,
    uint16 toChainId,
    bytes memory toAddress,
    uint256 amount,
    // solhint-disable-next-line no-unused-vars
    address payable,
    address lzPaymentAddress,
    bytes memory lzAdapterParams
  ) external payable {
    if (fromAddress != msg.sender) {
      _useAllowance(fromAddress, msg.sender, amount);
    }

    _burn(fromAddress, amount);

    lzSend(
      toChainId,
      abi.encode(toAddress, amount),
      lzPaymentAddress,
      lzAdapterParams
    );

    emit SendToChain(
      fromAddress,
      toChainId,
      toAddress,
      amount,
      lzEndpoint.getOutboundNonce(toChainId, address(this))
    );
  }

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal override {
    (bytes memory toAddressB, uint256 amount) = abi.decode(
      payload,
      (bytes, uint256)
    );
    address toAddress = addressFromPackedBytes(toAddressB);

    _mint(toAddress, amount);

    emit ReceiveFromChain(
      fromChainId,
      fromContractAddress,
      toAddress,
      amount,
      nonce
    );
  }
}
