import z from 'zod';

export const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),
  PORT: z.coerce.number().min(1).max(65535).default(3000),

  DATABASE_URL: z.url(),

  CORS_ORIGIN: z.string().default('*'),

  HYPERLIQUID_MAINNET_API_URL: z
    .url()
    .default('https://api-ui.hyperliquid.xyz'),
  HYPERLIQUID_TESTNET_API_URL: z
    .url()
    .default('https://api-ui.hyperliquid-testnet.xyz'),

  S3_ENDPOINT: z.url(),
  S3_ACCESS_KEY: z.string(),
  S3_SECRET_KEY: z.string(),
  S3_BUCKET: z.string(),
});

export type EnvConfig = z.infer<typeof envSchema>;
