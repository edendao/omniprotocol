// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";

import {Stewarded} from "./mixins/Stewarded.sol";
import {EdenDaoNS} from "./mixins/EdenDaoNS.sol";
import {Stewarded} from "./mixins/Stewarded.sol";
import {OmniTokenURI} from "./mixins/OmniTokenURI.sol";
import {PublicGood} from "./mixins/PublicGood.sol";

contract Space is ERC721, Stewarded, OmniTokenURI, EdenDaoNS {
    uint256 public circulatingSupply;
    bool public mintable;

    constructor(
        address _steward,
        address _omnicast,
        bool _mintable
    ) ERC721("Eden Dao Space", "DAO SPACE") {
        __initStewarded(_steward);
        __initOmniTokenURI(_omnicast);

        mintable = _mintable;
    }

    function tokenURI(uint256 id)
        public
        view
        override(ERC721, OmniTokenURI)
        returns (string memory)
    {
        return super.tokenURI(id);
    }

    function _mint(address to, string memory name)
        internal
        returns (uint256 id)
    {
        circulatingSupply++;
        id = idOf(name);
        _mint(to, id);
    }

    function mint(address to, string memory name)
        external
        requiresAuth
        returns (uint256)
    {
        return _mint(to, name);
    }

    mapping(address => uint256) public mintsBy;

    function mint(string memory name) public payable returns (uint256) {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "NO_SPOOFING");
        require(mintable, "NOT_MINTABLE");

        uint256 mints = mintsBy[msg.sender];
        require(mints < 10, "MINT_LIMIT");
        require(msg.value >= (mints + 1) * 0.05 ether, "INSUFFICIENT_VALUE");

        mintsBy[msg.sender] = mints + 1;
        return _mint(msg.sender, name);
    }

    // ======================
    // ====== EIP-2981 ======
    // ======================
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(authority), (salePrice * 10) / 100);
    }
}
