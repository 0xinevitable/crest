type Config = {
  ENVIRONMENT: 'development' | 'production';
  NETWORK: 'testnet' | 'mainnet';
};

const environment = (process.env.NEXT_PUBLIC_ENVIRONMENT || 'development') as 'development' | 'production';
const network = environment === 'production' ? 'mainnet' : 'testnet';

export const Config = {
  ENVIRONMENT: environment,
  NETWORK: network,
} as Config;
