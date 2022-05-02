// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {CREATE3} from "@solmate/utils/CREATE3.sol";

contract Factory {
  bytes internal creationCode;

  constructor(bytes memory _creationCode) {
    creationCode = _creationCode;
  }

  address[] public creations;

  function creationsCount() public view returns (uint256) {
    return creations.length;
  }

  function salt(bytes memory constructorCalldata)
    public
    view
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(msg.sender, constructorCalldata));
  }

  function lookupCreation(bytes memory constructorCalldata)
    public
    view
    returns (bool isDeployed, address creationAddress)
  {
    creationAddress = CREATE3.getDeployed(salt(constructorCalldata));
    isDeployed = creationAddress.code.length > 0;
  }

  event Created(uint256 indexed index, address indexed createdAddress);

  function _create(bytes memory constructorCalldata)
    internal
    returns (address createdAddress)
  {
    createdAddress = CREATE3.deploy(
      salt(constructorCalldata),
      abi.encodePacked(creationCode, constructorCalldata),
      0
    );

    emit Created(creations.length, createdAddress);
    creations.push(createdAddress);
  }
}
