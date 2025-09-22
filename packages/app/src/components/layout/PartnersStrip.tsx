import styled from '@emotion/styled';

const PARTNERS = [
  {
    name: 'Hyperliquid',
    logo: '/assets/logos/hyperliquid-logo.svg',
    width: '194.737px',
    height: '30px',
  },
  {
    name: 'Hyperdrive',
    logo: '/assets/logos/hyperdrive-logo.svg',
    width: '142.38px',
    height: '34px',
  },
  {
    name: 'Inevitable',
    logo: '/assets/logos/inevitable-logo.svg',
    width: '193.19px',
    height: '42px',
  },
  {
    name: 'deBridge',
    logo: '/assets/logos/debridge-logo.svg',
    width: '189px',
    height: '31px',
  },
];

export const PartnersStrip: React.FC = () => {
  return (
    <Container>
      <Content>
        {PARTNERS.map((partner) => (
          <PartnerItem key={partner.name}>
            <PartnerLogo
              src={partner.logo}
              alt={partner.name}
              $width={partner.width}
              $height={partner.height}
            />
          </PartnerItem>
        ))}
      </Content>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 63px;
  align-items: center;
  justify-content: center;
  padding: 44px 285px;
  height: 132px;
  width: 100%;
  max-width: 1728px;
  margin: 0 auto;
  overflow: hidden;
`;

const Content = styled.div`
  display: flex;
  gap: 63px;
  align-items: center;
  justify-content: center;
`;

const PartnerItem = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
`;

const PartnerLogo = styled.img<{ $width: string; $height: string }>`
  width: ${({ $width }) => $width};
  height: ${({ $height }) => $height};
  object-fit: contain;
`;
