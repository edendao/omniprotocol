// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { ERC721 } from "@rari-capital/solmate/tokens/ERC721.sol";

import { Passport } from "@protocol/Passport.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";
import { Authenticated } from "@protocol/mixins/Authenticated.sol";

abstract contract NiftyReplicator is Omnichain, Authenticated {
  Passport public immutable passport;

  mapping(uint256 => uint16) public tokenChain;
  mapping(uint256 => address) public tokenAddress;
  mapping(uint256 => uint256) public tokenId;

  constructor(address _authority, address _passport) Authenticated(_authority) {
    passport = Passport(_passport);
  }

  function lock(address collection, uint256 id) external {
    uint256 passportId = passport.idOf(msg.sender);

    ERC721 nifty = ERC721(collection);
    nifty.transferFrom(msg.sender, address(this), id);

    bytes memory uri = bytes(nifty.tokenURI(id));

    if (passport.balanceOf(msg.sender) == 0) {
      passport.mintTo(msg.sender);
    } else if (tokenAddress[passportId] != address(0)) {
      ERC721(tokenAddress[passportId]).safeTransferFrom(
        address(this),
        msg.sender,
        tokenId[passportId]
      );
    }

    passport.setTokenURI(passportId, uri);

    tokenChain[passportId] = uint16(block.chainid);
    tokenAddress[passportId] = collection;
    tokenId[passportId] = id;
  }

  function release() external {
    uint256 passportId = passport.idOf(msg.sender);
    ERC721(tokenAddress[passportId]).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId[passportId]
    );
    passport.setTokenURI(passportId, "");
  }

  function sync(
    uint16 toChainId,
    address owner,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    uint256 id = passport.idOf(owner);

    lzEndpoint.send{ value: msg.value }(
      toChainId,
      chainContracts[toChainId], // destination contract address
      abi.encode(owner, tokenChain[id], tokenAddress[id], tokenId[id]),
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
    (address owner, uint16 chainid, address token, uint256 id) = abi.decode(
      payload,
      (address, uint16, address, uint256)
    );

    uint256 passportId = passport.idOf(owner);
    tokenChain[passportId] = chainid;
    tokenAddress[passportId] = token;
    tokenId[passportId] = id;
  }
}
