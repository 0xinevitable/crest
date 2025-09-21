// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from '@solmate/tokens/ERC20.sol';
import { SafeTransferLib } from '@solmate/utils/SafeTransferLib.sol';
import { FixedPointMathLib } from '@solmate/utils/FixedPointMathLib.sol';
import { Auth, Authority } from '@solmate/auth/Auth.sol';
import { ReentrancyGuard } from '@solmate/utils/ReentrancyGuard.sol';
import { CrestVault } from './CrestVault.sol';
import { CrestAccountant } from './CrestAccountant.sol';
import { IHyperdriveMarket } from './interfaces/IHyperdriveMarket.sol';

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
     * @notice The USDT0 token contract
     */
    ERC20 public immutable usdt0;

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
     * @notice Minimum deposit amount (1 USDT0 - 6 decimals)
     */
    uint256 public constant MIN_DEPOSIT = 1e6;

    /**
     * @notice Minimum shares for initial deposit
     */
    uint256 public constant MIN_INITIAL_SHARES = 1e6;

    /**
     * @notice Hyperdrive market for USDT0 yield generation
     */
    IHyperdriveMarket public hyperdriveMarket;

    /**
     * @notice Tracks Hyperdrive shares owned by the vault
     */
    uint256 public hyperdriveShares;

    //============================== ERRORS ===============================

    error CrestTeller__Paused();
    error CrestTeller__ZeroAssets();
    error CrestTeller__ZeroShares();
    error CrestTeller__MinimumDepositNotMet();
    error CrestTeller__MinimumSharesNotMet();
    error CrestTeller__SharesAreLocked();
    error CrestTeller__ShareLockPeriodTooLong();
    error CrestTeller__NoAccountant();
    error CrestTeller__NoHyperdriveMarket();

    //============================== EVENTS ===============================

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event Paused();
    event Unpaused();
    event AccountantUpdated(address indexed accountant);
    event ShareLockPeriodUpdated(uint64 period);
    event HyperdriveMarketUpdated(address indexed market);

    //============================== MODIFIERS ===============================

    modifier whenNotPaused() {
        if (isPaused) revert CrestTeller__Paused();
        _;
    }

    //============================== CONSTRUCTOR ===============================

    constructor(
        address payable _vault,
        address _usdt0,
        address _owner
    ) Auth(_owner, Authority(address(0))) {
        vault = CrestVault(_vault);
        usdt0 = ERC20(_usdt0);
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
     * @notice Sets the Hyperdrive market contract
     */
    function setHyperdriveMarket(address _market) external requiresAuth {
        // Withdraw from old market if exists
        if (address(hyperdriveMarket) != address(0) && hyperdriveShares > 0) {
            _withdrawFromHyperdrive(type(uint256).max);
        }

        hyperdriveMarket = IHyperdriveMarket(_market);
        emit HyperdriveMarketUpdated(_market);

        // Deposit to new market if vault has USDT0
        uint256 vaultBalance = usdt0.balanceOf(address(vault));
        if (vaultBalance > 0) {
            _depositToHyperdrive(vaultBalance);
        }
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
     * @notice Deposits USDT0 for vault shares
     * @param assets Amount of USDT0 to deposit
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

        // Transfer USDT0 from user to vault
        usdt0.safeTransferFrom(msg.sender, address(vault), assets);

        // Mint shares through vault
        vault.enter(address(vault), usdt0, 0, receiver, shares);

        // Deposit USDT0 to Hyperdrive if configured
        if (address(hyperdriveMarket) != address(0)) {
            _depositToHyperdrive(assets);
        }

        // Set share lock
        shareUnlockTime[receiver] = block.timestamp + shareLockPeriod;

        emit Deposit(receiver, assets, shares);
    }

    //============================== WITHDRAW FUNCTIONS ===============================

    /**
     * @notice Withdraws USDT0 by burning vault shares
     * @param shares Amount of shares to burn
     * @param receiver Address to receive the USDT0
     * @return assets Amount of USDT0 withdrawn
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

        // Withdraw from Hyperdrive if needed
        if (address(hyperdriveMarket) != address(0)) {
            uint256 vaultBalance = usdt0.balanceOf(address(vault));
            if (vaultBalance < assets) {
                _withdrawFromHyperdrive(assets - vaultBalance);
            }
        }

        // Burn shares and transfer assets through vault
        vault.exit(receiver, usdt0, assets, msg.sender, shares);

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

    /**
     * @notice Returns the current value of Hyperdrive position including yield
     */
    function getHyperdriveValue() external view returns (uint256) {
        if (address(hyperdriveMarket) == address(0) || hyperdriveShares == 0) {
            return 0;
        }
        return hyperdriveMarket.previewRedeem(hyperdriveShares);
    }

    //============================== INTERNAL FUNCTIONS ===============================

    /**
     * @notice Deposits USDT0 from vault to Hyperdrive
     */
    function _depositToHyperdrive(uint256 amount) internal {
        if (address(hyperdriveMarket) == address(0)) return;

        // Transfer USDT0 from vault to this contract
        usdt0.safeTransferFrom(address(vault), address(this), amount);

        // Approve Hyperdrive to spend USDT0
        usdt0.approve(address(hyperdriveMarket), amount);

        // Deposit to Hyperdrive
        uint256 shares = hyperdriveMarket.deposit(amount, address(this));
        hyperdriveShares += shares;
    }

    /**
     * @notice Withdraws USDT0 from Hyperdrive to vault
     */
    function _withdrawFromHyperdrive(uint256 amount) internal {
        if (address(hyperdriveMarket) == address(0) || hyperdriveShares == 0)
            return;

        uint256 sharesToBurn;
        uint256 actualWithdrawAmount;

        if (amount == type(uint256).max) {
            // Withdraw all
            sharesToBurn = hyperdriveShares;
            actualWithdrawAmount = hyperdriveMarket.previewRedeem(sharesToBurn);
        } else {
            // Calculate shares needed for specific amount
            sharesToBurn = hyperdriveMarket.previewWithdraw(amount);
            if (sharesToBurn > hyperdriveShares) {
                sharesToBurn = hyperdriveShares;
            }
            actualWithdrawAmount = amount;
        }


        // Withdraw from Hyperdrive directly to vault
        hyperdriveMarket.redeem(
            sharesToBurn,
            address(vault),
            address(this)
        );
        hyperdriveShares -= sharesToBurn;
    }

    /**
     * @notice Emergency function to withdraw all from Hyperdrive
     */
    function emergencyWithdrawFromHyperdrive() external requiresAuth {
        if (address(hyperdriveMarket) != address(0) && hyperdriveShares > 0) {
            _withdrawFromHyperdrive(type(uint256).max);
        }
    }
}
