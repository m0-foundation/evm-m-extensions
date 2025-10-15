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

# Deploy tasks
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

deploy-swap-adapter:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeploySwapAdapter.s.sol:DeploySwapAdapter \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-swap-adapter-mainnet: RPC_URL=$(MAINNET_RPC_URL)
deploy-swap-adapter-mainnet: deploy-swap-adapter

deploy-swap-adapter-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-swap-adapter-sepolia: deploy-swap-adapter

deploy-swap-facility:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/DeploySwapFacility.s.sol:DeploySwapFacility \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-swap-facility-mainnet: RPC_URL=$(MAINNET_RPC_URL)
deploy-swap-facility-mainnet: deploy-swap-facility

deploy-swap-facility-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-swap-facility-sepolia: deploy-swap-facility

deploy-usdz:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/deploy/vendor/braid/DeployUSDZ.s.sol:DeployUSDZ \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-usdz-local: RPC_URL=$(LOCALHOST_RPC_URL)
deploy-usdz-local: deploy-usdz

deploy-usdz-mainnet: RPC_URL=$(MAINNET_RPC_URL)
deploy-usdz-mainnet: deploy-usdz

deploy-usdz-arbitrum: RPC_URL=$(ARBITRUM_RPC_URL)
deploy-usdz-arbitrum: deploy-usdz

# Upgrade tasks
upgrade-swap-facility:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/upgrade/UpgradeSwapFacility.s.sol:UpgradeSwapFacility \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast

upgrade-swap-facility-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
upgrade-swap-facility-sepolia: upgrade-swap-facility

