// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { CrestDiamond } from "./CrestDiamond.sol";
import { DiamondCutFacet } from "./facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "./facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "./facets/OwnershipFacet.sol";
import { VaultFacet } from "./facets/VaultFacet.sol";
import { TellerFacet } from "./facets/TellerFacet.sol";
import { ManagerFacet } from "./facets/ManagerFacet.sol";
import { AccountantFacet } from "./facets/AccountantFacet.sol";
import { DiamondInit } from "./upgradeInitializers/DiamondInit.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

contract DeployDiamond {
    struct DeploymentParams {
        address owner;
        address usdt0;
        address curator;
        address feeRecipient;
        string name;
        string symbol;
        uint64 shareLockPeriod;
        uint16 platformFeeBps;
        uint16 performanceFeeBps;
        uint16 maxSlippageBps;
    }

    function deployDiamond(DeploymentParams memory params) external returns (address) {
        // Deploy DiamondCutFacet
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        // Deploy Diamond
        CrestDiamond diamond = new CrestDiamond(
            params.owner,
            address(diamondCutFacet),
            params.name,
            params.symbol
        );

        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();

        // Deploy facets
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        VaultFacet vaultFacet = new VaultFacet();
        TellerFacet tellerFacet = new TellerFacet();
        ManagerFacet managerFacet = new ManagerFacet();
        AccountantFacet accountantFacet = new AccountantFacet();

        // Build cut struct with all facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](6);

        // Add DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Add VaultFacet
        bytes4[] memory vaultSelectors = new bytes4[](18);
        vaultSelectors[0] = VaultFacet.authorize.selector;
        vaultSelectors[1] = VaultFacet.unauthorize.selector;
        vaultSelectors[2] = VaultFacet.authorized.selector;
        vaultSelectors[3] = bytes4(keccak256("manage(address,bytes,uint256)"));
        vaultSelectors[4] = bytes4(keccak256("manage(address[],bytes[],uint256[])"));
        vaultSelectors[5] = VaultFacet.allocate.selector;
        vaultSelectors[6] = VaultFacet.rebalance.selector;
        vaultSelectors[7] = VaultFacet.enter.selector;
        vaultSelectors[8] = VaultFacet.exit.selector;
        vaultSelectors[9] = VaultFacet.setHyperdriveMarket.selector;
        vaultSelectors[10] = VaultFacet.depositToHyperdrive.selector;
        vaultSelectors[11] = VaultFacet.withdrawFromHyperdrive.selector;
        vaultSelectors[12] = VaultFacet.getHyperdriveValue.selector;
        vaultSelectors[13] = VaultFacet.setBeforeTransferHook.selector;
        vaultSelectors[14] = VaultFacet.beforeTransferHook.selector;
        vaultSelectors[15] = VaultFacet.currentSpotIndex.selector;
        vaultSelectors[16] = VaultFacet.currentPerpIndex.selector;
        vaultSelectors[17] = VaultFacet.hyperdriveShares.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultSelectors
        });

        // Add TellerFacet
        bytes4[] memory tellerSelectors = new bytes4[](12);
        tellerSelectors[0] = TellerFacet.setShareLockPeriod.selector;
        tellerSelectors[1] = TellerFacet.pauseTeller.selector;
        tellerSelectors[2] = TellerFacet.unpauseTeller.selector;
        tellerSelectors[3] = TellerFacet.deposit.selector;
        tellerSelectors[4] = TellerFacet.withdraw.selector;
        tellerSelectors[5] = TellerFacet.previewDeposit.selector;
        tellerSelectors[6] = TellerFacet.previewWithdraw.selector;
        tellerSelectors[7] = TellerFacet.areSharesLocked.selector;
        tellerSelectors[8] = TellerFacet.getShareUnlockTime.selector;
        tellerSelectors[9] = TellerFacet.shareLockPeriod.selector;
        tellerSelectors[10] = TellerFacet.isTellerPaused.selector;
        tellerSelectors[11] = TellerFacet.usdt0.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(tellerFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: tellerSelectors
        });

        // Add ManagerFacet
        bytes4[] memory managerSelectors = new bytes4[](14);
        managerSelectors[0] = ManagerFacet.allocate__bridgeToCore.selector;
        managerSelectors[1] = ManagerFacet.allocate__swapToUSDC.selector;
        managerSelectors[2] = ManagerFacet.allocate.selector;
        managerSelectors[3] = ManagerFacet.rebalance.selector;
        managerSelectors[4] = ManagerFacet.exit.selector;
        managerSelectors[5] = ManagerFacet.updateCurator.selector;
        managerSelectors[6] = ManagerFacet.updateMaxSlippage.selector;
        managerSelectors[7] = ManagerFacet.pauseManager.selector;
        managerSelectors[8] = ManagerFacet.unpauseManager.selector;
        managerSelectors[9] = ManagerFacet.getPositions.selector;
        managerSelectors[10] = ManagerFacet.hasOpenPositions.selector;
        managerSelectors[11] = ManagerFacet.estimatePositionValue.selector;
        managerSelectors[12] = ManagerFacet.curator.selector;
        managerSelectors[13] = ManagerFacet.maxSlippageBps.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(managerFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: managerSelectors
        });

        // Add AccountantFacet
        bytes4[] memory accountantSelectors = new bytes4[](18);
        accountantSelectors[0] = AccountantFacet.collectFees.selector;
        accountantSelectors[1] = AccountantFacet.updateFees.selector;
        accountantSelectors[2] = AccountantFacet.updateFeeRecipient.selector;
        accountantSelectors[3] = AccountantFacet.pauseAccountant.selector;
        accountantSelectors[4] = AccountantFacet.unpauseAccountant.selector;
        accountantSelectors[5] = AccountantFacet.getTotalAssets.selector;
        accountantSelectors[6] = AccountantFacet.getRate.selector;
        accountantSelectors[7] = AccountantFacet.updateAccountantFees.selector;
        accountantSelectors[8] = AccountantFacet.exchangeRate.selector;
        accountantSelectors[9] = AccountantFacet.convertToShares.selector;
        accountantSelectors[10] = AccountantFacet.convertToAssets.selector;
        accountantSelectors[11] = AccountantFacet.lastTotalAssets.selector;
        accountantSelectors[12] = AccountantFacet.platformFeeBps.selector;
        accountantSelectors[13] = AccountantFacet.performanceFeeBps.selector;
        accountantSelectors[14] = AccountantFacet.highWaterMark.selector;
        accountantSelectors[15] = AccountantFacet.accumulatedPlatformFees.selector;
        accountantSelectors[16] = AccountantFacet.accumulatedPerformanceFees.selector;
        accountantSelectors[17] = AccountantFacet.feeRecipient.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(accountantFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: accountantSelectors
        });

        // Prepare init data
        DiamondInit.InitArgs memory initArgs = DiamondInit.InitArgs({
            usdt0: params.usdt0,
            curator: params.curator,
            feeRecipient: params.feeRecipient,
            shareLockPeriod: params.shareLockPeriod,
            platformFeeBps: params.platformFeeBps,
            performanceFeeBps: params.performanceFeeBps,
            maxSlippageBps: params.maxSlippageBps
        });

        bytes memory initData = abi.encodeWithSelector(DiamondInit.init.selector, initArgs);

        // Execute diamond cut with initialization
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), initData);

        return address(diamond);
    }
}