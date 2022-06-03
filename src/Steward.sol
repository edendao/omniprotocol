// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferToken} from "./interfaces/TransferrableToken.sol";
import {MultiRolesAuthority} from "./mixins/auth/MultiRolesAuthority.sol";
import {Multicallable} from "./mixins/Multicallable.sol";
import {PublicGood} from "./mixins/PublicGood.sol";

contract Steward is MultiRolesAuthority, PublicGood, Multicallable {
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
  ) public view virtual override returns (bool) {
    return super.canCall(user, target, functionSig) && !isUserSanctioned[user];
  }

  mapping(address => bool) public isUserSanctioned;

  event UserSanctionUpdated(address indexed user, bool sanctioned);

  function setUserSanction(address user, bool sanctioned)
    public
    virtual
    requiresAuth
  {
    isUserSanctioned[user] = sanctioned;

    emit UserSanctionUpdated(user, sanctioned);
  }

  // ===============================
  // ====== Token Management =======
  // ===============================
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
