// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

error Unauthorized();

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified by DaoDeCyrus with custom errors and initialization
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(
        address indexed user,
        Authority indexed newAuthority
    );

    address public owner;

    Authority public authority;

    function __initAuth(address _owner, Authority _authority) internal {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        if (!isAuthorized(msg.sender, msg.sig)) {
            revert Unauthorized();
        }

        _;
    }

    function isAuthorized(address user, bytes4 functionSig)
        public
        view
        virtual
        returns (bool authorized)
    {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        authorized =
            (address(auth) != address(0) &&
                auth.canCall(user, address(this), functionSig)) ||
            user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        if (
            msg.sender != owner ||
            !authority.canCall(msg.sender, address(this), msg.sig)
        ) {
            revert Unauthorized();
        }

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}
