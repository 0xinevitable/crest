import styled from '@emotion/styled';

interface PieChartProps {
  size?: number;
}

export const PieChart: React.FC<PieChartProps> = ({ size = 400 }) => {
  return (
    <Container $size={size}>
      <OuterRing>
        <PieSegments>
          <Segment1 src="/assets/charts/pie-chart-segment-1.svg" />
          <Segment2 src="/assets/charts/pie-chart-segment-2.svg" />
          <Segment3 src="/assets/charts/pie-chart-segment-3.svg" />
        </PieSegments>
      </OuterRing>
      <InnerCircle>
        <InnerEffect src="/assets/charts/pie-chart-inner-effect.svg" />
        <CenterGraphic>
          <BackgroundIntersect src="/assets/charts/pie-chart-center-intersect.svg" />
          <CenterImage src="/assets/charts/pie-chart-center-3d.png" />
        </CenterGraphic>
      </InnerCircle>
    </Container>
  );
};

const Container = styled.div<{ $size: number }>`
  position: relative;
  width: ${({ $size }) => $size}px;
  height: ${({ $size }) => $size}px;
  background: #0a0f10;
  border-radius: 50%;
  flex-shrink: 0;
`;

const OuterRing = styled.div`
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  width: 340px;
  height: 340px;
  border-radius: 50%;
`;

const PieSegments = styled.div`
  position: relative;
  width: 100%;
  height: 100%;
`;

const Segment1 = styled.img`
  position: absolute;
  left: -6.18px;
  top: -5.59px;
  width: 340px;
  height: 340px;
  transform: rotate(272deg);
`;

const Segment2 = styled.img`
  position: absolute;
  left: -0.18px;
  top: 0.2px;
  width: 340px;
  height: 340px;
`;

const Segment3 = styled.img`
  position: absolute;
  left: -60px;
  top: -60px;
  width: 340px;
  height: 340px;
  transform: rotate(152deg);
`;

const InnerCircle = styled.div`
  position: absolute;
  left: 50px;
  top: 50px;
  width: 300px;
  height: 300px;
  background: #0a0f10;
  border-radius: 50%;
  overflow: hidden;
`;

const InnerEffect = styled.img`
  position: absolute;
  left: 109px;
  top: 57px;
  width: 32px;
  height: 32px;
  transform: scale(7);
`;

const CenterGraphic = styled.div`
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  width: 156px;
  height: 168px;
`;

const BackgroundIntersect = styled.img`
  position: absolute;
  left: 0.29px;
  top: 0.02px;
  width: 249.501px;
  height: 253.592px;
  transform: scale(0.6);
`;

const CenterImage = styled.img`
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  width: 156px;
  height: 168px;
  object-fit: cover;
  object-position: 30.62% 58.93%;
`;