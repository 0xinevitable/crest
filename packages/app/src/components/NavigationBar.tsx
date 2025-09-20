import styled from '@emotion/styled';

import { ConnectButton } from './ConnectButton';

export const NavigationBar = () => {
  return (
    <Wrapper>
      <Container>
        <ConnectButton />
      </Container>
    </Wrapper>
  );
};

const Wrapper = styled.div`
  width: 100%;
`;
const Container = styled.div`
  display: flex;
  width: 1200px;
  padding: 0 20px;
  align-items: center;
  gap: 24px;
`;
