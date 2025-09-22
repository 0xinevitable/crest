import styled from '@emotion/styled';

import { InstrumentSans, OpticianSans } from '@/fonts';

interface FeeItem {
  label: string;
  value: string;
  showInfo?: boolean;
}

interface FeeDisplayProps {
  fees: FeeItem[];
}

export const FeeDisplay: React.FC<FeeDisplayProps> = ({ fees }) => {
  return (
    <Container>
      {fees.map((fee, index) => (
        <FeeItem key={index}>
          <FeeLabel>{fee.label}</FeeLabel>
          <FeeValueContainer>
            <FeeValue>{fee.value}</FeeValue>
            {fee.showInfo && (
              <InfoIcon
                src="/assets/icons/info-icon.svg"
                onClick={() => console.log('Info clicked for:', fee.label)}
              />
            )}
          </FeeValueContainer>
        </FeeItem>
      ))}
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  flex-direction: column;
  gap: 7px;
  width: 100%;
`;

const FeeItem = styled.div`
  display: flex;
  gap: 10px;
  align-items: flex-start;
  padding: 10px 12px;
  background: #0c1214;
  border-radius: 8px;
  justify-content: space-between;
`;

const FeeLabel = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 18px;
  font-weight: 400;
  line-height: 1.4;
  color: #879a98;
  flex: 1;
`;

const FeeValueContainer = styled.div`
  display: flex;
  gap: 0.5rem;
  align-items: center;
`;

const FeeValue = styled.span`
  font-family: ${InstrumentSans.style.fontFamily};
  font-size: 18px;
  font-weight: 500;
  line-height: 1.4;
  color: #fff;
`;

const InfoIcon = styled.img`
  width: 18px;
  height: 18px;
  cursor: pointer;
  transition: opacity 0.2s ease;

  &:hover {
    opacity: 0.7;
  }
`;
