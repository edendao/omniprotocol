// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { Omnichain } from "@protocol/mixins/Omnichain.sol";
import { Authenticated } from "@protocol/mixins/Authenticated.sol";

import { GCounter } from "@protocol/libraries/GCounter.sol";

/*
 * The Eden Dao Passport is your cross-chain identity for the omnichain future.
 *
 * You can load it up with one of your NFTs and sync its properties across chains.
 */
contract Passport is Omnichain, Authenticated {
  event Transfer(address indexed from, address indexed to, uint256 indexed id);
  error Soulbound();

  string public constant name = "Eden Dao Passport";
  string public constant symbol = "PASSPORT";

  mapping(uint256 => address) public ownerOf;

  mapping(uint256 => bytes) internal cachedTokenURI;

  constructor(address _authority, address _lzEndpoint)
    Authenticated(_authority)
    Omnichain(_lzEndpoint)
  {
    this;
  }

  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  function balanceOf(address a) public view returns (uint256) {
    return ownerOf[idOf(a)] == address(0) ? 0 : 1;
  }

  function tokenURI(uint256 id) public view returns (string memory) {
    return string(cachedTokenURI[id]);
  }

  function setTokenURI(uint256 id, bytes memory uri) public requiresAuth {
    require(ownerOf[id] != address(0), "Passport: Not found");
    cachedTokenURI[id] = uri;
  }

  function ensureMintedTo(address to) public requiresAuth returns (uint256) {
    return balanceOf(to) == 0 ? mintTo(to) : idOf(to);
  }

  function mintTo(address to) public requiresAuth returns (uint256) {
    uint256 id = idOf(to);
    require(ownerOf[id] == address(0), "Passport: Already exists");

    ownerOf[id] = to;
    emit Transfer(address(0), to, id);

    return id;
  }

  function sync(
    uint16 toChainId,
    address owner,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    lzEndpoint.send{ value: msg.value }(
      toChainId,
      chainContracts[toChainId], // destination contract address
      abi.encode(owner, tokenURI(idOf(owner))),
      payable(msg.sender), // refund address (for extra gas)
      zroPaymentAddress,
      adapterParams
    );
  }

  function lzReceive(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64, // _nonce
    bytes memory payload
  ) external onlyRelayer(fromChainId, fromContractAddress) {
    (address owner, bytes memory uri) = abi.decode(payload, (address, bytes));

    uint256 id = idOf(owner);
    cachedTokenURI[id] = uri;

    if (ownerOf[id] != owner) {
      ownerOf[id] = owner;
      emit Transfer(address(0), owner, id);
    }
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
