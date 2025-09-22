import {
  createWalletClient,
  createPublicClient,
  http,
  getContract,
  encodeFunctionData,
  parseAbi,
  Hex,
  Address
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { parseArtifact, getSelectors } from './utils/diamondUtils';
import * as dotenv from 'dotenv';

dotenv.config();

// Configuration
const PRIVATE_KEY = process.env.PRIVATE_KEY as Hex;
const RPC_URL = process.env.RPC_URL || 'https://998.rpc.hyperliquid.xyz';

// Contract names
const FACET_NAMES = [
  'DiamondCutFacet',
  'DiamondLoupeFacet',
  'OwnershipFacet',
  'VaultFacet',
  'TellerFacet',
  'ManagerFacet',
  'AccountantFacet'
];

interface FacetCut {
  facetAddress: Address;
  action: number; // 0 = Add, 1 = Replace, 2 = Remove
  functionSelectors: Hex[];
}

interface DiamondInitArgs {
  usdt0: Address;
  curator: Address;
  feeRecipient: Address;
  shareLockPeriod: bigint;
  platformFeeBps: number;
  performanceFeeBps: number;
  maxSlippageBps: number;
}

async function deployContract(
  walletClient: any,
  publicClient: any,
  contractName: string,
  args: any[] = []
): Promise<Address> {
  const artifact = await parseArtifact(contractName);

  const hash = await walletClient.deployContract({
    abi: artifact.abi,
    bytecode: artifact.bytecode as Hex,
    args,
  });

  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log(`✅ ${contractName} deployed at:`, receipt.contractAddress);

  return receipt.contractAddress!;
}

async function main() {
  // Setup clients
  const account = privateKeyToAccount(PRIVATE_KEY);
  const walletClient = createWalletClient({
    account,
    transport: http(RPC_URL),
  });
  const publicClient = createPublicClient({
    transport: http(RPC_URL),
  });

  console.log('🚀 Starting Crest Diamond deployment...');
  console.log('Deployer address:', account.address);

  // Get configuration from environment or use defaults
  const config = {
    owner: (process.env.OWNER_ADDRESS as Address) || account.address,
    usdt0: process.env.USDT0_ADDRESS as Address,
    curator: process.env.CURATOR_ADDRESS as Address,
    feeRecipient: process.env.FEE_RECIPIENT_ADDRESS as Address,
    name: 'Crest Vault Shares',
    symbol: 'CREST',
    shareLockPeriod: BigInt(24 * 60 * 60), // 1 day
    platformFeeBps: 100, // 1%
    performanceFeeBps: 500, // 5%
    maxSlippageBps: 100, // 1%
  };

  // Deploy DiamondInit
  console.log('\n📦 Deploying DiamondInit...');
  const diamondInitAddress = await deployContract(walletClient, publicClient, 'DiamondInit');

  // Deploy DiamondCutFacet first (needed for diamond constructor)
  console.log('\n📦 Deploying DiamondCutFacet...');
  const diamondCutFacetAddress = await deployContract(walletClient, publicClient, 'DiamondCutFacet');

  // Deploy Diamond
  console.log('\n💎 Deploying Diamond...');
  const diamondAddress = await deployContract(
    walletClient,
    publicClient,
    'CrestDiamond',
    [config.owner, diamondCutFacetAddress, config.name, config.symbol]
  );

  // Deploy all facets and prepare cuts
  console.log('\n📦 Deploying facets...');
  const facetCuts: FacetCut[] = [];

  for (const facetName of FACET_NAMES) {
    if (facetName === 'DiamondCutFacet') {
      continue; // Already deployed and added in constructor
    }

    console.log(`\nDeploying ${facetName}...`);
    const facetAddress = await deployContract(walletClient, publicClient, facetName);

    // Get function selectors for this facet
    const selectors = await getSelectors(facetName);
    console.log(`  Found ${selectors.length} functions`);

    facetCuts.push({
      facetAddress,
      action: 0, // Add
      functionSelectors: selectors,
    });
  }

  // Prepare initialization data
  const initArgs: DiamondInitArgs = {
    usdt0: config.usdt0,
    curator: config.curator,
    feeRecipient: config.feeRecipient,
    shareLockPeriod: config.shareLockPeriod,
    platformFeeBps: config.platformFeeBps,
    performanceFeeBps: config.performanceFeeBps,
    maxSlippageBps: config.maxSlippageBps,
  };

  const initData = encodeFunctionData({
    abi: parseAbi(['function init((address,address,address,uint64,uint16,uint16,uint16))']),
    functionName: 'init',
    args: [initArgs],
  });

  // Execute diamond cut
  console.log('\n💎 Executing diamond cut...');
  const diamondCutAbi = parseAbi([
    'function diamondCut((address,uint8,bytes4[])[],address,bytes)'
  ]);

  const cutHash = await walletClient.writeContract({
    address: diamondAddress,
    abi: diamondCutAbi,
    functionName: 'diamondCut',
    args: [facetCuts, diamondInitAddress, initData],
  });

  await publicClient.waitForTransactionReceipt({ hash: cutHash });
  console.log('✅ Diamond cut executed successfully');

  // Log deployment summary
  console.log('\n' + '='.repeat(50));
  console.log('🎉 DEPLOYMENT SUCCESSFUL');
  console.log('='.repeat(50));
  console.log('Diamond Address:', diamondAddress);
  console.log('Owner:', config.owner);
  console.log('USDT0:', config.usdt0);
  console.log('Curator:', config.curator);
  console.log('Fee Recipient:', config.feeRecipient);
  console.log('='.repeat(50));

  return diamondAddress;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  });