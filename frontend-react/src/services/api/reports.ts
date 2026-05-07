import { api } from './client'
import type { Transaction, Receipt, CashBalance } from './transactions'

// ================== REPORTS API ==================

export interface CurrencyTurnover {
  currencyCode: string
  currencyName: string
  buyCount: number
  buyAmount: number
  buyHuf: number
  sellCount: number
  sellAmount: number
  sellHuf: number
}

export interface DailyClosingReport {
  reportDate: string
  branchId: string
  branchName: string
  sessionStatus: string
  openingBalanceHuf: number
  closingBalanceHuf?: number
  transactionCount: number
  buyCount: number
  sellCount: number
  reversalCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  currencyTurnovers: CurrencyTurnover[]
}

export interface PeriodReport {
  startDate: string
  endDate: string
  branchId: string
  branchName: string
  totalTransactionCount: number
  totalBuyCount: number
  totalSellCount: number
  totalReversalCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  dailyBreakdown: DailyClosingReport[]
}

export interface WorkerPerformanceReport {
  workerId: number
  workerCode?: string
  workerName: string
  startDate: string
  endDate: string
  totalTransactionCount: number
  totalBuyCount: number
  totalSellCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  averageDailyTransactions: number
  totalTransactions?: number
  buyTransactions?: number
  sellTransactions?: number
  reversalCount?: number
  totalTurnoverHuf?: number
  averageTransactionValue?: number
  currencyTurnovers?: CurrencyTurnover[]
}

export interface CurrencyReport {
  currencyId: number
  currencyCode: string
  currencyName: string
  startDate: string
  endDate: string
  totalBuyCount: number
  totalSellCount: number
  totalBuyAmount: number
  totalSellAmount: number
  totalBuyHuf: number
  totalSellHuf: number
  averageBuyRate: number
  averageSellRate: number
}

export interface CashStatusReport {
  branchId: string
  branchName: string
  reportTime: string
  balances: CashBalance[]
  totalHufEquivalent: number
  lowBalanceAlerts: string[]
  highBalanceAlerts: string[]
}

export const reportApi = {
  getDailyClosing: async (date?: string): Promise<DailyClosingReport> => {
    const params = date ? { date } : {}
    const response = await api.get<DailyClosingReport>('/reports/daily-closing', { params })
    return response.data
  },
  getPeriod: async (startDate: string, endDate: string): Promise<PeriodReport> => {
    const response = await api.get<PeriodReport>('/reports/period', {
      params: { startDate, endDate }
    })
    return response.data
  },
  getWorkerPerformance: async (workerId: number, startDate: string, endDate: string): Promise<WorkerPerformanceReport> => {
    const response = await api.get<WorkerPerformanceReport>(`/reports/worker/${workerId}`, {
      params: { startDate, endDate }
    })
    return response.data
  },
  getCurrencyReport: async (currencyId: number, startDate: string, endDate: string): Promise<CurrencyReport> => {
    const response = await api.get<CurrencyReport>(`/reports/currency/${currencyId}`, {
      params: { startDate, endDate }
    })
    return response.data
  },
  getCashStatus: async (): Promise<CashStatusReport> => {
    const response = await api.get<CashStatusReport>('/reports/cash-status')
    return response.data
  },
  getTodaySummary: async (): Promise<DailyClosingReport> => {
    const response = await api.get<DailyClosingReport>('/reports/today-summary')
    return response.data
  }
}

// ================== REPORT EXTENDED API ==================

export interface ReportSummary {
  totalCount: number
  totalAmount?: number
  totalProfit?: number
  [key: string]: string | number | undefined
}

export interface TransactionListReport {
  transactions: Transaction[]
  summary: ReportSummary
}

export interface ReceiptListReport {
  receipts: Receipt[]
  summary: ReportSummary
}

export const reportExtendedApi = {
  getTransactionList: async (branchId: string | undefined, startDate: string, endDate: string): Promise<TransactionListReport> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get<TransactionListReport>('/reports-extended/transaction-list', { params })
    return response.data
  },
  getReceiptList: async (branchId: string | undefined, startDate: string, endDate: string): Promise<ReceiptListReport> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get<ReceiptListReport>('/reports-extended/receipt-list', { params })
    return response.data
  },
  getFeeSummary: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/fee-summary', { params })
    return response.data
  },
  getMonthlyInventory: async (branchId: string | undefined, year: number, month: number): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/monthly-inventory', { params })
    return response.data
  },
  getMonthlyTurnover: async (branchId: string | undefined, year: number, month: number): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/monthly-turnover', { params })
    return response.data
  },
  getMonthlyTransfers: async (branchId: string | undefined, year: number, month: number): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/monthly-transfers', { params })
    return response.data
  },
  getHandlingCost: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/handling-cost', { params })
    return response.data
  },
  getDailyCashDesk: async (cashDeskId: string, date: string): Promise<unknown> => {
    const response = await api.get('/reports-extended/daily-cash-desk', {
      params: { cashDeskId, date }
    })
    return response.data
  },
  getCurrentCashDeskStatus: async (cashDeskId: string): Promise<unknown> => {
    const response = await api.get('/reports-extended/current-cash-desk-status', {
      params: { cashDeskId }
    })
    return response.data
  },
  getSuspiciousTransactions: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/suspicious-transactions', { params })
    return response.data
  },
  getCardTransactionFees: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/card-transaction-fees', { params })
    return response.data
  }
}

