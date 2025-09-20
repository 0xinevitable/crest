import styled from '@emotion/styled';
import { NextPage } from 'next';

const LandingPage: NextPage = () => {
  return <Container>Landing Page</Container>;
};

export default LandingPage;

const Container = styled.div`
  width: 100%;
  min-height: 100vh;
  overflow-x: hidden;
`;
