// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from "@solmate/tokens/ERC20.sol";

interface IVaultFacet {
    function rebalance(uint32 newSpotIndex, uint32 newPerpIndex) external;

    function enter(
        address from,
        ERC20 asset,
        uint256 assetAmount,
        address to,
        uint256 shareAmount
    ) external;
    function exit(
        address to,
        ERC20 asset,
        uint256 assetAmount,
        address from,
        uint256 shareAmount
    ) external;
    function depositToHyperdrive(ERC20 usdt0, uint256 amount) external;
    function withdrawFromHyperdrive(uint256 amount) external returns (uint256);

    function getHyperdriveValue() external view returns (uint256);
}
