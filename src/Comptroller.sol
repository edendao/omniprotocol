// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";
import {Multicallable} from "@protocol/mixins/Multicallable.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";
import {MultiRolesAuthority} from "@protocol/auth/MultiRolesAuthority.sol";

contract Comptroller is PublicGood, Multicallable, MultiRolesAuthority {
  function initialize(address _beneficiary, bytes calldata _params)
    external
    override
    initializer
  {
    __initAuth(abi.decode(_params, (address)), this);

    __initPublicGood(_beneficiary);
  }

  function setCapabilitiesTo(
    address roleAddress,
    uint8 withRoleId,
    bytes4[] memory functionSignatures,
    bool enabled
  ) external requiresAuth {
    for (uint256 i = 0; i < functionSignatures.length; i += 1) {
      setRoleCapability(withRoleId, functionSignatures[i], enabled);
    }
    setUserRole(roleAddress, withRoleId, enabled);
  }

  function withdrawTo(address to, uint256 amount) external requiresAuth {
    payable(to).transfer(amount);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) external requiresAuth {
    TransferToken(token).transfer(to, amount);
  }

  receive() external payable {}
}
