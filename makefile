CHAIN_ID_MAINNET := 1
RPC_URL_MAINNET := https://mainnet.infura.io/v3/d67c7cf47bfb4b6ebee10029ca0ba0dd

test:
	forge test -vvv 

build:
	forge build -vvv

clean:
	rm -rf broadcast out cache

node:
	anvil --chain-id 1337 # -b 2

test-flash-loans:
	forge test -vv --fork-url $(RPC_URL_MAINNET) --fork-block-number 16715630
