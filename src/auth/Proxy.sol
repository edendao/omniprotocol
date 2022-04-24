// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {PRBProxy, PRBProxy__NotOwner} from "@proxy/PRBProxy.sol";

contract Proxy is PRBProxy {
  function withdrawTo(address to, uint256 amount) public {
    if (msg.sender != owner) {
      revert PRBProxy__NotOwner(owner, msg.sender);
    }
    payable(to).transfer(amount);
  }
}
