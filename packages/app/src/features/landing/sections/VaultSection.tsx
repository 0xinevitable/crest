import styled from '@emotion/styled';

import { OperationHistory } from '@/components/ui/OperationHistory';
import { OpportunityCard } from '@/components/ui/OpportunityCard';
import { VaultMetrics } from '@/components/ui/VaultMetrics';
import { TradingForm } from '@/components/forms/TradingForm';
import { OpticianSans } from '@/fonts';

export const VaultSection: React.FC = () => {
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

        <VaultActions>
          <SectionTitle>OPPORTUNITIES</SectionTitle>
          <OpportunityCard
            apy="142.39%"
            title="7d LP APY"
            tags={['Provide Liquidity', 'Quick Exit']}
          />

          <SectionTitle>OPERATIONS</SectionTitle>
          <OperationHistory lastOperation="7h ago" />
        </VaultActions>
      </LeftColumn>

      <RightColumn>
        <TradingForm />
      </RightColumn>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 24px;
  align-items: flex-start;
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 160px 0;
`;

const LeftColumn = styled.div`
  display: flex;
  flex-direction: column;
  gap: 64px;
  flex: 1;
`;

const VaultCard = styled.div`
  display: flex;
  flex-direction: column;
  gap: 48px;
  padding: 32px 24px;
  background: #0a0f10;
  border-radius: 8px;
`;

const VaultHeader = styled.div`
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: flex-start;
  width: 299px;
`;

const VaultIcon = styled.div`
  position: relative;
  width: 64px;
  height: 64px;
  background: #091215;
  border-radius: 8px;
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
  font-size: 49px;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
  margin: 0;
  text-align: center;
`;

const VaultActions = styled.div`
  display: flex;
  flex-direction: column;
  gap: 32px;
`;

const SectionTitle = styled.h3`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 24px;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
  margin: 0;
`;

const RightColumn = styled.div`
  flex-shrink: 0;
`;