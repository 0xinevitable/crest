// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";
import { CoreWriterLib } from "@hyper-evm-lib/src/CoreWriterLib.sol";

contract SimpleSpotTestScript is Script {
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;
    uint32 constant HYPE_SPOT_INDEX = 1035; // HYPE/USDC on testnet

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== SIMPLE SPOT ORDER TEST ===");
        console.log("Deployer:", deployer);

        IERC20 usdt0 = IERC20(USDT0);
        uint256 usdt0Balance = usdt0.balanceOf(deployer);
        console.log("USDT0 balance:", usdt0Balance);

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Transfer USDT0 to system address for bridging
        console.log("\n1. Transferring 11 USDT0 to bridge...");
        address bridgeAddress = address(
            0x2222222222222222222222222222222222222222
        );
        usdt0.transfer(bridgeAddress, 11e6);

        // Step 2: Get BBO for HYPE/USDC
        console.log("\n2. Getting BBO for HYPE/USDC...");
        PrecompileLib.Bbo memory hypeBbo = PrecompileLib.bbo(
            uint64(HYPE_SPOT_INDEX)
        );
        console.log("   HYPE bid:", hypeBbo.bid);
        console.log("   HYPE ask:", hypeBbo.ask);

        if (hypeBbo.ask == 0) {
            console.log("ERROR: No ask price available");
            vm.stopBroadcast();
            return;
        }

        // Step 3: Place a small test order
        // Assuming we have some USDC in Core already
        uint64 testSize = 100000000; // 0.01 HYPE with 8 decimals (very small test)
        uint64 buyPrice = hypeBbo.ask + ((hypeBbo.ask * 100) / 10000); // 1% slippage

        console.log("3. Placing test buy order...");
        console.log("   Size:", testSize);
        console.log("   Price:", buyPrice);

        CoreWriterLib.placeLimitOrder(
            HYPE_SPOT_INDEX,
            true, // buy
            buyPrice,
            testSize,
            false, // not reduce only
            3, // IOC
            uint128(block.timestamp << 32) // unique cloid
        );

        vm.stopBroadcast();

        console.log("\nScript complete!");
        console.log("Check explorer for results");
    }
}
