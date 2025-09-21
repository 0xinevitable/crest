type Config = {
  ENVIRONMENT: 'development' | 'production';
};

export const Config = {
  ENVIRONMENT: process.env.NEXT_PUBLIC_ENVIRONMENT || 'development',
} as Config;
