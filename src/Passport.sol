// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { IERC721, IERC721Metadata } from "@boring/interfaces/IERC721.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

/*
 * A Passport is your cross-chain identity for the future.
 */
contract Passport is Authenticated, Omnichain, IERC721, IERC721Metadata {
  event Sync(
    uint16 indexed fromChainId,
    uint16 indexed toChainId,
    uint256 indexed id,
    uint256 domainId
  );
  error Soulbound();

  string public constant name = "Eden Dao Passport";
  string public constant symbol = "DAO PASS";

  mapping(uint256 => address) public ownerOf;
  // tokenId => domainId => data
  mapping(uint256 => mapping(uint256 => bytes)) public dataOf;
  uint256 public constant TOKEN_URI_DOMAIN = 0;

  constructor(address _authority, address _lzEndpoint)
    Authenticated(_authority)
    Omnichain(_lzEndpoint)
  {
    this;
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
      ownerOf[id] == msg.sender || isAuthorized(msg.sender, msg.sig),
      "UNAUTHORIZED"
    );
    dataOf[id][domainId] = data;
  }

  /* ==============================
   * LayerZero
   * ============================== */
  function lzSend(
    address owner,
    uint256 domainId,
    uint16 toChainId,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    uint256 passportId = findOrMintFor(owner);

    // solhint-disable-next-line check-send-result
    lzEndpoint.send{ value: msg.value }(
      toChainId,
      chainContracts[toChainId], // destination contract address
      abi.encode(owner, domainId, dataOf[passportId][domainId]),
      payable(msg.sender), // refund address (for extra gas)
      zroPaymentAddress,
      adapterParams
    );

    emit Sync(currentChainId, toChainId, passportId, domainId);
  }

  function lzReceive(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64, // _nonce
    bytes memory payload
  ) external onlyRelayer(fromChainId, fromContractAddress) {
    (address owner, uint256 domainId, bytes memory data) = abi.decode(
      payload,
      (address, uint256, bytes)
    );

    uint256 passportId = findOrMintFor(owner);

    dataOf[passportId][domainId] = data;
    emit Sync(fromChainId, currentChainId, passportId, domainId);
  }

  /* ===================
   * IERC721 Boilerplate
   * =================== */
  function approve(address, uint256) external payable {
    revert Soulbound();
  }

  function setApprovalForAll(address, bool) external pure {
    revert Soulbound();
  }

  function getApproved(uint256) external pure returns (address) {
    return address(0);
  }

  function isApprovedForAll(address, address) external pure returns (bool) {
    return false;
  }

  function transferFrom(
    address, // from
    address, // to
    uint256 // id
  ) external payable {
    revert Soulbound();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256 // id
  ) external payable {
    revert Soulbound();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256, // id,
    bytes calldata // payload
  ) external payable {
    revert Soulbound();
  }
}
