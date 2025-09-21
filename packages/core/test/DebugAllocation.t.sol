// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from "forge-std/Script.sol";
import { CrestManager } from "../src/CrestManager.sol";
import { CrestVault } from "../src/CrestVault.sol";
import { CrestTeller } from "../src/CrestTeller.sol";
import { CrestAccountant } from "../src/CrestAccountant.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";
import { CoreWriterLib } from "@hyper-evm-lib/src/CoreWriterLib.sol";

contract DebugAllocationScript is Script {
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
        console.log("\n=== DEPLOYING NEW CONTRACTS ===");

        CrestVault vault = new CrestVault(deployer, "Debug Vault", "dbgUSDT0");
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
        uint256 depositAmount = usdt0Balance > 30e6 ? 30e6 : usdt0Balance; // Use 30 USDT0 or all balance
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

        // Now test allocation with BBO (will work on-chain!)
        console.log("\n=== TESTING ALLOCATION WITH BBO ===");
        console.log("HYPE Spot Index:", HYPE_SPOT_INDEX);
        console.log("HYPE Perp Index:", HYPE_PERP_INDEX);

        // Call allocate (BBO will work inside the contract on-chain)
        manager.allocate(HYPE_SPOT_INDEX, HYPE_PERP_INDEX);

        // Check what happened
        console.log("\n=== CHECKING CORE BALANCES ===");

        // Check USDC balance in Core
        PrecompileLib.SpotBalance memory usdcBalance = PrecompileLib
            .spotBalance(
                address(manager),
                0 // USDC token ID
            );
        console.log("Manager USDC in Core:", usdcBalance.total);

        // Check HYPE balance
        uint64 hypeTokenId = 1105; // HYPE token ID on testnet
        PrecompileLib.SpotBalance memory hypeBalance = PrecompileLib
            .spotBalance(address(manager), hypeTokenId);
        console.log("Manager HYPE balance:", hypeBalance.total);

        // Check perp position
        PrecompileLib.Position memory perpPosPrecompile = PrecompileLib
            .position(address(manager), uint16(HYPE_PERP_INDEX));
        console.log("Perp position size (szi):", perpPosPrecompile.szi);
        console.log("Perp entry notional:", perpPosPrecompile.entryNtl);

        // Check margin account
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(manager));
        console.log("Margin account value:", marginSummary.accountValue);

        // Check stored positions in Manager
        (
            CrestManager.Position memory spotPos,
            CrestManager.Position memory perpPos
        ) = manager.getPositions();

        console.log("\n=== MANAGER STORED POSITIONS ===");
        console.log("Spot index:", spotPos.index);
        console.log("Spot size:", spotPos.size);
        console.log("Spot entry price:", spotPos.entryPrice);
        console.log("Perp index:", perpPos.index);
        console.log("Perp size:", perpPos.size);
        console.log("Perp entry price:", perpPos.entryPrice);

        // Test position value estimation (will use precompiles internally)
        uint256 positionValue = manager.estimatePositionValue();
        console.log("\nEstimated position value:", positionValue);

        // Check remaining USDT0
        uint256 remainingUsdt0 = usdt0.balanceOf(address(manager));
        console.log("Remaining USDT0 in manager:", remainingUsdt0);

        if (remainingUsdt0 > 40e6) {
            console.log(
                "\n!!! WARNING: Orders likely didn't fill - too much USDT0 remaining"
            );
        } else {
            console.log("\nOrders appear to have processed");
        }

        vm.stopBroadcast();

        console.log("\n=== SCRIPT COMPLETE ===");
        console.log("Check explorer for manager address:", address(manager));
    }
}
