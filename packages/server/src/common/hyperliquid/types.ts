export interface SpotMetaResponse {
  tokens: { name: string; index: number }[];
  universe: {
    index: number;
    tokens: [tokenIndex: number, quoteTokenIndex: number];
  }[];
}

export interface MetaResponse {
  universe: {
    szDecimals: number;
    name: string;
    maxLeverage: number;
    marginTableId: number;
  }[];
}

export type PredictedFundingData = [
  string,
  [
    string,
    {
      fundingRate: string;
      nextFundingTime: number;
      fundingIntervalHours: number;
    } | null,
  ][],
];

export interface HlPerpData {
  ticker: string;
  fundingRate: string;
}