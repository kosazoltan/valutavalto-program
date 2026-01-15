/**
 * Compliance modul főexport
 *
 * @since 2026-01-13
 */

// API
export { complianceApi } from './api/complianceApi'

// Hooks
export {
  useComplianceCheck,
  useCustomerProfile,
  useAmlAlerts,
  useDailyComplianceSummary,
  complianceKeys,
} from './hooks/useCompliance'

// Components
export { ComplianceCheckResult, CustomerRiskCard } from './components'

// Types
export type {
  ComplianceCheck,
  CustomerRiskProfile,
  AmlAlert,
  DailyComplianceSummary,
  Warning,
  RiskFactor,
} from './types'
