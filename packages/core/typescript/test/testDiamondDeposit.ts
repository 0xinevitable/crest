import {
  createWalletClient,
  createPublicClient,
  http,
  parseUnits,
  formatUnits,
  type Address,
  type Hex,
  encodeFunctionData,
  decodeFunctionResult,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import * as dotenv from 'dotenv';
import { readFileSync } from 'fs';

dotenv.config();

// Load deployment info
const deployment = JSON.parse(
  readFileSync('./deployments/998-diamond.json', 'utf-8')
);

// Configuration
const PRIVATE_KEY = process.env.PRIVATE_KEY as Hex;
const RPC_URL = 'https://evmrpc-jp.hyperpc.app/2a850a8987744037bc1fce0b59f22e1b';
const DIAMOND_ADDRESS = deployment.diamond as Address;
const USDT0_ADDRESS = deployment.usdt0 as Address;

// ABIs
const tellerAbi = [
  {
    name: 'previewDeposit',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'assets', type: 'uint256' }],
    outputs: [{ type: 'uint256' }],
  },
  {
    name: 'deposit',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'assets', type: 'uint256' },
      { name: 'receiver', type: 'address' },
    ],
    outputs: [{ name: 'shares', type: 'uint256' }],
  },
  {
    name: 'shareLockPeriod',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ type: 'uint64' }],
  },
] as const;

const erc20Abi = [
  {
    name: 'approve',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ type: 'bool' }],
  },
  {
    name: 'balanceOf',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ type: 'uint256' }],
  },
  {
    name: 'decimals',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ type: 'uint8' }],
  },
  {
    name: 'symbol',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ type: 'string' }],
  },
  {
    name: 'totalSupply',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ type: 'uint256' }],
  },
] as const;

