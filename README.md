_eden dao omniprotocol is in code review._ This is an opportunity for the community to get involved prior to testnet launch. PRs would be greatly appreciated!

Interested in building with eden dao omniprotocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**

# Eden Dao OmniProtocol is Public Goods Omnichain Infrastructure

**Public Goods** in that the  the usage of the protocol supports the regenerative mission of Eden Dao.

**Omnichain Infrastructure** in that it unlocks a new world of cross-chain possibilities, powered by LayerZero.

Gas-optimized, you can launch your own ERC20 with ≤0.1 ETH on mainnet. Here's the TL;DR:

**These examples use `cast` to call functions, though you could use any tool you like.** View the deployed contract addresses on [testnet](./deploy/testnet/deployments.json).

### A non-custodial protocol

It all begins with a `Steward` to self-custody your contracts with flexible, role-based authentication through Solmate's MultiRoleAuthority.

```bash
cast send 0xEdenDaoSteward "clone(address)" 0xOwnerAddress
```


### Bridge your existing ERC20 to other chains with Omnibridge

If you already have an ERC20, you can launch a **non-custodial** Omnibridge on the source chain to link up to an Omnitoken on the new chain. Effortlessly unlock multi-chain DAO Ops and DAO2DAO collaborations.

```bash
cast send 0xEdenDaoOmnibridge "clone(address,address)" \
  0xYourStewardAddress \
  0xYourTokenAddress
```


To connect your Omnibridge on Chain A to an Omnitoken on Chain B, simply:

```bash
# For Chain A
cast send 0xYourOmnibridgeOnChainA "setTrustedRemote(uint16,bytes)" ChainB_ID 0xYourOmnitokenOnChainB
# For Chain B
cast send 0xYourOmnitokenOnChainB "setTrustedRemote(uint16,bytes)" ChainA_ID 0xYourOmnibridgeOnChainA
```

### Launch and bridge across any chain with Omnitoken

Stop wasting months deciding what chain to launch on because of lock-in and high switching costs, just launch an Omnitoken on the chain you want. If you ever need to move to another chain, launch an Omnitoken there and link the two up. Now your token is easily bridgeable across chains!

```bash
cast send 0xEdenDaoOmnitoken "clone(address,string,string,uint8)" \
  0xYourStewardAddress \
  "Friends with Assets Under Management" \
  "FWAUM" \
  18
```

To connect an Omnitoken on Chain A to one on Chain B, simply:

```bash
# For Chain A
cast send 0xYourOmnitokenOnChainA "setTrustedRemote(uint16,bytes)" ChainB_ID 0xYourOmnitokenOnChainB
# For Chain B
cast send 0xYourOmnitokenOnChainB "setTrustedRemote(uint16,bytes)" ChainA_ID 0xYourOmnitokenOnChainA
```


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
