// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "@solmate/utils/FixedPointMathLib.sol";
import { ReentrancyGuard } from "@solmate/utils/ReentrancyGuard.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibCrestStorage } from "../libraries/LibCrestStorage.sol";

contract TellerFacet is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // ========================================= CONSTANTS =========================================

    uint256 internal constant MAX_SHARE_LOCK_PERIOD = 3 days;
    uint256 public constant MIN_DEPOSIT = 1e6;
    uint256 public constant MIN_INITIAL_SHARES = 1e6;

    //============================== ERRORS ===============================

    error CrestTeller__Paused();
    error CrestTeller__ZeroAssets();
    error CrestTeller__ZeroShares();
    error CrestTeller__MinimumDepositNotMet();
    error CrestTeller__MinimumSharesNotMet();
    error CrestTeller__SharesAreLocked();
    error CrestTeller__ShareLockPeriodTooLong();
    error CrestTeller__NoAccountant();

    //============================== EVENTS ===============================

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event Paused();
    event Unpaused();
    event ShareLockPeriodUpdated(uint64 period);

    //============================== MODIFIERS ===============================

    modifier whenNotPaused() {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        if (cs.isTellerPaused) revert CrestTeller__Paused();
        _;
    }

    modifier requiresAuth() {
        require(
            msg.sender == LibDiamond.contractOwner(),
            "UNAUTHORIZED"
        );
        _;
    }

    //============================== ADMIN FUNCTIONS ===============================

    function setShareLockPeriod(uint64 _period) external requiresAuth {
        if (_period > MAX_SHARE_LOCK_PERIOD)
            revert CrestTeller__ShareLockPeriodTooLong();
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        cs.shareLockPeriod = _period;
        emit ShareLockPeriodUpdated(_period);
    }

    function pauseTeller() external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        cs.isTellerPaused = true;
        emit Paused();
    }

    function unpauseTeller() external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        cs.isTellerPaused = false;
        emit Unpaused();
    }

    //============================== DEPOSIT FUNCTIONS ===============================

    function deposit(
        uint256 assets,
        address receiver
    ) external nonReentrant whenNotPaused returns (uint256 shares) {
        if (assets == 0) revert CrestTeller__ZeroAssets();
        if (assets < MIN_DEPOSIT) revert CrestTeller__MinimumDepositNotMet();

        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();

        // Calculate shares to mint using AccountantFacet
        shares = IAccountantFacet(address(this)).convertToShares(assets);
        if (shares == 0) revert CrestTeller__ZeroShares();

        // For initial deposit, ensure minimum shares
        if (ERC20(address(this)).totalSupply() == 0 && shares < MIN_INITIAL_SHARES) {
            revert CrestTeller__MinimumSharesNotMet();
        }

        // Transfer USDT0 from user to diamond
        cs.usdt0.safeTransferFrom(msg.sender, address(this), assets);

        // Mint shares through vault facet
        IVaultFacet(address(this)).enter(address(this), cs.usdt0, 0, receiver, shares);

        // Deposit to Hyperdrive through vault facet
        IVaultFacet(address(this)).depositToHyperdrive(cs.usdt0, assets);

        // Set share lock
        cs.shareUnlockTime[receiver] = block.timestamp + cs.shareLockPeriod;

        emit Deposit(receiver, assets, shares);
    }

    //============================== WITHDRAW FUNCTIONS ===============================

    function withdraw(
        uint256 shares,
        address receiver
    ) external nonReentrant whenNotPaused returns (uint256 assets) {
        if (shares == 0) revert CrestTeller__ZeroShares();

        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();

        if (block.timestamp < cs.shareUnlockTime[msg.sender])
            revert CrestTeller__SharesAreLocked();

        // Calculate assets to withdraw using AccountantFacet
        assets = IAccountantFacet(address(this)).convertToAssets(shares);
        if (assets == 0) revert CrestTeller__ZeroAssets();

        // Check if vault needs to withdraw from Hyperdrive
        uint256 vaultBalance = cs.usdt0.balanceOf(address(this));
        if (vaultBalance < assets) {
            IVaultFacet(address(this)).withdrawFromHyperdrive(assets - vaultBalance);
        }

        // Burn shares and transfer assets through vault facet
        IVaultFacet(address(this)).exit(receiver, cs.usdt0, assets, msg.sender, shares);

        emit Withdraw(msg.sender, assets, shares);
    }

    //============================== VIEW FUNCTIONS ===============================

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return IAccountantFacet(address(this)).convertToShares(assets);
    }

    function previewWithdraw(uint256 shares) external view returns (uint256) {
        return IAccountantFacet(address(this)).convertToAssets(shares);
    }

    function areSharesLocked(address user) external view returns (bool) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        return block.timestamp < cs.shareUnlockTime[user];
    }

    function getShareUnlockTime(address user) external view returns (uint256) {
        return LibCrestStorage.crestStorage().shareUnlockTime[user];
    }

    function shareLockPeriod() external view returns (uint64) {
        return LibCrestStorage.crestStorage().shareLockPeriod;
    }

    function isTellerPaused() external view returns (bool) {
        return LibCrestStorage.crestStorage().isTellerPaused;
    }

    function usdt0() external view returns (address) {
        return address(LibCrestStorage.crestStorage().usdt0);
    }
}

// Interfaces for cross-facet calls
interface IVaultFacet {
    function enter(address from, ERC20 asset, uint256 assetAmount, address to, uint256 shareAmount) external;
    function exit(address to, ERC20 asset, uint256 assetAmount, address from, uint256 shareAmount) external;
    function depositToHyperdrive(ERC20 usdt0, uint256 amount) external;
    function withdrawFromHyperdrive(uint256 amount) external returns (uint256);
}

interface IAccountantFacet {
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}