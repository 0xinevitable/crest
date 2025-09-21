import styled from '@emotion/styled';
import { useState } from 'react';

import { TradingForm } from '@/components/forms/TradingForm';
import { OperationHistory } from '@/components/ui/OperationHistory';
import { OperationHistoryModal } from '@/components/ui/OperationHistoryModal';
import { OpportunityCard } from '@/components/ui/OpportunityCard';
import { VaultMetrics } from '@/components/ui/VaultMetrics';
import { OpticianSans } from '@/fonts';

export const VaultSection: React.FC = () => {
  const [showOperationHistory, setShowOperationHistory] = useState(false);

  const handleViewHistory = () => {
    setShowOperationHistory(true);
  };

  const handleCloseHistory = () => {
    setShowOperationHistory(false);
  };

  const handleRefresh = () => {
    console.log('Refreshing operations...');
  };

  const handleViewAll = () => {
    console.log('Viewing all operations...');
  };

  return (
    <Container>
      <LeftColumn>
        <VaultCard>
          <VaultHeader>
            <VaultIcon>
              <VaultIconImage src="/assets/graphics/vault-background-image.png" />
              <VaultIconOverlay src="/assets/icons/vault-icon-overlay.svg" />
            </VaultIcon>
            <VaultTitle>Crest Vault</VaultTitle>
          </VaultHeader>

          <VaultMetrics apy="98.02%" tvl="$10.2M" />
        </VaultCard>

        <VaultActionList>
          <VaultActionSection>
            <SectionTitle>OPPORTUNITIES</SectionTitle>
            <OpportunityCard
              apy="142.39%"
              title="7d LP APY"
              tags={['Provide Liquidity', 'Quick Exit']}
            />
          </VaultActionSection>

          <VaultActionSection>
            <SectionTitle>OPERATIONS</SectionTitle>
            <OperationHistory
              lastOperation="7h ago"
              onViewHistory={handleViewHistory}
            />
          </VaultActionSection>
        </VaultActionList>
      </LeftColumn>

      <RightColumn>
        <TradingForm />
      </RightColumn>

      <OperationHistoryModal
        visible={showOperationHistory}
        onClose={handleCloseHistory}
        onRefresh={handleRefresh}
        onViewAll={handleViewAll}
      />
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 1.5rem;
  align-items: flex-start;
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 10rem 0;
`;

const LeftColumn = styled.div`
  display: flex;
  flex-direction: column;
  gap: 4rem;
  flex: 1;
`;

const VaultCard = styled.div`
  display: flex;
  flex-direction: column;
  gap: 3rem;
  padding: 2rem 1.5rem;
  background: #0a0f10;
  border-radius: 0.5rem;
`;

const VaultHeader = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1rem;
  align-items: flex-start;
  width: 299px;
`;

const VaultIcon = styled.div`
  position: relative;
  width: 64px;
  height: 64px;
  background: #091215;
  border-radius: 0.5rem;
  overflow: hidden;
`;

const VaultIconImage = styled.img`
  width: 100%;
  height: 100%;
  object-fit: cover;
`;

const VaultIconOverlay = styled.img`
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  width: 28.125px;
  height: 28.125px;
`;

const VaultTitle = styled.h2`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 3rem;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
  margin: 0;
  text-align: center;
`;

const VaultActionList = styled.ul`
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 32px;
`;
const VaultActionSection = styled.li`
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 16px;
`;

const SectionTitle = styled.h3`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
  margin: 0;
`;

const RightColumn = styled.div`
  flex-shrink: 0;
`;
