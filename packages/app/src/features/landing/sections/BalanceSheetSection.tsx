import styled from '@emotion/styled';
import { Cell, Pie, PieChart, ResponsiveContainer } from 'recharts';

import { BalanceItem } from '@/components/ui/BalanceItem';
import { OpticianSans } from '@/fonts';



interface BalanceData {
  title: string;
  subtitle: string;
  value: number;
  color: string;
  [key: string]: string | number;
}

const BALANCE_DATA: BalanceData[] = [
  {
    title: 'HYPE (SPOT)',
    subtitle: 'Hypercore',
    value: 49.42,
    color: '#18edeb',
  },
  {
    title: 'HYPE (1x SHORT)',
    subtitle: 'Hypercore',
    value: 49.42,
    color: '#e24e76',
  },
  {
    title: 'USDC (EXTRA MARGIN)',
    subtitle: 'Hypercore',
    value: 1.15,
    color: '#0085ff',
  },
  {
    title: 'USDC (TO BE ALLOCATED)',
    subtitle: 'HYPEREVM',
    value: 1.01,
    color: '#7f99ff',
  },
];

export const BalanceSheetSection: React.FC = () => {
  return (
    <Container>
      <Title>balance SHEET</Title>
      <Content>
        <ChartContainer>
          <ResponsiveContainer width="100%" height={400}>
            <PieChart>
              <Pie
                data={BALANCE_DATA}
                cx="50%"
                cy="50%"
                outerRadius={180}
                innerRadius={80}
                dataKey="value"
                stroke="none"
              >
                {BALANCE_DATA.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
          <CenterGraphic>
            <BackgroundIntersect src="/assets/charts/chart-background-intersect.svg" />
            <CenterImage src="/assets/charts/chart-center-3d.png" />
            <CenterEllipse src="/assets/charts/chart-center-ellipse.svg" />
          </CenterGraphic>
        </ChartContainer>
        <BalanceList>
          {BALANCE_DATA.map((item, index) => (
            <BalanceItem
              key={index}
              title={item.title}
              subtitle={item.subtitle}
              percentage={`${item.value.toFixed(2)}%`}
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
  align-items: center;
  width: 100%;
`;

const ChartContainer = styled.div`
  position: relative;
  width: 400px;
  height: 400px;
  flex-shrink: 0;
  background: #0a0f10;
  border-radius: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
`;

const CenterGraphic = styled.div`
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 300px;
  height: 300px;
  background: #0a0f10;
  border-radius: 300px;
  pointer-events: none;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
`;

const BackgroundIntersect = styled.img`
  position: absolute;
  top: 0;
  left: 0;
  width: 280px;
  height: 284px;
  object-fit: cover;
`;

const CenterImage = styled.img`
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 240px;
  height: 240px;
  object-fit: contain;
`;

const CenterEllipse = styled.img`
  position: absolute;
  top: 65px;
  left: 120px;
  width: 60px;
  height: 60px;
  object-fit: contain;
`;

const BalanceList = styled.div`
  display: flex;
  flex-direction: column;
  gap: 28px;
  flex: 1;
`;