#!/usr/bin/env python3
import subprocess
import argparse
import json
from eth_abi import encode


def get_selectors(contract_name):
    """Get function selectors for a contract using forge inspect."""
    try:
        # Run forge inspect to get method identifiers
        result = subprocess.run(
            ["forge", "inspect", contract_name, "methodIdentifiers"],
            capture_output=True,
            text=True,
            check=True,
        )

        # Parse JSON output
        method_ids = json.loads(result.stdout)

        # Convert to bytes4 array
        selectors = []
        for signature, selector in method_ids.items():
            selectors.append(bytes.fromhex(selector))

        # Encode as bytes4[] for Solidity
        encoded = encode(["bytes4[]"], [selectors])
        print("0x" + encoded.hex())

        return selectors

    except subprocess.CalledProcessError as e:
        print(f"Error running forge inspect: {e}")
        print(f"stderr: {e.stderr}")
        raise
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        raise


def parse_args():
    parser = argparse.ArgumentParser(
        description="Get function selectors for a Solidity contract"
    )
    parser.add_argument(
        "contract", type=str, help="Contract name (e.g., DiamondLoupeFacet)"
    )
    return parser.parse_args()


def main():
    args = parse_args()
    get_selectors(args.contract)


if __name__ == "__main__":
    main()
