import { api } from './client'
import type { BranchMonitoringDashboard } from './monitoring'

export interface TreasuryDashboardSummary {
  currencyTotals?: Record<string, unknown>
  totalBuyHuf?: number | string | null
  totalSellHuf?: number | string | null
  totalFeeHuf?: number | string | null
  totalProfit?: number | string | null
  totalTransactionCount?: number | null
  branchCount?: number | null
}

export interface TreasuryBranchComparison {
  branchId: string
  branchCode?: string | null
  branchName?: string | null
  totalBuyHuf?: number | string | null
  totalSellHuf?: number | string | null
  totalFeeHuf?: number | string | null
  totalProfit?: number | string | null
  transactionCount?: number | null
}

export interface TreasurySubmissionStatus {
  branchId: string
  branchCode?: string | null
  branchName?: string | null
  submitted?: boolean | null
  submittedAt?: string | null
}

export interface TreasuryBankFlow {
  currencyCode?: string | null
  currencyName?: string | null
  totalWithdraw?: number | string | null
  totalDeposit?: number | string | null
  netFlow?: number | string | null
}

export interface TreasuryAggregate {
  id?: string | null
  code?: string | null
  name?: string | null
  totalBuyHuf?: number | string | null
  totalSellHuf?: number | string | null
  totalFeeHuf?: number | string | null
  totalProfit?: number | string | null
  transactionCount?: number | null
  branchCount?: number | null
  lastSyncedAt?: string | null
}

export interface ErtektarConsolidatedBranchReport {
  branchCode?: string | null
  branchName?: string | null
  date?: string | null
  sellCount?: number | null
  buyCount?: number | null
  totalTransactions?: number | null
  sellHufVolume?: number | string | null
  buyHufVolume?: number | string | null
  totalHufTurnover?: number | string | null
  totalFees?: number | string | null
}

export interface ErtektarConsolidatedReport {
  dateFrom?: string | null
  dateTo?: string | null
  branches?: ErtektarConsolidatedBranchReport[] | null
  totals?: {
    totalTransactions?: number | null
    totalSellCount?: number | null
    totalBuyCount?: number | null
    totalHufTurnover?: number | string | null
    totalFees?: number | string | null
  } | null
}

export const treasuryApi = {
  dashboard: async (): Promise<TreasuryDashboardSummary> => {
    const response = await api.get<TreasuryDashboardSummary>('/treasury/dashboard')
    return response.data
  },
  branchComparison: async (): Promise<TreasuryBranchComparison[]> => {
    const response = await api.get<TreasuryBranchComparison[]>('/treasury/branch-comparison')
    return response.data
  },
  submissionStatus: async (): Promise<TreasurySubmissionStatus[]> => {
    const response = await api.get<TreasurySubmissionStatus[]>('/treasury/submission-status')
    return response.data
  },
  bankFlow: async (startDate?: string, endDate?: string): Promise<TreasuryBankFlow[]> => {
    const params = {
      ...(startDate ? { startDate } : {}),
      ...(endDate ? { endDate } : {}),
    }
    const response = await api.get<TreasuryBankFlow[]>('/treasury/bank-flow', {
      params,
    })
    return response.data
  },
  branchGroupSummary: async (date?: string): Promise<TreasuryAggregate[]> => {
    const response = await api.get<TreasuryAggregate[]>('/treasury/branch-group-summary', {
      params: date ? { date } : {},
    })
    return response.data
  },
  companySummary: async (date?: string): Promise<TreasuryAggregate[]> => {
    const response = await api.get<TreasuryAggregate[]>('/treasury/company-summary', {
      params: date ? { date } : {},
    })
    return response.data
  },
  ertektarBranches: async (): Promise<BranchMonitoringDashboard> => {
    const response = await api.get<BranchMonitoringDashboard>('/ertektar/branches')
    return response.data
  },
  ertektarConsolidatedReport: async (from?: string, to?: string): Promise<ErtektarConsolidatedReport> => {
    const response = await api.get<ErtektarConsolidatedReport>('/ertektar/reports/consolidated', {
      params: {
        ...(from ? { from } : {}),
        ...(to ? { to } : {}),
      },
    })
    return response.data
  },
}
