// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/diamond/interfaces/IDiamondCut.sol";
import "../src/diamond/interfaces/IDiamondLoupe.sol";
import "../src/diamond/facets/VaultFacet.sol";

contract UpgradeVaultFacetSmart is Script {
    function run() external {
        // Load deployment info
        address diamondAddress = 0x1A56836057e5c788C6d104f422Dc40100992EA0c;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new VaultFacet
        VaultFacet newVaultFacet = new VaultFacet();
        console.log("New VaultFacet deployed at:", address(newVaultFacet));

        // Get the diamond loupe to check existing functions
        IDiamondLoupe loupe = IDiamondLoupe(diamondAddress);

        // Prepare all function selectors for VaultFacet
        bytes4[] memory allSelectors = new bytes4[](20);
        allSelectors[0] = VaultFacet.authorize.selector;
        allSelectors[1] = VaultFacet.unauthorize.selector;
        allSelectors[2] = VaultFacet.authorized.selector;
        allSelectors[3] = bytes4(keccak256("manage(address,bytes,uint256)"));
        allSelectors[4] = bytes4(
            keccak256("manage(address[],bytes[],uint256[])")
        );
        allSelectors[5] = VaultFacet.allocate.selector;
        allSelectors[6] = VaultFacet.rebalance.selector;
        allSelectors[7] = VaultFacet.enter.selector;
        allSelectors[8] = VaultFacet.exit.selector;
        allSelectors[9] = VaultFacet.setHyperdriveMarket.selector;
        allSelectors[10] = VaultFacet.depositToHyperdrive.selector;
        allSelectors[11] = VaultFacet.withdrawFromHyperdrive.selector;
        allSelectors[12] = VaultFacet.getHyperdriveValue.selector;
        allSelectors[13] = VaultFacet.setBeforeTransferHook.selector;
        allSelectors[14] = VaultFacet.beforeTransferHook.selector;
        allSelectors[15] = VaultFacet.currentSpotIndex.selector;
        allSelectors[16] = VaultFacet.currentPerpIndex.selector;
        allSelectors[17] = VaultFacet.hyperdriveMarket.selector;
        allSelectors[18] = VaultFacet.hyperdriveShares.selector;
        allSelectors[19] = VaultFacet.hook.selector;

        // Separate selectors into Add and Replace based on what exists
        bytes4[] memory selectorsToAdd = new bytes4[](20);
        bytes4[] memory selectorsToReplace = new bytes4[](20);
        uint256 addCount = 0;
        uint256 replaceCount = 0;

        for (uint256 i = 0; i < allSelectors.length; i++) {
            address facetAddress = loupe.facetAddress(allSelectors[i]);
            if (facetAddress == address(0)) {
                // Function doesn't exist, add it
                selectorsToAdd[addCount] = allSelectors[i];
                addCount++;
                console.log(
                    "Will ADD function with selector:",
                    vm.toString(allSelectors[i])
                );
            } else {
                // Function exists, replace it
                selectorsToReplace[replaceCount] = allSelectors[i];
                replaceCount++;
                console.log(
                    "Will REPLACE function with selector:",
                    vm.toString(allSelectors[i]),
                    "from facet:",
                    facetAddress
                );
            }
        }

        // Prepare the diamond cuts
        uint256 cutCount = 0;
        if (addCount > 0) cutCount++;
        if (replaceCount > 0) cutCount++;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](
            cutCount
        );
        uint256 cutIndex = 0;

        // Add new functions if any
        if (addCount > 0) {
            bytes4[] memory toAdd = new bytes4[](addCount);
            for (uint256 i = 0; i < addCount; i++) {
                toAdd[i] = selectorsToAdd[i];
            }
            cut[cutIndex] = IDiamondCut.FacetCut({
                facetAddress: address(newVaultFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: toAdd
            });
            cutIndex++;
            console.log("Adding", addCount, "new functions");
        }

        // Replace existing functions if any
        if (replaceCount > 0) {
            bytes4[] memory toReplace = new bytes4[](replaceCount);
            for (uint256 i = 0; i < replaceCount; i++) {
                toReplace[i] = selectorsToReplace[i];
            }
            cut[cutIndex] = IDiamondCut.FacetCut({
                facetAddress: address(newVaultFacet),
                action: IDiamondCut.FacetCutAction.Replace,
                functionSelectors: toReplace
            });
            console.log("Replacing", replaceCount, "existing functions");
        }

        // Execute diamond cut
        if (cutCount > 0) {
            IDiamondCut(diamondAddress).diamondCut(cut, address(0), "");
            console.log("VaultFacet upgraded successfully!");
        } else {
            console.log("No changes needed");
        }

        vm.stopBroadcast();
    }
}
