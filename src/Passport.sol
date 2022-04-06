// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { IERC721, IERC721Metadata } from "@boring/interfaces/IERC721.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

struct PassportToken {
  string uri;
  bytes metadata;
}

/*
 * The Passport is your cross-chain identity for the omnichain future.
 */
contract Passport is Authenticated, Omnichain, IERC721, IERC721Metadata {
  event Sync(
    uint16 indexed fromChainId,
    uint16 indexed toChainId,
    uint256 indexed id
  );
  error Soulbound();

  string public name;
  string public symbol;

  mapping(uint256 => address) public ownerOf;
  mapping(uint256 => PassportToken) public token;

  uint16 public immutable currentChainId;

  constructor(
    address _authority,
    address _lzEndpoint,
    string memory _name,
    string memory _symbol
  ) Authenticated(_authority) Omnichain(_lzEndpoint) {
    currentChainId = uint16(block.chainid);
    name = _name;
    symbol = _symbol;
  }

  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  function balanceOf(address a) public view returns (uint256) {
    return ownerOf[idOf(a)] == address(0) ? 0 : 1;
  }

  function tokenURI(uint256 id) public view returns (string memory) {
    return token[id].uri;
  }

  function tokenMetadata(uint256 id) public view returns (bytes memory) {
    return token[id].metadata;
  }

  function setToken(
    uint256 id,
    string memory uri,
    bytes memory metadata
  ) external {
    require(
      idOf(msg.sender) == id || isAuthorized(msg.sender, msg.sig),
      "UNAUTHORIZED"
    );
    require(ownerOf[id] != address(0), "Passport: Not found");
    token[id].uri = uri;
    token[id].metadata = metadata;
  }

  function findOrMintFor(address to) public returns (uint256) {
    uint256 id = idOf(to);

    if (ownerOf[id] != address(0)) return id;

    ownerOf[id] = to;
    emit Transfer(address(0), to, id);

    return id;
  }

  /* ==============================
   * LayerZero
   * ============================== */
  function lzSync(
    uint16 toChainId,
    address owner,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    uint256 id = idOf(owner);

    lzEndpoint.send{ value: msg.value }(
      toChainId,
      chainContracts[toChainId], // destination contract address
      abi.encode(owner, token[id]),
      payable(msg.sender), // refund address (for extra gas)
      zroPaymentAddress,
      adapterParams
    );

    emit Sync(currentChainId, toChainId, id);
  }

  function lzReceive(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64, // _nonce
    bytes memory payload
  ) external onlyRelayer(fromChainId, fromContractAddress) {
    (address owner, PassportToken memory data) = abi.decode(
      payload,
      (address, PassportToken)
    );

    uint256 id = findOrMintFor(owner);
    token[id] = data;

    emit Sync(fromChainId, currentChainId, id);
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
