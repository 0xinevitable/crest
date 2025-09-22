import styled from '@emotion/styled';
import { useEffect, useState } from 'react';
import { toast } from 'react-toastify';
import { formatUnits } from 'viem';
import { useAccount } from 'wagmi';



import { OpticianSans } from '@/fonts';
import { useDeposit, useExchangeRate, useFees, useWithdraw } from '@/hooks';
import { Explorer } from '@/utils/explorer';

import { AmountInputWithTokens } from '../ui/AmountInputWithTokens';
import { FeeDisplay } from '../ui/FeeDisplay';
import { DepositWithdrawTabs } from './DepositWithdrawTabs';
import { PriceDisplay } from './PriceDisplay';


const TOKENS = {
  USDT0: {
    symbol: 'USDT0',
    name: 'USDT0',
    icon: '/assets/tokens/usdc-icon-primary.svg',
  },
  CREST: {
    symbol: 'CREST',
    name: 'CREST',
    icon: '/assets/tokens/crest-icon.png',
  },
};


export const TradingForm: React.FC = () => {
  const { isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);

  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw'>('deposit');
  const [inputAmount, setInputAmount] = useState('');

  // Programmable token configuration
  const [fromToken, setFromToken] = useState(TOKENS.USDT0);
  const [toToken, setToToken] = useState(TOKENS.CREST);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Update tokens when activeTab changes
  useEffect(() => {
    if (activeTab === 'deposit') {
      setFromToken(TOKENS.USDT0);
      setToToken(TOKENS.CREST);
    } else {
      setFromToken(TOKENS.CREST);
      setToToken(TOKENS.USDT0);
    }
  }, [activeTab]);

  const depositHook = useDeposit(inputAmount);
  const withdrawHook = useWithdraw(inputAmount);

  // Use the appropriate hook based on activeTab
  const currentHook = activeTab === 'deposit' ? depositHook : withdrawHook;

  const { exchangeRate } = useExchangeRate();
  const { fees } = useFees();

  useEffect(() => {
    if (currentHook.status === 'success') {
      setInputAmount('');
      setTimeout(() => currentHook.reset(), 2000);
    }
  }, [currentHook.status, currentHook.reset]);

  const handleSubmit = async () => {
    if (!isConnected) {
      toast.error('Please connect your wallet');
      return;
    }

    if (!inputAmount || Number(inputAmount) <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }

    await currentHook.submit();
  };

  const getButtonText = () => {
    if (!mounted) return 'Loading...';

    if (!isConnected) return 'Connect Wallet';

    switch (currentHook.status) {
      case 'approving':
        return 'Approving USDT0...';
      case 'depositing':
        return 'Depositing...';
      case 'withdrawing':
        return 'Withdrawing...';
      case 'success':
        return 'Success!';
      case 'error':
        return 'Try Again';
      default:
        if (activeTab === 'deposit' && depositHook.needsApproval)
          return 'Approve USDT0';
        return activeTab === 'deposit' ? 'Deposit' : 'Withdraw';
    }
  };

  const isButtonDisabled = () => {
    const isCalculating =
      activeTab === 'deposit'
        ? depositHook.isCalculatingShares
        : withdrawHook.isCalculatingAssets;

    return (
      !mounted ||
      !isConnected ||
      !inputAmount ||
      Number(inputAmount) <= 0 ||
      currentHook.isLoading ||
      isCalculating ||
      currentHook.status === 'success'
    );
  };

  return (
    <Container>
      <FormContent>
        <TabsAndBalanceRow>
          <DepositWithdrawTabs activeTab={activeTab} onTabChange={setActiveTab} />
          
          {/* Balance Display */}
          {currentHook.balance && (
            <BalanceInfo>
              Available:{' '}
              {Number(
                formatUnits(
                  currentHook.balance.value,
                  currentHook.balance.decimals,
                ),
              ).toFixed(6)}{' '}
              {fromToken.symbol}
            </BalanceInfo>
          )}
        </TabsAndBalanceRow>

        <AmountInputWithTokens
          label={activeTab === 'deposit' ? 'You deposit' : 'You withdraw'}
          value={inputAmount}
          onChange={setInputAmount}
          tokens={[fromToken]}
          onTokenSelect={(token) => console.log('Selected input token:', token)}
          variant="input"
        />

        <AmountInputWithTokens
          label={`You Receive${
            (
              activeTab === 'deposit'
                ? depositHook.isCalculatingShares
                : withdrawHook.isCalculatingAssets
            )
              ? ' (calculating...)'
              : ''
          }`}
          value={
            activeTab === 'deposit' ? depositHook.shares : withdrawHook.assets
          }
          onChange={() => {}}
          tokens={[toToken]}
          onTokenSelect={(token) =>
            console.log('Selected output token:', token)
          }
          variant="output"
        />

        {/* Transaction Hash */}
        {currentHook.txHash && (
          <TxHashDisplay>
            Transaction:{' '}
            <a
              href={Explorer.getTxLink(currentHook.txHash)}
              target="_blank"
              rel="noopener noreferrer"
            >
              {currentHook.txHash.slice(0, 10)}...{currentHook.txHash.slice(-8)}
            </a>
          </TxHashDisplay>
        )}

        <ActionButton onClick={handleSubmit} disabled={isButtonDisabled()}>
          <ButtonText>{getButtonText()}</ButtonText>
        </ActionButton>
      </FormContent>

      <PriceDisplay
        label="Price per share"
        fromToken={{
          symbol: fromToken.symbol,
          icon:
            fromToken.symbol === 'USDT0'
              ? '/assets/tokens/usdc-icon-secondary.svg'
              : fromToken.icon,
        }}
        toToken={{
          symbol: toToken.symbol,
          icon: toToken.icon,
        }}
        rate={
          activeTab === 'deposit'
            ? `1 ${fromToken.symbol} ≈ ${exchangeRate} ${toToken.symbol}`
            : `1 ${fromToken.symbol} ≈ ${(1 / Number(exchangeRate)).toFixed(6)} ${toToken.symbol}`
        }
      />
      <FeeDisplay fees={fees} />
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

const TabsAndBalanceRow = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
`;

const BalanceInfo = styled.div`
  font-size: 0.875rem;
  color: #8b949e;
  text-align: right;
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
