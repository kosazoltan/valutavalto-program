/**
 * Integration modul főexport
 *
 * @since 2026-01-13
 */

// API
export { mnbRateApi } from './api/mnbRateApi'

// Hooks
export {
  useMnbCurrentRates,
  useMnbRatesForDate,
  useMnbCurrencyRate,
  useMnbRateHistory,
  useMnbRateComparison,
  mnbRateKeys,
} from './hooks'

// Components
export { MnbRatesTable, RateComparisonTable } from './components'

// Pages
export { MnbRatesV2Page } from './MnbRatesV2Page'

// Types
export type { MnbRateDto, MnbRatesResponse, RateComparison, ComparisonReport } from './types'

// NAV Integration
export * from './nav'