async function main() {
  console.log('🧪 Testing Diamond Contract Deposit Functionality');
  console.log('='.repeat(50));
  console.log('Diamond:', DIAMOND_ADDRESS);
  console.log('USDT0:', USDT0_ADDRESS);
  console.log('');

  // Setup clients
  const account = privateKeyToAccount(PRIVATE_KEY);
  const walletClient = createWalletClient({
    account,
    chain: {
      id: 998,
      name: 'Hyperliquid Testnet',
      network: 'hyperliquid-testnet',
      nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 },
      rpcUrls: {
        default: { http: [RPC_URL] },
        public: { http: [RPC_URL] },
      },
    },
    transport: http(RPC_URL),
  });

  const publicClient = createPublicClient({
    chain: {
      id: 998,
      name: 'Hyperliquid Testnet',
      network: 'hyperliquid-testnet',
      nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 },
      rpcUrls: {
        default: { http: [RPC_URL] },
        public: { http: [RPC_URL] },
      },
    },
    transport: http(RPC_URL),
  });

  console.log('Account:', account.address);

  // Check USDT0 balance
  const usdt0Balance = await publicClient.readContract({
    address: USDT0_ADDRESS,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: [account.address],
  });

  const usdt0Decimals = await publicClient.readContract({
    address: USDT0_ADDRESS,
    abi: erc20Abi,
    functionName: 'decimals',
  });

  const usdt0Symbol = await publicClient.readContract({
    address: USDT0_ADDRESS,
    abi: erc20Abi,
    functionName: 'symbol',
  });

  console.log(`\n💰 ${usdt0Symbol} Balance: ${formatUnits(usdt0Balance, usdt0Decimals)}`);

  if (usdt0Balance === 0n) {
    console.log('❌ No USDT0 balance. Please get some testnet USDT0 first.');
    return;
  }

  // Test amount: 10 USDT0
  const depositAmount = parseUnits('10', usdt0Decimals);
  console.log(`\n📊 Testing with ${formatUnits(depositAmount, usdt0Decimals)} ${usdt0Symbol}`);

  // 1. Test previewDeposit
  console.log('\n1️⃣ Testing previewDeposit...');
  const previewShares = await publicClient.readContract({
    address: DIAMOND_ADDRESS,
    abi: tellerAbi,
    functionName: 'previewDeposit',
    args: [depositAmount],
  });

  console.log(`   Preview: ${formatUnits(depositAmount, usdt0Decimals)} ${usdt0Symbol} → ${formatUnits(previewShares, 6)} shares`);

  // Check if it's 1:1 for initial deposit
  const shareRate = Number(previewShares) / Number(depositAmount);
  console.log(`   Rate: 1 ${usdt0Symbol} = ${shareRate.toFixed(6)} shares`);

  if (Math.abs(shareRate - 1.0) < 0.0001) {
    console.log('   ✅ Initial rate is 1:1 as expected');
  } else {
    console.log('   ⚠️ Rate is not exactly 1:1');
  }

  // 2. Check share lock period
  console.log('\n2️⃣ Checking share lock period...');
  const lockPeriod = await publicClient.readContract({
    address: DIAMOND_ADDRESS,
    abi: tellerAbi,
    functionName: 'shareLockPeriod',
  });
  console.log(`   Lock period: ${Number(lockPeriod)} seconds (${Number(lockPeriod) / 3600} hours)`);

  // 3. Check current vault state
  console.log('\n3️⃣ Checking vault state...');
  const totalSupplyBefore = await publicClient.readContract({
    address: DIAMOND_ADDRESS,
    abi: erc20Abi,
    functionName: 'totalSupply',
  });
  console.log(`   Total supply before: ${formatUnits(totalSupplyBefore, 6)} CREST`);

  const userSharesBefore = await publicClient.readContract({
    address: DIAMOND_ADDRESS,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: [account.address],
  });
  console.log(`   User shares before: ${formatUnits(userSharesBefore, 6)} CREST`);

  // 4. Approve and deposit
  console.log('\n4️⃣ Approving USDT0...');
  const approveHash = await walletClient.writeContract({
    address: USDT0_ADDRESS,
    abi: erc20Abi,
    functionName: 'approve',
    args: [DIAMOND_ADDRESS, depositAmount],
  });

  const approveReceipt = await publicClient.waitForTransactionReceipt({ hash: approveHash });
  console.log(`   Approved in tx: ${approveReceipt.transactionHash}`);

  console.log('\n5️⃣ Depositing...');
  try {
    const depositHash = await walletClient.writeContract({
      address: DIAMOND_ADDRESS,
      abi: tellerAbi,
      functionName: 'deposit',
      args: [depositAmount, account.address],
    });

    const depositReceipt = await publicClient.waitForTransactionReceipt({ hash: depositHash });
    console.log(`   ✅ Deposit successful! Tx: ${depositReceipt.transactionHash}`);
    console.log(`   Gas used: ${depositReceipt.gasUsed}`);

    // Check balances after deposit
    console.log('\n6️⃣ Verifying balances after deposit...');

    const userSharesAfter = await publicClient.readContract({
      address: DIAMOND_ADDRESS,
      abi: erc20Abi,
      functionName: 'balanceOf',
      args: [account.address],
    });

    const totalSupplyAfter = await publicClient.readContract({
      address: DIAMOND_ADDRESS,
      abi: erc20Abi,
      functionName: 'totalSupply',
    });

    const usdt0BalanceAfter = await publicClient.readContract({
      address: USDT0_ADDRESS,
      abi: erc20Abi,
      functionName: 'balanceOf',
      args: [account.address],
    });

    console.log(`   User shares after: ${formatUnits(userSharesAfter, 6)} CREST`);
    console.log(`   Total supply after: ${formatUnits(totalSupplyAfter, 6)} CREST`);
    console.log(`   User USDT0 after: ${formatUnits(usdt0BalanceAfter, usdt0Decimals)} ${usdt0Symbol}`);

    const sharesReceived = userSharesAfter - userSharesBefore;
    console.log(`\n   📈 Shares received: ${formatUnits(sharesReceived, 6)} CREST`);
    console.log(`   📉 USDT0 spent: ${formatUnits(usdt0Balance - usdt0BalanceAfter, usdt0Decimals)} ${usdt0Symbol}`);

    // Verify 1:1 ratio
    const actualRate = Number(sharesReceived) / Number(depositAmount);
    if (Math.abs(actualRate - 1.0) < 0.0001) {
      console.log('   ✅ Deposit executed at 1:1 rate as expected!');
    } else {
      console.log(`   ⚠️ Actual rate: 1 ${usdt0Symbol} = ${actualRate.toFixed(6)} shares`);
    }

  } catch (error: any) {
    console.error('   ❌ Deposit failed:', error.message);
    if (error.cause) {
      console.error('   Cause:', error.cause.reason || error.cause);
    }
  }

  console.log('\n' + '='.repeat(50));
  console.log('Test completed!');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Test failed:', error);
    process.exit(1);
  });