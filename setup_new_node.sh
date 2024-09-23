#!/bin/bash

# Quorum New Node Setup Script

# Check if geth is installed
if ! command -v geth &> /dev/null
then
    echo "geth could not be found. Please install Quorum first."
    exit 1
fi

# Function to create genesis.json
create_genesis_json() {
    cat << EOF > genesis.json
{
  "alloc": {},
  "coinbase": "0x0000000000000000000000000000000000000000",
  "config": {
    "homesteadBlock": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "chainId": 10,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "eip158Block": 0,
    "isQuorum": true,
    "qbft": {
      "epochLength": 30000,
      "blockPeriodSeconds": 5
    }
  },
  "difficulty": "0x1",
  "extraData": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "gasLimit": "0xE0000000",
  "mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "nonce": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp": "0x00"
}
EOF
}

# Get node name from user
read -p "Enter the name for the new node: " NODE_NAME

# Create directory for the new node
mkdir -p $NODE_NAME
cd $NODE_NAME

# Create genesis.json
echo "Creating genesis.json..."
create_genesis_json

# Initialize the node
echo "Initializing the node..."
geth --datadir . init genesis.json

# Create a new account
echo "Creating a new account..."
ACCOUNT=$(geth --datadir . account new --password <(echo "password") | grep -o '0x[0-9a-fA-F]\+')
echo "New account created: $ACCOUNT"

# Start the node
echo "Starting the node..."
nohup geth --datadir . --networkid 10 --nodiscover --verbosity 5 --syncmode full --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints --http --http.addr 0.0.0.0 --http.port 22000 --http.api admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum --unlock $ACCOUNT --allow-insecure-unlock --password <(echo "password") > geth.log 2>&1 &

echo "Node $NODE_NAME is now running in the background. You can check the logs with 'tail -f geth.log'"
echo "To attach to this node, use: geth attach ipc:$PWD/geth.ipc"