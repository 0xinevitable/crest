// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script, console2 } from "forge-std/Script.sol";
import { HypeTradingContract } from "@hyper-evm-lib/test/utils/HypeTradingContract.sol";

contract DeployHypeTradingContract is Script {
    function run() external {
        // Get deployer from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deploying HypeTradingContract with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy HypeTradingContract with deployer as owner
        HypeTradingContract hypeTradingContract = new HypeTradingContract(
            deployer
        );

        console2.log(
            "HypeTradingContract deployed at:",
            address(hypeTradingContract)
        );
        console2.log("Owner:", hypeTradingContract.owner());
        console2.log(
            "HYPE token index:",
            hypeTradingContract.getHypeTokenIndex()
        );

        vm.stopBroadcast();

        // Save deployment info
        console2.log("\n=== Deployment Summary ===");
        console2.log("HypeTradingContract:", address(hypeTradingContract));
        console2.log("Owner:", deployer);
        console2.log("Network: Hyperliquid Testnet");
    }
}
