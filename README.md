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

- **`JMIExtension`**
  - Wraps `$M` token into a non-rebasing equivalent with a "Just Mint It" (JMI) backing model
  - Allows minting by depositing `$M` or other approved collateral assets, assuming a 1:1 peg
  - All yield is consolidated and claimable by a single, designated `yieldRecipient`
  - Includes pausing functionality, asset freezes, and caps on non-`$M` collateral
  - Inherits core `MExtension` functionality and yield direction from `MYieldToOne`

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

##### GRID (JMI Extension)

This extension is an implementation of [JMIExtension](https://github.com/m0-foundation/evm-m-extensions/blob/main/src/projects/jmi/JMIExtension.sol).

| Network | Implementation                                                                                                                    | Proxy                                                                                                                                        | Proxy Admin                                                                                                            |
| ------- | --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Plasma  | [0xf2414B88c565b53fBb3923C96Bdf826333973a27](https://plasmascan.to/token/0xf2414B88c565b53fBb3923C96Bdf826333973a27?chainid=9745) | [0x43324fA4842829dB99e25713F81da2d0e7eB21c3](https://plasmascan.to/token/0x43324fA4842829dB99e25713F81da2d0e7eB21c3?type=erc20&chainid=9745) | [0x38D54c22E3be4f8998b55a71a767D8203723eF2D](https://plasmascan.to/address/0x38D54c22E3be4f8998b55a71a767D8203723eF2D) |
