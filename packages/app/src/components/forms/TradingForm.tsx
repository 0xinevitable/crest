import styled from '@emotion/styled';
import { useEffect, useState } from 'react';
import { formatUnits } from 'viem';
import { useAccount } from 'wagmi';

import { OpticianSans } from '@/fonts';
import { useDeposit } from '@/hooks/useDeposit';
import { useExchangeRate } from '@/hooks/useExchangeRate';

import { AmountInputWithTokens } from '../ui/AmountInputWithTokens';
import { FeeDisplay } from '../ui/FeeDisplay';
import { DepositWithdrawTabs } from './DepositWithdrawTabs';
import { PriceDisplay } from './PriceDisplay';

const INPUT_TOKENS = [
  {
    symbol: 'USDT0',
    name: 'USDT0',
    icon: '/assets/tokens/usdc-icon-primary.svg',
  },
];

const OUTPUT_TOKENS = [
  {
    symbol: 'CREST',
    name: 'CREST',
    icon: '/assets/tokens/crest-icon.png',
  },
];

const FEES = [
  { label: 'Performance Fee', value: '5%', showInfo: true },
  { label: 'Management Fee', value: '1%', showInfo: true },
  { label: 'Withdrawal Period', value: '1 days', showInfo: false },
];

export const TradingForm: React.FC = () => {
  const { isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);

  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw'>('deposit');
  const [inputAmount, setInputAmount] = useState('0');

  useEffect(() => {
    setMounted(true);
  }, []);

  const {
    status,
    isLoading,
    isCalculatingShares,
    needsApproval,
    error,
    balance,
    shares,
    txHash,
    submit,
    reset,
  } = useDeposit(inputAmount);

  const { exchangeRate } = useExchangeRate();

  useEffect(() => {
    if (status === 'success') {
      setInputAmount('0');
      setTimeout(() => reset(), 2000);
    }
  }, [status, reset]);

  const handleDeposit = async () => {
    if (!isConnected) {
      alert('Please connect your wallet');
      return;
    }

    if (!inputAmount || Number(inputAmount) <= 0) {
      alert('Please enter a valid amount');
      return;
    }

    await submit();
  };

  const getButtonText = () => {
    // Prevent hydration mismatch by showing loading state until mounted
    if (!mounted) return 'Loading...';

    if (!isConnected) return 'Connect Wallet';

    switch (status) {
      case 'approving':
        return 'Approving USDT0...';
      case 'depositing':
        return 'Depositing...';
      case 'success':
        return 'Success!';
      case 'error':
        return 'Try Again';
      default:
        if (needsApproval) return 'Approve USDT0';
        return activeTab === 'deposit' ? 'Deposit' : 'Withdraw';
    }
  };

  const isButtonDisabled = () => {
    return (
      !mounted ||
      !isConnected ||
      !inputAmount ||
      Number(inputAmount) <= 0 ||
      isLoading ||
      isCalculatingShares ||
      status === 'success'
    );
  };

  return (
    <Container>
      <FormContent>
        <DepositWithdrawTabs activeTab={activeTab} onTabChange={setActiveTab} />

        {/* Balance Display */}
        {balance && (
          <BalanceInfo>
            Available:{' '}
            {Number(formatUnits(balance.value, balance.decimals)).toFixed(6)}{' '}
            {balance.symbol}
          </BalanceInfo>
        )}

        <AmountInputWithTokens
          label="You deposit"
          value={inputAmount}
          onChange={setInputAmount}
          tokens={INPUT_TOKENS}
          onTokenSelect={(token) => console.log('Selected input token:', token)}
          variant="input"
        />

        <AmountInputWithTokens
          label={`You Receive${isCalculatingShares ? ' (calculating...)' : ''}`}
          value={shares}
          onChange={() => {}}
          tokens={OUTPUT_TOKENS}
          onTokenSelect={(token) =>
            console.log('Selected output token:', token)
          }
          variant="output"
        />

        {/* Error Display */}
        {error && <ErrorMessage>{error}</ErrorMessage>}

        {/* Transaction Hash */}
        {txHash && (
          <TxHashDisplay>
            Transaction:{' '}
            <a
              href={`https://explorer.hyperliquid-testnet.xyz/tx/${txHash}`}
              target="_blank"
              rel="noopener noreferrer"
            >
              {txHash.slice(0, 10)}...{txHash.slice(-8)}
            </a>
          </TxHashDisplay>
        )}

        <ActionButton onClick={handleDeposit} disabled={isButtonDisabled()}>
          <ButtonText>{getButtonText()}</ButtonText>
        </ActionButton>
      </FormContent>

      <PriceDisplay
        label="Price per share"
        fromToken={{
          symbol: 'USDT0',
          icon: '/assets/tokens/usdc-icon-secondary.svg',
        }}
        toToken={{
          symbol: 'CREST',
          icon: '/assets/tokens/crest-icon.png',
        }}
        rate={`1 USDT0 ≈ ${exchangeRate} CREST`}
      />
      <FeeDisplay fees={FEES} />
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1.25rem;
  background: #0a0f10;
  border: 1px solid #233838;
  border-radius: 0.75rem;
  width: 625px;
`;

const FormContent = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  padding-bottom: 1.5rem;
`;

const ActionButton = styled.button`
  display: flex;
  gap: 0.75rem;
  align-items: center;
  justify-content: center;
  padding: 1rem 5rem;
  background: #256960;
  border-radius: 0.5rem;
  border: none;
  cursor: pointer;
  width: 100%;
  transition: background-color 0.2s ease;

  &:hover {
    background: #2d7a70;
  }

  &:disabled {
    background: #1a4d47;
    cursor: not-allowed;
  }
`;

const ButtonText = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.75rem;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
`;

const BalanceInfo = styled.div`
  font-size: 0.875rem;
  color: #8b949e;
  text-align: right;
  margin-bottom: -0.5rem;
`;

const ErrorMessage = styled.div`
  padding: 0.75rem;
  background: rgba(248, 81, 73, 0.1);
  border: 1px solid rgba(248, 81, 73, 0.3);
  border-radius: 0.375rem;
  color: #f85149;
  font-size: 0.875rem;
`;

const TxHashDisplay = styled.div`
  padding: 0.75rem;
  background: rgba(34, 134, 58, 0.1);
  border: 1px solid rgba(34, 134, 58, 0.3);
  border-radius: 0.375rem;
  color: #22863a;
  font-size: 0.875rem;

  a {
    color: #22863a;
    text-decoration: underline;

    &:hover {
      text-decoration: none;
    }
  }
`;
