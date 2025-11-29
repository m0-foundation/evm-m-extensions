# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# dapp deps
update:; forge update

# Deployment helpers
deploy-local :; FOUNDRY_PROFILE=production forge script script/Deploy.s.sol --rpc-url localhost --broadcast -v
deploy-sepolia :; FOUNDRY_PROFILE=production forge script script/Deploy.s.sol --rpc-url sepolia --broadcast -vvv

# Run slither
slither :; FOUNDRY_PROFILE=production forge build --build-info --skip '*/test/**' --skip '*/script/**' --force && slither --compile-force-framework foundry --ignore-compile --sarif results.sarif --config-file slither.config.json .

# Common tasks
profile ?=default

build:
	@./build.sh -p production

tests:
	@./test.sh -p $(profile)

fuzz:
	@./test.sh -t testFuzz -p $(profile)

integration:
	@./test.sh -d test/integration -p $(profile)

invariant:
	@./test.sh -d test/invariant -p $(profile)

coverage:
	FOUNDRY_PROFILE=$(profile) forge coverage --report lcov && lcov --extract lcov.info -o lcov.info 'src/*' --ignore-errors inconsistent && genhtml lcov.info -o coverage

gas-report:
	FOUNDRY_PROFILE=$(profile) forge test --force --gas-report > gasreport.ansi

sizes:
	@./build.sh -p production -s

clean:
	forge clean && rm -rf ./abi && rm -rf ./bytecode && rm -rf ./types


deploy-yield-to-one:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) EXTENSION_NAME=$(EXTENSION_NAME) \
	forge script script/deploy/DeployYieldToOne.s.sol:DeployYieldToOne \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-yield-to-one-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-yield-to-one-sepolia: deploy-yield-to-one

deploy-yield-to-all:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) EXTENSION_NAME=$(EXTENSION_NAME) \
	forge script script/deploy/DeployYieldToAllWithFee.s.sol:DeployYeildToAllWithFee \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-yield-to-all-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-yield-to-all-sepolia: deploy-yield-to-all

deploy-m-earner-manager:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) EXTENSION_NAME=$(EXTENSION_NAME) \
	forge script script/deploy/DeployMEarnerManager.s.sol:DeployMEarnerManager \
	--private-key $(PRIVATE_KEY) \
	--rpc-url $(RPC_URL) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-m-earner-manager-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-m-earner-manager-sepolia: deploy-m-earner-manager

deploy-jmi-extension:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) EXTENSION_NAME=$(EXTENSION_NAME) \
	forge script script/deploy/DeployJMIExtension.s.sol:DeployJMIExtension \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-jmi-extension-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-jmi-extension-sepolia: deploy-jmi-extension 

deploy-swap-adapter:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeploySwapAdapter.s.sol:DeploySwapAdapter \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive \
	--broadcast --verify --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL}

deploy-swap-adapter-local: RPC_URL=$(LOCALHOST_RPC_URL)
deploy-swap-adapter-local: deploy-swap-adapter

deploy-swap-adapter-mainnet: RPC_URL=$(MAINNET_RPC_URL)
deploy-swap-adapter-mainnet: VERIFIER="etherscan"
deploy-swap-adapter-mainnet: VERIFIER_URL=${MAINNET_VERIFIER_URL}
deploy-swap-adapter-mainnet: deploy-swap-adapter

deploy-swap-adapter-arbitrum: RPC_URL=$(ARBITRUM_RPC_URL)
deploy-swap-adapter-arbitrum: VERIFIER="etherscan"
deploy-swap-adapter-arbitrum: VERIFIER_URL=${ARBITRUM_VERIFIER_URL}
deploy-swap-adapter-arbitrum: deploy-swap-adapter

deploy-swap-adapter-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-swap-adapter-sepolia: VERIFIER="etherscan"
deploy-swap-adapter-sepolia: VERIFIER_URL=${SEPOLIA_VERIFIER_URL}
deploy-swap-adapter-sepolia: deploy-swap-adapter

deploy-swap-adapter-soneium: RPC_URL=$(SONEIUM_RPC_URL)
deploy-swap-adapter-soneium: VERIFIER="blockscout"
deploy-swap-adapter-soneium: VERIFIER_URL=${SONEIUM_VERIFIER_URL}
deploy-swap-adapter-soneium: deploy-swap-adapter

deploy-swap-facility:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) PAUSER=$(PAUSER) \
	forge script script/deploy/DeploySwapFacility.s.sol:DeploySwapFacility \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive -v \
	--broadcast --verify --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL}

deploy-swap-facility-local: RPC_URL=$(LOCALHOST_RPC_URL)
deploy-swap-facility-local: deploy-swap-facility

deploy-swap-facility-mainnet: RPC_URL=$(MAINNET_RPC_URL)
deploy-swap-facility-mainnet: VERIFIER="etherscan"
deploy-swap-facility-mainnet: VERIFIER_URL=${MAINNET_VERIFIER_URL}
deploy-swap-facility-mainnet: deploy-swap-facility

deploy-swap-facility-arbitrum: RPC_URL=$(ARBITRUM_RPC_URL)
deploy-swap-facility-arbitrum: VERIFIER="etherscan"
deploy-swap-facility-arbitrum: VERIFIER_URL=${ARBITRUM_VERIFIER_URL}
deploy-swap-facility-arbitrum: deploy-swap-facility

deploy-swap-facility-optimism: RPC_URL=$(OPTIMISM_RPC_URL)
deploy-swap-facility-optimism: VERIFIER="etherscan"
deploy-swap-facility-optimism: VERIFIER_URL=${OPTIMISM_VERIFIER_URL}
deploy-swap-facility-optimism: deploy-swap-facility

