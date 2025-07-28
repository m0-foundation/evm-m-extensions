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
- `swapInToken()`, `swapOutToken()` – Swap ERC-20 tokens to/from wrapped `$M` via Uniswap V3
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

# Overview

Guardian Audits conducted an in-depth security review of M-extensions by M^0 labs from June 23th to June 27rd, 2025. The comprehensive evaluation included developing a specialized fuzzing suite to uncover complex logical errors across various protocol states. This suite was created during the review period and successfully delivered upon the audit's completion.

# Contents

This fuzzing suite was developed for M^0 and updated with remediations at July 20th. The suite primarily targets core functionality found in `MEarnerManager.sol` and `MYieldFee.sol`, `MYieldToOne.sol` and `SwapFacility.sol`.

This suite implements a minimalistic, instant-on approach to fuzzing. It employs Echidna's stateful fuzzing mechanism to simulate the project lifecycle and and minimizes mocking with M0 token, MinterGateway, wrapped M token and Uniswap V3 local deployments.

All tested properties can be found below in this README.

## Setup

1. Install dependencies

`npm i`

`forge install`

## Usage

2. Run Echidna fuzzing with Foundry compilation tool

`forge clean && forge build test/fuzzing/Fuzz.sol && ./echidna . --contract Fuzz --config echidna.yaml`

3. Run Foundry reproducers
   `forge test --mt test_coverage_mint`

# Scope

Repo: https://github.com/GuardianOrg/m-extensions-m0-m-extensions-fuzz

Branch: `main`

Commit: `ba39e694aa7bfffd5138a0ead9f9cb7438c7929a`

Here's the fuzzing directory structure with its contents:

```
test/fuzzing
├── FoundryPlayground.sol
├── Fuzz.sol
├── FuzzGuided.sol
├── FuzzMEarnerManager.sol
├── FuzzMToken.sol
├── FuzzMYieldFee.sol
├── FuzzMYieldToOne.sol
├── FuzzSetup.sol
├── FuzzSwapFacility.sol
├── FuzzUni.sol
├── helpers
│   ├── BeforeAfter.sol
│   ├── FuzzStorageVariables.sol
│   ├── Postconditions
│   │   ├── PostconditionsBase.sol
│   │   ├── PostconditionsMEarnerManager.sol
│   │   ├── PostconditionsMToken.sol
│   │   ├── PostconditionsMYieldFee.sol
│   │   ├── PostconditionsMYieldToOne.sol
│   │   ├── PostconditionsSwapFacility.sol
│   │   └── PostconditionsUni.sol
│   └── Preconditions
│       ├── PreconditionsBase.sol
│       ├── PreconditionsMEarnerManager.sol
│       ├── PreconditionsMToken.sol
│       ├── PreconditionsMYieldFee.sol
│       ├── PreconditionsMYieldToOne.sol
│       ├── PreconditionsSwapFacility.sol
│       └── PreconditionsUni.sol
├── lifeSupport
│   ├── IContinuousIndexing.sol
│   └── Lock.sol
├── logicalCoverage
│   ├── logicalBase.sol
│   ├── logicalMEarnerManager.sol
│   ├── logicalMYieldFee.sol
│   └── logicalMYieldToOne.sol
├── logs
├── mocks
│   ├── DirectPoolMinter.sol
│   ├── MToken.sol
│   ├── MinterGateway.f.sol
│   ├── MockERC20.sol
│   ├── MockMToken.sol
│   ├── MockRegistar.sol
│   ├── WrappedMToken.f.sol
│   ├── abstract
│   │   └── ContinuousIndexing.sol
│   ├── interfaces
│   │   ├── IContinuousIndexing.sol
│   │   ├── IMToken.sol
│   │   └── IRateModel.sol
│   ├── libs
│   │   └── ContinuousIndexingMath.sol
│   └── rateModels
│       ├── EarnerRateModel.sol
│       ├── MinterRateModel.sol
│       ├── interfaces
│       │   ├── IEarnerRateModel.sol
│       │   ├── IMinterRateModel.sol
│       │   └── IRateModel.sol
│       └── solmate
│           └── src
│               └── utils
│                   └── SignedWadMath.sol
├── properties
│   ├── Properties.sol
│   ├── PropertiesBase.sol
│   ├── PropertiesDescriptions.sol
│   ├── Properties_ERR.sol
│   ├── Properties_MEARN.sol
│   ├── Properties_MYF.sol
│   ├── Properties_SWAP.sol
│   └── RevertHandler.sol
└── utils
    ├── FunctionCalls.sol
    ├── FuzzActors.sol
    └── FuzzConstants.sol
```

# Protocol Invariants Status Table

| Invariant ID | Invariant Description                                                                      | Passed | Remediations | Run Count |
| ------------ | ------------------------------------------------------------------------------------------ | ------ | ------------ | --------- |
| MYF-01       | MYieldFee extension mToken Balance must be greater or equal than projectedSupply           | ❌     | ❌           | 10M+      |
| MYF-02       | MYieldFee extension mToken Balance must be greater or equal than projectedSupply + fee     | ❌     | ❌           | 10M+      |
| SWAP-01-00   | YTO_TO_YTO: MYieldToOne yield must not change after swaps                                  | ✅     | ✅           | 10M+      |
| SWAP-01-01   | YFEE_TO_YFEE: MYieldFee yield must not change after swaps                                  | ✅     | ✅           | 10M+      |
| SWAP-01-02   | MEARN_TO_MEARN: MEarnerManager yield must not change after swaps                           | ✅     | ✅           | 10M+      |
| SWAP-02      | Swap facility M0 balance must be 0 after swap out                                          | ✅     | ✅           | 10M+      |
| SWAP-03      | Total M0 balance of all users must not change after swap                                   | ✅     | ✅           | 10M+      |
| SWAP-04      | Received amount of M0 must be greater or equal than slippage                               | ✅     | ✅           | 10M+      |
| SWAP-05      | Received amount of USDC must be greater or equal than slippage                             | ✅     | ✅           | 10M+      |
| MEARN-01     | MEarnerManager extension mToken Balance must be greater or equal than projectedTotalSupply | ❌     | ✅           | 10M+      |
| ERR-01       | Unexpected Error                                                                           | ✅     | ✅           | 10M+      |
