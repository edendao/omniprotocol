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
    uint256[9] memory premint = [
      idOf("my"),
      idOf("profile"),
      idOf("app"),
      idOf("name"),
      idOf("tokenuri"),
      idOf("terexitarius"),
      idOf("gitcoin"),
      idOf("station"),
      idOf("refi")
    ];
    for (uint256 i = 0; i < premint.length; i++) {
      _mint(comptrollerAddress(), premint[i]);
    }
  }

  function idOf(string memory node) public pure returns (uint256) {
    return namehash(node);
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

  function setTokenURI(uint256 channelId, bytes memory uri) external {
    require(msg.sender == ownerOf(channelId), "Omnichannel: ONLY_OWNER");
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
  event ReceiveOmnitransfer(
    uint16 indexed fromChainId,
    address indexed toAddress,
    uint256 indexed tokenId,
    uint64 nonce
  );

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata, // fromContractAddress
    uint64 nonce,
    bytes memory payload
  ) internal override {
    (bytes memory toAddressB, uint256 channelId, bytes memory uri) = abi.decode(
      payload,
      (bytes, uint256, bytes)
    );

    address toAddress = addressFromPackedBytes(toAddressB);
    _mint(toAddress, channelId);
    _tokenURI[channelId] = uri;

    emit ReceiveOmnitransfer(fromChainId, toAddress, channelId, nonce);
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

  event SendOmnitransfer(
    address indexed fromAddress,
    uint16 indexed toChainId,
    bytes indexed toAddress,
    uint256 tokenId,
    uint64 nonce
  );

  function omnitransfer(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 channelId,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable {
    _omnitransferFrom(
      msg.sender,
      toChainId,
      toAddress,
      channelId,
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  function omnitransferFrom(
    address fromAddress,
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable {
    _omnitransferFrom(
      fromAddress,
      toChainId,
      toAddress,
      amount,
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  function _omnitransferFrom(
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

    emit SendOmnitransfer(
      fromAddress,
      toChainId,
      toAddress,
      channelId,
      lzEndpoint.getOutboundNonce(toChainId, address(this))
    );
  }
}
