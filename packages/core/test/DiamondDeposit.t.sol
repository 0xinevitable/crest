// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDiamondTeller {
    function previewDeposit(uint256 assets) external view returns (uint256);
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);
    function withdraw(
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);
    function previewWithdraw(uint256 shares) external view returns (uint256);
    function shareLockPeriod() external view returns (uint64);
    function areSharesLocked(address user) external view returns (bool);

    function usdt0() external view returns (address);
}

interface IDiamondVault {
    function authorized(address) external view returns (bool);
    function currentSpotIndex() external view returns (uint32);
    function currentPerpIndex() external view returns (uint32);
}

contract DiamondDepositTest is Test {
    address constant DIAMOND = 0x36e139CaD3fF0E3a5B7Ebae7c12b85AFAd722f54; // From deployment
    address constant USDT0 = 0xa9056c15938f9aff34CD497c722Ce33dB0C2fD57; // Testnet USDT0
    address constant CURATOR = 0x02fD526263E6D3843fdefD945511aA83c78CcF35;

    address user = makeAddr("user");

    function setUp() public {
        // Fork testnet using the RPC URL from env or command line
        // Use: forge test --fork-url <RPC_URL>

        // Give user some USDT0
        deal(USDT0, user, 1000e6); // 1000 USDT0 (6 decimals)
    }

    function test_DiamondDeployment() public {
        // Check diamond code exists
        assertTrue(DIAMOND.code.length > 0, "Diamond not deployed");

        // Check USDT0 is set correctly
        address usdt0 = IDiamondTeller(DIAMOND).usdt0();
        assertEq(usdt0, USDT0, "USDT0 address mismatch");

        // Check share lock period
        uint64 lockPeriod = IDiamondTeller(DIAMOND).shareLockPeriod();
        assertEq(lockPeriod, 1 days, "Lock period should be 1 day");

        console.log("Diamond deployed at:", DIAMOND);
        console.log("USDT0:", usdt0);
        console.log("Lock period:", lockPeriod);
    }

    function test_PreviewDeposit() public {
        uint256 depositAmount = 100e6; // 100 USDT0

        // Preview deposit - should be 1:1 initially
        uint256 expectedShares = IDiamondTeller(DIAMOND).previewDeposit(
            depositAmount
        );

        console.log("Deposit amount:", depositAmount);
        console.log("Expected shares:", expectedShares);

        // For initial deposit, should be 1:1
        assertEq(expectedShares, depositAmount, "Initial rate should be 1:1");
    }

    function test_Deposit() public {
        uint256 depositAmount = 100e6; // 100 USDT0

        vm.startPrank(user);

        // Check initial balance
        uint256 initialBalance = IERC20(USDT0).balanceOf(user);
        assertEq(initialBalance, 1000e6, "User should have 1000 USDT0");

        // Approve diamond
        IERC20(USDT0).approve(DIAMOND, depositAmount);

        // Get expected shares
        uint256 expectedShares = IDiamondTeller(DIAMOND).previewDeposit(
            depositAmount
        );

        // Deposit
        uint256 sharesBefore = IERC20(DIAMOND).balanceOf(user);
        uint256 receivedShares = IDiamondTeller(DIAMOND).deposit(
            depositAmount,
            user
        );
        uint256 sharesAfter = IERC20(DIAMOND).balanceOf(user);

        vm.stopPrank();

        // Verify results
        assertEq(
            receivedShares,
            expectedShares,
            "Received shares should match preview"
        );
        assertEq(
            sharesAfter - sharesBefore,
            receivedShares,
            "Share balance increase mismatch"
        );
        assertEq(
            IERC20(USDT0).balanceOf(user),
            initialBalance - depositAmount,
            "USDT0 not deducted"
        );

        // For initial deposit, should be 1:1
        assertEq(
            receivedShares,
            depositAmount,
            "Initial deposit should be 1:1"
        );

        console.log("Deposited:", depositAmount);
        console.log("Received shares:", receivedShares);
        console.log("User USDT0 balance:", IERC20(USDT0).balanceOf(user));
        console.log("User share balance:", sharesAfter);
    }

    function test_MultipleDeposits() public {
        // First deposit
        uint256 firstDeposit = 100e6;

        vm.startPrank(user);
        IERC20(USDT0).approve(DIAMOND, type(uint256).max);

        uint256 firstShares = IDiamondTeller(DIAMOND).deposit(
            firstDeposit,
            user
        );
        assertEq(firstShares, firstDeposit, "First deposit should be 1:1");

        // Second deposit (should still be 1:1 if no yield generated)
        uint256 secondDeposit = 50e6;
        uint256 secondShares = IDiamondTeller(DIAMOND).deposit(
            secondDeposit,
            user
        );

        // Without yield generation, should still be 1:1
        assertEq(
            secondShares,
            secondDeposit,
            "Second deposit should also be 1:1"
        );

        vm.stopPrank();

        uint256 totalShares = IERC20(DIAMOND).balanceOf(user);
        assertEq(
            totalShares,
            firstShares + secondShares,
            "Total shares mismatch"
        );

        console.log("First deposit shares:", firstShares);
        console.log("Second deposit shares:", secondShares);
        console.log("Total shares:", totalShares);
    }

    function test_VaultFacetFunctions() public {
        // Test some vault facet functions
        uint32 spotIndex = IDiamondVault(DIAMOND).currentSpotIndex();
        uint32 perpIndex = IDiamondVault(DIAMOND).currentPerpIndex();

        console.log("Current spot index:", spotIndex);
        console.log("Current perp index:", perpIndex);

        // Both should be 0 initially
        assertEq(spotIndex, 0, "Spot index should be 0 initially");
        assertEq(perpIndex, 0, "Perp index should be 0 initially");

        // Check if curator is authorized
        bool isCuratorAuthorized = IDiamondVault(DIAMOND).authorized(CURATOR);
        console.log("Curator authorized:", isCuratorAuthorized);
    }
}
