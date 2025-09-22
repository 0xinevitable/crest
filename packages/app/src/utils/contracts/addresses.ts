import { Address } from 'viem';
import { Config } from '../config';

type ContractAddresses = {
  Crest: {
    Vault: Address;
    Teller: Address;
    Accountant: Address;
    Manager: Address;
    Curator: Address;
    Deployer: Address;
    FeeRecipient: Address;
  };
  Tokens: {
    USDT0: Address;
  };
};

const TestnetContracts: ContractAddresses = {
  Crest: {
    Vault: '0xCca1946A732E8a1400403A3061B9926C0B7C92ab',
    Teller: '0x631001Ec262E0d59Dc9b420e7f18aeB87349F128',
    Accountant: '0xe03bb63e59596Eb62696dadfAB49265AA464d888',
    Manager: '0x27ABADC46074b85CD43B4bF0301a2843fA1ca86C',
    Curator: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
    Deployer: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
    FeeRecipient: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
  },
  Tokens: {
    USDT0: '0x779Ded0c9e1022225f8E0630b35a9b54bE713736',
  },
};

const MainnetContracts: ContractAddresses = {
  Crest: {
    // Mainnet uses Diamond pattern - all contracts use the same diamond address
    Vault: '0x1A56836057e5c788C6d104f422Dc40100992EA0c',
    Teller: '0x1A56836057e5c788C6d104f422Dc40100992EA0c',
    Accountant: '0x1A56836057e5c788C6d104f422Dc40100992EA0c',
    Manager: '0x1A56836057e5c788C6d104f422Dc40100992EA0c',
    Curator: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
    Deployer: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
    FeeRecipient: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
  },
  Tokens: {
    USDT0: '0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb', // Mainnet USDT0
  },
};

export const Contracts = Config.ENVIRONMENT === 'production' 
  ? MainnetContracts 
  : TestnetContracts;