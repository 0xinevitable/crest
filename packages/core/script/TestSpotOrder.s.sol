// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";
import { CoreWriterLib } from "@hyper-evm-lib/src/CoreWriterLib.sol";

contract TestSpotOrderScript is Script {
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;
    uint64 constant HYPE_PERP_INDEX = 135; // HYPE-USD perp on testnet
    uint64 constant HYPE_SPOT_INDEX = 1035; // HYPE/USDC spot on testnet
    uint64 constant USDT0_SPOT_INDEX = 1133; // USDT0/USDC spot

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== TEST PERP ORDER WITH BBO ===");
        console.log("Deployer:", deployer);

        // // Fund the test contract with USDT0
        // console.log('\n2. Funding test contract with 20 USDT0...');
        // IERC20 usdt0 = IERC20(0x779Ded0c9e1022225f8E0630b35a9b54bE713736);
        // usdt0.transfer(address(testContract), 20e6);

        // // Call the test function (BBO will work inside the contract!)
        // console.log('\n3. Calling testPerpWithBBO...');
        PrecompileLib.Bbo memory bbo = PrecompileLib.bbo(HYPE_PERP_INDEX);
        console.log("SPOT bid: %e", bbo.bid);
        console.log("SPOT ask: %e", bbo.ask);

        console.log("\nScript complete!");
        // console.log('Check explorer for contract:', address(testContract));
    }
}
