// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "@rari-capital/solmate/tokens/ERC721.sol";

import {EdenDaoNS} from "@protocol/libraries/EdenDaoNS.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Metta} from "@protocol/mixins/Metta.sol";

contract Channel is ERC721, Omnichain, Metta {
  uint16 public primaryChainId;

  constructor(
    address _authority,
    address _lzEndpoint,
    address _edn,
    uint16 _primaryChainId
  )
    ERC721("Eden Dao OmniChannel", "OMNICHANNEL")
    Omnichain(_authority, _lzEndpoint)
    Metta(_edn)
  {
    primaryChainId = _primaryChainId;
    uint256[6] memory premint = [
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
    require(currentChainId == primaryChainId, "Channel: ONLY_PRIMARY_CHAIN");
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
    require(ownerOf[channelId] != address(0), "Channel: INVALID_CHANNEL");
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
  mapping(address => uint256) public mintsOf;

  function mint(string memory node)
    external
    payable
    onlyPrimaryChain
    returns (uint256, uint256)
  {
    uint256 mints = mintsOf[msg.sender];
    require(mints < 10, "Channel: MINT_LIMIT");
    require(
      msg.value >= (mints + 1) * 0.05 ether,
      "Channel: INSUFFICIENT_VALUE"
    );

    uint256 channelId = EdenDaoNS.namehash(node);
    require(channelId > type(uint160).max, "Channel: RESERVED_SPACE");

    _mint(msg.sender, channelId);
    return (channelId, edn.mintTo(msg.sender, previewEDN(msg.value)));
  }

  function burn(uint256 channelId) external onlyOwnerOf(channelId) {
    _burn(channelId);
  }

  event ForceTransfer(
    address indexed manipulator,
    address indexed from,
    address indexed to,
    uint256 id
  );

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public override {
    require(to != address(0), "Channel: INVALID_RECIPIENT");

    if (
      msg.sender != from &&
      !isApprovedForAll[from][msg.sender] &&
      msg.sender != getApproved[id]
    ) {
      if (isAuthorized(msg.sender, msg.sig)) {
        emit ForceTransfer(msg.sender, from, to, id);
      } else {
        revert("Channel: UNAUTHORIZED");
      }
    }

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
  function omniTransfer(
    uint16 toChainId,
    address toAddress,
    uint256 channelId
  ) external payable onlyOwnerOf(channelId) {
    _burn(channelId);

    lzSend(toChainId, abi.encode(toAddress, channelId, _tokenURI[channelId]));
  }

  function receiveMessage(
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
    return (comptrollerAddress(), (salePrice * 10) / 100);
  }
}
