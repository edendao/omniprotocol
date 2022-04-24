_eden dao protocol is in code review._ This is an opportunity for the community to get involved prior to testnet launch. PRs would be greatly appreciated!

Interested in building with eden dao protocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**

# Eden Dao Protocol is Regenerative Omnichain Infrastructure

**Regenerative** in that protocol fees are directed for the public good towards carbon dioxide removal and renewable energy.

**Omnichain infrastructure** in that it liberates DAOs from a single chain with new primitives. Eden Dao Protocol is a collection of immutable contracts for omnispace travel.

## Eden Dao Omnicast is an omnichain datastore

[Omnicast](./src/omnicast/Omnicast.sol) is a simple protocol to read and write arbitrary bytes messages across any LayerZero chain on a specific "channel" scoped to a wallet address.

As an arbitrary bytes store, what you use this for is up to you. You could:

1. Sign people's ledgers across chains
2. Certify a credential across chains
3. Leave art on people's Omnicasts
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
    bytes memory lzTransactionParams
  ) public payable {
    require(
      (msg.sender == address(uint160(toReceiverId)) || // write on your own omnicast
        withSenderId == idOf(msg.sender) || // write on your own channel
        msg.sender == omnichannel.ownerOf(toReceiverId)), // write on a branded channel name
      "Omnicast: UNAUTHORIZED_CHANNEL"
    );
    // implementation
  }
```

## Eden Dao Note is an Omnichain ERC20

New DAOs spend too much wasted time agonizing on which chain to launch on. Eden Dao illuminates the omnichain path with Note: A gas-optimized, secure ERC20 with simple cross-chain bridging built in.

To create your own Note, register a [Comptroller](./src/auth/ComptrollerFactory.sol), use that to create a [Note](./src/mint/NoteFactory.sol), and enable the [Omniportal](./src/mint/Omniportal.sol) to mint and burn your note:

```solidity
uint8 portalRole = 0;
comptroller.setRoleCapability(portalRole, Note.mintTo.selector, true);
comptroller.setRoleCapability(portalRole, Note.burnFrom.selector, true);
comptroller.setUserRole(address(portal), portalRole, true);
```

For the next chain, repeat the same steps. Then, hook both Notes up to each other:

```solidity
// on chain A
Note(noteAddressOnChainA).setRemoteNote(chainBId, abi.encodePacked(noteAddressOnChainB));
// on chain B
Note(noteAddressOnChainB).setRemoteNote(chainAId, abi.encodePacked(noteAddressOnChainA));
```

Now token holders can move their tokens across chains with a simple call to:

```solidity
  Omniportal.sendNote(
    address noteAddress, // on this chain
    uint256 amount, // amount
    uint16 toChainId, // LayerZero chain id
    bytes calldata toAddress, // receiver address
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) external payable {
    // implementation
  }
```

## Eden Dao Vaults are [Rari Vaults](https://github.com/Rari-Capital/vaults) that mint Notes

Rari Vaults are flexible, minimalist, gas-optimized yield aggregator for earning interest on any ERC20 token.
Eden Dao Vaults mint Notes, which can be connected to other Notes (or other Vaults) for DAOs to create their own decentralized reserves.
