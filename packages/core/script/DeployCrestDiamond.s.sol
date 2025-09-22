// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { DeployDiamond } from "../src/diamond/DeployDiamond.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployCrestDiamond is Script {
    function run() external {
        // Load configuration from environment
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        address owner = vm.envOr("OWNER_ADDRESS", deployer);
        address usdt0 = vm.envAddress("USDT0_ADDRESS");
        address curator = vm.envAddress("CURATOR_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");

        // Default configuration values
        string memory name = "Crest Vault Shares";
        string memory symbol = "CREST";
        uint64 shareLockPeriod = 1 days;
        uint16 platformFeeBps = 100; // 1%
        uint16 performanceFeeBps = 500; // 5%
        uint16 maxSlippageBps = 100; // 1%

        // Begin deployment
        vm.startBroadcast(privateKey);

        // Deploy the diamond deployer
        DeployDiamond deployHelper = new DeployDiamond();

        // Set up deployment parameters
        DeployDiamond.DeploymentParams memory params = DeployDiamond.DeploymentParams({
            owner: owner,
            usdt0: usdt0,
            curator: curator,
            feeRecipient: feeRecipient,
            name: name,
            symbol: symbol,
            shareLockPeriod: shareLockPeriod,
            platformFeeBps: platformFeeBps,
            performanceFeeBps: performanceFeeBps,
            maxSlippageBps: maxSlippageBps
        });

        // Deploy the diamond
        address diamond = deployHelper.deployDiamond(params);

        vm.stopBroadcast();

        // Log deployment information
        console2.log("========================================");
        console2.log("Crest Diamond Deployment Successful");
        console2.log("========================================");
        console2.log("Diamond Address:", diamond);
        console2.log("Owner:", owner);
        console2.log("USDT0 Token:", usdt0);
        console2.log("Curator:", curator);
        console2.log("Fee Recipient:", feeRecipient);
        console2.log("========================================");
        console2.log("Configuration:");
        console2.log("Share Lock Period:", shareLockPeriod, "seconds");
        console2.log("Platform Fee:", platformFeeBps, "bps");
        console2.log("Performance Fee:", performanceFeeBps, "bps");
        console2.log("Max Slippage:", maxSlippageBps, "bps");
        console2.log("========================================");
    }
}