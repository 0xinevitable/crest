// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { CrestTeller } from '../src/CrestTeller.sol';
import { CrestAccountant } from '../src/CrestAccountant.sol';
import { CrestVault } from '../src/CrestVault.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TestDepositScript is Script {
    // Testnet deployment addresses
    address constant VAULT = 0xafC295423e8b0907D527FEe64aB5b2e7B5C33795;
    address constant TELLER = 0x1A56836057e5c788C6d104f422Dc40100992EA0c;
    address constant ACCOUNTANT = 0xD1aaDfDa4225a103620D735131C96FE347F4bbA1;
    address constant USDT0 = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address deployer = vm.addr(deployerPrivateKey);

        console.log('=== TEST DEPOSIT ON TESTNET ===');
        console.log('Deployer:', deployer);

        // Get contracts
        CrestTeller teller = CrestTeller(TELLER);
        CrestAccountant accountant = CrestAccountant(ACCOUNTANT);
        CrestVault vault = CrestVault(payable(VAULT));
        IERC20 usdt0 = IERC20(USDT0);

        // Check current state
        uint256 usdt0Balance = usdt0.balanceOf(deployer);
        uint256 vaultBalance = usdt0.balanceOf(address(vault));
        uint256 totalSupply = vault.totalSupply();
        uint256 exchangeRate = accountant.exchangeRate();
        uint256 totalAssets = accountant.getTotalAssets();

        console.log('\n=== BEFORE DEPOSIT ===');
        console.log('Deployer USDT0:', usdt0Balance);
        console.log('Vault USDT0:', vaultBalance);
        console.log('Vault shares supply:', totalSupply);
        console.log('Exchange rate:', exchangeRate);
        console.log('Total assets:', totalAssets);

        if (usdt0Balance == 0) {
            console.log('ERROR: No USDT0 balance!');
            return;
        }

        // Deposit amount (50 USDT0)
        uint256 depositAmount = usdt0Balance > 50e6 ? 50e6 : usdt0Balance;

        vm.startBroadcast(deployerPrivateKey);

        // Approve and deposit
        console.log('\n=== EXECUTING DEPOSIT ===');
        console.log('Approving', depositAmount, 'USDT0...');
        usdt0.approve(address(teller), depositAmount);

        console.log('Depositing...');
        uint256 sharesReceived = teller.deposit(depositAmount, deployer);
        console.log('Shares received:', sharesReceived);

        vm.stopBroadcast();

        // Check final state
        console.log('\n=== AFTER DEPOSIT ===');
        console.log('Deployer USDT0:', usdt0.balanceOf(deployer));
        console.log('Vault USDT0:', usdt0.balanceOf(address(vault)));
        console.log('Vault shares supply:', vault.totalSupply());
        console.log('Exchange rate:', accountant.exchangeRate());

        console.log('\nScript complete!');
    }
}