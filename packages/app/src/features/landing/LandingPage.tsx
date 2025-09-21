import styled from '@emotion/styled';
import { NextPage } from 'next';



import { BalanceSheetSection } from './sections/BalanceSheetSection';
import { HeroSection } from './sections/HeroSection';
import { PartnersSection } from './sections/PartnersSection';
import { VaultSection } from './sections/VaultSection';


const LandingPage: NextPage = () => {
  return (
    <Container>
      <HeroSection />
      <PartnersSection />
      <VaultSection />
      <BalanceSheetSection />
      <Footer />
    </Container>
  );
};

export default LandingPage;

const Container = styled.div`
  width: 100%;
  min-height: 100vh;
  overflow-x: hidden;
  background: #141b1d;
`;

const Footer = styled.div`
  width: 100%;
  height: 428px;
  background: #0a0f10;
`;