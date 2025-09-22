// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import { IDiamondCut } from "../src/diamond/interfaces/IDiamondCut.sol";
import { DiamondInit } from "../src/diamond/upgradeInitializers/DiamondInit.sol";
import { CrestDiamond } from "../src/diamond/CrestDiamond.sol";

contract DeployDiamondWithFFI is Script {
    IDiamondCut.FacetCut[] private _facetCuts;

    uint256 constant TESTNET_CHAINID = 998;

    // Get USDT0 address based on chain
    function usdt0Address() internal view returns (address) {
        return
            block.chainid == TESTNET_CHAINID
                ? 0xa9056c15938f9aff34CD497c722Ce33dB0C2fD57 // Testnet USDT0 (PURR)
                : 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb; // Mainnet USDT0
    }

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        // Load addresses from env
        address owner = vm.envOr("OWNER_ADDRESS", deployer);
        address usdt0 = usdt0Address();
        address curator = vm.envAddress("CURATOR_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");

        vm.startBroadcast(privateKey);

        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();

        // Register all facets
        string[7] memory facets = [
            // Core diamond facets
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            // Protocol facets
            "VaultFacet",
            "TellerFacet",
            "ManagerFacet",
            "AccountantFacet"
        ];

        // Setup FFI command
        string[] memory inputs = new string[](3);
        inputs[0] = "python3";
        inputs[1] = "script/python/get_selectors.py";

        // First deploy DiamondCutFacet (needed for diamond constructor)
        address diamondCutFacet;

        // Process each facet
        for (uint256 i = 0; i < facets.length; i++) {
            string memory facet = facets[i];

            // Deploy the facet
            bytes memory bytecode = vm.getCode(string.concat(facet, ".sol"));
            address facetAddress;
            assembly {
                facetAddress := create(0, add(bytecode, 0x20), mload(bytecode))
            }

            // Store DiamondCutFacet address for diamond deployment
            if (
                keccak256(bytes(facet)) == keccak256(bytes("DiamondCutFacet"))
            ) {
                diamondCutFacet = facetAddress;
                continue; // Don't add to cuts, it's added in diamond constructor
            }

            // Get selectors using FFI
            inputs[2] = facet;
            bytes memory res = vm.ffi(inputs);
            bytes4[] memory selectors = abi.decode(res, (bytes4[]));

            // Create FacetCut struct
            _facetCuts.push(
                IDiamondCut.FacetCut({
                    facetAddress: facetAddress,
                    action: IDiamondCut.FacetCutAction.Add,
                    functionSelectors: selectors
                })
            );

            console.log(
                string.concat("Deployed ", facet, " at:"),
                facetAddress
            );
            console.log("  Selectors count:", selectors.length);
        }

        // Deploy Diamond
        CrestDiamond diamond = new CrestDiamond(
            owner,
            diamondCutFacet,
            "Crest Vault Shares",
            "CREST"
        );

        console.log("Diamond deployed at:", address(diamond));

        // Prepare initialization arguments
        DiamondInit.InitArgs memory initArgs = DiamondInit.InitArgs({
            usdt0: usdt0,
            curator: curator,
            feeRecipient: feeRecipient,
            shareLockPeriod: 1 days,
            platformFeeBps: 100,
            performanceFeeBps: 500,
            maxSlippageBps: 100
        });

        // Execute diamond cut with initialization
        IDiamondCut(address(diamond)).diamondCut(
            _facetCuts,
            address(diamondInit),
            abi.encodeWithSelector(DiamondInit.init.selector, initArgs)
        );

        console.log("Diamond initialization complete!");

        vm.stopBroadcast();
    }
}
