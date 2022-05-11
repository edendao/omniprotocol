_eden dao omniprotocol is in code review._ This is an opportunity for the community to get involved prior to testnet launch. PRs would be greatly appreciated!

Interested in building with eden dao protocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**

# Eden Dao OmniProtocol is Regenerative Omnichain Infrastructure

**Regenerative** in that the usage of the protocol supports the regenerative mission of Eden Dao.

**Omnichain Infrastructure** in that it unlocks a new world of cross-chain possibilities, powered by LayerZero.

Gas-optimized, you can launch your own ERC20 with ≤0.1 ETH on mainnet. Here's the TL;DR:

**These examples use `cast` to call functions, though you could use any tool you like.** View the deployed contract addresses on [testnet](./deploy/testnet/deployments.json).

### A non-custodial protocol

It all begins with a `Comptroller` to self-custody your contracts with flexible, role-based authentication through Solmate's MultiRoleAuthority.

```bash
cast send `eden-dao-comptroller` "clone(address)" 0xOwnerAddress
```

### Launch and bridge across any chain with Omnitoken

Stop wasting months deciding what chain to launch on because of lock-in and high switching costs, just launch an Omnitoken on the chain you want. If you ever need to move to another chain, launch an Omnitoken there and link the two up. Now your token is easily bridgeable across chains!

```bash
cast send `eden-dao-omnitoken` "clone(address,string,string,uint8)" \
  0xYourComptrollerAddress \
  "Friends with Assets Under Management" \
  "FWAUM" \
  18
```

### Bridge your existing ERC20 to other chains with Omnibridge

If you already have an ERC20, you can launch a **non-custodial** Omnibridge on the source chain and an Omnitoken on the new chain, link the two up, and now your DAO token can be bridged!

```bash
cast send `eden-dao-bridge` "clone(address,address)" \
  0xYourComptrollerAddress \
  0xYourTokenAddress
```

This unlocks multi-chain DAO Ops and DAO2DAO collaborations.

### Write on-chain messages across chains using Omnicast

Omnicast lets you write arbitrary bytes to a destination chain, so `abi.encode` your data on the source chain and `abi.decode` it on the receiving chain.

```solidity
// First Chain
omnicast.writeMessage(
  omnicast.idOf(secondChainContractAddress), // receiver
  omnicast.idOf(firstChainContractAddress), // sender
  bytes("Gardener of the Galaxy"),
  4, // LayerZero Chain ID
  address(0), // LayerZero Payment Address
  bytes("") // LayerZero Adapter Params
)

// Second Chain
string memory message = string(omnicast.readMessage(
  omnicast.idOf(secondChainContractAddress),
  omnicast.idOf(firstChainContractAddress)
));
assertEq(message, "Gardener of the Galaxy");
```
