// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { ERC721 } from "@rari-capital/solmate/tokens/ERC721.sol";

import { Passport } from "@protocol/Passport.sol";
import { Authenticated, PayableMinter } from "./PayableMinter.sol";

contract NiftyPassport is Authenticated, PayableMinter {
  Passport public immutable passport;

  mapping(uint256 => address) public passportCollection;
  mapping(uint256 => uint256) public passportToken;

  constructor(
    address _authority,
    address _edn,
    address _passport
  ) Authenticated(_authority) PayableMinter(_edn) {
    passport = Passport(_passport);
  }

  function replicate(address collection, uint256 id) external payable {
    uint256 passportId = passport.idOf(msg.sender);

    ERC721 nifty = ERC721(collection);
    bytes memory uri = bytes(nifty.tokenURI(id));

    nifty.transferFrom(msg.sender, address(this), id);

    if (passportId == 0) {
      passport.mintTo(msg.sender, uri);
      passportId = passport.idOf(msg.sender);
    } else {
      _release(passportId);
      passport.setTokenURI(passportId, uri);
    }

    _mint(msg.value);
  }

  function release() external {
    uint256 id = passport.idOf(msg.sender);
    _release(id);
    passport.setTokenURI(id, "");
  }

  function _release(uint256 passportId) internal {
    if (passportCollection[passportId] != address(0)) {
      require(
        passport.idOf(msg.sender) == passportId,
        "NiftyPassport: Not your nifty"
      );

      ERC721(passportCollection[passportId]).safeTransferFrom(
        address(this),
        msg.sender,
        passportToken[passportId]
      );
    }
  }
}
