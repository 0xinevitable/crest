import { Address } from 'viem';

export const Contracts = {
  Crest: {
    Vault: '0xCca1946A732E8a1400403A3061B9926C0B7C92ab' as Address,
    Teller: '0x631001Ec262E0d59Dc9b420e7f18aeB87349F128' as Address,
    Accountant: '0xe03bb63e59596Eb62696dadfAB49265AA464d888' as Address,
    Manager: '0x27ABADC46074b85CD43B4bF0301a2843fA1ca86C' as Address,
    Curator: '0x02fD526263E6D3843fdefD945511aA83c78CcF35' as Address,
    Deployer: '0x02fD526263E6D3843fdefD945511aA83c78CcF35' as Address,
    FeeRecipient: '0x02fD526263E6D3843fdefD945511aA83c78CcF35' as Address,
  },
  Tokens: {
    USDT0: '0x779Ded0c9e1022225f8E0630b35a9b54bE713736' as Address,
  },
} as const;