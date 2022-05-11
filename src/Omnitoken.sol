// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmnitoken} from "@protocol/interfaces/IOmnitoken.sol";
import {Cloneable} from "@protocol/mixins/Cloneable.sol";
import {ERC20} from "@protocol/mixins/ERC20.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

contract Omnitoken is
  ERC20,
  PublicGood,
  Comptrolled,
  IOmnitoken,
  Omnichain,
  Cloneable
{
  constructor(address _beneficiary, address _lzEndpoint) {
    __initPublicGood(_beneficiary);
    __initOmnichain(_lzEndpoint);
  }

  // ================================
  // ========== Cloneable ===========
  // ================================
  function initialize(address _beneficiary, bytes calldata _params)
    external
    virtual
    override
    initializer
  {
    __initPublicGood(_beneficiary);

    (
      address _lzEndpoint,
      address _comptroller,
      string memory _name,
      string memory _symbol,
      uint8 _decimals
    ) = abi.decode(_params, (address, address, string, string, uint8));

    __initOmnichain(_lzEndpoint);
    __initComptrolled(_comptroller);
    __initERC20(_name, _symbol, _decimals);
  }

  function clone(
    address _comptroller,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) external returns (address cloneAddress) {
    cloneAddress = clone();
    Cloneable(cloneAddress).initialize(
      beneficiary,
      abi.encode(address(lzEndpoint), _comptroller, _name, _symbol, _decimals)
    );
  }

  // ================================
  // ========= Public Good ==========
  // ================================
  uint16 public constant MAX_BPS = 10_000;
  uint16 public goodPoints = 25; // 0.25% for the planet

  event SetGoodPoints(uint16 points);

  function setGoodPoints(uint16 basisPoints) external requiresAuth {
    require(
      10 <= basisPoints && basisPoints <= MAX_BPS,
      "PublicGood: INVALID_BP"
    );
    goodPoints = basisPoints;
    emit SetGoodPoints(basisPoints);
  }

  function _mint(address to, uint256 amount) internal virtual override {
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

  // ===============================
  // ========= IOmnitoken ==========
  // ===============================
  function circulatingSupply() public view virtual returns (uint256) {
    return totalSupply;
  }

  function estimateSendFee(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    bool useZRO,
    bytes calldata adapterParams
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
    bytes calldata lzAdapterParams
  ) external payable virtual {
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
  ) internal virtual override {
    (bytes memory toAddressB, uint256 amount) = abi.decode(
      payload,
      (bytes, uint256)
    );
    address toAddress = _addressFromPackedBytes(toAddressB);

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
