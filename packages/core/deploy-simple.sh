#!/bin/bash

# Load environment variables
source .env

# Check required environment variables
if [[ -z "$PRIVATE_KEY" ]]; then
    echo "Error: PRIVATE_KEY is not set in .env"
    exit 1
fi

if [[ -z "$CURATOR_ADDRESS" ]]; then
    echo "Error: CURATOR_ADDRESS is not set in .env"
    exit 1
fi

if [[ -z "$FEE_RECIPIENT_ADDRESS" ]]; then
    echo "Error: FEE_RECIPIENT_ADDRESS is not set in .env"
    exit 1
fi

# Set RPC URL
RPC_URL=${1:-"https://evmrpc-jp.hyperpc.app/2a850a8987744037bc1fce0b59f22e1b"}

echo "🚀 Deploying Crest Diamond (Simple) to $RPC_URL"
echo "Curator: $CURATOR_ADDRESS"
echo "Fee Recipient: $FEE_RECIPIENT_ADDRESS"
echo ""

# Run deployment
forge script script/DeployDiamondSimple.s.sol \
    --rpc-url $RPC_URL \
    --broadcast \
    --via-ir \
    -vvvv

echo ""
echo "✅ Deployment complete!"