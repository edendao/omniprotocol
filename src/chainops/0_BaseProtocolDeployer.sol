// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptroller} from "@protocol/Comptroller.sol";
import {Note} from "@protocol/Note.sol";
import {Omnicast} from "@protocol/Omnicast.sol";
import {Omnichannel} from "@protocol/Omnichannel.sol";

contract BaseProtocolDeployer {
  Comptroller public comptroller;
  Note public note;
  Omnicast public omnicast;
  Omnichannel public omnichannel;

  constructor(
    address owner,
    address layerZeroEndpoint,
    uint16 primaryChainId
  ) {
    comptroller = new Comptroller(owner);

    note = new Note(address(comptroller), layerZeroEndpoint);
    omnichannel = new Omnichannel(
      address(comptroller),
      layerZeroEndpoint,
      address(note),
      primaryChainId
    );
    omnicast = new Omnicast(
      address(comptroller),
      layerZeroEndpoint,
      address(note),
      address(omnichannel)
    );
  }
}
