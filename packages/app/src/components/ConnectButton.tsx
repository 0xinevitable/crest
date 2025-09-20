import styled from '@emotion/styled';
import { ConnectButton as RainbowKitConnectButton } from '@rainbow-me/rainbowkit';
import { WalletIcon } from 'lucide-react';

import { shortenAddress } from '@/utils/address';

export const ConnectButton: React.FC = () => {
  return (
    <RainbowKitConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        mounted,
      }) => {
        const ready = mounted;
        const connected = mounted && account && chain;

        return (
          <div
            {...(!ready && {
              'aria-hidden': true,
              style: {
                opacity: 0,
                pointerEvents: 'none',
                userSelect: 'none',
              },
            })}
          >
            {(() => {
              if (!connected) {
                return (
                  <ConnectWalletButton onClick={openConnectModal} type="button">
                    Connect Wallet
                  </ConnectWalletButton>
                );
              }

              // FIXME: Check styles here
              if (chain.unsupported) {
                return (
                  <Button onClick={openChainModal} type="button">
                    Wrong network
                  </Button>
                );
              }

              return (
                <div style={{ display: 'flex', gap: 12 }}>
                  <UserButton onClick={openAccountModal} type="button">
                    <WalletIcon size={14} />

                    <span className="address">
                      {shortenAddress(account.address)}{' '}
                      <span className="balance">
                        {account.displayBalance
                          ? ` (${account.displayBalance})`
                          : ''}
                      </span>
                    </span>
                  </UserButton>
                </div>
              );
            })()}
          </div>
        );
      }}
    </RainbowKitConnectButton.Custom>
  );
};

const Button = styled.button`
  width: fit-content;
  display: flex;
  padding: 4px 16px;
  justify-content: center;
  align-items: center;
  gap: 10px;

  border-radius: 8px;
  background: #18edeb;

  color: #000;
  text-align: center;
  font-family: 'Optician Sans';
  font-size: 20px;
  font-style: normal;
  font-weight: 400;
  line-height: 130%; /* 28.6px */
`;
const ConnectWalletButton = styled(Button)``;

const UserButton = styled(Button)`
  background: #253738;
  color: #fff;

  & > svg {
    color: rgba(255, 255, 255, 0.6);
  }

  & > span {
    font-weight: 500;
    font-size: 20px;
    line-height: 1;
    text-align: center;
    letter-spacing: -0.04em;
  }

  span.balance {
    opacity: 0.7;

    @media (max-width: 820px) {
      display: none;
    }
  }
`;
