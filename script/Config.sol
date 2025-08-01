// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Vm } from "forge-std/Vm.sol";

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
        address blacklistManager;
        address yieldRecipientManager;
    }

    // Mainnet chain IDs
    uint256 public constant ETHEREUM_CHAIN_ID = 1;
    uint256 public constant ARBITRUM_CHAIN_ID = 42161;
    uint256 public constant OPTIMISM_CHAIN_ID = 10;

    // Testnet chain IDs
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;

    address public constant M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address public constant WRAPPED_M_TOKEN = 0x437cc33344a0B27A429f795ff6B469C72698B291;
    address public constant REGISTRAR = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;

    address public constant UNISWAP_ROUTER_ETHEREUM = address(0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af);
    address public constant UNISWAP_ROUTER_ARBITRUM = address(0xA51afAFe0263b40EdaEf0Df8781eA9aa03E381a3);
    address public constant UNISWAP_ROUTER_OPTIMISM = address(0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507);

    address public constant UNISWAP_ROUTER_SEPOLIA = address(0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b);
    address public constant UNISWAP_ROUTER_ARBITRUM_SEPOLIA = address(0xeFd1D4bD4cf1e86Da286BB4CB1B8BcED9C10BA47);

    address public constant WHITELISTED_TOKEN_0_ETHEREUM = address(0);
    address public constant WHITELISTED_TOKEN_1_ETHEREUM = address(0);

    address public constant WHITELISTED_TOKEN_0_SEPOLIA = address(M_TOKEN);
    address public constant WHITELISTED_TOKEN_1_SEPOLIA = address(WRAPPED_M_TOKEN);

    function _getDeployConfig(uint256 chainId_) internal pure returns (DeployConfig memory) {
        DeployConfig memory config;

        // Mainnet configs
        if (chainId_ == ETHEREUM_CHAIN_ID) {
            config.mToken = M_TOKEN;
            config.wrappedMToken = WRAPPED_M_TOKEN;
            config.registrar = REGISTRAR;
            config.uniswapV3Router = UNISWAP_ROUTER_ETHEREUM;
            config.admin = address(0);
            return config;
        }

        if (chainId_ == ARBITRUM_CHAIN_ID) {
            config.mToken = M_TOKEN;
            config.wrappedMToken = WRAPPED_M_TOKEN;
            config.registrar = REGISTRAR;
            config.uniswapV3Router = UNISWAP_ROUTER_ARBITRUM;
            config.admin = address(0);
            return config;
        }

        if (chainId_ == OPTIMISM_CHAIN_ID) {
            config.mToken = M_TOKEN;
            config.wrappedMToken = WRAPPED_M_TOKEN;
            config.registrar = REGISTRAR;
            config.uniswapV3Router = UNISWAP_ROUTER_OPTIMISM;
            config.admin = address(0);
            return config;
        }

        // Testnet configs
        if (chainId_ == LOCAL_CHAIN_ID) {
            config.mToken = M_TOKEN;
            config.wrappedMToken = WRAPPED_M_TOKEN;
            config.registrar = REGISTRAR;
            config.uniswapV3Router = UNISWAP_ROUTER_ETHEREUM;
            config.admin = address(0);
            return config;
        }

        if (chainId_ == SEPOLIA_CHAIN_ID) {
            config.mToken = M_TOKEN;
            config.wrappedMToken = WRAPPED_M_TOKEN;
            config.registrar = REGISTRAR;
            config.uniswapV3Router = UNISWAP_ROUTER_SEPOLIA;
            config.admin = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
            return config;
        }

        if (chainId_ == ARBITRUM_SEPOLIA_CHAIN_ID) {
            config.mToken = M_TOKEN;
            config.wrappedMToken = WRAPPED_M_TOKEN;
            config.registrar = REGISTRAR;
            config.uniswapV3Router = UNISWAP_ROUTER_ARBITRUM_SEPOLIA;
            config.admin = address(0);
            return config;
        }

        revert UnsupportedChain(chainId_);
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
                config.blacklistManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
                config.yieldRecipientManager = 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217;
            }
        }
    }

    function _getWhitelistedTokens(uint256 chainId_) internal view returns (address[] memory whitelistedTokens) {
        whitelistedTokens = new address[](2);

        if (chainId_ == ETHEREUM_CHAIN_ID) {
            whitelistedTokens[0] = WHITELISTED_TOKEN_0_ETHEREUM;
            whitelistedTokens[1] = WHITELISTED_TOKEN_1_ETHEREUM;
        }

        if (chainId_ == SEPOLIA_CHAIN_ID) {
            whitelistedTokens[0] = WHITELISTED_TOKEN_0_SEPOLIA;
            whitelistedTokens[1] = WHITELISTED_TOKEN_1_SEPOLIA;
        }

        return whitelistedTokens;
    }
}
