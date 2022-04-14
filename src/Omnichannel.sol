// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "@rari-capital/solmate/tokens/ERC721.sol";

import {EdenDaoNS} from "@protocol/mixins/EdenDaoNS.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";

contract Omnichannel is ERC721, Omnichain, EdenDaoNS {
  uint16 public primaryChainId;

  constructor(
    address _comptroller,
    address _lzEndpoint,
    uint16 _primaryChainId
  )
    ERC721("Eden Dao Omnichannel", "OMNICHANNEL")
    Omnichain(_comptroller, _lzEndpoint)
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
      _mint(comptrollerAddress(), premint[i]);
    }
  }

  function idOf(string memory node) public pure returns (uint256) {
    return namehash(node);
  }

  // ========================
  // ====== OWNERSHIP =======
  // ========================
  modifier onlyOwnerOf(uint256 channelId) {
    require(msg.sender == ownerOf(channelId), "Omnichannel: ONLY_OWNER");
    _;
  }

  // ==============================
  // ========= TOKEN URI ==========
  // ==============================
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
    whenNotPaused
    returns (uint256)
  {
    require(currentChainId == primaryChainId, "Omnichannel: INVALID_CHAIN");
    require(channelId > type(uint160).max, "Omnichannel: RESERVED_SPACE");

    _mint(to, channelId);
    return channelId;
  }

  function burn(uint256 channelId) external {
    require(
      ownerOf(channelId) == msg.sender || isAuthorized(msg.sender, msg.sig),
      "Omnichannel: UNAUTHORIZED"
    );
    _burn(channelId);
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

  // =======================
  // ====== OMNICHAIN ======
  // =======================
  event ReceiveFromChain(
    uint16 indexed fromChainId,
    address indexed toAddress,
    uint256 indexed tokenId,
    uint64 nonce
  );

  function receiveMessage(
    uint16, // fromChainId
    bytes calldata, // fromContractAddress
    uint64, // nonce
    bytes memory payload
  ) internal override {
    (bytes memory toAddressB, uint256 channelId, bytes memory uri) = abi.decode(
      payload,
      (bytes, uint256, bytes)
    );

    _mint(addressFromPackedBytes(toAddressB), channelId);
    _tokenURI[channelId] = uri;
  }

  function estimateSendFee(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 channelId,
    bool useZRO,
    bytes calldata adapterParams
  ) public view returns (uint256, uint256) {
    return
      lzEstimateSendGas(
        toChainId,
        abi.encode(toAddress, channelId, _tokenURI[channelId]),
        useZRO,
        adapterParams
      );
  }

  event SendToChain(
    address indexed fromAddress,
    uint16 indexed toChainId,
    bytes indexed toAddress,
    uint256 tokenId,
    uint64 nonce
  );

  function send(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 channelId,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable {
    omniTransferFrom(
      msg.sender,
      toChainId,
      toAddress,
      channelId,
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
    bytes memory lzTransactionParams
  ) external payable {
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
    uint256 channelId,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) internal {
    require(
      fromAddress == ownerOf(channelId) &&
        (msg.sender == fromAddress ||
          isApprovedForAll[fromAddress][msg.sender] ||
          msg.sender == getApproved[channelId]),
      "Omnichannel: UNAUTHORIZED"
    );

    _burn(channelId);

    lzSend(
      toChainId,
      abi.encode(toAddress, channelId, _tokenURI[channelId]),
      lzPaymentAddress,
      lzTransactionParams
    );

    emit SendToChain(
      fromAddress,
      toChainId,
      toAddress,
      channelId,
      lzEndpoint.getOutboundNonce(toChainId, address(this))
    );
  }
}
