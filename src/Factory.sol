// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {PublicGood} from "./mixins/PublicGood.sol";
import {Stewarded} from "./mixins/Stewarded.sol";

contract Factory is Stewarded, PublicGood {
  address public lzEndpoint;
  address public steward;
  address public token;
  address public bridge;

  constructor(
    address _beneficiary,
    address _lzEndpoint,
    address _steward,
    address _token,
    address _bridge
  ) {
    initialize(
      _beneficiary,
      abi.encode(_lzEndpoint, _steward, _token, _bridge)
    );
  }

  function _initialize(bytes memory _params) internal override {
    (
      address _lzEndpoint,
      address _steward,
      address _token,
      address _bridge
    ) = abi.decode(_params, (address, address, address, address));

    __initStewarded(_steward);

    lzEndpoint = _lzEndpoint;
    steward = _steward;
    token = _token;
    bridge = _bridge;
  }

  function setImplementations(
    address _lzEndpoint,
    address _steward,
    address _token,
    address _bridge
  ) external requiresAuth {
    lzEndpoint = _lzEndpoint;
    steward = _steward;
    token = _token;
    bridge = _bridge;
  }

  function _create2ProxyFor(address implementation, bytes32 salt)
    internal
    returns (address cloneAddress)
  {
    bytes20 targetBytes = bytes20(implementation);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let code := mload(0x40)
      mstore(
        code,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(code, 0x14), targetBytes)
      mstore(
        add(code, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      cloneAddress := create2(0, code, 0x37, salt)
    }
  }

  event StewardCreated(address indexed steward, address indexed owner);

  function createSteward(address _owner) public payable returns (address s) {
    bytes memory params = abi.encode(_owner);
    s = _create2ProxyFor(steward, keccak256(params));
    PublicGood(s).initialize(beneficiary, params);
    emit StewardCreated(s, _owner);
  }

  event TokenCreated(
    address indexed steward,
    address indexed token,
    string indexed name,
    string symbol,
    uint8 decimals
  );

  function createToken(
    address _steward,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public payable returns (address t) {
    bytes memory params = abi.encode(
      address(lzEndpoint),
      _steward,
      _name,
      _symbol,
      _decimals
    );
    t = _create2ProxyFor(token, keccak256(params));
    PublicGood(t).initialize(beneficiary, params);
    emit TokenCreated(_steward, t, _name, _symbol, _decimals);
  }

  event BridgeCreated(
    address indexed steward,
    address indexed bridge,
    address indexed asset
  );

  function createBridge(address _steward, address _asset)
    public
    payable
    returns (address b)
  {
    bytes memory params = abi.encode(address(lzEndpoint), _steward, _asset);
    b = _create2ProxyFor(bridge, keccak256(params));
    PublicGood(b).initialize(beneficiary, params);
    emit BridgeCreated(_steward, b, _asset);
  }
}
