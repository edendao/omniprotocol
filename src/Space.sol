// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "@solmate/tokens/ERC721.sol";

import {IOmnitoken} from "@protocol/interfaces/IOmnitoken.sol";
import {Stewarded} from "@protocol/mixins/Stewarded.sol";
import {EdenDaoNS} from "@protocol/mixins/EdenDaoNS.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {OmniTokenURI} from "@protocol/mixins/OmniTokenURI.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

contract Space is
  ERC721,
  Stewarded,
  Omnichain,
  IOmnitoken,
  OmniTokenURI,
  EdenDaoNS
{
  uint256 public circulatingSupply;
  bool public mintable;

  constructor(
    address _steward,
    address _omnicast,
    bool _mintable
  ) ERC721("Eden Dao Space", "DAO SPACE") {
    __initStewarded(_steward);
    __initOmniTokenURI(_omnicast);
    __initOmnichain(address(Omnichain(_omnicast).lzEndpoint()));

    mintable = _mintable;
  }

  function tokenURI(uint256 id)
    public
    view
    override(ERC721, OmniTokenURI)
    returns (string memory)
  {
    return super.tokenURI(id);
  }

  function _mintName(address to, string memory name)
    internal
    returns (uint256 id)
  {
    circulatingSupply++;
    id = idOf(name);
    _mint(to, id);
  }

  function mint(address to, string memory name)
    external
    requiresAuth
    returns (uint256)
  {
    return _mintName(to, name);
  }

  mapping(address => uint256) public mintsBy;

  function mint(string memory name) public payable returns (uint256) {
    // solhint-disable-next-line avoid-tx-origin
    require(msg.sender == tx.origin, "Space: NO_SPOOFING");
    require(mintable, "Space: NOT_MINTABLE");

    uint256 mints = mintsBy[msg.sender];
    require(mints < 10, "Space: MINT_LIMIT");
    require(msg.value >= (mints + 1) * 0.05 ether, "Space: INVALID_VALUE");

    mintsBy[msg.sender] = mints + 1;

    return _mintName(msg.sender, name);
  }

  // ======================
  // ====== EIP-2981 ======
  // ======================
  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 10) / 100);
  }

  // =========================
  // ======= OMNITOKEN =======
  // =========================
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
    uint256 id,
    // solhint-disable-next-line no-unused-vars
    address payable,
    address lzPaymentAddress,
    bytes calldata lzAdapterParams
  ) external payable {
    if (mintable) {
      transferFrom(fromAddress, address(this), id);
    } else if (msg.sender == fromAddress && fromAddress == ownerOf(id)) {
      _burn(id);
    } else {
      revert("Space: UNAUTHORIZED");
    }

    lzSend(
      toChainId,
      abi.encode(toAddress, id),
      lzPaymentAddress,
      lzAdapterParams
    );

    emit SendToChain(
      fromAddress,
      toChainId,
      toAddress,
      id,
      lzEndpoint.getOutboundNonce(toChainId, address(this))
    );
  }

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal override {
    (bytes memory toAddressB, uint256 id) = abi.decode(
      payload,
      (bytes, uint256)
    );
    address toAddress = _addressFromPackedBytes(toAddressB);

    if (mintable) {
      transferFrom(address(this), toAddress, id);
    } else {
      _mint(toAddress, id);
    }

    emit ReceiveFromChain(
      fromChainId,
      fromContractAddress,
      toAddress,
      id,
      nonce
    );
  }
}
