## $M Extensions Framework

**M Extension Framework** is a modular templates of ERC-20 **stablecoin extensions** that wrap the yield-bearing `$M` token into non-rebasing variants for improved composability within DeFi. Each extension manages yield distribution differently and integrates with a central **SwapFacility** contract that acts as the exclusive entry point for wrapping and unwrapping.

All contracts are deployed behind transparent upgradeable proxies (by default).

---

### 🧩 M Extensions

Each extension inherits from the abstract `MExtension` base contract, which defines shared wrapping logic. Only the `SwapFacility` is authorized to call `wrap()` and `unwrap()`. Yield is accrued based on the locked `$M` balance within each extension and minted via dedicated yield claim functions.

#### In-Scope Extensions

- **`MYieldToOne`**

  - All yield goes to a single configurable `yieldRecipient`
  - Includes a blacklist enforced on all user actions
  - Handles loss of `$M` earner status gracefully

- **`MEarnerManager`**

  - Redistributes yield to all holders minus per-address `feeRate`
  - Enforces a whitelist; non-whitelisted users are frozen and yield is redirected as fee
  - Yield is claimed via `claimFor(address)`
  - **Does not handle loss of `$M` earner status**, leading to potential insolvency if not upgraded

- **`MYieldFee`**

  - All users receive the same yield rate, discounted by a global `feeRate`
  - Yield can be redirected via `claimRecipient` per user
  - Includes `updateIndex()` to resync with new `$M` rates
  - Can handle loss and regain of `$M` earning status via `disableEarning()` and `enableEarning()`

- **`MSpokeYieldFee`**
  - Optimized for EVM sidechains (e.g., Arbitrum, Optimism)
  - Index updates occur via bridging, not time-based growth
  - Uses an external `rateOracle` for fee calculation
  - Inherits most behavior from `MYieldFee`

---

### 🔁 SwapFacility

The `SwapFacility` contract acts as the **exclusive router** for all wrapping and swapping operations involving `$M` and its extensions.

#### Key Functions

- `swap()` – Switch between extensions by unwrapping and re-wrapping
- `swapInM()`, `swapInMWithPermit()` – Accept `$M` and wrap into the selected extension
- `swapOutM()` – Unwrap to `$M` (restricted to whitelisted addresses only)

> All actions are subject to the rules defined by each extension (e.g., blacklists, whitelists)

---

### 💱 UniswapV3SwapAdapter

A helper contract that enables token swaps via Uniswap V3.

- Immutable and admin-controlled
- Uses Uniswap's `SwapRouter02`
- Functions:
  - `swapIn(path, ...)`
  - `swapOut(path, ...)`
- Supports multi-hop paths or single-hop with default 0.01% fee
- Token whitelist is controlled via `DEFAULT_ADMIN_ROLE`

---

## Deployment Addresses

### SwapFacility

#### Mainnet

