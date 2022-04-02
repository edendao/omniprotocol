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
  event Transfer(address indexed from, address indexed to, uint256 indexed id);
  error Soulbound();

  uint16 public immutable primaryChainId;
  uint256 public totalSupply;

  string public constant name = "Eden Dao Passport";
  string public constant symbol = "PASSPORT";

  mapping(address => uint256) public idOf;
  mapping(uint256 => address) public ownerOf;
  mapping(uint256 => bytes) internal cachedTokenURI;

  constructor(
    uint16 _primaryChainId,
    address _authority,
    address _lzEndpoint
  ) Authenticated(_authority) Omnichain(_lzEndpoint) {
    primaryChainId = _primaryChainId;
  }

  function mintTo(address to, bytes memory uri) public requiresAuth {
    require(
      primaryChainId == block.chainid,
      "Passport: Can only mint on primary chain"
    );
    require(balanceOf(to) == 0, "Passport: Can only have one");

    uint256 id = ++totalSupply;
    ownerOf[id] = to;
    idOf[to] = id;
    cachedTokenURI[id] = uri;

    emit Transfer(address(0), to, id);
  }

  function balanceOf(address a) public view returns (uint256) {
    return idOf[a] != 0 ? 1 : 0;
  }

  function tokenURI(uint256 id) public view returns (string memory) {
    return string(cachedTokenURI[id]);
  }

  function setTokenURI(uint256 id, bytes memory uri) public requiresAuth {
    require(ownerOf[id] != address(0), "Passport: Not found");
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
