// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/diamond/facets/VaultFacet.sol";

contract AuthorizeDiamond is Script {
    function run() external {
        address diamondAddress = 0x1A56836057e5c788C6d104f422Dc40100992EA0c;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Authorize the diamond to itself so facets can call each other
        VaultFacet(diamondAddress).authorize(diamondAddress);

        console.log("Diamond authorized to itself at:", diamondAddress);

        // Check if authorization was successful
        bool isAuthorized = VaultFacet(diamondAddress).authorized(diamondAddress);
        console.log("Authorization successful:", isAuthorized);

        vm.stopBroadcast();
    }
}