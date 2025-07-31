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

    address public constant WHITELISTED_TOKEN_0_SEPOLIA = address(0);
    address public constant WHITELISTED_TOKEN_1_SEPOLIA = address(0);

    function _getDeployConfig(uint256 chainId_) internal pure returns (DeployConfig memory) {
        // Mainnet configs
        if (chainId_ == ETHEREUM_CHAIN_ID)
            return
                DeployConfig({
                    mToken: M_TOKEN,
                    wrappedMToken: WRAPPED_M_TOKEN,
                    registrar: REGISTRAR,
                    uniswapV3Router: UNISWAP_ROUTER_ETHEREUM
                });

        if (chainId_ == ARBITRUM_CHAIN_ID)
            return
                DeployConfig({
                    mToken: M_TOKEN,
                    wrappedMToken: WRAPPED_M_TOKEN,
                    registrar: REGISTRAR,
                    uniswapV3Router: UNISWAP_ROUTER_ARBITRUM
                });

        if (chainId_ == OPTIMISM_CHAIN_ID)
            return
                DeployConfig({
                    mToken: M_TOKEN,
                    wrappedMToken: WRAPPED_M_TOKEN,
                    registrar: REGISTRAR,
                    uniswapV3Router: UNISWAP_ROUTER_OPTIMISM
                });

        // Testnet configs
        if (chainId_ == LOCAL_CHAIN_ID)
            return
                DeployConfig({
                    mToken: M_TOKEN,
                    wrappedMToken: WRAPPED_M_TOKEN,
                    registrar: REGISTRAR,
                    uniswapV3Router: UNISWAP_ROUTER_ETHEREUM
                });

        if (chainId_ == SEPOLIA_CHAIN_ID)
            return
                DeployConfig({
                    mToken: M_TOKEN,
                    wrappedMToken: WRAPPED_M_TOKEN,
                    registrar: REGISTRAR,
                    uniswapV3Router: UNISWAP_ROUTER_SEPOLIA
                });

        if (chainId_ == ARBITRUM_SEPOLIA_CHAIN_ID)
            return
                DeployConfig({
                    mToken: M_TOKEN,
                    wrappedMToken: WRAPPED_M_TOKEN,
                    registrar: REGISTRAR,
                    uniswapV3Router: UNISWAP_ROUTER_ARBITRUM_SEPOLIA
                });

        revert UnsupportedChain(chainId_);
    }

    function _getExtensionConfig(string memory name) internal pure returns (DeployExtensionConfig memory config) {
        if (keccak256(bytes(name)) == keccak256(bytes("MEarnerManagerTestnet"))) {
            config.name = name;
            config.symbol = "M0EMTest";
            config.admin = address(0);
            config.earnerManager = address(0);
            config.feeRecipient = address(0);
        }

        if (keccak256(bytes(name)) == keccak256(bytes("MYieldToAllTestnet"))) {
            config.name = name;
            config.symbol = "M0YTATest";
            config.admin = address(0);
            config.feeRate = 1000;
            config.feeRecipient = address(0);
            config.feeManager = address(0);
            config.claimRecipientManager = address(0);
        }

        if (keccak256(bytes(name)) == keccak256(bytes("MYieldToOneTestnet"))) {
            config.name = name;
            config.symbol = "M0YTOTest";
            config.admin = address(1);
            config.yieldRecipient = address(2);
            config.blacklistManager = address(3);
            config.yieldRecipientManager = address(4);
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
