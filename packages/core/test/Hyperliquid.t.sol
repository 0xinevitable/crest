// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";
import { CoreSimulatorLib } from "@hyper-evm-lib/test/simulation/CoreSimulatorLib.sol";
import { PrecompileSimulator } from "@hyper-evm-lib/test/utils/PrecompileSimulator.sol";

contract HyperliquidTest is Test {
    function setUp() public {
        vm.createSelectFork(
            "https://evmrpc-jp.hyperpc.app/44557a3c9a204f279070ded2023ed874"
        );

        // initialize the HyperCore simulator
        CoreSimulatorLib.init();
        PrecompileSimulator.init();
    }

    function test() public {
        address user = address(0x1);

        CoreSimulatorLib.forceAccountActivation(user);

        uint32 PERP_DEX_INDEX = 0;
        PrecompileLib.AccountMarginSummary memory summary = PrecompileLib
            .accountMarginSummary(PERP_DEX_INDEX, user);

        console.log("accountValue: %e", summary.accountValue);
        console.log("marginUsed: %e", summary.marginUsed);
        console.log("ntlPos: %e", summary.ntlPos);
        console.log("rawUsd: %e", summary.rawUsd);

        // query spot
        uint64 tokenIndex = 150; // HYPE
        uint64 spotIndex = PrecompileLib.getSpotIndex(tokenIndex);
        console.log("spotIndex:", spotIndex); // 107 (HYPE)

        PrecompileLib.SpotInfo memory spotInfo = PrecompileLib.spotInfo(
            spotIndex
        );
        console.log("spotInfo:", spotInfo.tokens[0], spotInfo.tokens[1]);
        // Output is [150 0] = HYPE/USDC (tokenIndex/quoteTokenIndex)

        uint256 normalizedSpotPx = PrecompileLib.normalizedSpotPx(spotIndex);
        console.log("normalizedSpotPx:", normalizedSpotPx); // with 8 decimals

        // query perps
        uint32 perpIndex = 159;
        PrecompileLib.PerpAssetInfo memory perpAssetInfo = PrecompileLib
            .perpAssetInfo(perpIndex);
        console.log("perpAssetInfo:", perpAssetInfo.coin); // HYPE

        uint256 normalizedMarkPx = PrecompileLib.normalizedMarkPx(perpIndex);
        console.log("normalizedMarkPx:", normalizedMarkPx); // with 6 decimals

        CoreSimulatorLib.nextBlock();
    }
}
