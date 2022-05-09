_eden dao protocol is in code review._ This is an opportunity for the community to get involved prior to testnet launch. PRs would be greatly appreciated!

Interested in building with eden dao protocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**

# Eden Dao Protocol is Regenerative Omnichain Infrastructure

**Regenerative** in that protocol fees are directed for the public good towards carbon dioxide removal and renewable energy.

**Omnichain infrastructure** in that it liberates DAOs from a single chain with new primitives. Eden Dao Protocol is a collection of immutable contracts for omnispace travel.

## Eden Dao Passport is an omnichain user store

[Passport](./src/passport/Passport.sol) is a simple protocol to read and write arbitrary bytes messages across any LayerZero chain on a specific "cast" scoped to a wallet address.

As an arbitrary bytes store, what you use this for is up to you. You could:

1. Sign people's ledgers across chains
2. Certify a credential across chains
3. Leave art on people's Passports
4. Write user data to another chain

```solidity
  // (receiverId => senderId => data[])
  mapping(uint256 => mapping(uint256 => bytes[])) public receivedMessages;

  function readMessage(uint256 receiverId, uint256 senderId)
    public
    view
    returns (bytes memory)
  {
    bytes[] memory messages = receivedMessages[receiverId][senderId];
    return messages[messages.length - 1];
  }

  function writeMessage(
    uint256 toReceiverId,
    uint256 withSenderId,
    bytes memory payload,
    uint16 onChainId,
    address lzPaymentAddress,
    bytes memory lzAdapterParams
  ) public payable {
    require(
      (msg.sender == ownerOf[toReceiverId] || // write on your own passport
        withSenderId == idOf(msg.sender) || // write on your own cast
        msg.sender == omnicast.ownerOf(toReceiverId)), // write on a branded cast name
      "Passport: UNAUTHORIZED_CAST"
    );
    // implementation
  }
```

Interested in building with eden dao protocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**

## Eden Dao Omnitoken is an Omnichain ERC20

New DAOs spend too much wasted time agonizing on which chain to launch on. Eden Dao illuminates the omnichain path with Omnitoken: A gas-optimized, secure ERC20 with simple cross-chain bridging built in.

At a high level, to create your own Omnitoken, register a [Comptroller](./src/auth/ComptrollerFactory.sol), use that to create a [Omnitoken](./src/mint/OmnitokenFactory.sol), and enable the [Omniportal](./src/mint/Omniportal.sol) to mint and burn your omnitoken. You can also specify an `address underlying` to create a Omnitoken "wrapper" token around your existing ERC20.
As an ERC20 Omnitoken, what you use this for is up to you:

0. Wrap your existing tokens to send them across chains
1. Multi-chain liquidity
2. Omnichain DAO Partnerships
3. Multi-chain DAO Ops for governance, payouts, etc.

```solidity
Comptroller comptroller = ComptrollerFactory(comptrollerFactoryAddress).create(); // msg.sender is now the owner

Omnitoken omnitoken = OmnitokenFactory(omnitokenFactoryAddress).deployOmnitoken(abi.encode(
  address(comptroller),
  "My Token Name",
  "SYM",
  uint8(18)
))

uint8 minterRole = 0;
bytes4[] memory selectors = new bytes4[](2);
selectors[0] = Omnitoken.mint.selector;
selectors[1] = Omnitoken.burn.selector;
comptroller.setCapabilitiesTo(address(omnibridge), minterRole, [], true);
```

For the next chain, repeat the same steps. Then, hook both Omnitokens up to each other:

```solidity
// on chain A
Omnitoken(omnitokenAddressOnChainA).setRemoteContract(chainBId, abi.encodePacked(omnitokenAddressOnChainB));
// on chain B
Omnitoken(omnitokenAddressOnChainB).setRemoteContract(chainAId, abi.encodePacked(omnitokenAddressOnChainA));
```

In addition to being a flexible, mintable/burnable ERC20, token holders can also send their tokens across chains with a simple call to:

```solidity
  Omnibridge(address(omnibridge)).sendOmnitoken( // from msg.sender
    address omnitokenAddress, // on this chain
    uint256 amount, // amount
    uint16 toChainId, // LayerZero chain id
    bytes calldata toAddress, // receiver address
    address lzPaymentAddress,
    bytes calldata lzAdapterParams
  ) external payable { // use estimateLayerZeroFee(uint8(toChainId), bool(useZRO), bytes(lzAdapterParams))
    // implementation
  }
```

Interested in building with eden dao protocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**

## Coming Soon: Eden Dao Vaults are Yearn Vaults that mint Omnitokens

Yearn Vaults are the gold standard for yield aggregators that earn interest on any ERC20 token.
Eden Dao Vaults mint Omnitokens, which can be connected to other Omnitokens (or other Vaults) for DAOs to create their own decentralized reserves.

These enable DAOs to mint yield aggregator omnitokens that can be simply bridged _to any other chain_.

Interested in building with eden dao protocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**
