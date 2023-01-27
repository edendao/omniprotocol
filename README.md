_eden dao omniprotocol is in code review._ This is an opportunity for the community to get involved prior to testnet launch. PRs would be greatly appreciated!

Interested in building with eden dao omniprotocol? **[Let's collaborate!](https://edendao.typeform.com/to/qrHGVQtx)**

# Eden Dao OmniProtocol is Public Goods Omnichain Infrastructure

**Public Goods** in that the the usage of the protocol supports the regenerative mission of Eden Dao.

**Omnichain Infrastructure** in that it unlocks a new world of cross-chain possibilities, powered by LayerZero.

Gas-optimized, you can launch your own ERC20 with ≤0.1 ETH on mainnet. Here's the TL;DR:

**These examples use `cast` to call functions, though you could use any tool you like.** View the deployed contract addresses on [testnet](./deploy/testnet/deployments.json).

### A non-custodial protocol

It all begins with a `Steward` to self-custody your contracts with flexible, role-based authentication through Solmate's MultiRoleAuthority.

```bash
cast send 0xEdenDaoSteward "clone(address)" 0xOwnerAddress
```

### Bridge your existing ERC20 to other chains with ERC20Vault

If you already have an ERC20, you can launch a **non-custodial** ERC20Vault on the source chain to link up to an ERC20Note on the new chain. Effortlessly unlock multi-chain DAO Ops and DAO2DAO collaborations.

```bash
cast send 0xEdenDaoERC20Vault "clone(address,address)" \
  0xYourStewardAddress \
  0xYourTokenAddress
```

To connect your ERC20Vault on Chain A to an ERC20Note on Chain B, simply:

```bash
# For Chain A
cast send 0xYourERC20VaultOnChainA "connect(uint16,bytes)" ChainB_ID 0xYourERC20NoteOnChainB
# For Chain B
cast send 0xYourERC20NoteOnChainB "connect(uint16,bytes)" ChainA_ID 0xYourERC20VaultOnChainA
```

### Launch and bridge across any chain with ERC20Note

Stop wasting months deciding what chain to launch on because of lock-in and high switching costs, just launch an ERC20Note on the chain you want. If you ever need to move to another chain, launch an ERC20Note there and link the two up. Now your token is easily bridgeable across chains!

```bash
cast send 0xEdenDaoERC20Note "clone(address,string,string,uint8)" \
  0xYourStewardAddress \
  "Friends with Assets Under Management" \
  "FWAUM" \
  18
```

To connect an ERC20Note on Chain A to one on Chain B, simply:

```bash
# For Chain A
cast send 0xYourERC20NoteOnChainA "connect(uint16,bytes)" ChainB_ID 0xYourERC20NoteOnChainB
# For Chain B
cast send 0xYourERC20NoteOnChainB "connect(uint16,bytes)" ChainA_ID 0xYourERC20NoteOnChainA
```
