// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { CrestManager } from '../src/CrestManager.sol';
import { CrestVault } from '../src/CrestVault.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TestAllocateDirectScript is Script {
    // Testnet deployment addresses
    address constant VAULT = 0xafC295423e8b0907D527FEe64aB5b2e7B5C33795;
    address constant MANAGER = 0x1893bdA8Ab1A3f7e74bf806ffe0C78b4F171B216;
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    // HYPE testnet indexes
    uint32 constant HYPE_SPOT_INDEX = 1035;
    uint32 constant HYPE_PERP_INDEX = 135;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address deployer = vm.addr(deployerPrivateKey);

        console.log('=== DIRECT ALLOCATION TEST ===');
        console.log('Deployer/Curator:', deployer);

        // Just broadcast the allocation without any precompile checks
        // The actual contract will handle the precompiles on-chain

        vm.startBroadcast(deployerPrivateKey);

        CrestManager manager = CrestManager(MANAGER);

        console.log('Calling manager.allocate with HYPE indexes...');

        // This will execute on-chain where precompiles exist
        manager.allocate(HYPE_SPOT_INDEX, HYPE_PERP_INDEX);

        console.log('Allocation transaction sent!');

        vm.stopBroadcast();

        console.log('\nTransaction broadcast complete. Check explorer for results.');
    }
}