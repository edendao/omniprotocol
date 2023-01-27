// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {Auth, Authority, Unauthorized} from "./auth/Auth.sol";

error InvalidToken();

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
        if (token.code.length == 0) {
            revert InvalidToken();
        }
        SafeTransferLib.safeTransfer(token, to, amount);
    }
}
