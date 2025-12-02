// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Config {
    error UnsupportedChain(uint256 chainId);

    struct DeployConfig {
        address mToken;
        address wrappedMToken;
        address registrar;
        address uniswapV3Router;
        address admin;
    }

    struct DeployExtensionConfig {
        // common
        string name;
        string symbol;
        address admin;
        // earner manager and yield to all
        address feeRecipient;
        // earner manager
        address earnerManager;
        // yield to all
        uint16 feeRate;
        address feeManager;
        address claimRecipientManager;
        // yield to one
        address yieldRecipient;
        address freezeManager;
        address yieldRecipientManager;
        // just mint it
        address pauser;
    }

    // Mainnet chain IDs
    uint256 public constant ETHEREUM_CHAIN_ID = 1;
    uint256 public constant ARBITRUM_CHAIN_ID = 42161;
    uint256 public constant OPTIMISM_CHAIN_ID = 10;
    uint256 public constant HYPER_EVM_CHAIN_ID = 999;
    uint256 public constant PLUME_CHAIN_ID = 98866;
    uint256 public constant BSC_CHAIN_ID = 56;
    uint256 public constant MANTRA_CHAIN_ID = 5888;
    uint256 public constant BASE_CHAIN_ID = 8453;
    uint256 public constant SONEIUM_CHAIN_ID = 1868;

    // Testnet chain IDs
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;
    uint256 public constant APECHAIN_TESTNET_CHAIN_ID = 33111;
    uint256 public constant BSC_TESTNET_CHAIN_ID = 97;
    uint256 public constant SONEIUM_TESTNET_CHAIN_ID = 1946;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;

    address public constant DEPLOYER = 0xF2f1ACbe0BA726fEE8d75f3E32900526874740BB;

    address public constant M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address public constant WRAPPED_M_TOKEN = 0x437cc33344a0B27A429f795ff6B469C72698B291;
    address public constant REGISTRAR = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;

    // Same address across all supported chains
    address public constant UNISWAP_V3_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant UNISWAP_ROUTER_SEPOLIA = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    function _getDeployConfig(uint256 chainId_) internal pure returns (DeployConfig memory) {
        DeployConfig memory config;

        // Mainnet configs
        if (chainId_ == ETHEREUM_CHAIN_ID) {
            config = _getDefaultDeployConfig();
            config.uniswapV3Router = UNISWAP_V3_ROUTER;
            return config;
        }

        if (chainId_ == ARBITRUM_CHAIN_ID) {
            config = _getDefaultDeployConfig();
            config.uniswapV3Router = UNISWAP_V3_ROUTER;
            return config;
        }

        if (chainId_ == OPTIMISM_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == HYPER_EVM_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == PLUME_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == BSC_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == MANTRA_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == BASE_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == SONEIUM_CHAIN_ID) {
            config = _getDefaultDeployConfig();
            config.uniswapV3Router = UNISWAP_V3_ROUTER;
            return config;
        }

        // Testnet configs
        if (chainId_ == LOCAL_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == SEPOLIA_CHAIN_ID) {
            config = _getDefaultDeployConfig();
            config.uniswapV3Router = UNISWAP_ROUTER_SEPOLIA;
            return config;
        }
        if (chainId_ == ARBITRUM_SEPOLIA_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == OPTIMISM_SEPOLIA_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == APECHAIN_TESTNET_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == BSC_TESTNET_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == BASE_SEPOLIA_CHAIN_ID) return _getDefaultDeployConfig();
        if (chainId_ == SONEIUM_TESTNET_CHAIN_ID) {
            config = _getDefaultDeployConfig();
            config.registrar = 0x09ddB94dE27d26Fa426276bF33932594B257F9B6;
            config.uniswapV3Router = UNISWAP_V3_ROUTER;
            return config;
        }

        revert UnsupportedChain(chainId_);
    }

    /// @dev Default config for EVM chains
    function _getDefaultDeployConfig() internal pure returns (DeployConfig memory) {
        return
            DeployConfig({
                mToken: M_TOKEN,
                wrappedMToken: WRAPPED_M_TOKEN,
                registrar: REGISTRAR,
                uniswapV3Router: address(0),
                admin: DEPLOYER
            });
    }

    function _getExtensionConfig(
        uint256 chainId_,
        string memory name
    ) internal pure returns (DeployExtensionConfig memory config) {
        if (chainId_ == SEPOLIA_CHAIN_ID) {
            if (keccak256(bytes(name)) == keccak256(bytes("MEarnerManagerTestnet"))) {
                config.name = name;
                config.symbol = "MEM";
                config.admin = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.earnerManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.feeRecipient = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
            }

            if (keccak256(bytes(name)) == keccak256(bytes("MYieldToAllTestnet"))) {
                config.name = name;
                config.symbol = "MYTA";
                config.admin = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.feeRate = 1000;
                config.feeRecipient = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.feeManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.claimRecipientManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
            }

            if (keccak256(bytes(name)) == keccak256(bytes("MYieldToOneTestnet"))) {
                config.name = name;
                config.symbol = "MYT1";
                config.admin = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.yieldRecipient = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.freezeManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.yieldRecipientManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
            }

            if (keccak256(bytes(name)) == keccak256(bytes("JMIExtensionTestnet"))) {
                config.name = name;
                config.symbol = "JMI";
                config.admin = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.yieldRecipient = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.freezeManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.pauser = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.yieldRecipientManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
            }
        }
    }

    function _getWhitelistedTokens(uint256 chainId_) internal pure returns (address[] memory whitelistedTokens) {
        if (chainId_ == ETHEREUM_CHAIN_ID) {
            whitelistedTokens = new address[](2);
            whitelistedTokens[0] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
            whitelistedTokens[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        }

        if (chainId_ == ARBITRUM_CHAIN_ID) {
            whitelistedTokens = new address[](1);
            whitelistedTokens[0] = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // USDC
        }

        if (chainId_ == SEPOLIA_CHAIN_ID) {
            whitelistedTokens = new address[](2);
            whitelistedTokens[0] = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // USDC
            whitelistedTokens[1] = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0; // USDT
        }

        if (chainId_ == SONEIUM_CHAIN_ID) {
            whitelistedTokens = new address[](1);
            whitelistedTokens[0] = 0xbA9986D2381edf1DA03B0B9c1f8b00dc4AacC369; // USDC.E (bridged)
        }

        return whitelistedTokens;
    }
}
