import styled from '@emotion/styled';

import { PartnersStrip } from '@/components/layout/PartnersStrip';

export const PartnersSection: React.FC = () => {
  return (
    <Container>
      <PartnersStrip />
    </Container>
  );
};

const Container = styled.div`
  width: 100%;
  background: #040606;
  border-top: 1px solid #233838;
  border-bottom: 1px solid #233838;
`;