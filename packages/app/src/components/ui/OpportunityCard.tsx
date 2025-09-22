import styled from '@emotion/styled';

import { InstrumentSans, OpticianSans } from '@/fonts';

interface OpportunityCardProps {
  apy: string;
  title: string;
  tags: string[];
}

export const OpportunityCard: React.FC<OpportunityCardProps> = ({
  apy,
  title,
  tags,
}) => {
  return (
    <Container>
      <Content>
        <Header>
          <HeaderIcon src="/assets/icons/opportunity-header-icon.svg" />
          <TagsContainer>
            {tags.map((tag, index) => (
              <Tag key={index}>{tag}</Tag>
            ))}
          </TagsContainer>
        </Header>
      </Content>
      <APYContainer>
        <APYLabel>{title}</APYLabel>
        <APYValue>{apy}</APYValue>
      </APYContainer>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 12px;
  align-items: flex-end;
  padding: 14px 16px 16px;
  background: #4afc38;
  border-radius: 8px;
  width: 100%;
`;

const Content = styled.div`
  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: flex-start;
  flex: 1;
`;

const Header = styled.div`
  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: flex-start;
`;

const HeaderIcon = styled.img`
  width: 205.713px;
  height: 28px;
`;

const TagsContainer = styled.div`
  display: flex;
  gap: 4px;
  align-items: flex-end;
`;

const Tag = styled.div`
  display: flex;
  gap: 10px;
  align-items: center;
  justify-content: center;
  padding: 5px 8px;
  background: linear-gradient(to bottom, #86f97a, #aaffa2);
  border-radius: 4px;
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 18px;
  font-weight: 400;
  line-height: 1.3;
  color: #113a0d;
`;

const APYContainer = styled.div`
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: flex-end;
  color: #113a0d;
`;

const APYLabel = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  color: #113a0d;
  font-size: 24px;
  font-weight: 400;
  line-height: 100%; /* 24px */
`;

const APYValue = styled.span`
  color: #113a0d;
  font-size: 28px;
  font-weight: 500;
  line-height: 130%; /* 36.4px */
`;
