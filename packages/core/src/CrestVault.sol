// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { ERC721Holder } from '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import { ERC1155Holder } from '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import { FixedPointMathLib } from '@solmate/utils/FixedPointMathLib.sol';
import { SafeTransferLib } from '@solmate/utils/SafeTransferLib.sol';
import { ERC20 } from '@solmate/tokens/ERC20.sol';
import { Auth, Authority } from '@solmate/auth/Auth.sol';
import { BeforeTransferHook } from './interfaces/BeforeTransferHook.sol';
import { IHyperdriveMarket } from './interfaces/IHyperdriveMarket.sol';

contract CrestVault is ERC20, Auth, ERC721Holder, ERC1155Holder {
    using Address for address;
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // ========================================= STATE =========================================

    /**
     * @notice Contract responsible for implementing `beforeTransfer`.
     */
    BeforeTransferHook public hook;

    /**
     * @notice Current allocation indexes for Hyperliquid
     */
    uint32 public currentSpotIndex;
    uint32 public currentPerpIndex;

    /**
     * @notice Hyperdrive market for USDT0 yield generation
     */
    IHyperdriveMarket public hyperdriveMarket;

    /**
     * @notice Tracks Hyperdrive shares owned by the vault
     */
    uint256 public hyperdriveShares;

    //============================== EVENTS ===============================

    event Enter(
        address indexed from,
        address indexed asset,
        uint256 amount,
        address indexed to,
        uint256 shares
    );
    event Exit(
        address indexed to,
        address indexed asset,
        uint256 amount,
        address indexed from,
        uint256 shares
    );
    event Allocation(uint32 spotIndex, uint32 perpIndex, uint256 amount);
    event Rebalance(
        uint32 oldSpotIndex,
        uint32 oldPerpIndex,
        uint32 newSpotIndex,
        uint32 newPerpIndex
    );
    event HyperdriveMarketUpdated(address indexed market);
    event HyperdriveDeposit(uint256 assets, uint256 shares);
    event HyperdriveWithdraw(uint256 assets, uint256 shares);

    //============================== CONSTRUCTOR ===============================

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol
    )
        ERC20(_name, _symbol, 6) // USDC has 6 decimals
        Auth(_owner, Authority(address(0)))
    {}

    /**
     * @notice Grant authorization to an address
     */
    function authorize(address target) external requiresAuth {
        authorized[target] = true;
    }

    /**
     * @notice Revoke authorization from an address
     */
    function unauthorize(address target) external requiresAuth {
        authorized[target] = false;
    }

    mapping(address => bool) public authorized;

    modifier requiresAuth() override {
        require(msg.sender == owner || authorized[msg.sender], 'UNAUTHORIZED');
        _;
    }

    //============================== MANAGE ===============================

    /**
     * @notice Allows manager to make an arbitrary function call from this contract.
     * @dev Callable by authorized roles.
     */
    function manage(
        address target,
        bytes calldata data,
        uint256 value
    ) external requiresAuth returns (bytes memory result) {
        result = target.functionCallWithValue(data, value);
    }

    /**
     * @notice Allows manager to make arbitrary function calls from this contract.
     * @dev Callable by authorized roles.
     */
    function manage(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external requiresAuth returns (bytes[] memory results) {
        uint256 targetsLength = targets.length;
        results = new bytes[](targetsLength);
        for (uint256 i; i < targetsLength; ++i) {
            results[i] = targets[i].functionCallWithValue(data[i], values[i]);
        }
    }

    //============================== ALLOCATION ===============================

    /**
     * @notice Allocates vault funds to Hyperliquid positions
     * @param spotIndex The spot market index to allocate to
     * @param perpIndex The perp market index to allocate to
     * @dev This will be called by the Manager role
     */
    function allocate(
        uint32 spotIndex,
        uint32 perpIndex
    ) external requiresAuth {
        currentSpotIndex = spotIndex;
        currentPerpIndex = perpIndex;

        // The actual allocation logic will be in the Manager contract
        // which will use the manage() function to interact with Hyperliquid

        emit Allocation(spotIndex, perpIndex, 0); // amount will be calculated in Manager
    }

    /**
     * @notice Rebalances the vault to new positions
     * @param newSpotIndex The new spot market index
     * @param newPerpIndex The new perp market index
     */
    function rebalance(
        uint32 newSpotIndex,
        uint32 newPerpIndex
    ) external requiresAuth {
        uint32 oldSpotIndex = currentSpotIndex;
        uint32 oldPerpIndex = currentPerpIndex;

        currentSpotIndex = newSpotIndex;
        currentPerpIndex = newPerpIndex;

        // The actual rebalancing logic will be in the Manager contract

        emit Rebalance(oldSpotIndex, oldPerpIndex, newSpotIndex, newPerpIndex);
    }

    //============================== ENTER ===============================

    /**
     * @notice Allows minter to mint shares, in exchange for assets.
     * @dev If assetAmount is zero, no assets are transferred in.
     * @dev Callable by authorized roles.
     */
    function enter(
        address from,
        ERC20 asset,
        uint256 assetAmount,
        address to,
        uint256 shareAmount
    ) external requiresAuth {
        // Transfer assets in
        if (assetAmount > 0)
            asset.safeTransferFrom(from, address(this), assetAmount);

        // Mint shares.
        _mint(to, shareAmount);

        emit Enter(from, address(asset), assetAmount, to, shareAmount);
    }

    //============================== EXIT ===============================

    /**
     * @notice Allows burner to burn shares, in exchange for assets.
     * @dev If assetAmount is zero, no assets are transferred out.
     * @dev Callable by authorized roles.
     */
    function exit(
        address to,
        ERC20 asset,
        uint256 assetAmount,
        address from,
        uint256 shareAmount
    ) external requiresAuth {
        // Burn shares.
        _burn(from, shareAmount);

        // Transfer assets out.
        if (assetAmount > 0) asset.safeTransfer(to, assetAmount);

        emit Exit(to, address(asset), assetAmount, from, shareAmount);
    }

    //============================== HYPERDRIVE INTEGRATION ===============================

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
    }

    /**
     * @notice Deposits idle USDT0 to Hyperdrive
     */
    function depositToHyperdrive(ERC20 usdt0, uint256 amount) external requiresAuth {
        if (address(hyperdriveMarket) == address(0)) return;

        // Approve Hyperdrive to spend USDT0
        usdt0.approve(address(hyperdriveMarket), amount);

        // Deposit to Hyperdrive
        uint256 shares = hyperdriveMarket.deposit(amount, address(this));
        hyperdriveShares += shares;

        emit HyperdriveDeposit(amount, shares);
    }

    /**
     * @notice Withdraws USDT0 from Hyperdrive
     */
    function withdrawFromHyperdrive(uint256 amount) external requiresAuth returns (uint256) {
        return _withdrawFromHyperdrive(amount);
    }

    /**
     * @notice Internal function to withdraw from Hyperdrive
     */
    function _withdrawFromHyperdrive(uint256 amount) internal returns (uint256 withdrawn) {
        if (address(hyperdriveMarket) == address(0) || hyperdriveShares == 0) return 0;

        uint256 sharesToBurn;

        if (amount == type(uint256).max) {
            // Withdraw all
            sharesToBurn = hyperdriveShares;
        } else {
            // Calculate shares needed for specific amount
            sharesToBurn = hyperdriveMarket.previewWithdraw(amount);
            if (sharesToBurn > hyperdriveShares) {
                sharesToBurn = hyperdriveShares;
            }
        }

        // Withdraw from Hyperdrive
        withdrawn = hyperdriveMarket.redeem(sharesToBurn, address(this), address(this));
        hyperdriveShares -= sharesToBurn;

        emit HyperdriveWithdraw(withdrawn, sharesToBurn);
        return withdrawn;
    }

    /**
     * @notice Returns the current value of Hyperdrive position
     */
    function getHyperdriveValue() external view returns (uint256) {
        if (address(hyperdriveMarket) == address(0) || hyperdriveShares == 0) {
            return 0;
        }
        return hyperdriveMarket.previewRedeem(hyperdriveShares);
    }

    //============================== BEFORE TRANSFER HOOK ===============================
    /**
     * @notice Sets the share locker.
     * @notice If set to zero address, the share locker logic is disabled.
     * @dev Callable by owner.
     */
    function setBeforeTransferHook(address _hook) external requiresAuth {
        hook = BeforeTransferHook(_hook);
    }

    /**
     * @notice Call `beforeTransferHook` passing in `from` `to`, and `msg.sender`.
     */
    function _callBeforeTransfer(address from, address to) internal view {
        if (address(hook) != address(0))
            hook.beforeTransfer(from, to, msg.sender);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _callBeforeTransfer(msg.sender, to);
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _callBeforeTransfer(from, to);
        return super.transferFrom(from, to, amount);
    }

    //============================== RECEIVE ===============================

    receive() external payable {}
}
