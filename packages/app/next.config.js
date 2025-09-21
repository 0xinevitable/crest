const { withPlugins } = require('next-composed-plugins');

const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withPlugins(
  {
    reactStrictMode: true,
    compiler: {
      emotion: true,
    },
    webpack5: true,
    webpack: (config) => {
      config.resolve.fallback = {
        // Peer dependency import fallback for wagmi > @wagmi/connectors > @metamask/sdk
        '@react-native-async-storage/async-storage': false,
      };
      return config;
    },
  },
  [withBundleAnalyzer],
);
