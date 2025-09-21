import styled from '@emotion/styled';

import { OpticianSans } from '@/fonts';

interface BalanceItemProps {
  title: string;
  subtitle: string;
  percentage: string;
  color: string;
}

export const BalanceItem: React.FC<BalanceItemProps> = ({
  title,
  subtitle,
  percentage,
  color,
}) => {
  return (
    <Container>
      <InfoContainer $color={color}>
        <Title>{title}</Title>
        <Subtitle>{subtitle}</Subtitle>
      </InfoContainer>
      <Percentage>{percentage}</Percentage>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 28px;
  align-items: center;
  width: 100%;
`;

const InfoContainer = styled.div<{ $color: string }>`
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: flex-start;
  padding-left: 44px;
  position: relative;

  &::before {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    bottom: 0;
    width: 10px;
    background-color: ${({ $color }) => $color};
  }
`;

const Title = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 24px;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
`;

const Subtitle = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 20px;
  font-weight: 400;
  line-height: 1.3;
  color: #879a98;
`;

const Percentage = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 20px;
  font-weight: 400;
  line-height: 1;
  color: #fff;
  text-align: right;
  flex: 1;
`;