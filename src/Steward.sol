// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferToken} from "@omniprotocol/interfaces/TransferrableToken.sol";
import {Cloneable} from "@omniprotocol/mixins/Cloneable.sol";
import {Multicallable} from "@omniprotocol/mixins/Multicallable.sol";
import {PublicGood} from "@omniprotocol/mixins/PublicGood.sol";
import {MultiRolesAuthority} from "@omniprotocol/auth/MultiRolesAuthority.sol";

contract Steward is MultiRolesAuthority, PublicGood, Cloneable, Multicallable {
  constructor(address _beneficiary, address _owner) {
    __initPublicGood(_beneficiary);
    __initAuth(_owner, this);

    isInitialized = true;
  }

  // ================================
  // ========== Cloneable ===========
  // ================================
  function initialize(address _beneficiary, bytes calldata _params)
    external
    override
    initializer
  {
    __initPublicGood(_beneficiary);
    __initAuth(abi.decode(_params, (address)), this);
  }

  function clone(address _owner)
    external
    payable
    returns (address cloneAddress)
  {
    bytes memory params = abi.encode(_owner);
    cloneAddress = clone(keccak256(params));
    Cloneable(cloneAddress).initialize(beneficiary, params);
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
