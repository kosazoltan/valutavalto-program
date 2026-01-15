/**
 * Compliance modul típusok
 *
 * @since 2026-01-13
 */

/**
 * Figyelmeztetés típus
 */
export interface Warning {
  code: string
  message: string
  severity: 'INFO' | 'WARNING' | 'ERROR'
}

/**
 * Compliance ellenőrzés eredménye
 */
export interface ComplianceCheck {
  passed: boolean
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'
  riskScore: number
  warnings: Warning[]
  requiredActions: string[]
  customerId: string
  checkedAt: string
}

/**
 * Kockázati tényező
 */
export interface RiskFactor {
  code: string
  description: string
  points: number
}

/**
 * Ügyfél kockázati profil
 */
export interface CustomerRiskProfile {
  customerId: string
  customerName: string
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'
  riskScore: number
  isPep: boolean
  isBlacklisted: boolean
  transactionCount30Days: number
  totalAmountHuf30Days: number
  transactionCount365Days: number
  totalAmountHuf365Days: number
  avgTransactionSize: number
  maxTransactionSize: number
  firstTransactionDate: string | null
  lastTransactionDate: string | null
  frequentCurrencies: string[]
  riskFactors: RiskFactor[]
  generatedAt: string
}

/**
 * AML riasztás
 */
export interface AmlAlert {
  id: number
  alertType: string
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'
  status: 'NEW' | 'UNDER_REVIEW' | 'RESOLVED' | 'ESCALATED'
  customerId: string
  customerName: string
  transactionId: number | null
  receiptNumber: string | null
  amountHuf: number
  description: string
  triggeredRule: string
  createdAt: string
  updatedAt: string
  assignedWorkerName: string | null
  notes: string | null
}

/**
 * Napi compliance összesítés
 */
export interface DailyComplianceSummary {
  date: string
  totalTransactions: number
  largeTransactionCount: number
  uniqueCustomers: number
  totalTurnover: number
  alertCount: number
  generatedAt: string
}
