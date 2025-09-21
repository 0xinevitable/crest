// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { stdJson } from 'forge-std/StdJson.sol';
import { CrestVault } from '../src/CrestVault.sol';
import { CrestTeller } from '../src/CrestTeller.sol';
import { CrestAccountant } from '../src/CrestAccountant.sol';
import { CrestManager } from '../src/CrestManager.sol';
import { LibString } from '@solady/utils/LibString.sol';
import { Empty } from './Empty.sol';

struct Output {
    // params
    address deployer;
    address curator;
    address feeRecipient;
    address usdt0;
    //
    // contracts
    address vault;
    address accountant;
    address teller;
    address manager;
}

contract DeployScript is Script {
    using stdJson for string;

    uint256 constant TESTNET_CHAINID = 998;

    // Get USDT0 address based on chain
    function usdt0Address() internal view returns (address) {
        return
            block.chainid == TESTNET_CHAINID
                ? 0x779Ded0c9e1022225f8E0630b35a9b54bE713736 // Testnet USDT0
                : 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb; // Mainnet USDT0
    }

    function makeBytes32() internal returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    address(new Empty())
                )
            );
    }

    function makeU256() internal returns (uint256) {
        return uint256(makeBytes32());
    }

    function makeStr() internal returns (string memory) {
        return LibString.toHexString(makeU256());
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address deployer = vm.addr(deployerPrivateKey);
        address curator = vm.envAddress('CURATOR_ADDRESS');
        address feeRecipient = vm.envAddress('FEE_RECIPIENT_ADDRESS');

        // Deploy vault
        vm.startBroadcast(deployerPrivateKey);
        CrestVault vault = new CrestVault(deployer, 'Crest Vault', 'CREST');

        // Deploy accountant
        CrestAccountant accountant = new CrestAccountant(
            payable(address(vault)),
            deployer,
            feeRecipient
        );

        // Deploy teller
        CrestTeller teller = new CrestTeller(
            payable(address(vault)),
            usdt0Address(),
            deployer
        );

        // Deploy manager
        CrestManager manager = new CrestManager(
            payable(address(vault)),
            usdt0Address(),
            deployer,
            curator
        );

        // Configure teller
        teller.setAccountant(address(accountant));

        // Configure Hyperdrive market for mainnet
        if (block.chainid != TESTNET_CHAINID) {
            address hyperdriveMarket = 0x260F5f56aD7D14789D43Fd538429d42Ff5b82B56;
            vault.setHyperdriveMarket(hyperdriveMarket);
            console.log('Hyperdrive Market configured:', hyperdriveMarket);
        }

        // Setup vault permissions
        vault.authorize(address(teller));
        vault.authorize(address(manager));
        vault.authorize(address(accountant));

        vm.stopBroadcast();

        // DEPLOYMENT COMPLETE
        console.log('Deployment complete!');

        {
            Output memory output;

            // params
            output.deployer = deployer;
            output.curator = curator;
            output.feeRecipient = feeRecipient;
            output.usdt0 = usdt0Address();

            // contracts
            output.vault = address(vault);
            output.accountant = address(accountant);
            output.teller = address(teller);
            output.manager = address(manager);

            string memory key = makeStr();
            string memory out = '';

            out = key.serialize('deployer', output.deployer);
            out = key.serialize('curator', output.curator);
            out = key.serialize('feeRecipient', output.feeRecipient);
            out = key.serialize('usdt0', output.usdt0);

            out = key.serialize('vault', output.vault);
            out = key.serialize('accountant', output.accountant);
            out = key.serialize('teller', output.teller);
            out = key.serialize('manager', output.manager);

            string memory path = string.concat(
                './deployments/',
                LibString.toString(block.chainid),
                '.json'
            );
            vm.writeJson(out, path);
            vm.writeLine(path, '');
        }
    }
}
