import type { paths, components, operations } from './src/generated/types';

// Re-export commonly used types for convenience
export type FundingRate = components['schemas']['FundingRate'];
export type Pagination = components['schemas']['Pagination'];
export type Error = components['schemas']['Error'];

// Path types for API endpoints
export type GetFundingRatesParams =
  paths['/funding-rates']['get']['parameters'];
export type GetFundingRatesResponse =
  paths['/funding-rates']['get']['responses']['200']['content']['application/json'];
export type GetFundingRateByIdParams =
  paths['/funding-rates/{id}']['get']['parameters'];
export type GetFundingRateByIdResponse =
  paths['/funding-rates/{id}']['get']['responses']['200']['content']['application/json'];
