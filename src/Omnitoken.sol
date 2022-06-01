// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmnitoken} from "./interfaces/IOmnitoken.sol";
import {ERC20} from "./mixins/ERC20.sol";
import {Stewarded} from "./mixins/Stewarded.sol";
import {Omnichain} from "./mixins/Omnichain.sol";
import {PublicGood} from "./mixins/PublicGood.sol";

contract Omnitoken is ERC20, Omnichain, IOmnitoken {
  // ================================
  // ======== Initializable =========
  // ================================
  function _initialize(bytes memory _params) internal virtual override {
    (
      address _lzEndpoint,
      address _steward,
      string memory _name,
      string memory _symbol,
      uint8 _decimals
    ) = abi.decode(_params, (address, address, string, string, uint8));

    __initOmnichain(_lzEndpoint);
    __initStewarded(_steward);
    __initERC20(_name, _symbol, _decimals);
  }

  // ================================
  // ============ ERC20 =============
  // ================================
  function mint(address to, uint256 amount) external virtual requiresAuth {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external virtual requiresAuth {
    if (msg.sender != from) {
      _useAllowance(from, msg.sender, amount);
    }
    _burn(from, amount);
  }

  function transfer(address to, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    return transferFrom(msg.sender, to, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override requiresAuth returns (bool) {
    return super.transferFrom(sender, recipient, amount);
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
