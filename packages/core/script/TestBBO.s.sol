// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from 'forge-std/Script.sol';
import { PrecompileLib } from '@hyper-evm-lib/src/PrecompileLib.sol';

contract BBOTester {
    function testBBO(uint64 index) external view returns (uint64 bid, uint64 ask) {
        PrecompileLib.Bbo memory bbo = PrecompileLib.bbo(index);
        return (bbo.bid, bbo.ask);
    }

    function testNormalizedPerpBBO(uint32 perpIndex) external view returns (uint256 bid, uint256 ask) {
        bid = PrecompileLib.normalizedPerpBboBid(perpIndex);
        ask = PrecompileLib.normalizedPerpBboAsk(perpIndex);
    }
}

contract TestBBOScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        BBOTester tester = new BBOTester();
        console.log('BBOTester deployed at:', address(tester));

        vm.stopBroadcast();
    }
}