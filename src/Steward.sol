// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferToken} from "./interfaces/TransferrableToken.sol";
import {MultiRolesAuthority} from "./mixins/auth/MultiRolesAuthority.sol";
import {Multicallable} from "./mixins/Multicallable.sol";
import {PublicGood} from "./mixins/PublicGood.sol";

contract Steward is MultiRolesAuthority, PublicGood, Multicallable {
  constructor(address _beneficiary, address _owner) {
    initialize(_beneficiary, abi.encode(_owner));
  }

  // ================================
  // ========== Initializable ===========
  // ================================
  function _initialize(bytes memory _params) internal override {
    __initAuth(abi.decode(_params, (address)), this);
  }

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
