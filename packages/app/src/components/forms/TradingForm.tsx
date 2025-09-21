import styled from '@emotion/styled';
import { useState } from 'react';

import { OpticianSans } from '@/fonts';

import { AmountInput } from '../ui/AmountInput';
import { FeeDisplay } from '../ui/FeeDisplay';
import { TokenSelector } from '../ui/TokenSelector';
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
    icon: '/assets/tokens/usdc-icon-1.svg',
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
    icon: '/assets/tokens/crest-token-icon.png',
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

        <AmountInput
          label="You lock"
          value={inputAmount}
          onChange={setInputAmount}
        />
        <TokenSelector tokens={INPUT_TOKENS} />

        <AmountInput
          label="You Receive"
          value={outputAmount}
          onChange={setOutputAmount}
        />
        <TokenSelector tokens={OUTPUT_TOKENS} variant="output" />

        <ActionButton>
          <ButtonText>Approve USDC</ButtonText>
        </ActionButton>
      </FormContent>

      <PriceDisplay
        label="Price per share"
        fromToken={{
          symbol: 'USDC',
          icon: '/assets/tokens/usdc-icon-2.svg',
        }}
        toToken={{
          symbol: 'CREST',
          icon: '/assets/tokens/crest-token-icon.png',
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
  gap: 10px;
  padding: 20px;
  background: #0a0f10;
  border: 1px solid #233838;
  border-radius: 12px;
  width: 625px;
`;

const FormContent = styled.div`
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding-bottom: 24px;
`;

const ActionButton = styled.button`
  display: flex;
  gap: 10px;
  align-items: center;
  justify-content: center;
  padding: 15px 81px;
  background: #256960;
  border-radius: 8px;
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
  font-size: 28px;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
`;