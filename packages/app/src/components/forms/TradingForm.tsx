import styled from '@emotion/styled';
import { useState } from 'react';

import { OpticianSans } from '@/fonts';

import { AmountInputWithTokens } from '../ui/AmountInputWithTokens';
import { FeeDisplay } from '../ui/FeeDisplay';
import { DepositWithdrawTabs } from './DepositWithdrawTabs';
import { PriceDisplay } from './PriceDisplay';

const INPUT_TOKENS = [
  {
    symbol: 'ETH',
    name: 'Ethereum',
    icon: '/assets/tokens/ethereum-icon.svg',
  },
  {
    symbol: 'USDC',
    name: 'USDC',
    icon: '/assets/tokens/usdc-icon-primary.svg',
  },
];

const OUTPUT_TOKENS = [
  {
    symbol: 'HYPEREVM',
    name: 'HyperEVM',
    icon: '/assets/tokens/hyperevm-icon.svg',
  },
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
  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw'>('deposit');
  const [inputAmount, setInputAmount] = useState('0');
  const [outputAmount, setOutputAmount] = useState('0');

  return (
    <Container>
      <FormContent>
        <DepositWithdrawTabs
          activeTab={activeTab}
          onTabChange={setActiveTab}
        />

        <AmountInputWithTokens
          label="You lock"
          value={inputAmount}
          onChange={setInputAmount}
          tokens={INPUT_TOKENS}
          onTokenSelect={(token) => console.log('Selected input token:', token)}
          variant="input"
        />

        <AmountInputWithTokens
          label="You Receive"
          value={outputAmount}
          onChange={setOutputAmount}
          tokens={OUTPUT_TOKENS}
          onTokenSelect={(token) => console.log('Selected output token:', token)}
          variant="output"
        />

        <ActionButton>
          <ButtonText>Approve USDC</ButtonText>
        </ActionButton>
      </FormContent>

      <PriceDisplay
        label="Price per share"
        fromToken={{
          symbol: 'USDC',
          icon: '/assets/tokens/usdc-icon-secondary.svg',
        }}
        toToken={{
          symbol: 'CREST',
          icon: '/assets/tokens/crest-icon.png',
        }}
        rate="1 USDC ≈ 0.99 CREST"
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