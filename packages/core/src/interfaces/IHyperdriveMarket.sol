// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IHyperdriveMarket {
    /**
     * @notice Preview how many shares would be minted for depositing assets
     * @param assets Amount of assets to deposit
     * @return shares Amount of shares that would be minted
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Deposit assets and mint shares to receiver
     * @param assets Amount of assets to deposit
     * @param receiver Address to receive the shares
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice Preview how many shares would be burned for withdrawing assets
     * @param assets Amount of assets to withdraw
     * @return shares Amount of shares that would be burned
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Withdraw assets by burning shares from owner
     * @param assets Amount of assets to withdraw
     * @param receiver Address to receive the assets
     * @param owner Address that owns the shares
     * @return shares Amount of shares burned
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @notice Preview how many assets would be received for redeeming shares
     * @param shares Amount of shares to redeem
     * @return assets Amount of assets that would be received
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice Redeem shares for assets
     * @param shares Amount of shares to redeem
     * @param receiver Address to receive the assets
     * @param owner Address that owns the shares
     * @return assets Amount of assets received
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /**
     * @notice Get the balance of shares for an account
     * @param account Address to check balance for
     * @return Balance of shares
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Get the total supply of shares
     * @return Total supply of shares
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Approve spender to spend shares
     * @param spender Address to approve
     * @param amount Amount to approve
     * @return success Whether approval was successful
     */
    function approve(address spender, uint256 amount) external returns (bool);
}