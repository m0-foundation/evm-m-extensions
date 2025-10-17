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

### Vendor Extensions

#### 0fns (by Dfns)

This extension is derived from [MEarnerManager](https://github.com/m0-foundation/evm-m-extensions/blob/main/src/projects/earnerManager/MEarnerManager.sol).

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

### 🚀 Deployments

#### Mainnet

##### 0fns (by Dfns)

| Network  | Implementation                                                                                                        | Proxy                                                                                                                 | Proxy Admin                                                                                                           |
| -------- | --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| --       |
| Ethereum | [0x4ffbc316CF29e8Eb39cBf819Cfd3D5F5b34033Ef](https://etherscan.io/address/0x4ffbc316CF29e8Eb39cBf819Cfd3D5F5b34033Ef) | [0x64df20A1814a6DD0F3d6f0A14073c47214c53f58](https://etherscan.io/address/0x64df20A1814a6DD0F3d6f0A14073c47214c53f58) | [0x1cb69655Ad51c8A12f5dCFd552c26473bD74D73A](https://etherscan.io/address/0x1cb69655Ad51c8A12f5dCFd552c26473bD74D73A) |
