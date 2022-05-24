// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmnicast} from "@omniprotocol/interfaces/IOmnicast.sol";

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
        0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f, // tokenuri.eden.dao
        id
      )
    );
  }
}
