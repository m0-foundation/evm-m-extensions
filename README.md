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
