// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from "forge-std/Script.sol";
import { CrestManager } from "../src/CrestManager.sol";
import { CrestVault } from "../src/CrestVault.sol";
import { CrestTeller } from "../src/CrestTeller.sol";
import { CrestAccountant } from "../src/CrestAccountant.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestNewDeploymentScript is Script {
    // Latest testnet deployment addresses from 998.json
    address constant VAULT = 0x7CafB22811073bdB3203999A2Dbe24A63A23802d;
    address constant TELLER = 0xDaCf544424491E831895162Fb5b96f428C317D49;
    address constant ACCOUNTANT = 0xde14f361dB29b698EA168bFfa7DE6b6589c3ba26;
    address constant MANAGER = 0xcC29Ea11E0F457b1BD36Ba18F18c3ba003584758;
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    // HYPE testnet indexes
    uint32 constant HYPE_SPOT_INDEX = 1035;
    uint32 constant HYPE_PERP_INDEX = 135;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== TESTING NEW DEPLOYMENT ===");
        console.log("Deployer/Curator:", deployer);
        console.log("");
        console.log("New Contract Addresses:");
        console.log("  Vault:", VAULT);
        console.log("  Teller:", TELLER);
        console.log("  Accountant:", ACCOUNTANT);
        console.log("  Manager:", MANAGER);

        // Get contracts
        CrestManager manager = CrestManager(MANAGER);
        CrestVault vault = CrestVault(payable(VAULT));
        CrestTeller teller = CrestTeller(TELLER);
        CrestAccountant accountant = CrestAccountant(ACCOUNTANT);
        IERC20 usdt0 = IERC20(USDT0);

        // Check current state
        uint256 userBalance = usdt0.balanceOf(deployer);
        uint256 vaultBalance = usdt0.balanceOf(address(vault));
        uint256 totalSupply = vault.totalSupply();

        console.log("\n=== INITIAL STATE ===");
        console.log("User USDT0 balance:", userBalance);
        console.log("Vault USDT0 balance:", vaultBalance);
        console.log("Vault total supply:", totalSupply);
        console.log("Exchange rate:", accountant.exchangeRate());

        if (userBalance < 50e6) {
            console.log("ERROR: Insufficient USDT0 balance (need at least 50)");
            return;
        }

        // Deposit USDT0
        uint256 depositAmount = userBalance > 100e6 ? 100e6 : 50e6;
        console.log("\n=== DEPOSITING ===");
        console.log("Deposit amount:", depositAmount);

        vm.startBroadcast(deployerPrivateKey);

        // Approve and deposit
        console.log("Approving teller...");
        usdt0.approve(address(teller), depositAmount);

        console.log("Depositing to vault...");
        uint256 sharesReceived = teller.deposit(depositAmount, deployer);
        console.log("Shares received:", sharesReceived);

        vm.stopBroadcast();

        // Check post-deposit state
        console.log("\n=== POST-DEPOSIT STATE ===");
        console.log("User USDT0 balance:", usdt0.balanceOf(deployer));
        console.log("User vault shares:", vault.balanceOf(deployer));
        console.log("Vault USDT0 balance:", usdt0.balanceOf(address(vault)));
        console.log("Vault total supply:", vault.totalSupply());
        console.log("Exchange rate:", accountant.exchangeRate());
        console.log("Total assets:", accountant.getTotalAssets());

        // Show allocation command
        console.log("\n=== ALLOCATION INSTRUCTIONS ===");
        console.log("The deposit was successful. Now allocate funds using:");
        console.log("");
        console.log(
            'cast send 0x5eA75B890bdB802e42a8010bf019b6aAD8F26473 "allocate(uint32,uint32)" 1035 135'
        );
        console.log(
            "  --private-key $PRIVATE_KEY --rpc-url https://rpc.hyperliquid-testnet.xyz/evm"
        );
        console.log("");
        console.log("Expected allocation breakdown:");
        uint256 currentVaultBalance = usdt0.balanceOf(address(vault));
        console.log("  Total to allocate:", currentVaultBalance);
        console.log("  Margin (10%):", currentVaultBalance / 10);
        console.log("  Spot (45%):", (currentVaultBalance * 45) / 100);
        console.log("  Perp (45%):", (currentVaultBalance * 45) / 100);

        console.log("\nScript complete!");
    }
}
