import { readFileSync } from 'fs';
import { join } from 'path';
import { Hex, keccak256, toHex, slice } from 'viem';
import { execSync } from 'child_process';

interface ContractArtifact {
  abi: any[];
  bytecode: Hex;
  deployedBytecode?: Hex;
  methodIdentifiers?: Record<string, string>;
}

/**
 * Parse a contract artifact from the forge output
 */
export async function parseArtifact(contractName: string): Promise<ContractArtifact> {
  const artifactPath = join(
    process.cwd(),
    'out',
    `${contractName}.sol`,
    `${contractName}.json`
  );

  try {
    const artifact = JSON.parse(readFileSync(artifactPath, 'utf-8'));
    return {
      abi: artifact.abi,
      bytecode: artifact.bytecode.object as Hex,
      deployedBytecode: artifact.deployedBytecode?.object as Hex,
      methodIdentifiers: artifact.methodIdentifiers,
    };
  } catch (error) {
    throw new Error(`Failed to parse artifact for ${contractName}: ${error}`);
  }
}

/**
 * Get function selectors for a contract using forge inspect
 */
export async function getSelectors(contractName: string): Promise<Hex[]> {
  try {
    // Use forge inspect to get method identifiers
    const result = execSync(
      `forge inspect ${contractName} methodIdentifiers`,
      { encoding: 'utf-8' }
    );

    const methodIdentifiers = JSON.parse(result);
    const selectors: Hex[] = [];

    for (const [, selector] of Object.entries(methodIdentifiers)) {
      selectors.push(`0x${selector}` as Hex);
    }

    return selectors;
  } catch (error) {
    console.error(`Failed to get selectors for ${contractName}:`, error);
    // Fallback: try to get from artifact
    return getSelectorsFromArtifact(contractName);
  }
}

/**
 * Get function selectors from artifact as fallback
 */
async function getSelectorsFromArtifact(contractName: string): Promise<Hex[]> {
  const artifact = await parseArtifact(contractName);
  const selectors: Hex[] = [];

  if (artifact.methodIdentifiers) {
    for (const selector of Object.values(artifact.methodIdentifiers)) {
      selectors.push(`0x${selector}` as Hex);
    }
  } else if (artifact.abi) {
    // Generate selectors from ABI
    for (const item of artifact.abi) {
      if (item.type === 'function') {
        const signature = getFunctionSignature(item);
        const selector = slice(keccak256(toHex(signature)), 0, 4);
        selectors.push(selector);
      }
    }
  }

  return selectors;
}

/**
 * Get function signature from ABI item
 */
function getFunctionSignature(abiItem: any): string {
  const inputs = abiItem.inputs
    .map((input: any) => getTypeString(input.type, input.components))
    .join(',');
  return `${abiItem.name}(${inputs})`;
}

/**
 * Get type string for function signature
 */
function getTypeString(type: string, components?: any[]): string {
  if (type.startsWith('tuple')) {
    if (!components) return type;
    const tupleTypes = components
      .map((c: any) => getTypeString(c.type, c.components))
      .join(',');
    return type.replace('tuple', `(${tupleTypes})`);
  }
  return type;
}

/**
 * Filter selectors to exclude certain functions if needed
 */
export function filterSelectors(
  selectors: Hex[],
  excludeList: Hex[] = []
): Hex[] {
  return selectors.filter(selector => !excludeList.includes(selector));
}

/**
 * Get all facet cuts for deployment
 */
export interface FacetInfo {
  name: string;
  address: string;
  selectors: Hex[];
}

export async function prepareFacetCuts(
  facets: FacetInfo[]
): Promise<any[]> {
  return facets.map(facet => ({
    facetAddress: facet.address,
    action: 0, // Add
    functionSelectors: facet.selectors,
  }));
}