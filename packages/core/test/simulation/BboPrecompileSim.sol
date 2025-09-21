// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {HyperCore} from "@hyper-evm-lib/test/simulation/HyperCore.sol";

contract BboPrecompileSim {
    HyperCore constant hyperCore = HyperCore(payable(0x9999999999999999999999999999999999999999));

    // Fallback function that handles BBO calls
    fallback() external payable {
        // Decode the asset ID from calldata
        uint64 assetId = abi.decode(msg.data, (uint64));

        uint64 bid;
        uint64 ask;

        // Determine if it's a spot or perp based on index ranges
        // Based on test constants:
        // - Spot indices are typically < 150 (e.g., HYPE_SPOT_INDEX = 107)
        // - Perp indices are typically >= 150 (e.g., HYPE_PERP_INDEX = 159)
        if (assetId < 150) {
            // It's a spot index
            uint64 spotPx = hyperCore.readSpotPx(uint32(assetId));
            // If price is 0, use a default
            if (spotPx == 0) {
                spotPx = 100000000; // $1.00 default
            }
            // Create a small spread around the spot price
            bid = spotPx - ((spotPx * 10) / 10000); // 0.1% below
            ask = spotPx + ((spotPx * 10) / 10000); // 0.1% above
        } else if (assetId < 10000) {
            // It's a perp index
            uint64 markPx = hyperCore.readMarkPx(uint32(assetId));
            // If price is 0, use a default
            if (markPx == 0) {
                markPx = 100000000; // $1.00 default
            }
            // Create a small spread around the mark price
            bid = markPx - ((markPx * 10) / 10000); // 0.1% below
            ask = markPx + ((markPx * 10) / 10000); // 0.1% above
        } else {
            // For asset IDs >= 10000, these might be special BBO requests
            // In Hyperliquid, BBO for perps might use assetId = spotIndex + 10000
            uint32 perpIndex = uint32(assetId - 10000);
            uint64 markPx = hyperCore.readMarkPx(perpIndex);
            if (markPx == 0) {
                markPx = 100000000; // $1.00 default
            }
            bid = markPx - ((markPx * 10) / 10000); // 0.1% below
            ask = markPx + ((markPx * 10) / 10000); // 0.1% above
        }

        // Return encoded Bbo struct
        bytes memory result = abi.encode(bid, ask);

        assembly {
            return(add(result, 32), mload(result))
        }
    }
}