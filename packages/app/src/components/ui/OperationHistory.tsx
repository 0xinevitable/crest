import styled from '@emotion/styled';

import { OpticianSans } from '@/fonts';

interface OperationHistoryProps {
  lastOperation: string;
  onViewHistory?: () => void;
}

export const OperationHistory: React.FC<OperationHistoryProps> = ({
  lastOperation,
  onViewHistory,
}) => {
  return (
    <Container>
      <InfoContainer>
        <Label>LAST OPERATION</Label>
        <Value>{lastOperation}</Value>
      </InfoContainer>
      <ViewHistoryButton onClick={onViewHistory}>
        <ButtonText>VIEW HISTORY</ButtonText>
        <ArrowIcon src="/assets/icons/arrow-up-right-icon.svg" />
      </ViewHistoryButton>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 14px 16px;
  background: #0a0f10;
  border-radius: 8px;
  width: 100%;
`;

const InfoContainer = styled.div`
  display: flex;
  gap: 12px;
  align-items: flex-start;
  flex: 1;
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 24px;
  font-weight: 400;
  line-height: 1;
`;

const Label = styled.div`
  color: #879a98;
`;

const Value = styled.div`
  color: #fff;
`;

const ViewHistoryButton = styled.button`
  display: flex;
  gap: 4px;
  align-items: center;
  justify-content: center;
  padding: 5px 8px 5px 5px;
  background: #121819;
  border-radius: 4px;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background: #1a2324;
  }
`;

const ButtonText = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 18px;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
`;

const ArrowIcon = styled.img`
  width: 18px;
  height: 18px;
`;