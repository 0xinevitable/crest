// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from "forge-std/Script.sol";
import { CrestManager } from "../src/CrestManager.sol";
import { CrestVault } from "../src/CrestVault.sol";
import { CrestTeller } from "../src/CrestTeller.sol";
import { CrestAccountant } from "../src/CrestAccountant.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";

contract DeployAndTestBBOScript is Script {
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;
    uint32 constant HYPE_SPOT_INDEX = 1035; // HYPE/USDC on testnet
    uint32 constant HYPE_PERP_INDEX = 135; // HYPE-USD perp on testnet

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address curator = deployer; // Use deployer as curator for testing
        console.log("Deployer:", deployer);

        IERC20 usdt0 = IERC20(USDT0);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new contracts
        console.log("\n=== DEPLOYING BBO-ENABLED CONTRACTS ===");

        CrestVault vault = new CrestVault(
            deployer,
            "BBO Test Vault",
            "bbotUSDT0"
        );
        console.log("Vault deployed:", address(vault));

        CrestManager manager = new CrestManager(
            payable(address(vault)),
            address(usdt0),
            curator,
            deployer
        );
        console.log("Manager deployed:", address(manager));

        CrestAccountant accountant = new CrestAccountant(
            payable(address(vault)),
            address(usdt0),
            address(manager),
            deployer,
            deployer
        );
        console.log("Accountant deployed:", address(accountant));

        CrestTeller teller = new CrestTeller(
            payable(address(vault)),
            address(usdt0),
            deployer
        );
        console.log("Teller deployed:", address(teller));

        // Setup contracts
        teller.setAccountant(address(accountant));
        vault.authorize(address(manager));
        vault.authorize(address(teller));

        // Check balance and deposit
        console.log("\n=== CHECKING BALANCE ===");
        uint256 usdt0Balance = usdt0.balanceOf(deployer);
        console.log("USDT0 balance:", usdt0Balance);

        if (usdt0Balance < 10e6) {
            console.log("ERROR: Not enough USDT0 balance");
            vm.stopBroadcast();
            return;
        }

        // Deposit some USDT0
        console.log("\n=== DEPOSITING FUNDS ===");
        uint256 depositAmount = usdt0Balance; // Use all available balance
        usdt0.approve(address(teller), depositAmount);
        uint256 shares = teller.deposit(depositAmount, deployer);
        console.log("Deposited USDT0:", depositAmount);
        console.log("Received shares:", shares);

        // Transfer funds from vault to manager for allocation
        console.log("\n=== TRANSFERRING TO MANAGER ===");
        vault.manage(
            address(usdt0),
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(manager),
                depositAmount
            ),
            0
        );
        console.log(
            "Manager USDT0 balance:",
            usdt0.balanceOf(address(manager))
        );

        // Now test allocation with BBO
        console.log("\n=== TESTING ALLOCATION WITH BBO ===");
        console.log("HYPE Spot Index:", HYPE_SPOT_INDEX);
        console.log("HYPE Perp Index:", HYPE_PERP_INDEX);

        // Don't call allocate in the script - precompiles don't work here
        // We'll call it as a separate transaction after deployment

        vm.stopBroadcast();

        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Manager address to check on explorer:", address(manager));
        console.log("Orders should fill using BBO prices");
    }
}
