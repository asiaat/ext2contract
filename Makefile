-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

build:; forge build

test :; forge test 

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRV_KEY) --broadcast  -vvvv
endif

SEPOLIA := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRV_KEY) --broadcast  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
GOERLI := --rpc-url $(GOERLI_RPC_URL) --private-key $(GOERLI_PRV_KEY) --broadcast  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
MUMBAI := --rpc-url $(MUMBAI_RPC_URL) --private-key $(MUMBAI_PRV_KEY) --broadcast  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
POLYGON := --rpc-url $(POLYGON_RPC_URL) --private-key $(POLYGON_PRV_KEY) --broadcast  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv


deploy:
	@forge script script/DeployChromaticEvo.s.sol:DeployChromaticEvo  $(NETWORK_ARGS)

deploySepolia: 
	@forge script script/DeployExt2Contract.s.sol:DeployExt2Contract $(SEPOLIA)

deployGoerli0: 
	@forge script script/DeployExt2Contract.s.sol:DeployExt2Contract $(GOERLI)

goerli: 
	@forge script script/DeployChromaticEvo.s.sol:DeployChromaticEvo $(GOERLI)

deployMumbai0: 
	@forge script script/DeployExt2Contract.s.sol:DeployExt2Contract $(MUMBAI)

mumbai: 
	@forge script script/DeployChromaticEvo.s.sol:DeployChromaticEvo $(MUMBAI)

polygon: 
	@forge script script/DeployChromaticEvolution.s.sol:DeployChromaticEvolution $(POLYGON) --gas-price 200000
