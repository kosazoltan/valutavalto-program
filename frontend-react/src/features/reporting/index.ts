/**
 * Reporting modul főexport
 *
 * Használat:
 * ```typescript
 * import { useDailyReport, DailyReportCard } from '@/features/reporting'
 * ```
 *
 * @since 2026-01-13
 */

// API
export { reportingApi } from './api/reportingApi'

// Hooks
export {
  useDailyReport,
  useDailySummary,
  usePeriodReport,
  useCurrencyTurnover,
  useWorkerStats,
  reportingKeys,
} from './hooks/useReporting'

// Components
export { DailyReportCard, PeriodReportChart, WorkerStatsTable } from './components'

// Types
export type {
  DailyReport,
  DailySummary,
  PeriodReport,
  CurrencyTurnover,
  WorkerStats,
  TransactionSummary,
  CurrencySummary,
  CashBalanceSummary,
  DailyBreakdown,
  CurrencyDetail,
  WorkerDetail,
} from './types'