// ================== LOGGING API ==================

export interface AuditLog {
  id: string
  action: string
  entityType: string
  entityId: string
  userId?: string
  userName?: string
  branchId?: string
  branchName?: string
  changes?: string
  ipAddress?: string
  userAgent?: string
  oldValue?: string
  newValue?: string
  reason?: string
  createdAt: string
}

export const loggingApi = {
  getSystemLogs: async (from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/system', { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  getPosLogs: async (from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/pos', { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  getNavLogs: async (from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/nav', { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  exportToCsv: async (from?: string, to?: string): Promise<Blob> => {
    const params: Record<string, string> = {}
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/export', { params, responseType: 'blob' })
    return response.data
  }
}

// ================== AUDIT LOG API (érzékeny műveletek) ==================

export const auditLogApi = {
  getByEntity: async (entityId: string): Promise<AuditLog[]> => {
    const response = await api.get<AuditLog[]>('/audit', { params: { entityId } })
    return response.data
  },
  getByWorker: async (workerId: string, from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get(`/audit/worker/${workerId}`, { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  getByBranch: async (branchId: string, from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get(`/audit/branch/${branchId}`, { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  getByAction: async (action: string, from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get(`/audit/action/${action}`, { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  getAll: async (from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/system', { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
}

// ================== ANONYMOUS REPORT API ==================

export interface AnonymousReport {
  id: string
  reportType: string
  subject?: string
  description: string
  reportedAt: string
  status: string
  assignedToId?: string
  assignedToName?: string
  resolution?: string
}

export const anonymousReportApi = {
  list: async (): Promise<AnonymousReport[]> => {
    const response = await api.get<AnonymousReport[]>('/anonymous-reports')
    return response.data
  },
  getById: async (id: string): Promise<AnonymousReport> => {
    const response = await api.get<AnonymousReport>(`/anonymous-reports/${id}`)
    return response.data
  },
  create: async (data: Partial<AnonymousReport>): Promise<AnonymousReport> => {
    const response = await api.post<AnonymousReport>('/anonymous-reports', data)
    return response.data
  },
  assign: async (id: string, assignedToId: string): Promise<AnonymousReport> => {
    const response = await api.post<AnonymousReport>(`/anonymous-reports/${id}/assign`, null, {
      params: { assignedToId }
    })
    return response.data
  },
  resolve: async (id: string, resolution: string): Promise<AnonymousReport> => {
    const response = await api.post<AnonymousReport>(`/anonymous-reports/${id}/resolve`, null, {
      params: { resolution }
    })
    return response.data
  }
}

// ================== DARIUS ===

export interface DariusReportLine {
  id: string; branchId: string; branchCode: string; currencyCode: string
  buyCount: number; buyCurrencyAmount: number; buyHufAmount: number
  sellCount: number; sellCurrencyAmount: number; sellHufAmount: number
  avgBuyRate: number; avgSellRate: number; handlingFeeHuf: number
}
export interface DariusDailyReport {
  id: string; reportDate: string; status: string; companyId: string
  totalBuyHuf: number; totalSellHuf: number; totalHandlingFeeHuf: number
  transactionCount: number; branchCount: number
  payloadHash?: string; payloadFormat?: string
  submittedAt?: string; submittedBy?: string; ackReference?: string; ackAt?: string
  errorMessage?: string; retryCount: number; maxRetries: number; nextRetryAt?: string
  approvedBy?: string; approvedAt?: string; notes?: string
  lines?: DariusReportLine[]
}
export interface DariusMonthlyDto {
  year: number; month: number; totalReports: number
  acknowledgedCount: number; failedCount: number; pendingCount: number
  totalBuyHuf: number; totalSellHuf: number; totalHandlingFeeHuf: number
  totalTransactionCount: number; dailyReports: DariusDailyReport[]
}
export const dariusApi = {
  generate: (date: string) => api.post<DariusDailyReport>(`/darius/generate?date=${date}`),
  approve: (id: string) => api.post<DariusDailyReport>(`/darius/${id}/approve`),
  submit: (id: string) => api.post<DariusDailyReport>(`/darius/${id}/submit`),
  acknowledge: (id: string, ref: string) => api.post<DariusDailyReport>(`/darius/${id}/acknowledge?ackReference=${encodeURIComponent(ref)}`),
  retryFailed: () => api.post<DariusDailyReport[]>('/darius/retry-failed'),
  getByDate: (date: string) => api.get<DariusDailyReport>(`/darius/by-date?date=${date}`),
  getRange: (from: string, to: string) => api.get<DariusDailyReport[]>(`/darius/range?startDate=${from}&endDate=${to}`),
  getMonthly: (year: number, month: number) => api.get<DariusMonthlyDto>(`/darius/monthly?year=${year}&month=${month}`),
  getMissingDates: (from: string, to: string) => api.get<string[]>(`/darius/missing-dates?startDate=${from}&endDate=${to}`),
}
