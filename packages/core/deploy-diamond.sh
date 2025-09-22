#!/bin/bash

# Load environment variables
source .env

# Check required environment variables
if [[ -z "$PRIVATE_KEY" ]]; then
    echo "Error: PRIVATE_KEY is not set in .env"
    exit 1
fi

if [[ -z "$USDT0_ADDRESS" ]]; then
    echo "Error: USDT0_ADDRESS is not set in .env"
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

# Set default RPC if not provided
RPC_URL=${RPC_URL:-"https://998.rpc.hyperliquid.xyz"}

echo "🚀 Deploying Crest Diamond to $RPC_URL"
echo "Curator: $CURATOR_ADDRESS"
echo "Fee Recipient: $FEE_RECIPIENT_ADDRESS"
echo ""

# Check if FFI is enabled
if [[ "$1" == "--ffi" ]]; then
    echo "Using FFI deployment script..."
    forge script script/DeployDiamondWithFFI.s.sol \
        --rpc-url $RPC_URL \
        --broadcast \
        --verify \
        -vvvv
else
    echo "Using standard deployment script..."
    forge script script/DeployCrestDiamondV2.s.sol \
        --rpc-url $RPC_URL \
        --broadcast \
        --verify \
        -vvvv
fi

echo ""
echo "✅ Deployment complete!"