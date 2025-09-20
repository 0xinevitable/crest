import styled from '@emotion/styled';

import { ConnectButton } from './ConnectButton';

export const NavigationBar = () => {
  return (
    <Wrapper>
      <Container>
        <Logo src="/assets/crest-logo.svg" />

        <Right>
          <ConnectButton />
        </Right>
      </Container>
    </Wrapper>
  );
};

const Wrapper = styled.div`
  width: 100%;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
`;
const Container = styled.div`
  margin: 0 auto;
  padding: 24px 20px;

  width: 100%;
  max-width: 1200px;

  display: flex;
  align-items: center;
`;
const Logo = styled.img`
  width: 124px;
  height: 32px;
  object-fit: contain;
`;

const Right = styled.div`
  margin-left: auto;
  display: flex;
  align-items: center;
`;
