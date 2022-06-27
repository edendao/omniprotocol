// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

import {ERC20, SafeTransferLib} from "@omniprotocol/libraries/SafeTransferLib.sol";
import {Auth, Authority} from "./auth/Auth.sol";

abstract contract Stewarded is Auth {
    function __initStewarded(address _steward) internal {
        __initAuth(Auth(_steward).owner(), Authority(_steward));
    }

    function withdrawTo(address to, uint256 amount) public requiresAuth {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) public virtual requiresAuth {
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }
}
