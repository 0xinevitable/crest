// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { PrecompileLib } from '@hyper-evm-lib/src/PrecompileLib.sol';

library CustomPrecompileLib {
    struct NormalizedBbo {
        uint256 bid;
        uint256 ask;
    }

    // Returns normalized BBO for spot markets with appropriate decimals
    function normalizedSpotBbo(
        uint64 spotIndex
    ) internal view returns (NormalizedBbo memory) {
        PrecompileLib.Bbo memory bboPrices = PrecompileLib.bbo(spotIndex);
        PrecompileLib.SpotInfo memory info = PrecompileLib.spotInfo(spotIndex);
        uint8 baseSzDecimals = PrecompileLib
            .tokenInfo(info.tokens[0])
            .szDecimals;

        return
            NormalizedBbo({
                bid: bboPrices.bid * 10 ** baseSzDecimals,
                ask: bboPrices.ask * 10 ** baseSzDecimals
            });
    }

    // Returns normalized BBO for perp markets with appropriate decimals
    function normalizedPerpBbo(
        uint32 perpIndex
    ) internal view returns (NormalizedBbo memory) {
        PrecompileLib.Bbo memory bboPrices = PrecompileLib.bbo(
            uint64(perpIndex)
        );
        PrecompileLib.PerpAssetInfo memory info = PrecompileLib.perpAssetInfo(
            perpIndex
        );

        return
            NormalizedBbo({
                bid: bboPrices.bid * 10 ** info.szDecimals,
                ask: bboPrices.ask * 10 ** info.szDecimals
            });
    }
}
