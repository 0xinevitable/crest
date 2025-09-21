// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { CrestManager } from "../../src/CrestManager.sol";
import { CrestVault } from "../../src/CrestVault.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";

contract TestCrestManager is CrestManager {
    constructor(
        address _vault,
        address _owner,
        address _curator,
        address _feeRecipient
    ) CrestManager(payable(_vault), _owner, _curator, _feeRecipient) {}

    // Override price functions to use spotPx/markPx for testing
    function _getMarketPrices(uint32 spotIndex, uint32 perpIndex) internal view override returns (uint64 spotPrice, uint64 perpPrice) {
        // Use spotPx/markPx with slippage for testing
        spotPrice = PrecompileLib.spotPx(uint64(spotIndex));
        spotPrice = spotPrice + ((spotPrice * 100) / 10000); // Add 1% for market buy

        perpPrice = PrecompileLib.markPx(perpIndex);
        perpPrice = perpPrice - ((perpPrice * 100) / 10000); // Subtract 1% for market sell
    }

    function _getUsdt0BidPrice() internal view override returns (uint64) {
        return PrecompileLib.spotPx(uint64(usdt0SpotIndex()));
    }

    function _getUsdt0AskPrice() internal view override returns (uint64) {
        return PrecompileLib.spotPx(uint64(usdt0SpotIndex()));
    }

    function _getSpotBidPrice(uint32 spotIndex) internal view override returns (uint64) {
        return PrecompileLib.spotPx(uint64(spotIndex));
    }

    function _getPerpAskPrice(uint32 perpIndex) internal view override returns (uint64) {
        return PrecompileLib.markPx(perpIndex);
    }

    function _getSpotMidPrice(uint32 spotIndex) internal view override returns (uint64) {
        return PrecompileLib.spotPx(uint64(spotIndex));
    }

    function _getPerpMidPrice(uint32 perpIndex) internal view override returns (uint64) {
        return PrecompileLib.markPx(perpIndex);
    }
}