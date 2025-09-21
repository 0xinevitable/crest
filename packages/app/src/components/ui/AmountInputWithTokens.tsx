import styled from '@emotion/styled';

import { InstrumentSans, OpticianSans } from '@/fonts';

import { Token, TokenBadge } from './TokenBadge';

interface AmountInputWithTokensProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  tokens: Token[];
  onTokenSelect?: (token: Token) => void;
  variant?: 'input' | 'output';
}

export const AmountInputWithTokens: React.FC<AmountInputWithTokensProps> = ({
  label,
  value,
  onChange,
  placeholder = '0',
  tokens,
  onTokenSelect,
  variant = 'input',
}) => {
  const handleInputChange = (inputValue: string) => {
    // Allow only numbers and decimal point
    const numericValue = inputValue.replace(/[^0-9.]/g, '');

    // Prevent multiple decimal points
    const parts = numericValue.split('.');
    if (parts.length > 2) {
      return;
    }

    onChange(numericValue);
  };
  return (
    <Container>
      <Label>{label}</Label>
      <InputRow>
        <Input
          type="text"
          value={value}
          onChange={(e) => handleInputChange(e.target.value)}
          placeholder={placeholder}
          disabled={variant === 'output'}
          $variant={variant}
        />
      </InputRow>

      <TokensContainer>
        {tokens.map((token) => (
          <TokenBadge
            key={token.symbol}
            token={token}
            onClick={() => onTokenSelect?.(token)}
            variant={variant}
            size="small"
          />
        ))}
      </TokensContainer>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  align-items: flex-start;
  padding: 1rem;
  background: #121819;
  border-radius: 0.5rem;
  width: 100%;
`;

const Label = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #879a98;
`;

const InputRow = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  gap: 1rem;
`;

const Input = styled.input<{ $variant: 'input' | 'output' }>`
  font-family: ${InstrumentSans.style.fontFamily};
  font-size: 2.25rem;
  font-weight: 500;
  line-height: 1.3;
  color: #fff;
  background: transparent;
  border: none;
  outline: none;
  flex: 1;

  &::placeholder {
    color: #fff;
    opacity: 0.7;
  }

  &:focus {
    outline: none;
  }

  &:disabled {
    cursor: not-allowed;
  }
`;

const TokensContainer = styled.div`
  display: flex;
  gap: 0.5rem;
  align-items: center;
  flex-shrink: 0;
`;
