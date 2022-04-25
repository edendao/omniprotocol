// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

import {Omnicast} from "@protocol/omnicast/Omnicast.sol";
import {Omnichannel} from "@protocol/omnicast/Omnichannel.sol";

contract Omnispace is Comptrolled {
  Omnichannel public immutable omnichannel;
  Omnicast public immutable omnicast;

  mapping(address => uint256) public channelsRegisteredBy;

  constructor(
    address _comptroller,
    address _omnichannel,
    address _omnicast
  ) Comptrolled(_comptroller) {
    omnichannel = Omnichannel(payable(_omnichannel));
    omnicast = Omnicast(payable(_omnicast));
  }

  function capabilities(uint8 role) public view returns (bytes memory) {
    bytes4[] memory selectors = new bytes4[](2);
    selectors[0] = omnichannel.mint.selector;
    selectors[1] = omnicast.mint.selector;

    return
      abi.encodeWithSelector(
        comptroller.setCapabilitiesTo.selector,
        address(this),
        role,
        selectors,
        true
      );
  }

  function register(string memory label) public payable returns (uint256) {
    require(channelsRegisteredBy[msg.sender] < 10, "Omnichannel: MINT_LIMIT");
    require(
      msg.value >= (channelsRegisteredBy[msg.sender] + 1) * 0.05 ether,
      "Omnichannel: INSUFFICIENT_VALUE"
    );
    channelsRegisteredBy[msg.sender] += 1;

    return omnichannel.mint(msg.sender, label);
  }

  function claim() public payable returns (uint256) {
    require(msg.value >= 0.01 ether, "Omnicast: INSUFFICIENT_VALUE");
    return omnicast.mint(msg.sender);
  }

  receive() external payable override {
    claim();
  }
}
