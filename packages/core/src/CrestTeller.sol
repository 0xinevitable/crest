// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from '@solmate/tokens/ERC20.sol';
import { SafeTransferLib } from '@solmate/utils/SafeTransferLib.sol';
import { FixedPointMathLib } from '@solmate/utils/FixedPointMathLib.sol';
import { Auth, Authority } from '@solmate/auth/Auth.sol';
import { ReentrancyGuard } from '@solmate/utils/ReentrancyGuard.sol';
import { CrestVault } from './CrestVault.sol';
import { CrestAccountant } from './CrestAccountant.sol';

contract CrestTeller is Auth, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // ========================================= CONSTANTS =========================================

    /**
     * @notice The maximum share lock period.
     */
    uint256 internal constant MAX_SHARE_LOCK_PERIOD = 3 days;

    // ========================================= STATE =========================================

    /**
     * @notice The CrestVault contract
     */
    CrestVault public immutable vault;

    /**
     * @notice The Accountant contract for exchange rate calculation
     */
    CrestAccountant public accountant;

    /**
     * @notice The USDC token contract
     */
    ERC20 public immutable usdc;

    /**
     * @notice After deposits, shares are locked to the msg.sender's address for `shareLockPeriod`.
     */
    uint64 public shareLockPeriod = 1 days;

    /**
     * @notice Maps user address to the time their shares will be unlocked.
     */
    mapping(address => uint256) public shareUnlockTime;

    /**
     * @notice Used to pause deposits and withdrawals
     */
    bool public isPaused;

    /**
     * @notice Minimum deposit amount (1 USDC)
     */
    uint256 public constant MIN_DEPOSIT = 1e6;

    /**
     * @notice Minimum shares for initial deposit
     */
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
    event AccountantUpdated(address indexed accountant);
    event ShareLockPeriodUpdated(uint64 period);

    //============================== MODIFIERS ===============================

    modifier whenNotPaused() {
        if (isPaused) revert CrestTeller__Paused();
        _;
    }

    //============================== CONSTRUCTOR ===============================

    constructor(
        address payable _vault,
        address _usdc,
        address _owner
    ) Auth(_owner, Authority(address(0))) {
        vault = CrestVault(_vault);
        usdc = ERC20(_usdc);
    }

    //============================== ADMIN FUNCTIONS ===============================

    /**
     * @notice Sets the accountant contract
     */
    function setAccountant(address _accountant) external requiresAuth {
        accountant = CrestAccountant(_accountant);
        emit AccountantUpdated(_accountant);
    }

    /**
     * @notice Updates the share lock period
     */
    function setShareLockPeriod(uint64 _period) external requiresAuth {
        if (_period > MAX_SHARE_LOCK_PERIOD)
            revert CrestTeller__ShareLockPeriodTooLong();
        shareLockPeriod = _period;
        emit ShareLockPeriodUpdated(_period);
    }

    /**
     * @notice Pauses deposits and withdrawals
     */
    function pause() external requiresAuth {
        isPaused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses deposits and withdrawals
     */
    function unpause() external requiresAuth {
        isPaused = false;
        emit Unpaused();
    }

    //============================== DEPOSIT FUNCTIONS ===============================

    /**
     * @notice Deposits USDC for vault shares
     * @param assets Amount of USDC to deposit
     * @param receiver Address to receive the shares
     * @return shares Amount of shares minted
     */
    function deposit(
        uint256 assets,
        address receiver
    ) external nonReentrant whenNotPaused returns (uint256 shares) {
        if (assets == 0) revert CrestTeller__ZeroAssets();
        if (assets < MIN_DEPOSIT) revert CrestTeller__MinimumDepositNotMet();
        if (address(accountant) == address(0))
            revert CrestTeller__NoAccountant();

        // Calculate shares to mint
        shares = accountant.convertToShares(assets);
        if (shares == 0) revert CrestTeller__ZeroShares();

        // For initial deposit, ensure minimum shares
        if (vault.totalSupply() == 0 && shares < MIN_INITIAL_SHARES) {
            revert CrestTeller__MinimumSharesNotMet();
        }

        // Transfer USDC from user
        usdc.safeTransferFrom(msg.sender, address(vault), assets);

        // Mint shares through vault
        vault.enter(address(vault), usdc, 0, receiver, shares);

        // Set share lock
        shareUnlockTime[receiver] = block.timestamp + shareLockPeriod;

        emit Deposit(receiver, assets, shares);
    }

    //============================== WITHDRAW FUNCTIONS ===============================

    /**
     * @notice Withdraws USDC by burning vault shares
     * @param shares Amount of shares to burn
     * @param receiver Address to receive the USDC
     * @return assets Amount of USDC withdrawn
     */
    function withdraw(
        uint256 shares,
        address receiver
    ) external nonReentrant whenNotPaused returns (uint256 assets) {
        if (shares == 0) revert CrestTeller__ZeroShares();
        if (block.timestamp < shareUnlockTime[msg.sender])
            revert CrestTeller__SharesAreLocked();
        if (address(accountant) == address(0))
            revert CrestTeller__NoAccountant();

        // Calculate assets to withdraw
        assets = accountant.convertToAssets(shares);
        if (assets == 0) revert CrestTeller__ZeroAssets();

        // Burn shares and transfer assets through vault
        vault.exit(receiver, usdc, assets, msg.sender, shares);

        emit Withdraw(msg.sender, assets, shares);
    }

    //============================== VIEW FUNCTIONS ===============================

    /**
     * @notice Returns the amount of shares that would be minted for a given amount of assets
     */
    function previewDeposit(uint256 assets) external view returns (uint256) {
        if (address(accountant) == address(0)) return 0;
        return accountant.convertToShares(assets);
    }

    /**
     * @notice Returns the amount of assets that would be withdrawn for a given amount of shares
     */
    function previewWithdraw(uint256 shares) external view returns (uint256) {
        if (address(accountant) == address(0)) return 0;
        return accountant.convertToAssets(shares);
    }

    /**
     * @notice Returns whether a user's shares are currently locked
     */
    function areSharesLocked(address user) external view returns (bool) {
        return block.timestamp < shareUnlockTime[user];
    }

    /**
     * @notice Returns the timestamp when a user's shares will be unlocked
     */
    function getShareUnlockTime(address user) external view returns (uint256) {
        return shareUnlockTime[user];
    }
}
