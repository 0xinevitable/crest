import styled from '@emotion/styled';
import React from 'react';

import { OpticianSans } from '@/fonts';

import { Modal, ModalProps } from './Modal';

type OperationType = 'ALLOCATION' | 'REBALANCING' | 'EXIT';

interface OperationItem {
  type: OperationType;
  label: string;
  timestamp: string;
  txId?: string;
  icon?: string;
}

interface OperationHistoryModalProps extends Omit<ModalProps, 'children'> {
  operations?: OperationItem[];
  onRefresh?: () => void;
  onViewAll?: () => void;
  onClose: () => void;
}

const mockOperations: OperationItem[] = [
  {
    type: 'ALLOCATION',
    label: '+1,334 USDC',
    timestamp: '7h ago',
    txId: 'tx123',
  },
  {
    type: 'REBALANCING',
    label: 'HYPE/USDC',
    timestamp: '7h ago',
    txId: 'tx456',
    icon: '/assets/logos/hyperliquid-logo.svg',
  },
  {
    type: 'REBALANCING',
    label: 'Ai16Z/USDC',
    timestamp: '7h ago',
    txId: 'tx789',
  },
];

export const OperationHistoryModal: React.FC<OperationHistoryModalProps> = ({
  operations = mockOperations,
  onRefresh,
  onViewAll,
  onClose,
  ...modalProps
}) => {
  return (
    <Modal {...modalProps} onDismiss={onClose}>
      <Container>
        <Header>
          <Title>OPERATION HISTORY</Title>
          <CloseButton onClick={onClose}>
            <CloseIcon src="/assets/icons/close-icon.svg" alt="Close" />
          </CloseButton>
        </Header>

        <OperationsList>
          {operations.map((operation, index) => (
            <OperationItem key={index}>
              <OperationInfo>
                <OperationTypeLabel>{operation.type}</OperationTypeLabel>
                <OperationLabelContainer>
                  {operation.type === 'ALLOCATION' && (
                    <AllocationLabel>{operation.label}</AllocationLabel>
                  )}
                  {operation.type === 'REBALANCING' && (
                    <RebalancingLabel>
                      {operation.icon && (
                        <TokenIcon src={operation.icon} alt={operation.label} />
                      )}
                      <TokenPair>{operation.label}</TokenPair>
                    </RebalancingLabel>
                  )}
                  {operation.type === 'EXIT' && (
                    <ExitLabel>{operation.label}</ExitLabel>
                  )}
                </OperationLabelContainer>
              </OperationInfo>
              
              <TransactionInfo>
                <TxButton>
                  <TxText>TX</TxText>
                  <ArrowIcon src="/assets/icons/arrow-up-right-icon.svg" alt="External link" />
                </TxButton>
                <Timestamp>{operation.timestamp}</Timestamp>
              </TransactionInfo>
            </OperationItem>
          ))}
        </OperationsList>

        <Footer>
          <RefreshButton onClick={onRefresh}>
            <ButtonText>REFRESH</ButtonText>
          </RefreshButton>
          <ViewAllButton onClick={onViewAll}>
            <ButtonText>VIEW ALL</ButtonText>
          </ViewAllButton>
        </Footer>
      </Container>
    </Modal>
  );
};

const Container = styled.div`
  width: 625px;
  height: 494px;
  background: #0a0f10;
  border-radius: 0.75rem;
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
`;

const Header = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
`;

const Title = styled.h2`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.75rem;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
  margin: 0;
`;

const CloseButton = styled.button`
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
`;

const CloseIcon = styled.img`
  width: 1.5rem;
  height: 1.5rem;
`;

const OperationsList = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  flex: 1;
  overflow-y: auto;
`;

const OperationItem = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1rem;
  background: #121819;
  border-radius: 0.5rem;
`;

const OperationInfo = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
`;

const OperationTypeLabel = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #879a98;
`;

const OperationLabelContainer = styled.div`
  display: flex;
  align-items: center;
  gap: 0.75rem;
`;

const AllocationLabel = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #59d0cf;
`;

const RebalancingLabel = styled.div`
  display: flex;
  align-items: center;
  gap: 0.75rem;
`;

const TokenIcon = styled.img`
  width: 1.25rem;
  height: 1.25rem;
  border-radius: 50%;
  object-fit: cover;
`;

const TokenPair = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #59d0cf;
`;

const ExitLabel = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #e24e76;
`;

const TransactionInfo = styled.div`
  display: flex;
  align-items: center;
  gap: 1.25rem;
`;

const TxButton = styled.button`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.25rem 0.5rem;
  background: #233838;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background: #2d4545;
  }
`;

const TxText = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.25rem;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
`;

const ArrowIcon = styled.img`
  width: 1.125rem;
  height: 1.125rem;
`;

const Timestamp = styled.div`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
`;

const Footer = styled.div`
  display: flex;
  gap: 0.75rem;
  width: 100%;
`;

const RefreshButton = styled.button`
  flex: 1;
  padding: 0.75rem;
  background: #256960;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background: #2d7a70;
  }
`;

const ViewAllButton = styled.button`
  flex: 1;
  padding: 0.75rem;
  background: #132c2d;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background: #1a3a3b;
  }
`;

const ButtonText = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 1.3;
  color: #fff;
`;