| Chain    | Proxy                                                                                                                            | Implementation                                                                                                                   | ProxyAdmin                                                                                                                       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Ethereum | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://etherscan.io/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)            | [0xb4b738e41a0a79f09194e2f459b86f2406917ef0](https://etherscan.io/address/0xb4b738e41a0a79f09194e2f459b86f2406917ef0)            | [0x0f38d8a5583f9316084e9c40737244870c565924](https://etherscan.io/address/0x0f38d8a5583f9316084e9c40737244870c565924)            |
| Arbitrum | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://arbiscan.io/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)             | [0xdbb20434e95afc9667c014fd69eda765aa785ef9](https://arbiscan.io/address/0xdbb20434e95afc9667c014fd69eda765aa785ef9)             | [0x0f38d8a5583f9316084e9c40737244870c565924](https://arbiscan.io/address/0x0f38d8a5583f9316084e9c40737244870c565924)             |
| Optimism | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://optimistic.etherscan.io/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278) | [0x07dd9e3b00002f9cb178670159d4e6fe0d8cd146](https://optimistic.etherscan.io/address/0x07dd9e3b00002f9cb178670159d4e6fe0d8cd146) | [0x0f38d8a5583f9316084e9c40737244870c565924](https://optimistic.etherscan.io/address/0x0f38d8a5583f9316084e9c40737244870c565924) |
| BSC      | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://bscscan.com/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)             | [0xbc1e1838889a9458acd7bb3378b489ce5e1d2c1a](https://bscscan.com/address/0xbc1e1838889a9458acd7bb3378b489ce5e1d2c1a)             | [0x0f38d8a5583f9316084e9c40737244870c565924](https://bscscan.com/address/0x0f38d8a5583f9316084e9c40737244870c565924)             |
| Linea    | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://lineascan.build/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)         | [0x9e0fdb26954bc8998158c0c921c8254bd6dfe5ec](https://lineascan.build/address/0x9e0fdb26954bc8998158c0c921c8254bd6dfe5ec)         | [0x0f38d8a5583f9316084e9c40737244870c565924](https://lineascan.build/address/0x0f38d8a5583f9316084e9c40737244870c565924)         |
| HyperEVM | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://hyperevmscan.io/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)         | [0x23e07a9353236d0367ea9c5d6481c39920c6984c](https://hyperevmscan.io/address/0x23e07a9353236d0367ea9c5d6481c39920c6984c)         | [0x0f38d8a5583f9316084e9c40737244870c565924](https://hyperevmscan.io/address/0x0f38d8a5583f9316084e9c40737244870c565924)         |
| Plume    | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://explorer.plume.org/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)      | [0xF3Ef8f66955FFe4637768A2C7937f731CD67d890](https://explorer.plume.org/address/0xF3Ef8f66955FFe4637768A2C7937f731CD67d890)      | [0x0f38d8a5583f9316084e9c40737244870c565924](https://explorer.plume.org/address/0x0f38d8a5583f9316084e9c40737244870c565924)      |

#### Testnet

| Chain            | Proxy                                                                                                                                  | Implementation                                                                                                                         | ProxyAdmin                                                                                                                             |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Sepolia          | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://sepolia.etherscan.io/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)          | [0x431b9048c6ff6ef9d5d3e326675242134afa3dc3](https://sepolia.etherscan.io/address/0x431b9048c6ff6ef9d5d3e326675242134afa3dc3)          | [0x0f38d8a5583f9316084e9c40737244870c565924](https://sepolia.etherscan.io/address/0x0f38d8a5583f9316084e9c40737244870c565924)          |
| Arbitrum Sepolia | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://sepolia.arbiscan.io/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278)           | [0x248af94d8f8f7f37b9b2355c8ca46b19e7c7c6c2](https://sepolia.arbiscan.io/address/0x248af94d8f8f7f37b9b2355c8ca46b19e7c7c6c2)           | [0x0f38d8a5583f9316084e9c40737244870c565924](https://sepolia.arbiscan.io/address/0x0f38d8a5583f9316084e9c40737244870c565924)           |
| Optimism Sepolia | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://sepolia-optimism.etherscan.io/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278) | [0x248af94d8f8f7f37b9b2355c8ca46b19e7c7c6c2](https://sepolia-optimism.etherscan.io/address/0x248af94d8f8f7f37b9b2355c8ca46b19e7c7c6c2) | [0x0f38d8a5583f9316084e9c40737244870c565924](https://sepolia-optimism.etherscan.io/address/0x0f38d8a5583f9316084e9c40737244870c565924) |
| Soneium Minato   | [0xB6807116b3B1B321a390594e31ECD6e0076f6278](https://soneium-minato.blockscout.com/address/0xB6807116b3B1B321a390594e31ECD6e0076f6278) | [0x23d8162e084aA33D8EF6FCC0Ab33f4028A53Ee79](https://soneium-minato.blockscout.com/address/0x23d8162e084aA33D8EF6FCC0Ab33f4028A53Ee79) | [0x0f38d8a5583f9316084e9c40737244870c565924](https://soneium-minato.blockscout.com/address/0x0f38d8a5583f9316084e9c40737244870c565924) |

### UniswapV3SwapAdapter

| Chain    | Address                                                                                                               |
| -------- | --------------------------------------------------------------------------------------------------------------------- |
| Ethereum | [0x023bd2F0A95373C55FC8D1c5F8e60cC3B9Bc4f4b](https://etherscan.io/address/0x023bd2F0A95373C55FC8D1c5F8e60cC3B9Bc4f4b) |
| Arbitrum | [0x023bd2F0A95373C55FC8D1c5F8e60cC3B9Bc4f4b](https://arbiscan.io/address/0x023bd2F0A95373C55FC8D1c5F8e60cC3B9Bc4f4b)  |
