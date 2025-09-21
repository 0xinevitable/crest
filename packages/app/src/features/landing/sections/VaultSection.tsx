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

const VaultActions = styled.div`
  display: flex;
  flex-direction: column;
  gap: 2rem;
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