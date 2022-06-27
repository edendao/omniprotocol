// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20, SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {MultiRolesAuthority} from "./mixins/auth/MultiRolesAuthority.sol";
import {Multicallable} from "./mixins/Multicallable.sol";
import {Stewarded} from "./mixins/Stewarded.sol";
import {PublicGood} from "./mixins/PublicGood.sol";

contract Steward is MultiRolesAuthority, PublicGood, Stewarded, Multicallable {
    // ================================
    // ======== Initializable =========
    // ================================
    constructor(address _beneficiary, address _owner) {
        initialize(_beneficiary, abi.encode(_owner));
    }

    function _initialize(bytes memory _params) internal override {
        __initAuth(abi.decode(_params, (address)), this);
    }

    // ================================
    // ========== Authority ===========
    // ================================
    function setCapabilitiesTo(
        address roleAddress,
        uint8 withRoleId,
        bytes4[] memory signatures,
        bool enabled
    ) external requiresAuth {
        for (uint256 i = 0; i < signatures.length; i += 1) {
            setRoleCapability(withRoleId, signatures[i], enabled);
        }
        setUserRole(roleAddress, withRoleId, enabled);
    }

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool ok) {
        ok =
            super.canCall(user, target, functionSig) &&
            !isAccountSanctioned[user];
    }

    mapping(address => bool) public isAccountSanctioned;

    event AccountSanctionUpdated(address indexed account, bool sanctioned);

    function sanction(address account, bool sanctioned)
        public
        virtual
        requiresAuth
    {
        isAccountSanctioned[account] = sanctioned;

        emit AccountSanctionUpdated(account, sanctioned);
    }

    receive() external payable {}
}
