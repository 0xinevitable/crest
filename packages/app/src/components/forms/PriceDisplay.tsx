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
          <TokenIcon src={fromToken.icon} alt={fromToken.symbol} $zIndex={2} />
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

const Label = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 18px;
  font-weight: 400;
  line-height: 1.4;
  color: #879a98;
  flex: 1;
`;

const RateContainer = styled.div`
  display: flex;
  padding: 10px 12px;
  align-items: center;
  gap: 10px;

  border-radius: 8px;
  background: linear-gradient(182deg, #0b2524 1.31%, #132c2d 98.68%);
`;
const TokenPair = styled.div`
  display: flex;
  align-items: center;
  padding-right: 9px;
  z-index: 0;
`;

const TokenIcon = styled.img<{ $zIndex: number; $hasOverlap?: boolean }>`
  width: 28px;
  height: 28px;
  border-radius: 50%;
  z-index: ${({ $zIndex }) => $zIndex};
  margin-right: ${({ $hasOverlap }) => ($hasOverlap ? '-9px' : '0')};
  border: ${({ $hasOverlap }) => ($hasOverlap ? '2px solid #256960' : 'none')};
  z-index: 0;

  &:last-of-type {
    margin-left: -9px;
    z-index: 1;
  }
`;

const RateText = styled.span`
  color: #fff;
  text-align: right;
  font-size: 18px;
  font-style: normal;
  font-weight: 500;
  line-height: 130%; /* 23.4px */
`;
