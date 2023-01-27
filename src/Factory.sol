// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {LibClone} from "solady/utils/LibClone.sol";
import {PublicGood} from "./mixins/PublicGood.sol";
import {Stewarded} from "./mixins/Stewarded.sol";

contract Factory is Stewarded {
    using LibClone for address;

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

    event StewardCreated(address indexed steward, address indexed owner);

    function createSteward(address _owner) public payable returns (address s) {
        bytes memory params = abi.encode(_owner);
        s = steward.cloneDeterministic(keccak256(params));

        PublicGood(s).initialize(address(authority), params);
        emit StewardCreated(s, _owner);
    }

    function getSteward(address _owner) public view returns (address s) {
        s = steward.predictDeterministicAddress(
            keccak256(abi.encode(_owner)),
            address(this)
        );
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
        note = erc20note.cloneDeterministic(keccak256(params));

        PublicGood(note).initialize(address(authority), params);
        emit ERC20NoteCreated(_steward, note, _name, _symbol, _decimals);
    }

    function getERC20Note(
        address _steward,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public view returns (address note) {
        note = erc20note.predictDeterministicAddress(
            keccak256(
                abi.encode(
                    address(lzEndpoint),
                    _steward,
                    _name,
                    _symbol,
                    _decimals
                )
            ),
            address(this)
        );
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
        vault = erc20vault.cloneDeterministic(keccak256(params));

        PublicGood(vault).initialize(address(authority), params);
        emit ERC20VaultCreated(_steward, vault, _asset);
    }

    function getERC20Vault(address _steward, address _asset)
        public
        view
        returns (address vault)
    {
        vault = erc20vault.predictDeterministicAddress(
            keccak256(abi.encode(address(lzEndpoint), _steward, _asset)),
            address(this)
        );
    }
}
