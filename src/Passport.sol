// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { Auth, Authority } from "@rari-capital/solmate/auth/Auth.sol";
import { ERC721 } from "@rari-capital/solmate/tokens/ERC721.sol";

import { Pausable } from "@protocol/mixins/Pausable.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

contract Passport is ERC721, Auth, Omnichain, Pausable {
  uint256 public totalSupply;

  constructor(address _authority, address _lzEndpoint)
    ERC721("Eden Dao Passport", "PASSPORT")
    Omnichain(_lzEndpoint)
    Auth(Auth(_authority).owner(), Authority(_authority))
  {
    _mint(owner, totalSupply++);
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
      "Passport: Can only transfer owned pass"
    );
    _burn(_id);

    lzEndpoint.send{ value: msg.value }(
      _toChainId, // destination chainId
      chainContracts[_toChainId], // destination UA address
      abi.encode(_toAddress, _id), // abi.encode()'ed bytes
      payable(msg.sender), // refund address (LayerZero will refund any extra gas back to caller of send()
      _zroPaymentAddress, // 'zroPaymentAddress' unused for this mock/example
      _adapterParams
    );
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _fromAddress,
    uint64, // _nonce
    bytes memory _payload
  ) external {
    require(
      msg.sender == address(lzEndpoint) &&
        _fromAddress.length == chainContracts[_srcChainId].length &&
        keccak256(_fromAddress) == keccak256(chainContracts[_srcChainId]),
      "Passport: Invalid caller for lzReceive"
    );

    (address _toAddress, uint256 _id) = abi.decode(
      _payload,
      (address, uint256)
    );

    _mint(_toAddress, _id);
  }
}
