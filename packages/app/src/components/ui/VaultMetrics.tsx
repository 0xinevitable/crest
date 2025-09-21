import styled from '@emotion/styled';

import { InstrumentSans, OpticianSans } from '@/fonts';

interface VaultMetricsProps {
  apy: string;
  tvl: string;
  showFeverIcon?: boolean;
}

export const VaultMetrics: React.FC<VaultMetricsProps> = ({
  apy,
  tvl,
  showFeverIcon = true,
}) => {
  return (
    <Container>
      <MetricGroup>
        <Label>Estimated APY</Label>
        <ValueContainer>
          <Value>{apy}</Value>
          {showFeverIcon && (
            <FeverIcon>
              <FeverImage src="/assets/icons/fever-mode-icon.png" />
              <Ellipse1 src="/assets/icons/fever-ellipse-1.svg" />
              <Ellipse2 src="/assets/icons/fever-ellipse-2.svg" />
            </FeverIcon>
          )}
        </ValueContainer>
      </MetricGroup>

      <MetricGroup>
        <Label>TVL</Label>
        <Value>{tvl}</Value>
      </MetricGroup>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 76px;
  align-items: center;
  width: 100%;
`;

const MetricGroup = styled.div`
  display: flex;
  flex-direction: column;
  gap: 11px;
  align-items: flex-start;
`;

const Label = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 24px;
  font-weight: 400;
  line-height: 1.3;
  color: #879a98;
`;

const ValueContainer = styled.div`
  display: flex;
  gap: 6px;
  align-items: flex-start;
`;

const Value = styled.span`
  font-family: ${InstrumentSans.style.fontFamily};
  font-size: 40px;
  font-weight: 500;
  line-height: 1.3;
  color: #fff;
`;

const FeverIcon = styled.div`
  position: relative;
  width: 20.308px;
  height: 44px;
`;

const FeverImage = styled.img`
  position: absolute;
  top: 0;
  left: 0;
  width: 20.308px;
  height: 44px;
  object-fit: cover;
  object-position: 45.83% 35%;
  filter: blur(0px);
`;

const Ellipse1 = styled.img`
  position: absolute;
  left: 6.77px;
  top: 29.61px;
  width: 10.154px;
  height: 10.154px;
`;

const Ellipse2 = styled.img`
  position: absolute;
  left: 5.92px;
  top: 26.23px;
  width: 10.154px;
  height: 15.231px;
`;
