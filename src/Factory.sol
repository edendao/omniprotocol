// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {PublicGood} from "./mixins/PublicGood.sol";
import {Stewarded} from "./mixins/Stewarded.sol";

contract Factory is Stewarded {
    address public steward;
    address public erc20note;
    address public erc20vault;
    address public lzEndpoint;

    constructor(
        address _steward,
        address _erc20note,
        address _erc20vault,
        address _lzEndpoint
    ) {
        __initStewarded(_steward);

        steward = _steward;
        erc20note = _erc20note;
        erc20vault = _erc20vault;
        lzEndpoint = _lzEndpoint;
    }

    function setImplementations(
        address _steward,
        address _erc20note,
        address _erc20vault,
        address _lzEndpoint
    ) external requiresAuth {
        steward = _steward;
        erc20note = _erc20note;
        erc20vault = _erc20vault;
        lzEndpoint = _lzEndpoint;
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

        PublicGood(s).initialize(address(authority), params);
        emit StewardCreated(s, _owner);
    }

    event ERC20NoteCreated(
        address indexed steward,
        address indexed note,
        string indexed name,
        string symbol,
        uint8 decimals
    );

    function createERC20Note(
        address _steward,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public payable returns (address note) {
        bytes memory params = abi.encode(
            address(lzEndpoint),
            _steward,
            _name,
            _symbol,
            _decimals
        );
        note = _create2ProxyFor(erc20note, keccak256(params));

        PublicGood(note).initialize(address(authority), params);
        emit ERC20NoteCreated(_steward, note, _name, _symbol, _decimals);
    }

    event ERC20VaultCreated(
        address indexed steward,
        address indexed vault,
        address indexed asset
    );

    function createERC20Vault(address _steward, address _asset)
        public
        payable
        returns (address vault)
    {
        bytes memory params = abi.encode(address(lzEndpoint), _steward, _asset);
        vault = _create2ProxyFor(erc20vault, keccak256(params));

        PublicGood(vault).initialize(address(authority), params);
        emit ERC20VaultCreated(_steward, vault, _asset);
    }
}
