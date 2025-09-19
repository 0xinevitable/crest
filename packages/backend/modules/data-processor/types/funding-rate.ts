export interface ExchangeFundingData {
  fundingRate: string;
  nextFundingTime: number;
  fundingIntervalHours?: number;
}

export interface ExchangeData {
  [exchangeName: string]: ExchangeFundingData | null;
}

export interface SymbolData {
  [symbolName: string]: Array<[string, ExchangeFundingData | null]>;
}

export type RawLogData = Array<
  [string, Array<[string, ExchangeFundingData | null]>]
>;

export interface ProcessedFundingRate {
  symbol: string;
  exchange: string;
  fundingRate: number;
  nextFundingTime: Date;
  fundingIntervalHours: number | null;
  processedAt: Date;
  logFile: string;
}

export interface LogProcessingResult {
  totalRecords: number;
  successfulRecords: number;
  errors: string[];
}
