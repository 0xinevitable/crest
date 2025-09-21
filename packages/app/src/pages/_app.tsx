import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppProps } from 'next/app';
import React from 'react';
import { WagmiProvider } from 'wagmi';

import { NavigationBar } from '@/components/NavigationBar';
import { wagmiConfig } from '@/constants/config';
import { InstrumentSans } from '@/fonts';
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

      <style jsx global>{`
        * {
          font-family:
            ${InstrumentSans.style.fontFamily},
            -apple-system,
            BlinkMacSystemFont,
            'Segoe UI',
            Roboto,
            Helvetica,
            Arial,
            sans-serif,
            'Apple Color Emoji',
            'Segoe UI Emoji',
            'Segoe UI Symbol';
          font-optical-sizing: auto;
        }
      `}</style>
    </>
  );
};

export default MyApp;
