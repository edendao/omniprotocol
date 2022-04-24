# Eden Dao Protocol is Regenerative Omnichain Infrastructure

**Regenerative** in that protocol fees are directed for the public good towards carbon dioxide removal and renewable energy.

**Omnichain infrastructure** in that it liberates DAOs from a single chain with new primitives.

EDEN DAO IS IN DEVELOPER PREVIEW. IF YOU WOULD LIKE TO COLLABORATE, DO REACH OUT ON [TWITTER](https://twitter.com/CyrusOfEden).

## Eden Dao Omnicast is an omnichain account datastore

[Omnicast](./src/omnicast/Omnicast.sol) is a simple protocol to read and write arbitrary bytes messages across any LayerZero chain. Every address has its own Omnicast as a soulbound NFT. Messages are written to a `uint256 receiverOmnicastId` on a `uint256 senderOmnicastId` channel. Every address has its own unique `omnicastId = uint256(uint160(msg.sender))`, and [Omnichannel](./src/omnicast/Omnichannel.sol) NFTs can be minted to write to vanity channel names like `fwb.eden.dao`.

As an arbitrary bytes store, what you use this for is up to you. You could:

1. Sign people's ledgers across chains
2. Certify a credential across chains
3. Leave art on people's Omnicasts
4. Write user data to another chain

## Eden Dao Notes are omnichain tokens

New DAOs spend too much wasted time agonizing on which chain to launch on. Eden Dao illuminates the omnichain path with Note: A gas-optimized, secure ERC20 with simple cross-chain bridging built in.

To create your own Note, register a [Comptroller](./src/auth/ComptrollerFactory.sol), use that to create a [Note](./src/mint/NoteFactory.sol), and enable the Omniportal to mint and burn your note:

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

Now your tokens can be bridged across the chains simply and conveniently thanks to LayerZero!

## Eden Dao Vaults are Rari Vaults that mint Notes

Rari Vaults are flexible, minimalist, gas-optimized yield aggregator for earning interest on any ERC20 token.
Eden Dao Vaults mint Notes, which can be connected to other Notes (or other Vaults) for DAOs to create their own decentralized reserves.
