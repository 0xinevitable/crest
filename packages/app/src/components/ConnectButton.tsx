import styled from '@emotion/styled';
import { ConnectButton as RainbowKitConnectButton } from '@rainbow-me/rainbowkit';
import { WalletIcon } from 'lucide-react';

import { OpticianSans } from '@/fonts';
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
  padding: 0.25rem 1rem;
  justify-content: center;
  align-items: center;
  gap: 0.75rem;

  border-radius: 0.5rem;
  background: #18edeb;

  color: #000;
  text-align: center;
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 1.25rem;
  font-style: normal;
  font-weight: 400;
  line-height: 100%;
`;
const ConnectWalletButton = styled(Button)`
  padding: 0.25rem 1rem;
`;

const UserButton = styled(Button)`
  background: #253738;
  color: #fff;

  & > svg {
    color: rgba(255, 255, 255, 0.6);
  }

  & > span {
    font-weight: 500;
    font-size: 1.25rem;
    line-height: 1;
    text-align: center;
    letter-spacing: -0.04em;
  }

  span.balance {
    opacity: 0.7;

    @media (max-width: 51.25rem) {
      display: none;
    }
  }
`;
