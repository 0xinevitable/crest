// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract MockBboPrecompile {
    // Store BBO data for different assets
    mapping(uint64 => uint64) public bids;
    mapping(uint64 => uint64) public asks;

    // Set BBO for testing
    function setBbo(uint64 assetId, uint64 bid, uint64 ask) external {
        bids[assetId] = bid;
        asks[assetId] = ask;
    }

    // Fallback function that handles BBO calls
    fallback() external payable {
        // Decode the asset ID from calldata
        uint64 assetId = abi.decode(msg.data, (uint64));

        // Get stored bid/ask
        uint64 bid = bids[assetId];
        uint64 ask = asks[assetId];

        // If not set, use hardcoded values for the test
        if (bid == 0 && ask == 0) {
            // Hardcode expected prices for the test
            // HYPE_SPOT_INDEX = 107, expecting 10000 * 1e8
            // HYPE_PERP_INDEX = 159, expecting 10050 * 1e8

            if (assetId == 107) {
                // HYPE spot - $10,000 with 0.1% spread
                bid = 1000000000000 - 1000000000; // $10,000 - 0.1%
                ask = 1000000000000 + 1000000000; // $10,000 + 0.1%
            } else if (assetId == 159) {
                // HYPE perp - $10,050 with 0.1% spread
                bid = 1005000000000 - 1005000000; // $10,050 - 0.1%
                ask = 1005000000000 + 1005000000; // $10,050 + 0.1%
            } else if (assetId == 166) {
                // USDT0/USDC spot - $1.00 with 0.1% spread
                bid = 100000000 - 100000; // $1.00 - 0.1%
                ask = 100000000 + 100000; // $1.00 + 0.1%
            } else {
                // Default for other assets - $1.00
                bid = 100000000 - 100000;
                ask = 100000000 + 100000;
            }
        }

        // Return encoded Bbo struct
        bytes memory result = abi.encode(bid, ask);

        assembly {
            return(add(result, 32), mload(result))
        }
    }
}