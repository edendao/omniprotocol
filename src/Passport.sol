// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { IERC721, IERC721Metadata } from "@boring/interfaces/IERC721.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";
import { Soulbound, Immovable } from "@protocol/mixins/Soulbound.sol";

import { Domain } from "./Domain.sol";

/*
 * A Passport is your cross-chain identity for the future.
 */
contract Passport is
  IERC721,
  IERC721Metadata,
  Omnichain,
  Soulbound,
  Authenticated
{
  uint256 public constant TOKEN_URI_DOMAIN = 0;
  Domain public domain;

  event Sync(
    uint16 indexed fromChainId,
    uint16 indexed toChainId,
    uint256 indexed id,
    uint256 domainId
  );

  string public constant name = "Eden Dao Passport";
  string public constant symbol = "DAO PASS";

  mapping(uint256 => address) public ownerOf;
  // tokenId => domainId => data
  mapping(uint256 => mapping(uint256 => bytes)) public dataOf;

  constructor(
    address _authority,
    address _lzEndpoint,
    address _domain
  ) Authenticated(_authority) Omnichain(_lzEndpoint) {
    domain = Domain(_domain);
  }

  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  function findOrMintFor(address to) public returns (uint256) {
    uint256 id = idOf(to);

    if (ownerOf[id] != address(0)) return id;

    ownerOf[id] = to;
    emit Transfer(address(0), to, id);

    return id;
  }

  function balanceOf(address a) public view returns (uint256) {
    return ownerOf[idOf(a)] == address(0) ? 0 : 1;
  }

  function tokenURI(uint256 id) public view returns (string memory) {
    return string(dataOf[id][TOKEN_URI_DOMAIN]);
  }

  function setData(
    uint256 id,
    uint256 domainId,
    bytes memory data
  ) external {
    require(
      ownerOf[id] == msg.sender || domain.ownerOf(domainId) == msg.sender,
      "Passport: UNAUTHORIZED"
    );
    dataOf[id][domainId] = data;
  }

  /* ==============================
   * LayerZero
   * ============================== */
  function syncData(
    uint16 toChainId,
    address owner,
    uint256 domainId,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    require(
      owner == msg.sender || domain.ownerOf(domainId) == msg.sender,
      "Passport: UNAUTHORIZED"
    );
    uint256 passportId = findOrMintFor(owner);

    lzSend(
      toChainId,
      abi.encode(owner, domainId, dataOf[passportId][domainId]),
      zroPaymentAddress,
      adapterParams
    );

    emit Sync(currentChainId, toChainId, passportId, domainId);
  }

  function onReceive(
    uint16 fromChainId,
    bytes calldata, // _fromContractAddress,
    uint64, // _nonce
    bytes memory payload
  ) internal override {
    (address owner, uint256 domainId, bytes memory data) = abi.decode(
      payload,
      (address, uint256, bytes)
    );

    uint256 passportId = findOrMintFor(owner);

    dataOf[passportId][domainId] = data;
    emit Sync(fromChainId, currentChainId, passportId, domainId);
  }

  // ===================
  // ===== IERC721 =====
  // ===================
  function approve(address, uint256) external payable {
    revert Immovable();
  }

  function setApprovalForAll(address, bool) external pure {
    revert Immovable();
  }

  function getApproved(uint256) external pure returns (address) {
    return address(0);
  }

  function isApprovedForAll(address, address) external pure returns (bool) {
    return false;
  }
}
