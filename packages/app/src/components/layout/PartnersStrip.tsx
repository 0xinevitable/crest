import styled from '@emotion/styled';

const PARTNERS = [
  {
    name: 'Hyperliquid',
    logo: '/assets/logos/hyperliquid-logo.svg',
    width: '194.737px',
    height: '30px',
  },
  {
    name: 'Inevitable',
    logo: '/assets/logos/inevitable-pfp-icon.svg',
    width: '42px',
    height: '42px',
  },
  {
    name: 'Inevitable Text',
    logo: '/assets/logos/inevitable-text-logo.svg',
    width: '134.39px',
    height: '20.16px',
  },
  {
    name: 'Partner Frame',
    logo: '/assets/logos/partner-frame-logo.svg',
    width: '206.55px',
    height: '34px',
  },
];

export const PartnersStrip: React.FC = () => {
  return (
    <Container>
      <Content>
        <PartnerItem>
          <PartnerLogo
            src={PARTNERS[0].logo}
            alt={PARTNERS[0].name}
            $width={PARTNERS[0].width}
            $height={PARTNERS[0].height}
          />
        </PartnerItem>

        <PartnerGroup>
          <PartnerLogo
            src={PARTNERS[1].logo}
            alt={PARTNERS[1].name}
            $width={PARTNERS[1].width}
            $height={PARTNERS[1].height}
          />
          <PartnerLogo
            src={PARTNERS[2].logo}
            alt={PARTNERS[2].name}
            $width={PARTNERS[2].width}
            $height={PARTNERS[2].height}
          />
        </PartnerGroup>

        <PartnerItem>
          <PartnerLogo
            src={PARTNERS[3].logo}
            alt={PARTNERS[3].name}
            $width={PARTNERS[3].width}
            $height={PARTNERS[3].height}
          />
        </PartnerItem>
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

const PartnerGroup = styled.div`
  display: flex;
  gap: 16.8px;
  align-items: center;
`;

const PartnerLogo = styled.img<{ $width: string; $height: string }>`
  width: ${({ $width }) => $width};
  height: ${({ $height }) => $height};
  object-fit: contain;
`;