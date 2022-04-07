// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { ERC721 } from "@rari-capital/solmate/tokens/ERC721.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

contract Domain is ERC721, Omnichain, Authenticated {
  uint16 public primaryChainId;

  constructor(
    address _authority,
    address _lzEndpoint,
    uint16 _primaryChainId
  )
    // Eden Dao Domain Service = Eden Dao DS = Eden Dao Deus = DAO DEUS
    ERC721("Eden Dao Domain", "DAO DEUS")
    Omnichain(_lzEndpoint)
    Authenticated(_authority)
  {
    primaryChainId = _primaryChainId;
    uint16[26] memory premint = [
      0,
      1,
      2,
      3,
      5,
      8,
      10,
      13,
      21,
      22,
      28,
      29,
      30,
      31,
      34,
      42,
      69,
      80,
      81,
      222,
      365,
      443,
      420,
      1998,
      2001,
      4242
    ];
    for (uint256 i = 0; i < premint.length; i++) {
      _mint(owner, premint[i]);
    }
  }

  // ===================================
  // == SETTING AND READING TOKEN URI ==
  // ===================================
  mapping(uint256 => string) internal _tokenURI;

  function tokenURI(uint256 domainId)
    public
    view
    override
    returns (string memory)
  {
    return _tokenURI[domainId];
  }

  function setTokenURI(uint256 domainId, string memory uri)
    external
    onlyOwnerOf(domainId)
  {
    _tokenURI[domainId] = uri;
  }

  // ===================================
  // ======== COMPTROLLER POWERS =======
  // ===================================
  function withdraw() public {
    payable(owner).transfer(address(this).balance);
  }

  // ===================================
  // ===== MINTS, BURNS, TRANSFERS =====
  // ===================================
  event Gift(address indexed giver, uint256 indexed amount);

  function mintTo(address to, uint256 domainId) external payable {
    require(currentChainId == primaryChainId, "Domains: Not on primary chain");
    require(msg.value >= 0.01 ether, "Domains: Mint price is >=0.01 ETH");
    _mint(to, domainId);
    emit Gift(msg.sender, msg.value);
  }

  modifier onlyOwnerOf(uint256 domainId) {
    require(msg.sender == ownerOf[domainId], "Domain: UNAUTHORIZED");
    _;
  }

  function burn(uint256 domainId) external onlyOwnerOf(domainId) {
    _burn(domainId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public override {
    require(
      msg.sender == from ||
        isApprovedForAll[from][msg.sender] ||
        msg.sender == getApproved[id] ||
        isAuthorized(msg.sender, msg.sig), // for DAO control, later
      "Domain: UNAUTHORIZED"
    );

    require(to != address(0), "Domain: Invalid Recipient");

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      balanceOf[from]--;
      balanceOf[to]++;
    }

    ownerOf[id] = to;

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function send(
    uint16 toChainId,
    address toAddress,
    uint256 domainId,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    require(msg.sender == ownerOf[domainId], "Domain: UNAUTHORIZED");

    _burn(domainId);

    lzSend(
      toChainId,
      abi.encode(toAddress, domainId),
      zroPaymentAddress,
      adapterParams
    );
  }

  function onReceive(
    uint16, // _fromChainId
    bytes calldata, // _fromContractAddress
    uint64, // _nonce
    bytes memory payload
  ) internal override {
    (address toAddress, uint256 domainId) = abi.decode(
      payload,
      (address, uint256)
    );
    _mint(toAddress, domainId);
  }
}
