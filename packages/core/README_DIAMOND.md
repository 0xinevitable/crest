# Crest Diamond Pattern Implementation

This directory contains the refactored Crest protocol using the EIP-2535 Diamond pattern.

## Structure

```
src/diamond/
├── CrestDiamond.sol           # Main diamond contract with ERC20 functionality
├── facets/
│   ├── DiamondCutFacet.sol    # Handles diamond upgrades
│   ├── DiamondLoupeFacet.sol  # Diamond introspection
│   ├── OwnershipFacet.sol     # Ownership management
│   ├── VaultFacet.sol         # Vault logic
│   ├── TellerFacet.sol        # Deposit/withdrawal logic
│   ├── ManagerFacet.sol       # Position management
│   └── AccountantFacet.sol    # Fee and rate management
├── libraries/
│   ├── LibDiamond.sol         # Diamond standard storage
│   └── LibCrestStorage.sol    # Crest-specific shared storage
├── interfaces/                 # Diamond interfaces
└── upgradeInitializers/
    └── DiamondInit.sol        # One-time initialization
```

## Deployment

### Using Forge with FFI (Recommended)

1. Install Python dependencies:
```bash
pip install eth-abi
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your values
```

3. Deploy using Forge:
```bash
forge script script/DeployDiamondWithFFI.s.sol --rpc-url $RPC_URL --broadcast
```

### Using TypeScript/Viem

1. Install dependencies:
```bash
npm install viem dotenv
```

2. Run deployment:
```bash
npx ts-node typescript/deploy/deployDiamond.ts
```

### Using Hardhat-style Forge Script

```bash
forge script script/DeployCrestDiamondV2.s.sol --rpc-url $RPC_URL --broadcast
```

## Key Features

### Diamond Benefits
- **Modularity**: Each facet handles specific functionality
- **Upgradability**: Add/replace/remove functions without redeploying
- **Gas Efficiency**: Shared storage reduces redundancy
- **No Contract Size Limit**: Split logic across multiple facets

### Shared Storage Pattern
All facets share the same storage layout defined in `LibCrestStorage.sol`, enabling seamless data sharing between facets.

### Cross-Facet Communication
Facets can call each other's functions through the diamond proxy:
- TellerFacet calls VaultFacet for minting/burning shares
- AccountantFacet calls ManagerFacet for position values
- All facets access shared storage directly

## Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Test specific facet
forge test --match-contract VaultFacetTest
```

## Upgrading

To add new functionality:

1. Create a new facet:
```solidity
contract NewFeatureFacet {
    // Implementation
}
```

2. Deploy and add to diamond:
```solidity
IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
cut[0] = IDiamondCut.FacetCut({
    facetAddress: address(newFeatureFacet),
    action: IDiamondCut.FacetCutAction.Add,
    functionSelectors: selectors
});

IDiamondCut(diamond).diamondCut(cut, address(0), "");
```

## Security Considerations

1. **Storage Collisions**: Always use the diamond storage pattern
2. **Initialization**: Use DiamondInit for one-time setup
3. **Access Control**: Check permissions in each facet
4. **Selector Clashes**: Ensure unique function signatures
5. **Reentrancy**: Use guards where necessary

## Gas Optimization

The diamond pattern adds a small overhead (~2.3k gas) for the delegatecall, but saves gas through:
- Shared storage (no duplicate state variables)
- Efficient upgrade path (no migration needed)
- Optimized function routing

## Migration from Old Contracts

The old contracts are marked as deprecated but retained for reference:
- `CrestVault.sol` → `VaultFacet.sol`
- `CrestTeller.sol` → `TellerFacet.sol`
- `CrestManager.sol` → `ManagerFacet.sol`
- `CrestAccountant.sol` → `AccountantFacet.sol`

All functionality has been preserved with the same interfaces.