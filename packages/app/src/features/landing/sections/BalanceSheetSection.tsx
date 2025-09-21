import styled from '@emotion/styled';

import { BalanceItem } from '@/components/ui/BalanceItem';
import { PieChart } from '@/components/ui/PieChart';
import { OpticianSans } from '@/fonts';

const BALANCE_ITEMS = [
  {
    title: 'HYPE (SPOT)',
    subtitle: 'Hypercore',
    percentage: '49.42%',
    color: '#18edeb',
  },
  {
    title: 'HYPE (1x SHORT)',
    subtitle: 'Hypercore',
    percentage: '49.42%',
    color: '#e24e76',
  },
  {
    title: 'USDC (EXTRA MARGIN)',
    subtitle: 'Hypercore',
    percentage: '1.15%',
    color: '#0085ff',
  },
  {
    title: 'USDC (TO BE ALLOCATED)',
    subtitle: 'HYPEREVM',
    percentage: '1.01%',
    color: '#7f99ff',
  },
];

export const BalanceSheetSection: React.FC = () => {
  return (
    <Container>
      <Title>balance SHEET</Title>
      <Content>
        <PieChart size={400} />
        <BalanceList>
          {BALANCE_ITEMS.map((item, index) => (
            <BalanceItem
              key={index}
              title={item.title}
              subtitle={item.subtitle}
              percentage={item.percentage}
              color={item.color}
            />
          ))}
        </BalanceList>
      </Content>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  flex-direction: column;
  gap: 54px;
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
`;

const Title = styled.h2`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 44px;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
  margin: 0;
`;

const Content = styled.div`
  display: flex;
  gap: 64px;
  align-items: flex-start;
  width: 100%;
`;

const BalanceList = styled.div`
  display: flex;
  flex-direction: column;
  gap: 28px;
  flex: 1;
`;