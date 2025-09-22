// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibCrestStorage } from "../libraries/LibCrestStorage.sol";
import { BeforeTransferHook } from "../../interfaces/BeforeTransferHook.sol";
import { IHyperdriveMarket } from "../../interfaces/IHyperdriveMarket.sol";

contract VaultFacet {
    using Address for address;
    using SafeTransferLib for ERC20;

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

    //============================== MODIFIERS ===============================

    modifier requiresAuth() {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        require(
            msg.sender == LibDiamond.contractOwner() || cs.authorized[msg.sender],
            "UNAUTHORIZED"
        );
        _;
    }

    //============================== AUTHORIZATION ===============================

    function authorize(address target) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        cs.authorized[target] = true;
    }

    function unauthorize(address target) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        cs.authorized[target] = false;
    }

    function authorized(address target) external view returns (bool) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        return cs.authorized[target];
    }

    //============================== MANAGE ===============================

    function manage(
        address target,
        bytes calldata data,
        uint256 value
    ) external requiresAuth returns (bytes memory result) {
        result = target.functionCallWithValue(data, value);
    }

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

    function allocate(uint32 spotIndex, uint32 perpIndex) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        cs.currentSpotIndex = spotIndex;
        cs.currentPerpIndex = perpIndex;

        emit Allocation(spotIndex, perpIndex, 0);
    }

    function rebalance(uint32 newSpotIndex, uint32 newPerpIndex) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        uint32 oldSpotIndex = cs.currentSpotIndex;
        uint32 oldPerpIndex = cs.currentPerpIndex;

        cs.currentSpotIndex = newSpotIndex;
        cs.currentPerpIndex = newPerpIndex;

        emit Rebalance(oldSpotIndex, oldPerpIndex, newSpotIndex, newPerpIndex);
    }

    //============================== ENTER ===============================

    function enter(
        address from,
        ERC20 asset,
        uint256 assetAmount,
        address to,
        uint256 shareAmount
    ) external requiresAuth {
        if (assetAmount > 0)
            asset.safeTransferFrom(from, address(this), assetAmount);

        // Mint shares through Diamond's ERC20
        CrestDiamond(payable(address(this)))._mint(to, shareAmount);

        emit Enter(from, address(asset), assetAmount, to, shareAmount);
    }

    //============================== EXIT ===============================

    function exit(
        address to,
        ERC20 asset,
        uint256 assetAmount,
        address from,
        uint256 shareAmount
    ) external requiresAuth {
        // Burn shares through Diamond's ERC20
        CrestDiamond(payable(address(this)))._burn(from, shareAmount);

        if (assetAmount > 0) asset.safeTransfer(to, assetAmount);

        emit Exit(to, address(asset), assetAmount, from, shareAmount);
    }

    //============================== HYPERDRIVE INTEGRATION ===============================

    function setHyperdriveMarket(address _market) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();

        if (address(cs.hyperdriveMarket) != address(0) && cs.hyperdriveShares > 0) {
            _withdrawFromHyperdrive(type(uint256).max);
        }

        cs.hyperdriveMarket = IHyperdriveMarket(_market);
        emit HyperdriveMarketUpdated(_market);
    }

    function depositToHyperdrive(ERC20 usdt0, uint256 amount) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();

        if (address(cs.hyperdriveMarket) == address(0)) return;

        usdt0.approve(address(cs.hyperdriveMarket), amount);

        uint256 shares = cs.hyperdriveMarket.deposit(amount, address(this));
        cs.hyperdriveShares += shares;

        emit HyperdriveDeposit(amount, shares);
    }

    function withdrawFromHyperdrive(uint256 amount) external requiresAuth returns (uint256) {
        return _withdrawFromHyperdrive(amount);
    }

    function _withdrawFromHyperdrive(uint256 amount) internal returns (uint256 withdrawn) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();

        if (address(cs.hyperdriveMarket) == address(0) || cs.hyperdriveShares == 0)
            return 0;

        uint256 sharesToBurn;

        if (amount == type(uint256).max) {
            sharesToBurn = cs.hyperdriveShares;
        } else {
            sharesToBurn = cs.hyperdriveMarket.previewWithdraw(amount);
            if (sharesToBurn > cs.hyperdriveShares) {
                sharesToBurn = cs.hyperdriveShares;
            }
        }

        withdrawn = cs.hyperdriveMarket.redeem(
            sharesToBurn,
            address(this),
            address(this)
        );
        cs.hyperdriveShares -= sharesToBurn;

        emit HyperdriveWithdraw(withdrawn, sharesToBurn);
        return withdrawn;
    }

    function getHyperdriveValue() external view returns (uint256) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();

        if (address(cs.hyperdriveMarket) == address(0) || cs.hyperdriveShares == 0) {
            return 0;
        }
        return cs.hyperdriveMarket.previewRedeem(cs.hyperdriveShares);
    }

    //============================== BEFORE TRANSFER HOOK ===============================

    function setBeforeTransferHook(address _hook) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        cs.hook = BeforeTransferHook(_hook);
    }

    function beforeTransferHook(address from, address to) external view {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage.crestStorage();
        if (address(cs.hook) != address(0))
            cs.hook.beforeTransfer(from, to, msg.sender);
    }

    //============================== GETTERS ===============================

    function currentSpotIndex() external view returns (uint32) {
        return LibCrestStorage.crestStorage().currentSpotIndex;
    }

    function currentPerpIndex() external view returns (uint32) {
        return LibCrestStorage.crestStorage().currentPerpIndex;
    }

    function hyperdriveMarket() external view returns (address) {
        return address(LibCrestStorage.crestStorage().hyperdriveMarket);
    }

    function hyperdriveShares() external view returns (uint256) {
        return LibCrestStorage.crestStorage().hyperdriveShares;
    }

    function hook() external view returns (address) {
        return address(LibCrestStorage.crestStorage().hook);
    }
}

// Helper contract interface to access Diamond's ERC20 functions
interface CrestDiamond {
    function _mint(address to, uint256 amount) external;
    function _burn(address from, uint256 amount) external;
}