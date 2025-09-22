// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import { IDiamondCut } from "../src/diamond/interfaces/IDiamondCut.sol";
import { DiamondInit } from "../src/diamond/upgradeInitializers/DiamondInit.sol";
import { CrestDiamond } from "../src/diamond/CrestDiamond.sol";
import { DiamondCutFacet } from "../src/diamond/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/diamond/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/diamond/facets/OwnershipFacet.sol";
import { VaultFacet } from "../src/diamond/facets/VaultFacet.sol";
import { TellerFacet } from "../src/diamond/facets/TellerFacet.sol";
import { ManagerFacet } from "../src/diamond/facets/ManagerFacet.sol";
import { AccountantFacet } from "../src/diamond/facets/AccountantFacet.sol";

contract DeployCrestDiamondV2 is Script {
    // Store the FacetCut struct for each facet being deployed
    IDiamondCut.FacetCut[] private _facetCuts;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        address owner = vm.envOr("OWNER_ADDRESS", deployer);
        address usdt0 = vm.envAddress("USDT0_ADDRESS");
        address curator = vm.envAddress("CURATOR_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");

        vm.startBroadcast(privateKey);

        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();

        // Deploy DiamondCutFacet first (needed for Diamond constructor)
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        // Deploy Diamond
        CrestDiamond diamond = new CrestDiamond(
            owner,
            address(diamondCutFacet),
            "Crest Vault Shares",
            "CREST"
        );

        // Deploy and register all facets
        string[6] memory facets = [
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "VaultFacet",
            "TellerFacet",
            "ManagerFacet",
            "AccountantFacet"
        ];

        // Use FFI to get selectors
        string[] memory inputs = new string[](3);
        inputs[0] = "forge";
        inputs[1] = "inspect";

        for (uint256 i = 0; i < facets.length; i++) {
            string memory facetName = facets[i];

            // Deploy the facet
            address facetAddress;
            if (keccak256(bytes(facetName)) == keccak256(bytes("DiamondLoupeFacet"))) {
                facetAddress = address(new DiamondLoupeFacet());
            } else if (keccak256(bytes(facetName)) == keccak256(bytes("OwnershipFacet"))) {
                facetAddress = address(new OwnershipFacet());
            } else if (keccak256(bytes(facetName)) == keccak256(bytes("VaultFacet"))) {
                facetAddress = address(new VaultFacet());
            } else if (keccak256(bytes(facetName)) == keccak256(bytes("TellerFacet"))) {
                facetAddress = address(new TellerFacet());
            } else if (keccak256(bytes(facetName)) == keccak256(bytes("ManagerFacet"))) {
                facetAddress = address(new ManagerFacet());
            } else if (keccak256(bytes(facetName)) == keccak256(bytes("AccountantFacet"))) {
                facetAddress = address(new AccountantFacet());
            }

            // Get selectors (using hardcoded approach for simplicity)
            bytes4[] memory selectors = getSelectorsForFacet(facetName);

            // Create FacetCut struct
            _facetCuts.push(
                IDiamondCut.FacetCut({
                    facetAddress: facetAddress,
                    action: IDiamondCut.FacetCutAction.Add,
                    functionSelectors: selectors
                })
            );
        }

        // Prepare init data
        DiamondInit.InitArgs memory initArgs = DiamondInit.InitArgs({
            usdt0: usdt0,
            curator: curator,
            feeRecipient: feeRecipient,
            shareLockPeriod: 1 days,
            platformFeeBps: 100,
            performanceFeeBps: 500,
            maxSlippageBps: 100
        });

        bytes memory initData = abi.encodeWithSelector(
            DiamondInit.init.selector,
            initArgs
        );

        // Execute diamond cut with all facets
        IDiamondCut(address(diamond)).diamondCut(
            _facetCuts,
            address(diamondInit),
            initData
        );

        vm.stopBroadcast();

        // Log deployment info
        console.log("Diamond deployed at:", address(diamond));
        console.log("Owner:", owner);
        console.log("USDT0:", usdt0);
        console.log("Curator:", curator);
        console.log("Fee Recipient:", feeRecipient);
    }

    function getSelectorsForFacet(string memory facetName) private pure returns (bytes4[] memory) {
        if (keccak256(bytes(facetName)) == keccak256(bytes("DiamondLoupeFacet"))) {
            bytes4[] memory selectors = new bytes4[](5);
            selectors[0] = DiamondLoupeFacet.facets.selector;
            selectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
            selectors[2] = DiamondLoupeFacet.facetAddresses.selector;
            selectors[3] = DiamondLoupeFacet.facetAddress.selector;
            selectors[4] = DiamondLoupeFacet.supportsInterface.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("OwnershipFacet"))) {
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = OwnershipFacet.transferOwnership.selector;
            selectors[1] = OwnershipFacet.owner.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("VaultFacet"))) {
            bytes4[] memory selectors = new bytes4[](18);
            selectors[0] = VaultFacet.authorize.selector;
            selectors[1] = VaultFacet.unauthorize.selector;
            selectors[2] = VaultFacet.authorized.selector;
            selectors[3] = bytes4(keccak256("manage(address,bytes,uint256)"));
            selectors[4] = bytes4(keccak256("manage(address[],bytes[],uint256[])"));
            selectors[5] = VaultFacet.allocate.selector;
            selectors[6] = VaultFacet.rebalance.selector;
            selectors[7] = VaultFacet.enter.selector;
            selectors[8] = VaultFacet.exit.selector;
            selectors[9] = VaultFacet.setHyperdriveMarket.selector;
            selectors[10] = VaultFacet.depositToHyperdrive.selector;
            selectors[11] = VaultFacet.withdrawFromHyperdrive.selector;
            selectors[12] = VaultFacet.getHyperdriveValue.selector;
            selectors[13] = VaultFacet.setBeforeTransferHook.selector;
            selectors[14] = VaultFacet.beforeTransferHook.selector;
            selectors[15] = VaultFacet.currentSpotIndex.selector;
            selectors[16] = VaultFacet.currentPerpIndex.selector;
            selectors[17] = VaultFacet.hyperdriveShares.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("TellerFacet"))) {
            bytes4[] memory selectors = new bytes4[](12);
            selectors[0] = TellerFacet.setShareLockPeriod.selector;
            selectors[1] = TellerFacet.pauseTeller.selector;
            selectors[2] = TellerFacet.unpauseTeller.selector;
            selectors[3] = TellerFacet.deposit.selector;
            selectors[4] = TellerFacet.withdraw.selector;
            selectors[5] = TellerFacet.previewDeposit.selector;
            selectors[6] = TellerFacet.previewWithdraw.selector;
            selectors[7] = TellerFacet.areSharesLocked.selector;
            selectors[8] = TellerFacet.getShareUnlockTime.selector;
            selectors[9] = TellerFacet.shareLockPeriod.selector;
            selectors[10] = TellerFacet.isTellerPaused.selector;
            selectors[11] = TellerFacet.usdt0.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("ManagerFacet"))) {
            bytes4[] memory selectors = new bytes4[](14);
            selectors[0] = ManagerFacet.allocate__bridgeToCore.selector;
            selectors[1] = ManagerFacet.allocate__swapToUSDC.selector;
            selectors[2] = ManagerFacet.allocate.selector;
            selectors[3] = ManagerFacet.rebalance.selector;
            selectors[4] = ManagerFacet.exit.selector;
            selectors[5] = ManagerFacet.updateCurator.selector;
            selectors[6] = ManagerFacet.updateMaxSlippage.selector;
            selectors[7] = ManagerFacet.pauseManager.selector;
            selectors[8] = ManagerFacet.unpauseManager.selector;
            selectors[9] = ManagerFacet.getPositions.selector;
            selectors[10] = ManagerFacet.hasOpenPositions.selector;
            selectors[11] = ManagerFacet.estimatePositionValue.selector;
            selectors[12] = ManagerFacet.curator.selector;
            selectors[13] = ManagerFacet.maxSlippageBps.selector;
            return selectors;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("AccountantFacet"))) {
            bytes4[] memory selectors = new bytes4[](18);
            selectors[0] = AccountantFacet.collectFees.selector;
            selectors[1] = AccountantFacet.updateFees.selector;
            selectors[2] = AccountantFacet.updateFeeRecipient.selector;
            selectors[3] = AccountantFacet.pauseAccountant.selector;
            selectors[4] = AccountantFacet.unpauseAccountant.selector;
            selectors[5] = AccountantFacet.getTotalAssets.selector;
            selectors[6] = AccountantFacet.getRate.selector;
            selectors[7] = AccountantFacet.updateAccountantFees.selector;
            selectors[8] = AccountantFacet.exchangeRate.selector;
            selectors[9] = AccountantFacet.convertToShares.selector;
            selectors[10] = AccountantFacet.convertToAssets.selector;
            selectors[11] = AccountantFacet.lastTotalAssets.selector;
            selectors[12] = AccountantFacet.platformFeeBps.selector;
            selectors[13] = AccountantFacet.performanceFeeBps.selector;
            selectors[14] = AccountantFacet.highWaterMark.selector;
            selectors[15] = AccountantFacet.accumulatedPlatformFees.selector;
            selectors[16] = AccountantFacet.accumulatedPerformanceFees.selector;
            selectors[17] = AccountantFacet.feeRecipient.selector;
            return selectors;
        }

        revert("Unknown facet name");
    }
}