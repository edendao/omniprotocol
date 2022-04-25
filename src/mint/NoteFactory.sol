// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Factory} from "@protocol/mixins/Factory.sol";

import {Note} from "./Note.sol";

contract NoteFactory is Factory, Comptrolled {
  constructor(address _comptroller)
    Comptrolled(_comptroller)
    Factory(type(Note).creationCode)
  {
    this;
  }

  event NoteDeployed(Note note, string name, string symbol, uint8 decimals);

  // bytes memory createParams = abi.encode(
  //   address underlying,
  //   address noteComptroller,
  //   string memory name,
  //   string memory symbol,
  //   uint8 decimals
  // )
  function deployNote(bytes memory createParams)
    public
    payable
    returns (Note note)
  {
    note = Note(payable(_create(createParams)));

    emit NoteDeployed(note, note.name(), note.symbol(), note.decimals());
  }
}
