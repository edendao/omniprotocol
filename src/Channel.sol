// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "@rari-capital/solmate/tokens/ERC721.sol";

import {EdenDaoNS} from "@protocol/libraries/EdenDaoNS.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";

contract Channel is ERC721, Omnichain {
  uint16 public primaryChainId;

  constructor(
    address _authority,
    address _lzEndpoint,
    uint16 _primaryChainId
  )
    // Eden Dao Channel Service = Eden Dao DS = Eden Dao Deus = DAO DEUS
    ERC721("Eden Dao Channel", "OMNISPACE")
    Omnichain(_authority, _lzEndpoint)
  {
    primaryChainId = _primaryChainId;
    uint256[40] memory premint = [
      0,
      1,
      2,
      3,
      5,
      6,
      7,
      8,
      10,
      13,
      21,
      22,
      28,
      29,
      30,
      31,
      34,
      42,
      69,
      80,
      81,
      222,
      365,
      420,
      443,
      1337,
      1998,
      2001,
      4242,
      662607015, // Planck's Constant
      12345667890,
      12345667890987654321,
      2718281828459045235360, // Euler's number
      3141592653589793238462, // π
      0x02dae9de41f5b412ce8d65c69e825802e5cfc0bb85d707c53c94e30d4ddd56d2,
      0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f,
      0xea8fba367ad6b69c052c234a59bf5699ab50fa270606dbafe9a4ce0980c9c7aa,
      0x024ea6b6f347d1530d953d352fe1f5df9bd6ba1fd817c0b7243943917d8507ed,
      0x25294245858553a1889e6fe0f4976bd4e2405f5d55396afa91cad09a95c78137,
      0xf689f82b3b8f0beecad45cce0f793c9553e6f68d339c23fe6cecb993903a1744
    ];
    for (uint256 i = 0; i < premint.length; i++) {
      _mint(owner, premint[i]);
    }
  }

  function idOf(string memory node) public pure returns (uint256) {
    return EdenDaoNS.namehash(node);
  }

  // ========================
  // ====== MODIFIERS =======
  // ========================
  modifier onlyPrimaryChain() {
    require(currentChainId == primaryChainId, "Channel: INVALID_CHAIN");
    _;
  }

  modifier onlyOwnerOf(uint256 channelId) {
    require(msg.sender == ownerOf[channelId], "Channel: ONLY_OWNER");
    _;
  }

  // ========================
  // ====== TOKEN URI =======
  // ========================
  mapping(uint256 => bytes) internal _tokenURI;

  function tokenURI(uint256 channelId)
    public
    view
    override
    returns (string memory)
  {
    return string(_tokenURI[channelId]);
  }

  function setTokenURI(uint256 channelId, bytes memory uri)
    external
    onlyOwnerOf(channelId)
  {
    _tokenURI[channelId] = uri;
  }

  // ===================================
  // ===== MINTS, BURNS, TRANSFERS =====
  // ===================================
  function mintTo(address to, uint256 channelId)
    external
    requiresAuth
    onlyPrimaryChain
  {
    _mint(to, channelId);
  }

  function burn(uint256 channelId)
    external
    onlyPrimaryChain
    onlyOwnerOf(channelId)
  {
    _burn(channelId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public override {
    require(to != address(0), "Channel: INVALID_RECIPIENT");
    require(
      msg.sender == from ||
        isApprovedForAll[from][msg.sender] ||
        msg.sender == getApproved[id] ||
        isAuthorized(msg.sender, msg.sig), // for DAO control, later
      "Channel: UNAUTHORIZED"
    );

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      balanceOf[from]--;
      balanceOf[to]++;
    }

    ownerOf[id] = to;
    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  // =======================
  // ====== LayerZero ======
  // =======================
  function sendToken(
    uint16 toChainId,
    address toAddress,
    uint256 channelId,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable onlyOwnerOf(channelId) {
    _burn(channelId);
    lzSend(
      toChainId,
      abi.encode(toAddress, channelId, _tokenURI[channelId]),
      zroPaymentAddress,
      adapterParams
    );
  }

  function onReceive(
    uint16, // _fromChainId
    bytes calldata, // _fromContractAddress
    uint64, // _nonce
    bytes memory payload
  ) internal override {
    (address toAddress, uint256 channelId, bytes memory uri) = abi.decode(
      payload,
      (address, uint256, bytes)
    );

    _mint(toAddress, channelId);
    _tokenURI[channelId] = uri;
  }

  // ======================
  // ====== EIP-2981 ======
  // ======================
  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(comptroller()), (salePrice * 10) / 100);
  }
}
