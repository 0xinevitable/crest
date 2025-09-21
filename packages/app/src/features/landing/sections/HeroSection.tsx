import styled from '@emotion/styled';

import { InstrumentSans, OpticianSans } from '@/fonts';

export const HeroSection: React.FC = () => {
  return (
    <Container>
      <BackgroundIntersect src="/assets/graphics/hero-background-intersect.svg" />
      <CenterGraphic src="/assets/graphics/hero-3d-graphic.png" />

      <Content>
        <Title>
          Ride the Peak
          <br />
          of Every Wave
        </Title>
        <Subtitle>
          High-performing, Hedged Yields
          <br />
          from the Best Hyperliquid Funding
        </Subtitle>
      </Content>
    </Container>
  );
};

const Container = styled.div`
  position: relative;
  width: 100%;
  height: 43rem;
  background: linear-gradient(to bottom, #171f20, #090e0f);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
`;

const BackgroundIntersect = styled.img`
  position: absolute;
  left: 50%;
  top: 0;
  transform: translateX(-50%);
  width: 61rem;
  height: 33rem;
  object-fit: contain;
`;

const CenterGraphic = styled.img`
  position: absolute;
  left: calc(50% - 0.133px);
  top: 54px;
  width: 365.733px;
  height: 422px;

  object-fit: cover;
  object-position: 37.54% 30.7%;
  background-size: 162.64% 140.95%;
  transform: translateX(-50%);
`;

const Content = styled.div`
  position: absolute;
  top: 389px;
  left: 50%;
  transform: translateX(-50%);

  display: flex;
  flex-direction: column;
  gap: 28px;
  align-items: center;
  text-align: center;
  width: 31rem;
  z-index: 10;
`;

const Title = styled.h1`
  font-family: ${OpticianSans.style.fontFamily};
  color: #fff;
  text-align: center;
  font-size: 64px;
  font-weight: 400;
  line-height: 93%; /* 59.52px */
`;

const Subtitle = styled.p`
  font-family: ${InstrumentSans.style.fontFamily};
  color: #59d0cf;
  text-align: center;
  font-size: 24px;
  font-weight: 500;
  line-height: 130%; /* 31.2px */
`;
