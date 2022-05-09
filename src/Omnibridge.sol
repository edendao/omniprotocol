// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "@protocol/libraries/SafeTransferLib.sol";

import {IOFT} from "@protocol/interfaces/IOFT.sol";

import {ERC20} from "@protocol/mixins/ERC20.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";
import {Cloneable} from "@protocol/mixins/Cloneable.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Omnitoken} from "@protocol/Omnitoken.sol";

contract Omnibridge is PublicGood {
  using SafeTransferLib for ERC20;

  address public immutable omnitoken;

  constructor(address _comptroller, address _omnitoken) {
    __initPublicGood(_comptroller);
    __initComptrolled(_comptroller);

    omnitoken = _omnitoken;
  }

  event CreateComptroller(address indexed owner, address comptroller);

  function createComptroller(address _owner) external returns (Comptroller c) {
    c = Comptroller(
      payable(createClone(comptrollerAddress(), abi.encode(_owner)))
    );
    emit CreateComptroller(_owner, address(c));
  }

  event CreateOmnitoken(
    address indexed comptroller,
    string name,
    string symbol,
    uint8 decimals
  );

  function createOmnitoken(
    address _comptroller,
    address _lzEndpoint,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) external returns (Omnitoken n) {
    n = Omnitoken(
      createClone(
        omnitoken,
        abi.encode(_comptroller, _lzEndpoint, _name, _symbol, _decimals)
      )
    );
    emit CreateOmnitoken(_comptroller, _name, _symbol, _decimals);
  }

  function createClone(address target, bytes memory params)
    internal
    returns (address deployedAddress)
  {
    bytes20 targetBytes = bytes20(target);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let clone := mload(0x40)
      mstore(
        clone,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(clone, 0x14), targetBytes)
      mstore(
        add(clone, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      deployedAddress := create(0, clone, 0x37)
    }
    Cloneable(deployedAddress).initialize(comptrollerAddress(), params);
  }

  // mapping(address => Omnitoken) public noteOf;

  // function redeemFor(address tokenAddress, uint256 amount) external {
  //   ERC20 note = ERC20(noteOf[tokenAddress]);

  //   note.safeTransferFrom(msg.sender, address(this), amount);

  //   ERC20(tokenAddress).
  // }

  // function sendFrom(
  //   address fromAddress,
  //   uint16 toChainId,
  //   bytes memory toAddress,
  //   uint256 amount,
  //   address payable,
  //   address lzPaymentAddress,
  //   bytes memory lzAdapterParams
  // ) external payable {
  //   address tokenAddress;
  //   (tokenAddress, lzAdapterParams) = abi.decode(
  //     lzAdapterParams,
  //     (address, bytes)
  //   );

  //   ERC20(tokenAddress).safeTransferFrom(fromAddress, address(this), amount);

  //   Omnitoken note = noteOf[tokenAddress];
  //   note.mint(address(this), amount);
  //   note.sendFrom{value: msg.value}(
  //     address(this),
  //     toChainId,
  //     toAddress,
  //     amount,
  //     payable(address(0)),
  //     lzPaymentAddress,
  //     lzAdapterParams
  //   );
  // }

  // function estimateSendFee(
  //   uint16 toChainId,
  //   bytes memory toAddress,
  //   uint256 amount,
  //   bool useZRO,
  //   bytes memory adapterParams
  // ) external view returns (uint256 nativeFee, uint256 zroFee) {
  //   address tokenAddress;
  //   (tokenAddress, adapterParams) = abi.decode(adapterParams, (address, bytes));

  //   (nativeFee, zroFee) = noteOf[tokenAddress].estimateSendFee(
  //     toChainId,
  //     toAddress,
  //     amount,
  //     useZRO,
  //     adapterParams
  //   );
  // }

  // function withdrawToken(address, uint256) external pure override {
  //   revert("Omnibridge: WITHDRAW_DISABLED");
  // }

  // function circulatingSupply() external pure returns (uint256) {
  //   return 0;
  // }
}
