// SPDX-License-Identifier: UNTITLED
pragma solidity ^0.8.0;

import "./utils/FunctionCalls.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IUniswapV3Factory } from "uniswapv3/v3-core/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "uniswapv3/v3-core/interfaces/IUniswapV3Pool.sol";
import { TickMath } from "uniswapv3/v3-core/libraries/TickMath.sol";
import { INonfungiblePositionManager } from "uniswapv3/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import { UniswapV3Pool } from "uniswapv3/v3-core/UniswapV3Pool.sol";
import { V3SwapRouter } from "uniswapv3/v3-periphery/V3SwapRouter.sol";
import { TTGRegistrarReader } from "src/libs/TTGRegistrarReader.sol";
contract FuzzSetup is FunctionCalls {
    uint256 public liquidityTokenId;

    function fuzzSetup() internal {
        deployMToken();
        deployUniV3();
        deployM0();
        initializeM0();
        deployPool();
        setUsers();
        labelAll();
    }

    function deployMToken() internal {
        registrar = new MockRegistrar(address(0x123));
        console.log("minterGateway address", _getCreateAddress(address(this), 5));
        mToken = new MToken(address(registrar), _getCreateAddress(address(this), 5));
        console.log("mToken address", address(mToken));
        minterGateway = new MinterGateway(address(registrar), address(mToken));
        assert(address(minterGateway) == _getCreateAddress(address(this), 5));
        wMToken = new WrappedMToken(address(mToken), admin);
        weth = new WETH();
        USDC = new MockERC20("USDC", "USDC", 6);
        whitelistedTokens = [address(USDC), address(weth)];

        // Mint tokens for liquidity provision
        USDC.mint(address(this), 2000000 * 1e6); // 2M USDC

        minterGateway.activateMinter(address(this));
        mintMToken(address(this), 2000000 * 1e6); // mintMToken(address(this), 2000000 * 1e6); // 2M MToken
    }

    function deployUniV3() internal {
        uniV3Factory = new UniswapV3Factory();
        emit log_named_address("uniV3Factory", address(uniV3Factory));
        bytes32 initCodeHash = keccak256(type(UniswapV3Pool).creationCode); //NOTE: for the pool init code changes
        emit log_named_bytes32("initCodeHash", initCodeHash);
        console.log("initCodeHash");
        console.logBytes32(initCodeHash);

        uniV3Factory.enableFeeAmount(100, 1);
        positionManager = new NonfungiblePositionManager(address(uniV3Factory), address(weth), address(0x123)); // token descriptor
        v3SwapRouter = new SwapRouter02(
            address(uniV3Factory), // factoryV2 is not used
            address(uniV3Factory),
            address(positionManager),
            address(weth)
        );
    }

    function deployPool() internal {
        // Determine token order (token0 < token1)
        address token0 = address(USDC) < address(wMToken) ? address(USDC) : address(wMToken);
        address token1 = address(USDC) < address(wMToken) ? address(wMToken) : address(USDC);
        require(token0 < token1, "token0 must be less than token1");
        // Create pool with 0.01% fee (100 basis points)

        emit log_named_address("token0", token0);
        emit log_named_address("token1", token1);
        emit log_named_uint("UNISWAP_V3_FEE", UNISWAP_V3_FEE);
        emit log_named_address("uniV3Factory", address(uniV3Factory));
        address poolAddress = uniV3Factory.createPool(token0, token1, UNISWAP_V3_FEE);
        emit log_named_address("poolAddress", poolAddress);

        assert(poolAddress == address(v3SwapRouter.getPool(token0, token1, UNISWAP_V3_FEE)));

        usdcMTokenPool = IUniswapV3Pool(poolAddress);

        // Initialize pool with 1:1 price ratio
        // For 1:1 ratio, sqrtPriceX96 = sqrt(1) * 2^96 = 2^96
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // 2^96
        usdcMTokenPool.initialize(sqrtPriceX96);

        // Add liquidity using position manager
        addLiquidity();
    }

    function addLiquidity() internal {
        mintMToken(address(this), 2000000 * 1e6); // 2M MToken
        mToken.approve(address(wMToken), type(uint256).max);
        wMToken.wrap(address(this), 2000000 * 1e6);

        // Approve tokens to position manager
        USDC.approve(address(positionManager), type(uint256).max);
        wMToken.approve(address(positionManager), type(uint256).max);

        // Get current tick and calculate tick range
        (, int24 currentTick, , , , , ) = usdcMTokenPool.slot0();
        int24 tickSpacing = usdcMTokenPool.tickSpacing();

        // Set tick range around current price (±10 tick spacings)
        int24 tickLower = ((currentTick - (10 * tickSpacing)) / tickSpacing) * tickSpacing;
        int24 tickUpper = ((currentTick + (10 * tickSpacing)) / tickSpacing) * tickSpacing;

        // Mint liquidity position
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(USDC) < address(wMToken) ? address(USDC) : address(wMToken),
            token1: address(USDC) < address(wMToken) ? address(wMToken) : address(USDC),
            fee: UNISWAP_V3_FEE,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: 1000000 * 1e6, // 1M USDC (6 decimals)
            amount1Desired: 1000000 * 1e6, // 1M wMToken (6 decimals)
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 1 hours
        });

        (liquidityTokenId, , , ) = positionManager.mint(params);
    }

    function deployM0() internal {
        rateOracle = new MockRateOracle();
        swapAdapter = new UniswapV3SwapAdapter(address(wMToken), address(v3SwapRouter), admin, whitelistedTokens);

        swapFacility = SwapFacility(
            UnsafeUpgrades.deployUUPSProxy(
                address(new SwapFacility(address(mToken), address(registrar), address(swapAdapter))),
                abi.encodeWithSelector(SwapFacility.initialize.selector, admin)
            )
        );

        MYieldToOne mYieldToOne1Impl = new MYieldToOne();
        ERC1967Proxy mYieldToOne1Proxy = new ERC1967Proxy(
            address(mYieldToOne1Impl),
            abi.encodeWithSelector(
                MYieldToOne.initialize.selector,
                "NAME1",
                "SYMBOL1",
                address(mToken),
                address(swapFacility),
                yieldRecipient,
                admin,
                blacklistManager,
                yieldRecipientManager
            )
        );
        mYieldToOne1 = MYieldToOne(address(mYieldToOne1Proxy));

        MYieldToOne mYieldToOne2Impl = new MYieldToOne();
        ERC1967Proxy mYieldToOne2Proxy = new ERC1967Proxy(
            address(mYieldToOne2Impl),
            abi.encodeWithSelector(
                MYieldToOne.initialize.selector,
                "NAME2",
                "SYMBOL2",
                address(mToken),
                address(swapFacility),
                yieldRecipient,
                admin,
                blacklistManager,
                yieldRecipientManager
            )
        );
        mYieldToOne2 = MYieldToOne(address(mYieldToOne2Proxy));

        MYieldToOne mYieldToOne3Impl = new MYieldToOne();
        ERC1967Proxy mYieldToOne3Proxy = new ERC1967Proxy(
            address(mYieldToOne3Impl),
            abi.encodeWithSelector(
                MYieldToOne.initialize.selector,
                "NAME3",
                "SYMBOL3",
                address(mToken),
                address(swapFacility),
                yieldRecipient,
                admin,
                blacklistManager,
                yieldRecipientManager
            )
        );
        mYieldToOne3 = MYieldToOne(address(mYieldToOne3Proxy));

        MYieldFeeHarness mYieldFee1Impl = new MYieldFeeHarness();
        ERC1967Proxy mYieldFee1Proxy = new ERC1967Proxy(
            address(mYieldFee1Impl),
            abi.encodeWithSelector(
                MYieldFeeHarness.initialize.selector,
                "MYieldFee1",
                "MYF1",
                address(mToken),
                address(swapFacility),
                YIELD_FEE_RATE,
                feeRecipient,
                admin,
                yieldFeeManager,
                claimRecipientManager
            )
        );
        mYieldFee1 = MYieldFeeHarness(address(mYieldFee1Proxy));

        MYieldFeeHarness mYieldFee2Impl = new MYieldFeeHarness();
        ERC1967Proxy mYieldFee2Proxy = new ERC1967Proxy(
            address(mYieldFee2Impl),
            abi.encodeWithSelector(
                MYieldFeeHarness.initialize.selector,
                "MYieldFee2",
                "MYF2",
                address(mToken),
                address(swapFacility),
                YIELD_FEE_RATE,
                feeRecipient,
                admin,
                yieldFeeManager,
                claimRecipientManager
            )
        );
        mYieldFee2 = MYieldFeeHarness(address(mYieldFee2Proxy));

        MYieldFeeHarness mYieldFee3Impl = new MYieldFeeHarness();
        ERC1967Proxy mYieldFee3Proxy = new ERC1967Proxy(
            address(mYieldFee3Impl),
            abi.encodeWithSelector(
                MYieldFeeHarness.initialize.selector,
                "MYieldFee3",
                "MYF3",
                address(mToken),
                address(swapFacility),
                YIELD_FEE_RATE,
                feeRecipient,
                admin,
                yieldFeeManager,
                claimRecipientManager
            )
        );
        mYieldFee3 = MYieldFeeHarness(address(mYieldFee3Proxy));

        MEarnerManagerHarness mEarnerManager1Impl = new MEarnerManagerHarness();
        ERC1967Proxy mEarnerManager1Proxy = new ERC1967Proxy(
            address(mEarnerManager1Impl),
            abi.encodeWithSelector(
                MEarnerManagerHarness.initialize.selector,
                "MEarnerManager1",
                "MEM1",
                address(mToken),
                address(swapFacility),
                admin,
                earnerManager,
                feeRecipient
            )
        );
        mEarnerManager1 = MEarnerManagerHarness(address(mEarnerManager1Proxy));

        MEarnerManagerHarness mEarnerManager2Impl = new MEarnerManagerHarness();
        ERC1967Proxy mEarnerManager2Proxy = new ERC1967Proxy(
            address(mEarnerManager2Impl),
            abi.encodeWithSelector(
                MEarnerManagerHarness.initialize.selector,
                "MEarnerManager2",
                "MEM2",
                address(mToken),
                address(swapFacility),
                admin,
                earnerManager,
                feeRecipient
            )
        );
        mEarnerManager2 = MEarnerManagerHarness(address(mEarnerManager2Proxy));

        MEarnerManagerHarness mEarnerManager3Impl = new MEarnerManagerHarness();
        ERC1967Proxy mEarnerManager3Proxy = new ERC1967Proxy(
            address(mEarnerManager3Impl),
            abi.encodeWithSelector(
                MEarnerManagerHarness.initialize.selector,
                "MEarnerManager3",
                "MEM3",
                address(mToken),
                address(swapFacility),
                admin,
                earnerManager,
                feeRecipient
            )
        );
        mEarnerManager3 = MEarnerManagerHarness(address(mEarnerManager3Proxy));

        mYieldToOneArray = [address(mYieldToOne1), address(mYieldToOne2), address(mYieldToOne3)];
        mYieldFeeArray = [address(mYieldFee1), address(mYieldFee2), address(mYieldFee3)];
        mEarnerManagerArray = [address(mEarnerManager1), address(mEarnerManager2), address(mEarnerManager3)];
        allExtensions = [
            address(mYieldToOne1),
            address(mYieldFee1),
            address(mEarnerManager1),
            address(mYieldToOne2),
            address(mYieldFee2),
            address(mEarnerManager2),
            address(mYieldToOne3),
            address(mYieldFee3),
            address(mEarnerManager3)
        ];

        earnerRateModel = new EarnerRateModel(address(minterGateway), address(registrar), address(mToken));
        minterRateModel = new MinterRateModel(address(registrar));
    }

    function initializeM0() internal {
        swapFacility.grantRole(M_SWAPPER_ROLE, USER1);
        swapFacility.grantRole(M_SWAPPER_ROLE, USER2);
        swapFacility.grantRole(M_SWAPPER_ROLE, USER3);

        registrar.setEarner(address(mYieldToOne1), true);
        registrar.setEarner(address(mYieldToOne2), true);
        registrar.setEarner(address(mYieldToOne3), true);
        registrar.setEarner(address(mEarnerManager1), true);
        registrar.setEarner(address(mEarnerManager2), true);
        registrar.setEarner(address(mEarnerManager3), true);
        registrar.setEarner(address(mYieldFee1), true);
        registrar.setEarner(address(mYieldFee2), true);
        registrar.setEarner(address(mYieldFee3), true);

        registrar.set(bytes32("minter_rate_model"), bytes32(uint256(uint160(address(minterRateModel)))));
        registrar.set(bytes32("earner_rate_model"), bytes32(uint256(uint160(address(earnerRateModel)))));

        registrar.updateConfig(MAX_EARNER_RATE, _baseEarnerRate);
        registrar.updateConfig(BASE_MINTER_RATE, _baseMinterRate);
        registrar.updateConfig(TTGRegistrarReader.EARNER_RATE_MODEL, address(earnerRateModel));
        registrar.updateConfig(TTGRegistrarReader.MINTER_RATE_MODEL, address(minterRateModel));
        registrar.updateConfig(TTGRegistrarReader.UPDATE_COLLATERAL_VALIDATOR_THRESHOLD, 1);
        registrar.updateConfig(TTGRegistrarReader.UPDATE_COLLATERAL_INTERVAL, _updateInterval);
        registrar.updateConfig(TTGRegistrarReader.MINT_DELAY, _mintDelay);
        registrar.updateConfig(TTGRegistrarReader.MINT_TTL, _mintTtl);
        registrar.updateConfig(TTGRegistrarReader.MINT_RATIO, _mintRatio);
        registrar.updateConfig(TTGRegistrarReader.PENALTY_RATE, _penaltyRate);
        registrar.updateConfig(TTGRegistrarReader.MINTER_FREEZE_TIME, _minterFreezeTime);
        // mToken.setCurrentIndex(11e11); //TODO: recheck starting index

        mEarnerManager1.setAccountOf(address(swapFacility), 0, 0, true, 0);
        mEarnerManager2.setAccountOf(address(swapFacility), 0, 0, true, 0);
        mEarnerManager3.setAccountOf(address(swapFacility), 0, 0, true, 0);

        mYieldFee1.enableEarning();
        mYieldFee2.enableEarning();
        mYieldFee3.enableEarning();
    }

    function setUsers() internal {
        for (uint256 i = 0; i < USERS.length; i++) {
            mintMToken(USERS[i], 1e9 * 1e6);

            vm.prank(USERS[i]);
            mToken.approve(address(wMToken), type(uint256).max);

            vm.prank(USERS[i]);
            wMToken.wrap(USERS[i], ((1e9 * 1e6) / 2));

            USDC.mint(USERS[i], 1e9 * 1e6);
            vm.deal(USERS[i], 1e9 * 1e18);
            vm.prank(USERS[i]);
            weth.deposit{ value: 1e9 * 1e18 }();

            vm.prank(USERS[i]);
            mToken.approve(address(swapFacility), type(uint256).max);

            vm.prank(USERS[i]);
            wMToken.approve(address(swapFacility), type(uint256).max);

            vm.prank(USERS[i]);
            USDC.approve(address(swapFacility), type(uint256).max); //NOTE: USDC is the base token

            vm.prank(USERS[i]);
            weth.approve(address(swapFacility), type(uint256).max);

            vm.prank(USERS[i]);
            USDC.approve(address(v3SwapRouter), type(uint256).max);

            vm.prank(USERS[i]);
            weth.approve(address(v3SwapRouter), type(uint256).max);

            mEarnerManager1.setAccountOf(USERS[i], 0, 0, true, 0);
            mEarnerManager2.setAccountOf(USERS[i], 0, 0, true, 0);
            mEarnerManager3.setAccountOf(USERS[i], 0, 0, true, 0);

            for (uint256 j = 0; j < allExtensions.length; j++) {
                vm.prank(USERS[i]);
                IERC20(allExtensions[j]).approve(address(swapFacility), type(uint256).max);
            }
        }
    }

    //DO LABELING
    function labelAll() internal {
        //CONTRACTS
        vm.label(address(rateOracle), "RateOracle");
        vm.label(address(registrar), "Registrar");
        vm.label(address(swapFacility), "SwapFacility");

        vm.label(address(mYieldToOne1), "MYieldToOne1");
        vm.label(address(mYieldToOne2), "MYieldToOne2");
        vm.label(address(mYieldToOne3), "MYieldToOne3");
        vm.label(address(mYieldFee1), "MYieldFee1");
        vm.label(address(mYieldFee2), "MYieldFee2");
        vm.label(address(mYieldFee3), "MYieldFee3");
        vm.label(address(mEarnerManager1), "MEarnerManager1");
        vm.label(address(mEarnerManager2), "MEarnerManager2");
        vm.label(address(mEarnerManager3), "MEarnerManager3");

        //UNISWAP V3
        vm.label(address(uniV3Factory), "UniV3Factory");
        vm.label(address(v3SwapRouter), "V3SwapRouter");
        vm.label(address(positionManager), "PositionManager");
        vm.label(address(usdcMTokenPool), "USDC-MToken-Pool");

        //TOKENS
        vm.label(address(USDC), "USDC");
        vm.label(address(weth), "WETH");
        vm.label(address(mToken), "MToken");

        //USERS
        vm.label(USER1, "USER1");
        vm.label(USER2, "USER2");
        vm.label(USER3, "USER3");
    }

    // calculates address of contract predeployment
    function _getCreateAddress(address deployer, uint256 nonce) internal pure returns (address) {
        if (nonce == 0) {
            return
                address(
                    uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80)))))
                );
        } else if (nonce <= 0x7f) {
            return
                address(
                    uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce)))))
                );
        } else if (nonce <= 0xff) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))
                            )
                        )
                    )
                );
        } else if (nonce <= 0xffff) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))
                            )
                        )
                    )
                );
        } else {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))
                            )
                        )
                    )
                );
        }
    }

    function mintMToken(address destination, uint256 amount) internal {
        uint48 mintId = minterGateway.proposeMint(amount, destination);
        minterGateway.mintM(mintId);
    }
}
