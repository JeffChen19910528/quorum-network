#!/bin/bash

# Improved script to set up and start Quorum nodes using Docker

set -e

# Function to check if a port is in use
is_port_in_use() {
    lsof -i:$1 >/dev/null 2>&1
}

# Function to find next available port
find_next_port() {
    local port=$1
    while is_port_in_use $port; do
        echo "Port $port is in use, trying next one." >&2
        port=$((port + 1))
    done
    echo $port
}

# Function to create necessary files for a node
create_node_files() {
    local node_name=$1
    local http_port=$2

    mkdir -p $node_name

    # Create genesis.json
    cat > $node_name/genesis.json <<EOF
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

    # Append to docker-compose.yml
    cat >> docker-compose.yml <<EOF
  $node_name:
    build: .
    volumes:
      - ./$node_name:/qdata
    ports:
      - "$http_port:22000"
    environment:
      - NODENAME=$node_name
      - QUORUM_NETWORK_ID=10
    networks:
      - quorum-network

EOF
}

# Create Dockerfile
cat > Dockerfile <<EOF
FROM ethereum/client-go:latest

RUN apk add --no-cache bash curl

COPY start-node.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-node.sh

ENTRYPOINT ["start-node.sh"]
EOF

# Create start-node.sh
cat > start-node.sh <<EOF
#!/bin/bash

# Initialize the node if not already initialized
if [ ! -d /qdata/geth/chaindata ]; then
    echo "Initializing node \${NODENAME}..."
    geth --datadir /qdata init /qdata/genesis.json
fi

# Check if account exists, if not create one
if [ ! -d /qdata/keystore ] || [ -z "\$(ls -A /qdata/keystore)" ]; then
    echo "Creating new account for \${NODENAME}..."
    geth --datadir /qdata account new --password <(echo "password") | grep -o '0x[0-9a-fA-F]\+' > /qdata/account.txt
fi

ACCOUNT=\$(cat /qdata/account.txt)

# Start the node
exec geth --datadir /qdata \\
    --networkid \${QUORUM_NETWORK_ID} \\
    --nodiscover \\
    --verbosity 5 \\
    --syncmode full \\
    --mine \\
    --miner.threads 1 \\
    --miner.gasprice 0 \\
    --emitcheckpoints \\
    --http \\
    --http.addr 0.0.0.0 \\
    --http.port 22000 \\
    --http.api admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum \\
    --unlock \${ACCOUNT} \\
    --allow-insecure-unlock \\
    --password <(echo "password")
EOF

chmod +x start-node.sh

# Start docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'

services:
EOF

# Create files for each node
base_port=22000
for i in {1..3}; do
    node_name="node$i"
    port=$(find_next_port $base_port)
    create_node_files $node_name $port
    base_port=$((port + 1))
done

# Finish docker-compose.yml
cat >> docker-compose.yml <<EOF

networks:
  quorum-network:
    driver: bridge
EOF

# Function to clean up
cleanup() {
    echo "Cleaning up..."
    docker-compose down -v || true
    docker rm -f $(docker ps -a -q --filter name=quorum-network_node) 2>/dev/null || true
    docker rmi -f $(docker images -q --filter reference='quorum-network_node*') 2>/dev/null || true
    sudo rm -rf Dockerfile docker-compose.yml start-node.sh node* || true
}

# Start the nodes
if docker-compose up -d; then
    echo "Quorum nodes have been started. Use 'docker-compose logs -f' to view logs."
else
    echo "Error starting Quorum nodes. Cleaning up..."
    cleanup
    exit 1
fi

# Set trap to clean up on script exit
trap cleanup EXIT

echo "Press Ctrl+C to stop the nodes and clean up."
read -r -d '' _ </dev/tty