deploy-swap-facility-hyperliquid: RPC_URL=$(HYPERLIQUID_RPC_URL)
deploy-swap-facility-hyperliquid: VERIFIER="etherscan"
deploy-swap-facility-hyperliquid: VERIFIER_URL=${HYPERLIQUID_VERIFIER_URL}
deploy-swap-facility-hyperliquid: deploy-swap-facility

deploy-swap-facility-plume: RPC_URL=$(PLUME_RPC_URL)
deploy-swap-facility-plume: VERIFIER="blockscout"
deploy-swap-facility-plume: VERIFIER_URL=${PLUME_VERIFIER_URL}
deploy-swap-facility-plume: deploy-swap-facility

deploy-swap-facility-bsc: RPC_URL=$(BSC_RPC_URL)
deploy-swap-facility-bsc: VERIFIER="etherscan"
deploy-swap-facility-bsc: VERIFIER_URL=${BSC_VERIFIER_URL}
deploy-swap-facility-bsc: deploy-swap-facility

deploy-swap-facility-mantra: RPC_URL=$(MANTRA_RPC_URL)
deploy-swap-facility-mantra: VERIFIER="blockscout"
deploy-swap-facility-mantra: VERIFIER_URL=${MANTRA_VERIFIER_URL}
deploy-swap-facility-mantra: deploy-swap-facility

deploy-swap-facility-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-swap-facility-sepolia: VERIFIER="etherscan"
deploy-swap-facility-sepolia: VERIFIER_URL=${SEPOLIA_VERIFIER_URL}
deploy-swap-facility-sepolia: deploy-swap-facility

deploy-swap-facility-arbitrum-sepolia: RPC_URL=$(ARBITRUM_SEPOLIA_RPC_URL)
deploy-swap-facility-arbitrum-sepolia: VERIFIER="etherscan"
deploy-swap-facility-arbitrum-sepolia: VERIFIER_URL=${ARBITRUM_SEPOLIA_VERIFIER_URL}
deploy-swap-facility-arbitrum-sepolia: deploy-swap-facility

deploy-swap-facility-optimism-sepolia: RPC_URL=$(OPTIMISM_SEPOLIA_RPC_URL)
deploy-swap-facility-optimism-sepolia: VERIFIER="etherscan"
deploy-swap-facility-optimism-sepolia: VERIFIER_URL=${OPTIMISM_SEPOLIA_VERIFIER_URL}
deploy-swap-facility-optimism-sepolia: deploy-swap-facility

deploy-swap-facility-apechain-testnet: RPC_URL=$(APECHAIN_TESTNET_RPC_URL)
deploy-swap-facility-apechain-testnet: VERIFIER="etherscan"
deploy-swap-facility-apechain-testnet: VERIFIER_URL=${APECHAIN_TESTNET_VERIFIER_URL}
deploy-swap-facility-apechain-testnet: deploy-swap-facility

deploy-swap-facility-bsc-testnet: RPC_URL=$(BSC_TESTNET_RPC_URL)
deploy-swap-facility-bsc-testnet: VERIFIER="etherscan"
deploy-swap-facility-bsc-testnet: VERIFIER_URL=${BSC_TESTNET_VERIFIER_URL}
deploy-swap-facility-bsc-testnet: deploy-swap-facility

deploy-swap-facility-soneium-testnet: RPC_URL=$(SONEIUM_TESTNET_RPC_URL)
deploy-swap-facility-soneium-testnet: VERIFIER="blockscout"
deploy-swap-facility-soneium-testnet: VERIFIER_URL=${SONEIUM_TESTNET_VERIFIER_URL}
deploy-swap-facility-soneium-testnet: deploy-swap-facility

deploy-swap-facility-base-sepolia: RPC_URL=$(BASE_SEPOLIA_RPC_URL)
deploy-swap-facility-base-sepolia: VERIFIER="etherscan"
deploy-swap-facility-base-sepolia: VERIFIER_URL=${BASE_SEPOLIA_VERIFIER_URL}
deploy-swap-facility-base-sepolia: deploy-swap-facility

deploy-swap-facility-base: RPC_URL=$(BASE_RPC_URL)
deploy-swap-facility-base: VERIFIER="etherscan"
deploy-swap-facility-base: VERIFIER_URL=${BASE_VERIFIER_URL}
deploy-swap-facility-base: deploy-swap-facility

deploy-swap-facility-soneium: RPC_URL=$(SONEIUM_RPC_URL)
deploy-swap-facility-soneium: VERIFIER="blockscout"
deploy-swap-facility-soneium: VERIFIER_URL=${SONEIUM_VERIFIER_URL}
deploy-swap-facility-soneium: deploy-swap-facility

upgrade-swap-facility:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) PAUSER=$(PAUSER) \
	forge script script/upgrade/UpgradeSwapFacility.s.sol:UpgradeSwapFacility \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast

upgrade-swap-facility-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
upgrade-swap-facility-sepolia: upgrade-swap-facility

propose-transfer-swap-facility-owner:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/ProposeTransferSwapFacilityOwner.s.sol:ProposeTransferSwapFacilityOwner \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast

propose-transfer-swap-facility-owner-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
propose-transfer-swap-facility-owner-sepolia: propose-transfer-swap-facility-owner

propose-transfer-swap-facility-owner-mainnet: RPC_URL=$(MAINNET_RPC_URL)
propose-transfer-swap-facility-owner-mainnet: propose-transfer-swap-facility-owner

propose-transfer-swap-facility-owner-bsc: RPC_URL=$(BSC_RPC_URL)
propose-transfer-swap-facility-owner-bsc: propose-transfer-swap-facility-owner

propose-transfer-swap-facility-owner-linea: RPC_URL=$(LINEA_RPC_URL)
propose-transfer-swap-facility-owner-linea: propose-transfer-swap-facility-owner