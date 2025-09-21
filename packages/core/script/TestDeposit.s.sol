// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { CrestTeller } from '../src/CrestTeller.sol';
import { CrestAccountant } from '../src/CrestAccountant.sol';
import { CrestVault } from '../src/CrestVault.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TestDepositScript is Script {
    // Latest testnet deployment addresses from 998.json
    address constant VAULT = 0xe7A35E0003B6b02C07574464a5C832b147eA7AF7;
    address constant TELLER = 0xFa77546D8D32C96936Cd0acbC03A858BFd42fae6;
    address constant ACCOUNTANT = 0x6D254abb2b5e71Cb223d94B6E6FF8a4921E7a0a7;
    address constant MANAGER = 0x033E25Fea72e025DeBaB55Ce481D3E40E50e4275;
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