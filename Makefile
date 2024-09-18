-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

ANVIL_PRIVATE_KEY_0 := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

clean  :; forge clean

remove :; rm -rf dependencies/ && rm soldeer.lock

install :; forge soldeer install

update:; forge soldeer update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

ANVIL_NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_0) --broadcast

SEPOLIA_NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := $(SEPOLIA_NETWORK_ARGS)
else
	NETWORK_ARGS := $(ANVIL_NETWORK_ARGS)
endif

deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)

checkEtherscanApi:
	@response_mainnet=$$(curl -s "https://api.etherscan.io/api?module=account&action=balance&address=$(PUBLIC_KEY_DEV)&tag=latest&apikey=$(ETHERSCAN_API_KEY)"); \
	echo "Mainnet:" $$response_mainnet; \
	response_sepolia=$$(curl -s "https://api-sepolia.etherscan.io/api?module=account&action=balance&address=$(PUBLIC_KEY_DEV)&tag=latest&apikey=$(ETHERSCAN_API_KEY)"); \
	echo "Sepolia:" $$response_sepolia;
