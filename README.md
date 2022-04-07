# Eden Dao Passport: Omnichain Identity

Hello padawan, welcome to the omnichain space.

As is often the case in crypto, we needed infrastructure that hadn't been built yet.

Current identity solutions depend on off-chain data or complex oracles.

Eden Dao Passport is a simple, extensible protocol for syncing user identity across chains. Identity is soulbound to a single wallet address.

We build upon LayerZero Protocol. In the coming weeks, we will have support for: Ethereum, Polygon, Arbitrum, Avalanche, Optimism, and Celo.

## Users sync their on-chain reputation throughout omnispace

Eden Dao Passport is an NFT soulbound to your wallet address. You cannot trade it, you cannot lose it.

Every wallet address is assigned its own unique `uint256 passportId` across chains.

A user can set or sync their own passport's data, which is divided into domains.

Domains are slots that can be written to and synced by holders of the Domain NFT of that `domainId`.

```solidity
// tokenId => domainId => data
mapping(uint256 => mapping(uint256 => bytes)) public dataOf;
```

## Applications can write to their domain and sync it across chains

A Domain NFT permits calling the `setData` and `syncData` methods on the Passport for your specific `domainId`. This Domain NFT can be bridged across any of the LayerZero chains. Only 1 chain can have this NFT at a time, and it is that chain that has the power to call the `setData` and `syncData` methods.

```solidity
function setData(
  uint256 id,
  uint256 domainId,
  bytes memory data
) external {
  require(
    ownerOf[id] == msg.sender || domain.ownerOf(domainId) == msg.sender,
    "Passport: UNAUTHORIZED"
  );
  dataOf[id][domainId] = data;
}

/* ==============================
 * LayerZero
 * ============================== */
function syncData(
  uint16 toChainId,
  address owner,
  uint256 domainId,
  address zroPaymentAddress,
  bytes calldata adapterParams
) external payable {
  require(
    owner == msg.sender || domain.ownerOf(domainId) == msg.sender,
    "Passport: UNAUTHORIZED"
  );

  uint256 passportId = findOrMintFor(owner);

  lzSend(
    toChainId,
    abi.encode(owner, domainId, dataOf[passportId][domainId]),
    zroPaymentAddress,
    adapterParams
  );

  emit Sync(currentChainId, toChainId, passportId, domainId);
}

```

## What will you build?

Just imagine how you could sync reputation, badges, achievements, and more across chains with your protocol! It is up to you how you pack your bytes into your domain, and how you interpret them.

Conjure up your own domain by sending ETH to the ConjureDeus contract at ``. This will reserve a domain id inferred from the message sender, your wallet address, mint you your domain NFT, mint you your own Eden Dao Passport, and for every ETH you gift, you will receive 1000 EDN tokens.

If you want to have more control over the domain id you mint, head on over to the Etherscan and `cast(uint256 domainId, bytes memory tokenURI) payable` with the params of your choice. But do make sure to send along more than 0.01 ETH!
