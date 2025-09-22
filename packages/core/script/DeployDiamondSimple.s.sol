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
import { LibString } from "@solmate/utils/LibString.sol";

contract DeployDiamondSimple is Script {
    uint256 constant TESTNET_CHAINID = 998;

    function usdt0Address() internal view returns (address) {
        return
            block.chainid == TESTNET_CHAINID
                ? 0xa9056c15938f9aff34CD497c722Ce33dB0C2fD57 // Testnet USDT0 (PURR)
                : 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb; // Mainnet USDT0
    }

    function _writeDeploymentJson(
        CrestDiamond diamond,
        address deployer,
        address curator,
        address feeRecipient,
        address usdt0
    ) internal {
        string memory obj = "deployment";

        // Core addresses
        vm.serializeAddress(obj, "diamond", address(diamond));
        vm.serializeAddress(obj, "deployer", deployer);
        vm.serializeAddress(obj, "curator", curator);
        vm.serializeAddress(obj, "feeRecipient", feeRecipient);
        vm.serializeAddress(obj, "usdt0", usdt0);

        // Chain info
        vm.serializeUint(obj, "chainId", block.chainid);
        vm.serializeUint(obj, "blockNumber", block.number);
        string memory output = vm.serializeUint(
            obj,
            "timestamp",
            block.timestamp
        );

        // Create deployments directory if it doesn't exist
        string memory dirPath = "./deployments/";

        // Write to file
        string memory path = string.concat(
            dirPath,
            LibString.toString(block.chainid),
            "-diamond.json"
        );

        vm.writeJson(output, path);

        console.log("\nDeployment info written to:", path);
    }

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        // Load addresses
        address owner = deployer; // Use deployer as owner
        address usdt0 = usdt0Address();
        address curator = vm.envAddress("CURATOR_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");

        console.log("Deploying with:");
        console.log("  Deployer:", deployer);
        console.log("  Owner:", owner);
        console.log("  USDT0:", usdt0);
        console.log("  Curator:", curator);
        console.log("  Fee Recipient:", feeRecipient);
        console.log("  Chain ID:", block.chainid);

        vm.startBroadcast(privateKey);

        // Step 1: Deploy DiamondInit
        console.log("\n1. Deploying DiamondInit...");
        DiamondInit diamondInit = new DiamondInit();
        console.log("   DiamondInit deployed at:", address(diamondInit));

        // Step 2: Deploy DiamondCutFacet
        console.log("\n2. Deploying DiamondCutFacet...");
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        console.log(
            "   DiamondCutFacet deployed at:",
            address(diamondCutFacet)
        );

        // Step 3: Deploy Diamond
        console.log("\n3. Deploying Diamond...");
        CrestDiamond diamond = new CrestDiamond(
            owner,
            address(diamondCutFacet),
            "Crest Vault Shares",
            "CREST"
        );
        console.log("   Diamond deployed at:", address(diamond));

        // Step 4: Deploy all facets
        console.log("\n4. Deploying facets...");

        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        console.log("   DiamondLoupeFacet:", address(diamondLoupeFacet));

        OwnershipFacet ownershipFacet = new OwnershipFacet();
        console.log("   OwnershipFacet:", address(ownershipFacet));

        VaultFacet vaultFacet = new VaultFacet();
        console.log("   VaultFacet:", address(vaultFacet));

        TellerFacet tellerFacet = new TellerFacet();
        console.log("   TellerFacet:", address(tellerFacet));

        ManagerFacet managerFacet = new ManagerFacet();
        console.log("   ManagerFacet:", address(managerFacet));

        AccountantFacet accountantFacet = new AccountantFacet();
        console.log("   AccountantFacet:", address(accountantFacet));

        // Step 5: Prepare facet cuts
        console.log("\n5. Preparing facet cuts...");
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](6);

        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // VaultFacet - split into smaller arrays to avoid stack too deep
        bytes4[] memory vaultSelectors = new bytes4[](19);
        vaultSelectors[0] = VaultFacet.authorize.selector;
        vaultSelectors[1] = VaultFacet.unauthorize.selector;
        vaultSelectors[2] = VaultFacet.authorized.selector;
        vaultSelectors[3] = bytes4(keccak256("manage(address,bytes,uint256)"));
        vaultSelectors[4] = bytes4(
            keccak256("manage(address[],bytes[],uint256[])")
        );
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
        vaultSelectors[18] = VaultFacet.hook.selector;
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultSelectors
        });

        // TellerFacet
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
        cuts[3] = IDiamondCut.FacetCut({
            facetAddress: address(tellerFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: tellerSelectors
        });

        // ManagerFacet
        bytes4[] memory managerSelectors = new bytes4[](18);
        managerSelectors[0] = ManagerFacet.allocate__bridgeToCore.selector;
        managerSelectors[1] = ManagerFacet.allocate__swapToUSDC.selector;
        managerSelectors[2] = ManagerFacet.allocatePositions.selector;
        managerSelectors[3] = ManagerFacet.rebalancePositions.selector;
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
        managerSelectors[14] = ManagerFacet.totalAllocated.selector;
        managerSelectors[15] = ManagerFacet.isManagerPaused.selector;

        managerSelectors[16] = ManagerFacet.transferUsdClass.selector;
        managerSelectors[17] = ManagerFacet.placeLimitOrder.selector;

        cuts[4] = IDiamondCut.FacetCut({
            facetAddress: address(managerFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: managerSelectors
        });

        // AccountantFacet
        bytes4[] memory accountantSelectors = new bytes4[](19);
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
        accountantSelectors[15] = AccountantFacet
            .accumulatedPlatformFees
            .selector;
        accountantSelectors[16] = AccountantFacet
            .accumulatedPerformanceFees
            .selector;
        accountantSelectors[17] = AccountantFacet.feeRecipient.selector;
        accountantSelectors[18] = AccountantFacet.isAccountantPaused.selector;
        cuts[5] = IDiamondCut.FacetCut({
            facetAddress: address(accountantFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: accountantSelectors
        });

        // Step 6: Prepare init data
        console.log("\n6. Preparing initialization data...");
        DiamondInit.InitArgs memory initArgs = DiamondInit.InitArgs({
            usdt0: usdt0,
            curator: curator,
            feeRecipient: feeRecipient,
            shareLockPeriod: 1 days,
            platformFeeBps: 100, // 1%
            performanceFeeBps: 500, // 5%
            maxSlippageBps: 100 // 1%
        });

        bytes memory initData = abi.encodeWithSelector(
            DiamondInit.init.selector,
            initArgs
        );

        // Step 7: Execute diamond cut
        console.log("\n7. Executing diamond cut...");
        IDiamondCut(address(diamond)).diamondCut(
            cuts,
            address(diamondInit),
            initData
        );

        console.log("\nDiamond deployment complete!");
        console.log("Diamond address:", address(diamond));

        // Write deployment info to JSON
        _writeDeploymentJson(diamond, deployer, curator, feeRecipient, usdt0);

        vm.stopBroadcast();
    }
}
