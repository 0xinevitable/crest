import { Address } from 'viem';

export const Contracts = {
  Crest: {
    Vault: '0xcC94F7f8C7e77b197ED0cb85f50997Bae7a49a8b' as Address,
    Teller: '0x97e956869455bC59BCA559a130109A3D5aCc0049' as Address,
    Accountant: '0x3bc8D1648F445b99A812B858E82786637dfC4d9D' as Address,
    Manager: '0x36EBA6d5cd2d862deFE6E41FBF90EeB347594e4F' as Address,
    Curator: '0x02fD526263E6D3843fdefD945511aA83c78CcF35' as Address,
    Deployer: '0x02fD526263E6D3843fdefD945511aA83c78CcF35' as Address,
    FeeRecipient: '0x02fD526263E6D3843fdefD945511aA83c78CcF35' as Address,
  },
  Tokens: {
    USDT0: '0x779Ded0c9e1022225f8E0630b35a9b54bE713736' as Address,
  },
} as const;
