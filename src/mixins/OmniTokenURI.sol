// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IOmnicast {
  // Read the latest message
  function readMessage(uint256 senderId, uint256 receiverId)
    external
    view
    returns (bytes memory data);
}

abstract contract OmniTokenURI {
  IOmnicast public omnicast;

  function __initOmniTokenURI(address _omnicast) internal {
    omnicast = IOmnicast(_omnicast);
  }

  function tokenURI(uint256 id)
    public
    view
    virtual
    returns (string memory uri)
  {
    uri = string(
      omnicast.readMessage(
        // passport.tokenuri.eden.dao
        0xac56186bb23931a016888c3c51709e488987cc4249d0d75aa789c7bbac71cb04,
        id
      )
    );
  }
}
