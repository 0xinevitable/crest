import styled from '@emotion/styled';

import { InstrumentSans, OpticianSans } from '@/fonts';

interface PriceDisplayProps {
  label: string;
  fromToken: {
    symbol: string;
    icon: string;
  };
  toToken: {
    symbol: string;
    icon: string;
  };
  rate: string;
}

export const PriceDisplay: React.FC<PriceDisplayProps> = ({
  label,
  fromToken,
  toToken,
  rate,
}) => {
  return (
    <Container>
      <Label>{label}</Label>
      <RateContainer>
        <TokenPair>
          <TokenIcon
            src={fromToken.icon}
            alt={fromToken.symbol}
            $zIndex={2}
          />
          <TokenIcon
            src={toToken.icon}
            alt={toToken.symbol}
            $zIndex={1}
            $hasOverlap
          />
        </TokenPair>
        <RateText>{rate}</RateText>
      </RateContainer>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 10px;
  align-items: flex-start;
  padding: 10px 12px;
  background: #0c1214;
  border-radius: 8px;
`;

const Label = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 18px;
  font-weight: 400;
  line-height: 1.4;
  color: #879a98;
  flex: 1;
`;

const RateContainer = styled.div`
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 10px 12px;
  border-radius: 8px;
`;

const TokenPair = styled.div`
  display: flex;
  align-items: center;
  padding-right: 9px;
`;

const TokenIcon = styled.img<{ $zIndex: number; $hasOverlap?: boolean }>`
  width: 28px;
  height: 28px;
  border-radius: 50%;
  z-index: ${({ $zIndex }) => $zIndex};
  margin-right: ${({ $hasOverlap }) => ($hasOverlap ? '-9px' : '0')};
  border: ${({ $hasOverlap }) =>
    $hasOverlap ? '2px solid #256960' : 'none'};
`;

const RateText = styled.div`
  font-family: ${InstrumentSans.style.fontFamily};
  font-size: 18px;
  font-weight: 500;
  line-height: 1.3;
  color: #fff;
  text-align: right;
`;