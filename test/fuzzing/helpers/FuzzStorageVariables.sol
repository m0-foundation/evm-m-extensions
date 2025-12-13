// SPDX-License-Identifier: UNTITLED
pragma solidity ^0.8.0;

import "../utils/FuzzActors.sol";

import { ContinuousIndexingMath } from "lib/common/src/libs/ContinuousIndexingMath.sol";
import { IndexingMath } from "lib/common/src/libs/IndexingMath.sol";
import { Upgrades, UnsafeUpgrades } from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import { SwapFacility } from "src/swap/SwapFacility.sol";
import { MockRateOracle } from "test/utils/Mocks.sol";
import { MockRegistrar } from "test/fuzzing/mocks/MockRegistar.sol";
import { MToken } from "test/fuzzing/mocks/MToken.sol";
import { MockERC20 } from "test/fuzzing/mocks/MockERC20.sol";
import { Helpers } from "test/utils/Helpers.sol";

import { MYieldToOne } from "src/projects/yieldToOne/MYieldToOne.sol";
import { JMIExtension } from "src/projects/jmi/JMIExtension.sol";
import { MEarnerManagerHarness } from "test/harness/MEarnerManagerHarness.sol";
import { MYieldFeeHarness } from "test/harness/MYieldFeeHarness.sol";

import { WETH9 as WETH } from "uniswapv3/mocks/WETH.sol";
import { UniswapV3Factory } from "uniswapv3/v3-core/UniswapV3Factory.sol";
import { SwapRouter02 } from "uniswapv3/v3-periphery/SwapRouter02.sol";
import { NonfungiblePositionManager } from "uniswapv3/v3-periphery/NonfungiblePositionManager.sol";
import { UniswapV3SwapAdapter } from "src/swap/UniswapV3SwapAdapter.sol";
import { WrappedMToken } from "test/fuzzing/mocks/WrappedMToken.f.sol";
import { IUniswapV3Pool } from "uniswapv3/v3-core/interfaces/IUniswapV3Pool.sol";

import { EarnerRateModel } from "test/fuzzing/mocks/rateModels/EarnerRateModel.sol";
import { MinterRateModel } from "test/fuzzing/mocks/rateModels/MinterRateModel.sol";
import { MinterGateway } from "test/fuzzing/mocks/MinterGateway.f.sol";
import { DirectPoolMinter } from "test/fuzzing/mocks/DirectPoolMinter.sol";

contract FuzzStorageVariables is FuzzActors {
    // ==============================================================
    // FUZZING SUITE SETUP
    // ==============================================================

    address currentActor;
    bool _setActor = true;

    uint256 internal constant PRIME = 2147483647;
    uint256 internal constant SEED = 22;
    uint256 iteration = 1; // fuzzing iteration
    uint256 lastTimestamp;

    bool internal protocolSet;

    //==============================================================
    // REVERTS CONFIGURATION
    //==============================================================

    bool internal constant CATCH_REQUIRE_REVERT = true; // Set to false to ignore require()/revert()
    bool internal constant CATCH_EMPTY_REVERTS = true; // Set to true to allow empty return data

    // ==============================================================
    // M0 CONFIGURATION
    // ==============================================================

    uint16 public constant YIELD_FEE_RATE = 2000; // 20%

    bytes32 public constant EARNERS_LIST = "earners";
    uint32 public constant M_EARNER_RATE = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY

    uint56 public constant EXP_SCALED_ONE = 1e12;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant FREEZE_MANAGER_ROLE = keccak256("FREEZE_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant YIELD_RECIPIENT_MANAGER_ROLE = keccak256("YIELD_RECIPIENT_MANAGER_ROLE");
    bytes32 public constant EARNER_MANAGER_ROLE = keccak256("EARNER_MANAGER_ROLE");
    bytes32 public constant ASSET_CAP_MANAGER_ROLE = keccak256("ASSET_CAP_MANAGER_ROLE");
    bytes32 public constant M_SWAPPER_ROLE = keccak256("M_SWAPPER_ROLE");

    uint16 public constant ONE_HUNDRED_PERCENT = 10_000;
    uint24 public constant UNISWAP_V3_FEE = 100;

    // ==============================================================
    // M0 SETTINGS
    // ==============================================================
    bytes32 internal constant MAX_EARNER_RATE = "max_earner_rate";
    bytes32 internal constant BASE_MINTER_RATE = "base_minter_rate";

    uint32 internal _baseEarnerRate = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY
    uint32 internal _baseMinterRate = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY
    uint256 internal _updateInterval = 24 hours;
    uint256 internal _mintDelay = 0;
    uint256 internal _mintTtl = 0;
    uint256 internal _mintRatio = 9_000; // 90%
    uint32 internal _penaltyRate = 100; // 1%, bps
    uint32 internal _minterFreezeTime = 24 hours;

    uint256 internal _start = block.timestamp;

    // ==============================================================
    // M0 CONTRACTS
    // ==============================================================

    WrappedMToken internal wMToken;
    MockERC20 internal USDC;
    WETH internal weth;

    IUniswapV3Pool internal usdcMTokenPool;
    DirectPoolMinter internal minter;

    address[] internal whitelistedTokens;
    UniswapV3Factory internal uniV3Factory;
    SwapRouter02 internal v3SwapRouter;
    NonfungiblePositionManager internal positionManager;

    MToken internal mToken;
    MockRateOracle internal rateOracle;
    MockRegistrar internal registrar;
    UniswapV3SwapAdapter internal swapAdapter;
    SwapFacility internal swapFacility;

    MYieldToOne internal mYieldToOne1;
    MYieldFeeHarness internal mYieldFee1;
    MEarnerManagerHarness internal mEarnerManager1;

    MYieldToOne internal mYieldToOne2;
    MYieldFeeHarness internal mYieldFee2;
    MEarnerManagerHarness internal mEarnerManager2;

    MYieldToOne internal mYieldToOne3;
    MYieldFeeHarness internal mYieldFee3;
    MEarnerManagerHarness internal mEarnerManager3;

    JMIExtension internal jmiExtension;
    JMIExtension internal jmiExtension2; // Second JMI extension for Extension → Extension swaps

    MockERC20 internal DAI; // Asset token for JMI Extension

    address[3] internal mYieldToOneArray;
    address[3] internal mYieldFeeArray;
    address[3] internal mEarnerManagerArray;
    address[] internal allExtensions;

    EarnerRateModel internal earnerRateModel;
    MinterRateModel internal minterRateModel;

    MinterGateway internal minterGateway;
}
