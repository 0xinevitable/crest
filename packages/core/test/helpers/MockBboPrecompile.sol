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

        // Get stored bid/ask or use defaults
        uint64 bid = bids[assetId];
        uint64 ask = asks[assetId];

        // If not set, return some default values
        if (bid == 0 && ask == 0) {
            // Default to 100 USD with small spread
            bid = 100 * 1e8 - 1e6;
            ask = 100 * 1e8 + 1e6;
        }

        // Return encoded Bbo struct
        bytes memory result = abi.encode(bid, ask);

        assembly {
            return(add(result, 32), mload(result))
        }
    }
}