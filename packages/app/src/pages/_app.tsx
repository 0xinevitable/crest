import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppProps } from 'next/app';
import React from 'react';
import { WagmiProvider } from 'wagmi';

import { NavigationBar } from '@/components/NavigationBar';
import { wagmiConfig } from '@/constants/config';
import '@/styles/global.css';

const queryClient = new QueryClient();

const MyApp: React.FC<AppProps> = ({ Component, pageProps }) => {
  return (
    <>
      <WagmiProvider config={wagmiConfig}>
        <QueryClientProvider client={queryClient}>
          <RainbowKitProvider
            locale="en-US"
            modalSize="compact"
            theme={darkTheme({
              accentColor: '#ABF5FF',
              accentColorForeground: '#000',
              borderRadius: 'large',
              overlayBlur: 'small',
            })}
          >
            <NavigationBar />

            <Component {...pageProps} />
          </RainbowKitProvider>
        </QueryClientProvider>
      </WagmiProvider>

      <div id="portal" />
    </>
  );
};

export default MyApp;
