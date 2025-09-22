// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/diamond/interfaces/IDiamondCut.sol";
import "../src/diamond/interfaces/IDiamondLoupe.sol";
import "../src/diamond/facets/VaultFacet.sol";
import "../src/diamond/facets/TellerFacet.sol";
import "../src/diamond/facets/ManagerFacet.sol";
import "../src/diamond/facets/AccountantFacet.sol";
import "../src/diamond/facets/DiamondLoupeFacet.sol";
import "../src/diamond/facets/DiamondCutFacet.sol";

contract UpgradeFacet is Script {
    address constant DIAMOND_ADDRESS = 0x1A56836057e5c788C6d104f422Dc40100992EA0c;

    function run() external {
        // Pass facet name as argument: vault, teller, manager, or accountant
        string memory facetName = vm.envString("FACET_NAME");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        if (keccak256(bytes(facetName)) == keccak256(bytes("vault"))) {
            upgradeVaultFacet();
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("teller"))) {
            upgradeTellerFacet();
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("manager"))) {
            upgradeManagerFacet();
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("accountant"))) {
            upgradeAccountantFacet();
        } else {
            revert("Invalid facet name. Use: vault, teller, manager, or accountant");
        }

        vm.stopBroadcast();
    }

    function upgradeVaultFacet() internal {
        console.log("Upgrading VaultFacet...");

        // Deploy new VaultFacet
        VaultFacet newFacet = new VaultFacet();
        console.log("New VaultFacet deployed at:", address(newFacet));

        // Get current facet address for these selectors
        IDiamondLoupe loupe = IDiamondLoupe(DIAMOND_ADDRESS);
        address currentFacet = loupe.facetAddress(VaultFacet.enter.selector);
        console.log("Current VaultFacet at:", currentFacet);

        // Prepare the function selectors
        bytes4[] memory selectors = new bytes4[](20);
        selectors[0] = VaultFacet.enter.selector;
        selectors[1] = VaultFacet.exit.selector;
        selectors[2] = VaultFacet.allocatePositions.selector;
        selectors[3] = VaultFacet.depositToHyperdrive.selector;
        selectors[4] = VaultFacet.withdrawFromHyperdrive.selector;
        selectors[5] = VaultFacet.totalAssets.selector;
        selectors[6] = VaultFacet.totalSupply.selector;
        selectors[7] = VaultFacet.shareValue.selector;
        selectors[8] = VaultFacet.shareValueOfUser.selector;
        selectors[9] = VaultFacet.availableLiquidityForWithdrawal.selector;
        selectors[10] = VaultFacet.authorize.selector;
        selectors[11] = VaultFacet.deauthorize.selector;
        selectors[12] = VaultFacet.setBeforeTransferHook.selector;
        selectors[13] = VaultFacet.isAuthorized.selector;
        selectors[14] = VaultFacet.authorized.selector;
        selectors[15] = VaultFacet.hook.selector;
        selectors[16] = VaultFacet.assetToShareDecimals.selector;
        selectors[17] = VaultFacet.getCurator.selector;
        selectors[18] = VaultFacet.isPaused.selector;
        selectors[19] = VaultFacet.pauseStatus.selector;

        replaceFacet(address(newFacet), selectors);
        console.log("VaultFacet upgraded successfully!");
    }

    function upgradeTellerFacet() internal {
        console.log("Upgrading TellerFacet...");

        TellerFacet newFacet = new TellerFacet();
        console.log("New TellerFacet deployed at:", address(newFacet));

        bytes4[] memory selectors = new bytes4[](11);
        selectors[0] = TellerFacet.deposit.selector;
        selectors[1] = TellerFacet.withdraw.selector;
        selectors[2] = TellerFacet.previewDeposit.selector;
        selectors[3] = TellerFacet.previewWithdraw.selector;
        selectors[4] = TellerFacet.setShareLockPeriod.selector;
        selectors[5] = TellerFacet.pauseTeller.selector;
        selectors[6] = TellerFacet.unpauseTeller.selector;
        selectors[7] = TellerFacet.areSharesLocked.selector;
        selectors[8] = TellerFacet.getShareUnlockTime.selector;
        selectors[9] = TellerFacet.shareLockPeriod.selector;
        selectors[10] = TellerFacet.isTellerPaused.selector;

        replaceFacet(address(newFacet), selectors);
        console.log("TellerFacet upgraded successfully!");
    }

    function upgradeManagerFacet() internal {
        console.log("Upgrading ManagerFacet...");

        ManagerFacet newFacet = new ManagerFacet();
        console.log("New ManagerFacet deployed at:", address(newFacet));

        bytes4[] memory selectors = new bytes4[](24);
        selectors[0] = ManagerFacet.allocatePositions.selector;
        selectors[1] = ManagerFacet.rebalancePositions.selector;
        selectors[2] = ManagerFacet.depositToHyperliquid.selector;
        selectors[3] = ManagerFacet.withdrawFromHyperliquid.selector;
        selectors[4] = ManagerFacet.setMaxSlippageBps.selector;
        selectors[5] = ManagerFacet.setPauseState.selector;
        selectors[6] = ManagerFacet.depositToHyperdrive.selector;
        selectors[7] = ManagerFacet.withdrawFromHyperdrive.selector;
        selectors[8] = ManagerFacet.getSpotPositions.selector;
        selectors[9] = ManagerFacet.getPerpPositions.selector;
        selectors[10] = ManagerFacet.getSpotPosition.selector;
        selectors[11] = ManagerFacet.getPerpPosition.selector;
        selectors[12] = ManagerFacet.numSpotPositions.selector;
        selectors[13] = ManagerFacet.numPerpPositions.selector;
        selectors[14] = ManagerFacet.totalSpotValue.selector;
        selectors[15] = ManagerFacet.totalPerpValue.selector;
        selectors[16] = ManagerFacet.totalHyperdriveValue.selector;
        selectors[17] = ManagerFacet.maxSlippageBps.selector;
        selectors[18] = ManagerFacet.hlCore.selector;
        selectors[19] = ManagerFacet.hlOperator.selector;
        selectors[20] = ManagerFacet.hyperdrive.selector;
        selectors[21] = ManagerFacet.isPaused.selector;
        selectors[22] = ManagerFacet.hyperdriveSharesBalance.selector;
        selectors[23] = ManagerFacet.hyperdriveSharePrice.selector;

        replaceFacet(address(newFacet), selectors);
        console.log("ManagerFacet upgraded successfully!");
    }

    function upgradeAccountantFacet() internal {
        console.log("Upgrading AccountantFacet...");

        AccountantFacet newFacet = new AccountantFacet();
        console.log("New AccountantFacet deployed at:", address(newFacet));

        bytes4[] memory selectors = new bytes4[](18);
        selectors[0] = AccountantFacet.convertToShares.selector;
        selectors[1] = AccountantFacet.convertToAssets.selector;
        selectors[2] = AccountantFacet.updateExchangeRate.selector;
        selectors[3] = AccountantFacet.chargeFees.selector;
        selectors[4] = AccountantFacet.claimFees.selector;
        selectors[5] = AccountantFacet.setPlatformFeeBps.selector;
        selectors[6] = AccountantFacet.setPerformanceFeeBps.selector;
        selectors[7] = AccountantFacet.setFeeRecipient.selector;
        selectors[8] = AccountantFacet.getRate.selector;
        selectors[9] = AccountantFacet.getTotalAssets.selector;
        selectors[10] = AccountantFacet.getTotalSupply.selector;
        selectors[11] = AccountantFacet.lastRate.selector;
        selectors[12] = AccountantFacet.platformFeeBps.selector;
        selectors[13] = AccountantFacet.performanceFeeBps.selector;
        selectors[14] = AccountantFacet.highWaterMark.selector;
        selectors[15] = AccountantFacet.accumulatedPlatformFees.selector;
        selectors[16] = AccountantFacet.accumulatedPerformanceFees.selector;
        selectors[17] = AccountantFacet.feeRecipient.selector;

        replaceFacet(address(newFacet), selectors);
        console.log("AccountantFacet upgraded successfully!");
    }

    function replaceFacet(address newFacetAddress, bytes4[] memory selectors) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: newFacetAddress,
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        IDiamondCut(DIAMOND_ADDRESS).diamondCut(cut, address(0), "");
    }
}