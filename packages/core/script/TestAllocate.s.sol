// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { CrestManager } from '../src/CrestManager.sol';
import { CrestVault } from '../src/CrestVault.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TestAllocateScript is Script {
    // Testnet deployment addresses
    address constant VAULT = 0xafC295423e8b0907D527FEe64aB5b2e7B5C33795;
    address constant MANAGER = 0x1893bdA8Ab1A3f7e74bf806ffe0C78b4F171B216;
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    // HYPE testnet indexes
    uint32 constant HYPE_SPOT_INDEX = 1035;
    uint32 constant HYPE_PERP_INDEX = 135;

    // Precompile addresses
    address constant SPOT_PX_PRECOMPILE = 0x0000000000000000000000000000000000000808;
    address constant MARK_PX_PRECOMPILE = 0x0000000000000000000000000000000000000807;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address deployer = vm.addr(deployerPrivateKey);

        console.log('=== TEST ALLOCATION ON TESTNET ===');
        console.log('Deployer/Curator:', deployer);

        // Get contracts
        CrestManager manager = CrestManager(MANAGER);
        CrestVault vault = CrestVault(payable(VAULT));
        IERC20 usdt0 = IERC20(USDT0);

        // Check current state
        uint256 vaultBalance = usdt0.balanceOf(address(vault));
        console.log('\n=== CURRENT STATE ===');
        console.log('Vault USDT0 balance:', vaultBalance);
        console.log('Vault total supply:', vault.totalSupply());

        if (vaultBalance < 50e6) {
            console.log('ERROR: Insufficient USDT0 in vault (need at least 50)');
            return;
        }

        // Check if precompiles work
        console.log('\n=== TESTING PRECOMPILES ===');

        // Test spot price precompile
        (bool spotSuccess, bytes memory spotResult) = SPOT_PX_PRECOMPILE.staticcall(
            abi.encode(uint64(HYPE_SPOT_INDEX))
        );
        if (spotSuccess) {
            uint64 spotPrice = abi.decode(spotResult, (uint64));
            console.log('HYPE Spot Price (raw):', spotPrice);
            console.log('HYPE Spot Price ($):', spotPrice / 1e8);
        } else {
            console.log('Failed to get spot price from precompile');
        }

        // Test perp price precompile
        (bool perpSuccess, bytes memory perpResult) = MARK_PX_PRECOMPILE.staticcall(
            abi.encode(uint32(HYPE_PERP_INDEX))
        );
        if (perpSuccess) {
            uint64 perpPrice = abi.decode(perpResult, (uint64));
            console.log('HYPE Perp Mark Price (raw):', perpPrice);
            console.log('HYPE Perp Mark Price ($):', perpPrice / 1e6);
        } else {
            console.log('Failed to get perp price from precompile');
        }

        // Try to allocate
        console.log('\n=== ATTEMPTING ALLOCATION ===');
        console.log('Allocating to HYPE with indexes:');
        console.log('  Spot Index:', HYPE_SPOT_INDEX);
        console.log('  Perp Index:', HYPE_PERP_INDEX);

        vm.startBroadcast(deployerPrivateKey);

        try manager.allocate(HYPE_SPOT_INDEX, HYPE_PERP_INDEX) {
            console.log('SUCCESS: Allocation completed!');

            // Check positions
            (CrestManager.Position memory spotPos, CrestManager.Position memory perpPos) = manager.getPositions();
            console.log('\n=== POSITIONS CREATED ===');
            console.log('Spot position:');
            console.log('  Index:', spotPos.index);
            console.log('  Size:', spotPos.size);
            console.log('  Entry Price:', spotPos.entryPrice);
            console.log('Perp position:');
            console.log('  Index:', perpPos.index);
            console.log('  Size:', perpPos.size);
            console.log('  Entry Price:', perpPos.entryPrice);
        } catch Error(string memory reason) {
            console.log('FAILED: Allocation failed with reason:', reason);
        } catch (bytes memory lowLevelData) {
            console.log('FAILED: Allocation failed (low-level error)');
            // Try to decode the error
            if (lowLevelData.length > 0) {
                console.log('Error data length:', lowLevelData.length);
            }
        }

        vm.stopBroadcast();

        console.log('\nScript complete!');
    }
}