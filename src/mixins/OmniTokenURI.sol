// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface Omnicast {
  function readMessage(uint256 senderId, uint256 receiverId)
    external
    view
    returns (bytes memory);
}

abstract contract OmniTokenURI {
  address public omnicast;

  function __initOmniTokenURI(address _omnicast) internal {
    omnicast = _omnicast;
  }

  function tokenURI(uint256 id)
    public
    view
    virtual
    returns (string memory uri)
  {
    uri = string(
      Omnicast(omnicast).readMessage(
        0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f, // tokenuri.eden.dao
        id
      )
    );
  }
}
