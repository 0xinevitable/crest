import styled from '@emotion/styled';

import { InstrumentSans } from '@/fonts';

interface Token {
  symbol: string;
  icon: string;
  name: string;
}

interface TokenSelectorProps {
  tokens: Token[];
  selectedTokens?: string[];
  onTokenSelect?: (symbol: string) => void;
  variant?: 'input' | 'output';
}

export const TokenSelector: React.FC<TokenSelectorProps> = ({
  tokens,
  selectedTokens = [],
  onTokenSelect,
  variant = 'input',
}) => {
  return (
    <Container>
      {tokens.map((token) => (
        <TokenButton
          key={token.symbol}
          onClick={() => onTokenSelect?.(token.symbol)}
          $isSelected={selectedTokens.includes(token.symbol)}
          $variant={variant}
        >
          <TokenIcon src={token.icon} alt={token.symbol} />
          <TokenName>{token.name}</TokenName>
        </TokenButton>
      ))}
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 6px;
  align-items: flex-start;
`;

const TokenButton = styled.button<{
  $isSelected: boolean;
  $variant: 'input' | 'output';
}>`
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 10px 12px;
  border-radius: 8px;
  background: ${({ $variant }) =>
    $variant === 'input' ? '#0a0f10' : 'transparent'};
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background: ${({ $variant }) =>
      $variant === 'input' ? '#121819' : '#0a0f10'};
  }
`;

const TokenIcon = styled.img`
  width: 28px;
  height: 28px;
  border-radius: 50%;
  object-fit: cover;
`;

const TokenName = styled.span`
  font-family: ${InstrumentSans.style.fontFamily};
  font-size: 24px;
  font-weight: 500;
  line-height: 1;
  color: #fff;
`;