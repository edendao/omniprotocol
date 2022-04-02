// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { Omnichain } from "@protocol/mixins/Omnichain.sol";
import { Authenticated } from "@protocol/mixins/Authenticated.sol";

/*
 * The Eden Dao Passport is your cross-chain identity for the omnichain future.
 *
 * You can load it up with one of your NFTs and sync its properties across chains.
 */
contract Passport is Omnichain, Authenticated {
  string public constant name = "Eden Dao Passport";
  string public constant symbol = "PASSPORT";
  uint16 public immutable primaryChainId;

  event Transfer(address indexed from, address indexed to, uint256 indexed id);
  error Soulbound();

  uint256 public totalSupply;

  mapping(uint256 => bytes) internal cachedTokenURI;

  mapping(uint256 => bytes) public metadata;
  mapping(uint256 => address) public ownerOf;
  mapping(address => uint256) internal idOf;

  constructor(
    uint16 _primaryChainId,
    address _authority,
    address _lzEndpoint
  ) Authenticated(_authority) Omnichain(_lzEndpoint) {
    primaryChainId = _primaryChainId;
  }

  function mintTo(address to) public requiresAuth {
    require(
      primaryChainId == block.chainid,
      "Passport: Can only mint on primary chain"
    );
    require(balanceOf(to) == 0, "Passport: Can only have one");

    totalSupply += 1;
    ownerOf[totalSupply] = to;
    idOf[to] = totalSupply;

    emit Transfer(address(0), to, totalSupply);
  }

  function balanceOf(address a) public view returns (uint256) {
    return idOf[a] != 0 ? 1 : 0;
  }

  function tokenURI(uint256 id) public view returns (string memory) {
    return string(cachedTokenURI[id]);
  }

  function setTokenURI(uint256 id, bytes memory uri) public requiresAuth {
    cachedTokenURI[id] = uri;
  }

  function sync(
    uint16 toChainId,
    uint256 id,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    lzEndpoint.send{ value: msg.value }(
      toChainId,
      chainContracts[toChainId], // destination contract address
      abi.encode(ownerOf[id], id, tokenURI(id)), // abi.encode()'ed bytes,
      payable(msg.sender), // refund address (for extra gas)
      zroPaymentAddress,
      adapterParams
    );
  }

  function lzReceive(
    uint16 fromChainId,
    bytes calldata callerAddress,
    uint64, // _nonce
    bytes memory payload
  ) external {
    require(
      msg.sender == address(lzEndpoint) &&
        callerAddress.length == chainContracts[fromChainId].length &&
        keccak256(callerAddress) == keccak256(chainContracts[fromChainId]),
      "Passport: Invalid caller for lzReceive"
    );

    (address passportOwner, uint256 id, bytes memory uri) = abi.decode(
      payload,
      (address, uint256, bytes)
    );

    if (ownerOf[id] == address(0)) {
      ownerOf[id] = passportOwner;
      idOf[owner] = id;

      emit Transfer(address(0), passportOwner, id);
    }

    cachedTokenURI[id] = uri;
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
