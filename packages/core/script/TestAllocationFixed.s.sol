// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { CrestManager } from '../src/CrestManager.sol';
import { CrestVault } from '../src/CrestVault.sol';
import { CrestTeller } from '../src/CrestTeller.sol';
import { CrestAccountant } from '../src/CrestAccountant.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TestAllocationFixedScript is Script {
    // Testnet deployment addresses
    address constant VAULT = 0xafC295423e8b0907D527FEe64aB5b2e7B5C33795;
    address constant TELLER = 0x1A56836057e5c788C6d104f422Dc40100992EA0c;
    address constant ACCOUNTANT = 0xD1aaDfDa4225a103620D735131C96FE347F4bbA1;
    address constant MANAGER = 0x1893bdA8Ab1A3f7e74bf806ffe0C78b4F171B216;
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    // HYPE testnet indexes
    uint32 constant HYPE_SPOT_INDEX = 1035;
    uint32 constant HYPE_PERP_INDEX = 135;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address deployer = vm.addr(deployerPrivateKey);

        console.log('=== TEST FIXED ALLOCATION LOGIC ===');
        console.log('Deployer/Curator:', deployer);

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

        console.log('\n=== CURRENT STATE ===');
        console.log('User USDT0:', userBalance);
        console.log('Vault USDT0:', vaultBalance);
        console.log('Vault shares:', totalSupply);
        console.log('Exchange rate:', accountant.exchangeRate());

        // Check if we need to deposit first
        if (vaultBalance == 0 && userBalance >= 50e6) {
            console.log('\n=== DEPOSITING FIRST ===');
            vm.startBroadcast(deployerPrivateKey);

            uint256 depositAmount = userBalance > 100e6 ? 100e6 : 50e6;
            console.log('Depositing:', depositAmount);

            usdt0.approve(address(teller), depositAmount);
            uint256 shares = teller.deposit(depositAmount, deployer);
            console.log('Shares received:', shares);

            vm.stopBroadcast();

            // Update vault balance
            vaultBalance = usdt0.balanceOf(address(vault));
        }

        if (vaultBalance < 50e6) {
            console.log('\nERROR: Insufficient USDT0 in vault for allocation (need at least 50)');
            return;
        }

        // Check current positions
        (CrestManager.Position memory spotPos, CrestManager.Position memory perpPos) = manager.getPositions();

        console.log('\n=== CURRENT POSITIONS ===');
        console.log('Spot position size:', spotPos.size);
        console.log('Perp position size:', perpPos.size);

        if (spotPos.size > 0 || perpPos.size > 0) {
            console.log('Positions already exist. Exiting them first...');
            vm.startBroadcast(deployerPrivateKey);
            manager.exit();
            vm.stopBroadcast();
            console.log('Positions exited.');
        }

        console.log('\n=== ALLOCATING WITH FIXED LOGIC ===');
        console.log('Allocating', vaultBalance, 'USDT0 to HYPE positions');
        console.log('Expected allocation:');
        console.log('  - Margin (10%):', vaultBalance / 10);
        console.log('  - Spot (45%):', (vaultBalance * 45) / 100);
        console.log('  - Perp (45%):', (vaultBalance * 45) / 100);

        // NOTE: We can't simulate this because forge doesn't support Hyperliquid precompiles
        // The allocation will fail in simulation but should work on actual testnet
        console.log('\nNOTE: Allocation must be sent directly via cast send due to precompile limitations.');
        console.log('Run this command to allocate:');
        console.log('cast send', MANAGER, '"allocate(uint32,uint32)"', HYPE_SPOT_INDEX, HYPE_PERP_INDEX);
        console.log('--private-key $PRIVATE_KEY --rpc-url https://rpc.hyperliquid-testnet.xyz/evm');

        console.log('\nScript complete!');
    }
}