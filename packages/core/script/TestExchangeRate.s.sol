// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { CrestManager } from '../src/CrestManager.sol';
import { CrestVault } from '../src/CrestVault.sol';
import { CrestTeller } from '../src/CrestTeller.sol';
import { CrestAccountant } from '../src/CrestAccountant.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TestExchangeRateScript is Script {
    // Latest testnet deployment addresses
    address constant VAULT = 0xA351De12FBa8A7cDc9cE8bcc38215c5d715b00b6;
    address constant TELLER = 0x5101a50e44f9B3D5F30Bd048E34bfA8aB7aF5B08;
    address constant ACCOUNTANT = 0x39302b737E25bd5217038935626E6c5c1476C417;
    address constant MANAGER = 0x1013c950B41025A0495C48EdAFAccd7e235A4a8B;
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    // HYPE testnet indexes
    uint32 constant HYPE_SPOT_INDEX = 1035;
    uint32 constant HYPE_PERP_INDEX = 135;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address deployer = vm.addr(deployerPrivateKey);

        console.log('=== TESTING EXCHANGE RATE WITH UPDATED ACCOUNTANT ===');
        console.log('Deployer:', deployer);

        // Get contracts
        CrestManager manager = CrestManager(MANAGER);
        CrestVault vault = CrestVault(payable(VAULT));
        CrestTeller teller = CrestTeller(TELLER);
        CrestAccountant accountant = CrestAccountant(ACCOUNTANT);
        IERC20 usdt0 = IERC20(USDT0);

        // Check initial state
        uint256 userBalance = usdt0.balanceOf(deployer);
        uint256 vaultBalance = usdt0.balanceOf(address(vault));
        uint256 totalSupply = vault.totalSupply();

        console.log('\n=== INITIAL STATE ===');
        console.log('User USDT0:', userBalance);
        console.log('Vault USDT0:', vaultBalance);
        console.log('Vault shares:', totalSupply);
        console.log('Exchange rate:', accountant.exchangeRate());
        console.log('Total assets:', accountant.getTotalAssets());
        console.log('Manager allocated:', manager.totalAllocated());

        // Deposit if vault is empty
        if (totalSupply == 0 && userBalance >= 100e6) {
            console.log('\n=== DEPOSITING 100 USDT0 ===');

            vm.startBroadcast(deployerPrivateKey);
            usdt0.approve(address(teller), 100e6);
            uint256 shares = teller.deposit(100e6, deployer);
            vm.stopBroadcast();

            console.log('Shares received:', shares);
            console.log('Exchange rate after deposit:', accountant.exchangeRate());
            console.log('Total assets after deposit:', accountant.getTotalAssets());
        }

        // Show current state
        console.log('\n=== CURRENT STATE ===');
        console.log('Vault USDT0:', usdt0.balanceOf(address(vault)));
        console.log('Vault shares:', vault.totalSupply());
        console.log('Manager allocated:', manager.totalAllocated());
        console.log('Total assets:', accountant.getTotalAssets());
        console.log('Exchange rate:', accountant.exchangeRate());

        // Show allocation command if funds available
        if (usdt0.balanceOf(address(vault)) >= 50e6) {
            console.log('\n=== READY TO ALLOCATE ===');
            console.log('Run this command to allocate:');
            console.log('cast send 0x1013c950B41025A0495C48EdAFAccd7e235A4a8B "allocate(uint32,uint32)" 1035 135');
            console.log('  --private-key $PRIVATE_KEY --rpc-url https://rpc.hyperliquid-testnet.xyz/evm');

            console.log('\nAfter allocation, run this script again to see the exchange rate update!');
        } else if (manager.totalAllocated() > 0) {
            console.log('\n=== FUNDS ALREADY ALLOCATED ===');
            console.log('Total allocated:', manager.totalAllocated());
            console.log('Exchange rate WITH Core positions:', accountant.exchangeRate());
            console.log('Expected rate: 1e6 (1:1) if no profits/losses');

            uint256 currentRate = accountant.exchangeRate();
            if (currentRate == 1e6) {
                console.log('SUCCESS: Exchange rate is correct!');
            } else if (currentRate == 0) {
                console.log('ERROR: Exchange rate is still 0 - getTotalAssets might not be reading Manager correctly');
            } else {
                console.log('Exchange rate reflects profit/loss');
            }
        }

        console.log('\nScript complete!');
    }
}