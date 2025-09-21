import styled from '@emotion/styled';

import { OpticianSans } from '@/fonts';

interface DepositWithdrawTabsProps {
  activeTab: 'deposit' | 'withdraw';
  onTabChange: (tab: 'deposit' | 'withdraw') => void;
}

export const DepositWithdrawTabs: React.FC<DepositWithdrawTabsProps> = ({
  activeTab,
  onTabChange,
}) => {
  return (
    <Container>
      <Tab
        $isActive={activeTab === 'deposit'}
        onClick={() => onTabChange('deposit')}
      >
        Deposit
      </Tab>
      <Tab
        $isActive={activeTab === 'withdraw'}
        onClick={() => onTabChange('withdraw')}
      >
        Withdraw
      </Tab>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 4px;
  align-items: flex-start;
`;

const Tab = styled.button<{ $isActive: boolean }>`
  display: flex;
  gap: 10px;
  align-items: center;
  justify-content: center;
  padding: 6px 20px;
  border-radius: 8px;
  background: ${({ $isActive }) => ($isActive ? '#121819' : 'transparent')};
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;

  font-family: ${OpticianSans.style.fontFamily};
  font-size: 24px;
  font-weight: 400;
  line-height: 1.3;
  color: ${({ $isActive }) => ($isActive ? '#fff' : '#879a98')};

  &:hover {
    background: ${({ $isActive }) => ($isActive ? '#121819' : '#0a0f10')};
  }
`;