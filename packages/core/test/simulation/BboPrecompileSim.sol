// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {HyperCore} from "@hyper-evm-lib/test/simulation/HyperCore.sol";

contract BboPrecompileSim {
    HyperCore constant hyperCore = HyperCore(payable(0x9999999999999999999999999999999999999999));

    // Store BBO prices for each asset
    mapping(uint64 => uint64) public bids;
    mapping(uint64 => uint64) public asks;

    // Store whether an asset should use spot or mark price
    mapping(uint64 => bool) public isSpot;
    mapping(uint64 => bool) public isPriceSet;

    // Function to set BBO for an asset
    function setBbo(uint64 assetId, uint64 bid, uint64 ask) public {
        bids[assetId] = bid;
        asks[assetId] = ask;
        isPriceSet[assetId] = true;
    }

    // Function to map an asset to spot price
    function setAsSpot(uint64 assetId) public {
        isSpot[assetId] = true;
    }

    // Function to map an asset to mark price (perp)
    function setAsPerp(uint64 assetId) public {
        isSpot[assetId] = false;
    }

    // Fallback function that handles BBO calls
    fallback() external payable {
        // Decode the asset ID from calldata
        uint64 assetId = abi.decode(msg.data, (uint64));

        uint64 bid;
        uint64 ask;

        // Check if we have prices set for this asset
        if (isPriceSet[assetId]) {
            bid = bids[assetId];
            ask = asks[assetId];
        } else {
            // Try to get from HyperCore based on whether it's spot or perp
            uint64 price;
            if (isSpot[assetId]) {
                price = hyperCore.readSpotPx(uint32(assetId));
            } else {
                price = hyperCore.readMarkPx(uint32(assetId));
            }

            // If still no price, use default
            if (price == 0) {
                price = 100000000; // $1.00 default
            }

            // Create a small spread around the price
            bid = price - ((price * 10) / 10000); // 0.1% below
            ask = price + ((price * 10) / 10000); // 0.1% above
        }

        // Return encoded Bbo struct
        bytes memory result = abi.encode(bid, ask);

        assembly {
            return(add(result, 32), mload(result))
        }
    }
}