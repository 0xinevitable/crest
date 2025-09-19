// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {CrestVault} from "../src/CrestVault.sol";
import {CrestTeller} from "../src/CrestTeller.sol";
import {CrestAccountant} from "../src/CrestAccountant.sol";
import {CrestManager} from "../src/CrestManager.sol";

contract DeployCrestVault is Script {
    // Hyperliquid USDC address
    address constant USDC = 0xd825E39c8F28401f36eBe4DF59A8B92a8A1A0b93;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address curator = vm.envAddress("CURATOR_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");

        console.log("Deploying CrestVault with:");
        console.log("  Deployer:", deployer);
        console.log("  Curator:", curator);
        console.log("  Fee Recipient:", feeRecipient);
        console.log("  USDC:", USDC);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vault
        CrestVault vault = new CrestVault(deployer, "Crest Vault", "CREST");
        console.log("Vault deployed at:", payable(address(vault)));

        // Deploy accountant
        CrestAccountant accountant = new CrestAccountant(
            payable(address(vault)),
            deployer,
            feeRecipient
        );
        console.log("Accountant deployed at:", address(accountant));

        // Deploy teller
        CrestTeller teller = new CrestTeller(
            payable(address(vault)),
            USDC,
            deployer
        );
        console.log("Teller deployed at:", address(teller));

        // Deploy manager
        CrestManager manager = new CrestManager(
            payable(address(vault)),
            USDC,
            deployer,
            curator
        );
        console.log("Manager deployed at:", address(manager));

        // Configure teller
        teller.setAccountant(address(accountant));
        console.log("Accountant set in Teller");

        // Setup vault permissions
        vault.authorize(address(teller));
        vault.authorize(address(manager));
        vault.authorize(address(accountant));
        console.log("Vault permissions configured");

        vm.stopBroadcast();

        console.log("\nDeployment complete!");
        console.log("========================");
        console.log("Vault:", payable(address(vault)));
        console.log("Teller:", address(teller));
        console.log("Accountant:", address(accountant));
        console.log("Manager:", address(manager));
        console.log("========================");
        console.log("\nNext steps:");
        console.log("1. Verify contracts on explorer");
        console.log("2. Test deposit/withdraw functionality");
        console.log("3. Configure initial allocation parameters");
    }
}