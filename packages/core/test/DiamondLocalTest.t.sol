// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
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

// Mock USDT0 token for testing
contract MockUSDT0 is ERC20 {
    constructor() ERC20("Mock USDT0", "USDT0", 6) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Interfaces for calling diamond functions
interface IDiamondTeller {
    function previewDeposit(uint256 assets) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 shares, address receiver) external returns (uint256 assets);
    function previewWithdraw(uint256 shares) external view returns (uint256);
    function shareLockPeriod() external view returns (uint64);
    function areSharesLocked(address user) external view returns (bool);
}

contract DiamondLocalTest is Test {
    CrestDiamond public diamond;
    MockUSDT0 public usdt0;

    address public owner = address(this);
    address public curator = makeAddr("curator");
    address public feeRecipient = makeAddr("feeRecipient");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);

    function setUp() public {
        // Deploy mock USDT0
        usdt0 = new MockUSDT0();

        // Deploy and setup diamond
        diamond = _deployDiamond();

        // Mint USDT0 to test users
        usdt0.mint(alice, 1000e6); // 1000 USDT0
        usdt0.mint(bob, 1000e6); // 1000 USDT0

        // Label addresses for better test output
        vm.label(address(diamond), "Diamond");
        vm.label(address(usdt0), "USDT0");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
    }

    function _deployDiamond() internal returns (CrestDiamond) {
        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();

        // Deploy DiamondCutFacet
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        // Deploy Diamond
        CrestDiamond _diamond = new CrestDiamond(
            owner,
            address(diamondCutFacet),
            "Crest Vault Shares",
            "CREST"
        );

        // Deploy all facets
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        VaultFacet vaultFacet = new VaultFacet();
        TellerFacet tellerFacet = new TellerFacet();
        ManagerFacet managerFacet = new ManagerFacet();
        AccountantFacet accountantFacet = new AccountantFacet();

        // Prepare facet cuts
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

        // VaultFacet
        bytes4[] memory vaultSelectors = new bytes4[](19);
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
        bytes4[] memory managerSelectors = new bytes4[](16);
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
        accountantSelectors[15] = AccountantFacet.accumulatedPlatformFees.selector;
        accountantSelectors[16] = AccountantFacet.accumulatedPerformanceFees.selector;
        accountantSelectors[17] = AccountantFacet.feeRecipient.selector;
        accountantSelectors[18] = AccountantFacet.isAccountantPaused.selector;
        cuts[5] = IDiamondCut.FacetCut({
            facetAddress: address(accountantFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: accountantSelectors
        });

        // Prepare init data
        DiamondInit.InitArgs memory initArgs = DiamondInit.InitArgs({
            usdt0: address(usdt0),
            curator: curator,
            feeRecipient: feeRecipient,
            shareLockPeriod: 1 days,
            platformFeeBps: 100, // 1%
            performanceFeeBps: 500, // 5%
            maxSlippageBps: 100 // 1%
        });

        bytes memory initData = abi.encodeWithSelector(DiamondInit.init.selector, initArgs);

        // Execute diamond cut
        IDiamondCut(address(_diamond)).diamondCut(cuts, address(diamondInit), initData);

        // Authorize the diamond itself so facets can call each other
        VaultFacet(address(_diamond)).authorize(address(_diamond));

        return _diamond;
    }

    function test_PreviewDeposit_InitialRate() public {
        uint256 depositAmount = 100e6; // 100 USDT0

        // Preview deposit - should be 1:1 initially
        uint256 expectedShares = IDiamondTeller(address(diamond)).previewDeposit(depositAmount);

        assertEq(expectedShares, depositAmount, "Initial rate should be 1:1");

        console.log("Deposit amount:", depositAmount);
        console.log("Expected shares:", expectedShares);
        console.log("Rate: 1:1 [PASS]");
    }

    function test_PreviewDeposit_VariousAmounts() public {
        uint256[5] memory amounts = [uint256(1e6), 10e6, 100e6, 1000e6, 10000e6];

        for (uint i = 0; i < amounts.length; i++) {
            uint256 shares = IDiamondTeller(address(diamond)).previewDeposit(amounts[i]);
            assertEq(shares, amounts[i], "Should be 1:1 for all amounts initially");
            console.log("Amount:", amounts[i], "-> Shares:", shares);
        }
    }

    function test_Deposit_SingleUser() public {
        uint256 depositAmount = 100e6; // 100 USDT0

        vm.startPrank(alice);

        // Approve diamond
        usdt0.approve(address(diamond), depositAmount);

        // Get expected shares
        uint256 expectedShares = IDiamondTeller(address(diamond)).previewDeposit(depositAmount);

        // Check initial balances
        uint256 aliceUsdt0Before = usdt0.balanceOf(alice);
        uint256 aliceSharesBefore = diamond.balanceOf(alice);
        uint256 vaultUsdt0Before = usdt0.balanceOf(address(diamond));

        // Deposit
        vm.expectEmit(true, false, false, true, address(diamond));
        emit Deposit(alice, depositAmount, expectedShares);

        uint256 receivedShares = IDiamondTeller(address(diamond)).deposit(depositAmount, alice);

        vm.stopPrank();

        // Verify balances
        assertEq(receivedShares, expectedShares, "Received shares should match preview");
        assertEq(receivedShares, depositAmount, "Should be 1:1 initially");
        assertEq(diamond.balanceOf(alice), aliceSharesBefore + receivedShares, "Alice shares incorrect");
        assertEq(usdt0.balanceOf(alice), aliceUsdt0Before - depositAmount, "Alice USDT0 not deducted");
        assertEq(usdt0.balanceOf(address(diamond)), vaultUsdt0Before + depositAmount, "Vault USDT0 incorrect");

        console.log("Alice deposited:", depositAmount);
        console.log("Alice received shares:", receivedShares);
        console.log("Diamond USDT0 balance:", usdt0.balanceOf(address(diamond)));
    }

    function test_Deposit_MultipleUsers() public {
        uint256 aliceDeposit = 100e6;
        uint256 bobDeposit = 200e6;

        // Alice deposits first
        vm.startPrank(alice);
        usdt0.approve(address(diamond), aliceDeposit);
        uint256 aliceShares = IDiamondTeller(address(diamond)).deposit(aliceDeposit, alice);
        vm.stopPrank();

        assertEq(aliceShares, aliceDeposit, "Alice should get 1:1");
        assertEq(diamond.totalSupply(), aliceShares, "Total supply should equal Alice shares");

        // Bob deposits second (still 1:1 if no yield)
        vm.startPrank(bob);
        usdt0.approve(address(diamond), bobDeposit);
        uint256 bobShares = IDiamondTeller(address(diamond)).deposit(bobDeposit, bob);
        vm.stopPrank();

        assertEq(bobShares, bobDeposit, "Bob should also get 1:1");
        assertEq(diamond.totalSupply(), aliceShares + bobShares, "Total supply incorrect");

        console.log("Alice shares:", aliceShares);
        console.log("Bob shares:", bobShares);
        console.log("Total supply:", diamond.totalSupply());
        console.log("Vault USDT0:", usdt0.balanceOf(address(diamond)));
    }

    function test_Deposit_CheckShareLock() public {
        uint256 depositAmount = 100e6;

        vm.startPrank(alice);
        usdt0.approve(address(diamond), depositAmount);

        // Check lock period
        uint64 lockPeriod = IDiamondTeller(address(diamond)).shareLockPeriod();
        assertEq(lockPeriod, 1 days, "Lock period should be 1 day");

        // Deposit
        IDiamondTeller(address(diamond)).deposit(depositAmount, alice);

        // Check if shares are locked
        bool locked = IDiamondTeller(address(diamond)).areSharesLocked(alice);
        assertTrue(locked, "Shares should be locked after deposit");

        vm.stopPrank();

        console.log("Share lock period:", lockPeriod, "seconds");
        console.log("Alice shares locked:", locked);
    }

    function test_PreviewWithdraw() public {
        uint256 depositAmount = 100e6;

        // Setup: Alice deposits first
        vm.startPrank(alice);
        usdt0.approve(address(diamond), depositAmount);
        uint256 shares = IDiamondTeller(address(diamond)).deposit(depositAmount, alice);
        vm.stopPrank();

        // Preview withdrawal
        uint256 expectedAssets = IDiamondTeller(address(diamond)).previewWithdraw(shares);

        // Should be 1:1 if no yield/loss
        assertEq(expectedAssets, depositAmount, "Withdrawal should be 1:1");

        console.log("Shares to withdraw:", shares);
        console.log("Expected USDT0:", expectedAssets);
    }

    function test_Deposit_SmallAmounts() public {
        // Test very small deposits work fine
        uint256 smallDeposit = 1; // 0.000001 USDT0

        vm.startPrank(alice);
        usdt0.approve(address(diamond), smallDeposit);

        // Should succeed even with tiny amount
        uint256 shares = IDiamondTeller(address(diamond)).deposit(smallDeposit, alice);
        assertEq(shares, smallDeposit, "Small deposit should work");

        vm.stopPrank();

        // Test regular small amount
        uint256 regularSmall = 1e6; // 1 USDT0

        vm.startPrank(bob);
        usdt0.approve(address(diamond), regularSmall);

        uint256 bobShares = IDiamondTeller(address(diamond)).deposit(regularSmall, bob);
        assertEq(bobShares, regularSmall, "1 USDT0 deposit should work");

        vm.stopPrank();

        console.log("Small deposit (0.000001 USDT0) succeeded");
        console.log("Regular small deposit (1 USDT0) succeeded");
    }

    function testFuzz_Deposit(uint256 amount) public {
        // Bound to reasonable amounts
        amount = bound(amount, 1e6, 1000000e6); // 1 to 1M USDT0

        // Mint exact amount to alice
        deal(address(usdt0), alice, amount);

        vm.startPrank(alice);
        usdt0.approve(address(diamond), amount);

        uint256 preview = IDiamondTeller(address(diamond)).previewDeposit(amount);
        uint256 shares = IDiamondTeller(address(diamond)).deposit(amount, alice);

        vm.stopPrank();

        // Verify 1:1 ratio and preview accuracy
        assertEq(shares, amount, "Should always be 1:1 initially");
        assertEq(shares, preview, "Preview should match actual");
        assertEq(diamond.balanceOf(alice), shares, "Share balance incorrect");
        assertEq(usdt0.balanceOf(address(diamond)), amount, "Vault balance incorrect");
    }
}