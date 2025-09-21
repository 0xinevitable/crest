import styled from '@emotion/styled';

import { InstrumentSans } from '@/fonts';

export interface Token {
  symbol: string;
  icon: string;
  name: string;
}

interface TokenBadgeProps {
  token: Token;
  onClick?: (symbol: string) => void;
  variant?: 'input' | 'output';
  size?: 'default' | 'small';
}

export const TokenBadge: React.FC<TokenBadgeProps> = ({
  token,
  onClick,
  variant = 'input',
  size = 'default',
}) => {
  return (
    <BadgeButton
      onClick={() => onClick?.(token.symbol)}
      variant={variant}
      size={size}
    >
      <TokenIcon
        src={token.icon}
        alt={token.symbol}
        size={size}
        isHyperEVM={token.name.toLowerCase() === 'hyperevm'}
      />
      {token.name.toLowerCase() !== 'hyperevm' && (
        <TokenName size={size}>{token.name}</TokenName>
      )}
    </BadgeButton>
  );
};

const BadgeButton = styled.button<{
  variant: 'input' | 'output';
  size: 'default' | 'small';
}>`
  display: flex;
  gap: 0.75rem;
  align-items: center;
  padding: ${({ size }) =>
    size === 'small' ? '0.5rem 0.75rem' : '0.75rem 0.75rem'};
  border-radius: 0.5rem;
  background: ${({ variant }) =>
    variant === 'input' ? '#0a0f10' : '#50d2c126'};
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background: ${({ variant }) =>
      variant === 'input' ? '#000000' : '#50d2c126'};
  }

  &:focus {
    outline: ${({ variant }) =>
      variant === 'input' ? '2px solid #59d0cf' : 'none'};
    outline-offset: 2px;
  }
`;

const TokenIcon = styled.img<{
  size: 'default' | 'small';
  isHyperEVM: boolean;
}>`
  width: ${({ size, isHyperEVM }) => {
    if (isHyperEVM) return '100%';
    return size === 'small' ? '20px' : '28px';
  }};
  height: ${({ size }) => (size === 'small' ? '20px' : '28px')};
  border-radius: ${({ isHyperEVM }) => (isHyperEVM ? '0' : '50%')};
  object-fit: cover;
  flex-shrink: 0;
`;

const TokenName = styled.span<{ size: 'default' | 'small' }>`
  font-family: ${InstrumentSans.style.fontFamily};
  font-size: ${({ size }) => (size === 'small' ? '1.25rem' : '1.5rem')};
  font-weight: 500;
  line-height: 1;
  color: #fff;
  white-space: nowrap;
`;
