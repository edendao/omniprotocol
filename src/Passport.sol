// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { ERC721 } from "@rari-capital/solmate/tokens/ERC721.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Pausable } from "@protocol/mixins/Pausable.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

import { GCounter } from "@protocol/libraries/GCounter.sol";

contract Passport is ERC721, Authenticated, Omnichain, Pausable {
  uint256 public totalSupply;

  mapping(uint256 => uint256[]) internal chainReputationsOf;

  constructor(address _authority, address _lzEndpoint)
    ERC721("Eden Dao Passport", "PASSPORT")
    Omnichain(_lzEndpoint)
    Authenticated(_authority)
  {
    _mint(owner, totalSupply++);
  }

  function reputationOf(uint256 _tokenId) public view returns (uint256) {
    return GCounter.value(chainReputationsOf[_tokenId]);
  }

  function addReputation(uint256 _tokenId, uint256 _amount)
    external
    requiresAuth
  {
    GCounter.incrementBy(
      chainReputationsOf[_tokenId],
      chainIdIndex[uint16(block.chainid)],
      _amount
    );
  }

  function mintTo(address _to) external requiresAuth {
    _mint(_to, totalSupply++);
  }

  function tokenURI(uint256 _id) public pure override returns (string memory) {
    return string(abi.encodePacked(_id));
  }

  function lzSend(
    uint16 _toChainId,
    address _toAddress,
    uint256 _id,
    address _zroPaymentAddress, // ZRO payment address
    bytes calldata _adapterParams // txParameters
  ) external payable {
    require(
      ownerOf[_id] == msg.sender,
      "Passport: Only owner can sync their passport"
    );

    lzEndpoint.send{ value: msg.value }(
      _toChainId, // destination chainId
      chainContracts[_toChainId], // destination UA address
      abi.encode(_toAddress, _id, chainReputationsOf[_id]), // abi.encode()'ed bytes
      payable(msg.sender), // refund address (LayerZero will refund any extra gas back to caller of send()
      _zroPaymentAddress, // 'zroPaymentAddress' unused for this mock/example
      _adapterParams
    );
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _callerAddress,
    uint64, // _nonce
    bytes memory _payload
  ) external {
    require(
      msg.sender == address(lzEndpoint) &&
        _callerAddress.length == chainContracts[_srcChainId].length &&
        keccak256(_callerAddress) == keccak256(chainContracts[_srcChainId]),
      "Passport: Invalid caller for lzReceive"
    );

    (
      address _receiveAddress,
      uint256 _id,
      uint256[] memory _chainReputationsOfToken
    ) = abi.decode(_payload, (address, uint256, uint256[]));

    _mint(_receiveAddress, _id);
    GCounter.merge(chainReputationsOf[_id], _chainReputationsOfToken);
  }
}
