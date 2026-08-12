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

export interface DailyReportFull {
  reportDate: string
  branchId: string
  branchCode?: string
  branchName?: string
  branchAddress?: string
  taxId?: string
  closingBalanceHuf?: number | string | null
  closingBalanceForeign?: number | string | null
  closingBalanceTotal?: number | string | null
  currencyLines?: Array<Record<string, unknown>>
  hufDenominations?: Array<Record<string, unknown>>
  discountLines?: Array<Record<string, unknown>>
  transactionCount?: number
  buyCount?: number
  sellCount?: number
  reversalCount?: number
  [key: string]: unknown
}

export const reportApi = {
  getDailyClosing: async (date?: string): Promise<DailyClosingReport> => {
    const params = date ? { date } : {}
    const response = await api.get<DailyClosingReport>('/reports/daily-closing', { params })
    return response.data
  },
  getPeriod: async (startDate: string, endDate: string): Promise<PeriodReport> => {
    const response = await api.get<PeriodReport>('/reports/period', {
      params: { startDate, endDate },
    })
    return response.data
  },
  getWorkerPerformance: async (
    workerId: number,
    startDate: string,
    endDate: string,
  ): Promise<WorkerPerformanceReport> => {
    const response = await api.get<WorkerPerformanceReport>(`/reports/worker/${workerId}`, {
      params: { startDate, endDate },
    })
    return response.data
  },
  getCurrencyReport: async (
    currencyId: number,
    startDate: string,
    endDate: string,
  ): Promise<CurrencyReport> => {
    const response = await api.get<CurrencyReport>(`/reports/currency/${currencyId}`, {
      params: { startDate, endDate },
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
  },
  getDailyFullReport: async (branchId: string, date: string): Promise<DailyReportFull> => {
    const response = await api.get<DailyReportFull>(`/reports/daily/${branchId}/${date}/full`)
    return response.data
  },
  exportDailyClosingPdf: async (branchId: string, date: string): Promise<Blob> => {
    const response = await api.get(`/reports/daily/${branchId}/${date}/pdf`, {
      responseType: 'blob',
    })
    return response.data as Blob
  },
  getMonthlyTurnover: async (year: number, month: number): Promise<unknown> => {
    const response = await api.get('/reports/monthly-turnover', {
      params: { year, month },
    })
    return response.data
  },
  getTransferReport: async (startDate: string, endDate: string): Promise<unknown> => {
    const response = await api.get('/reports/transfers', {
      params: { startDate, endDate },
    })
    return response.data
  },
  getHandlingFeeReport: async (startDate: string, endDate: string): Promise<unknown> => {
    const response = await api.get('/reports/handling-fees', {
      params: { startDate, endDate },
    })
    return response.data
  },
  exportMonthlyTurnoverCsv: async (year: number, month: number): Promise<Blob> => {
    const response = await api.get('/reports/monthly-turnover/csv', {
      params: { year, month },
      responseType: 'blob',
    })
    return response.data as Blob
  },
  exportPeriodCsv: async (startDate: string, endDate: string): Promise<Blob> => {
    const response = await api.get('/reports/period/csv', {
      params: { startDate, endDate },
      responseType: 'blob',
    })
    return response.data as Blob
  },
}

// ================== NAV REPORT API ==================

/** NAV-jelenthető tranzakció sor (2M+ Ft). */
export interface NavReportableTransaction {
  transactionId: number
  receiptNumber: string
  transactionType: string
  transactionDate: string
  transactionTime: string
  currencyCode: string
  currencyAmount: number
  exchangeRate: number
  hufAmount: number
  customerId: string | null
  customerName: string | null
  customerAddress: string | null
  customerDocumentNumber: string | null
}

/** Napi NAV adatszolgáltatás riport. */
export interface NavReport {
  date: string
  reportableTransactionCount: number
  totalAmountHuf: number
  transactions: NavReportableTransaction[]
}

export interface NavClosing {
  id: string
  closingDate: string
  branchId?: string | null
  closingType?: string | null
  totalRevenue?: number | string | null
  totalExpense?: number | string | null
  handlingFeeTotal?: number | string | null
  vatAmount?: number | string | null
  status?: string | null
  navReferenceNumber?: string | null
  createdAt?: string | null
}

export interface NavClosingSummary {
  branchId?: string | null
  date?: string | null
  totalRevenue?: number | string | null
  totalExpense?: number | string | null
  handlingFeeTotal?: number | string | null
  vatAmount?: number | string | null
  transactionCount?: number | string | null
}

export interface NavClosingValidationResult {
  branchCode?: string | null
  branchName?: string | null
  closingDate?: string | null
  navAmount?: number | string | null
  systemAmount?: number | string | null
  discrepancy?: number | string | null
  isMatch: boolean
  closingId: string
}

interface PageResponse<T> {
  content?: T[]
}

export const navReportApi = {
  /** Napi NAV riport (összesítő + jelenthető tranzakciók). Backend: GET /api/v1/nav-reports/daily?date */
  getDaily: async (date: string): Promise<NavReport> => {
    const response = await api.get<NavReport>('/nav-reports/daily', { params: { date } })
    return response.data
  },
  /** Jelenthető tranzakciók tételes listája. Backend: GET /api/v1/nav-reports/reportable?date */
  getReportable: async (date: string): Promise<NavReportableTransaction[]> => {
    const response = await api.get<NavReportableTransaction[]>('/nav-reports/reportable', {
      params: { date },
    })
    return response.data
  },
  /** NAV CSV export. Backend: GET /api/v1/nav-reports/csv?date → text/csv. */
  exportCsv: async (date: string): Promise<Blob> => {
    const response = await api.get('/nav-reports/csv', { params: { date }, responseType: 'blob' })
    return response.data as Blob
  },
  /** NAV zárások listája. Backend: GET /api/v1/nav/closings */
  listClosings: async (params?: {
    dateFrom?: string
    dateTo?: string
    page?: number
    size?: number
  }): Promise<NavClosing[]> => {
    const response = await api.get<PageResponse<NavClosing> | NavClosing[]>('/nav/closings', {
      params: {
        page: params?.page ?? 0,
        size: params?.size ?? 20,
        dateFrom: params?.dateFrom,
        dateTo: params?.dateTo,
      },
    })
    const payload = response.data
    return Array.isArray(payload) ? payload : (payload.content ?? [])
  },
  /** NAV zárás napi összesítő. Backend: GET /api/v1/nav/closings/{id}/summary */
  getClosingSummary: async (id: string): Promise<NavClosingSummary> => {
    const response = await api.get<NavClosingSummary>(`/nav/closings/${id}/summary`)
    return response.data
  },
  /** NAV záró összeg validálása. Backend: POST /api/v1/nav/closings/validate-amount */
  validateNavAmount: async (
    branchId: string,
    date: string,
    navAmount: number,
  ): Promise<NavClosingValidationResult> => {
    const response = await api.post<NavClosingValidationResult>(
      '/nav/closings/validate-amount',
      null,
      {
        params: { branchId, date, navAmount },
      },
    )
    return response.data
  },
  /** NAV zárási eltérés jóváhagyása. Backend: POST /api/v1/nav/closings/{id}/approve-discrepancy */
  approveDiscrepancy: async (
    closingId: string,
    navAmount: number,
    justification: string,
  ): Promise<void> => {
    await api.post<void>(`/nav/closings/${closingId}/approve-discrepancy`, null, {
      params: { navAmount, justification },
    })
  },
  /** Havi PTGSZLAH XML export. Backend: GET /api/v1/nav/closings/ptgszlah/monthly */
  exportMonthlyPtgszlah: async (year: number, month: number): Promise<Blob> => {
    const response = await api.get('/nav/closings/ptgszlah/monthly', {
      params: { year, month },
      responseType: 'blob',
    })
    return response.data as Blob
  },
  /** Egyedi időszakos PTGSZLAH XML export. Backend: GET /api/v1/nav/closings/ptgszlah/custom */
  exportCustomPtgszlah: async (from: string, to: string): Promise<Blob> => {
    const response = await api.get('/nav/closings/ptgszlah/custom', {
      params: { from, to },
      responseType: 'blob',
    })
    return response.data as Blob
  },
}

// ================== CENTRAL CONSOLIDATED REPORTS (CSV) API ==================

export const centralReportApi = {
  /** Napi konszolidált riport CSV. Backend: GET /api/v1/central-reports/daily?date=YYYY-MM-DD */
  daily: async (date: string): Promise<Blob> => {
    const response = await api.get('/central-reports/daily', {
      params: { date },
      responseType: 'blob',
    })
    return response.data as Blob
  },
  /** Heti riport CSV. Backend: GET /api/v1/central-reports/weekly?weekStart=YYYY-MM-DD */
  weekly: async (weekStart: string): Promise<Blob> => {
    const response = await api.get('/central-reports/weekly', {
      params: { weekStart },
      responseType: 'blob',
    })
    return response.data as Blob
  },
  /** Havi riport CSV. Backend: GET /api/v1/central-reports/monthly?month=YYYY-MM */
  monthly: async (month: string): Promise<Blob> => {
    const response = await api.get('/central-reports/monthly', {
      params: { month },
      responseType: 'blob',
    })
    return response.data as Blob
  },
}

// ================== DAILY JOURNAL (NAPKÖNYV) PDF API ==================

export const dailyJournalApi = {
  /**
   * Napkönyv PDF letöltés (legacy NAPKONYV parity).
   * Backend: GET /api/v1/reports/daily-journal?branchId&date → application/pdf blob.
   */
  downloadPdf: async (branchId: string, date: string): Promise<Blob> => {
    const response = await api.get('/reports/daily-journal', {
      params: { branchId, date },
      responseType: 'blob',
    })
    return response.data as Blob
  },
}

// ================== AVERAGE RATE REPORT API ==================

/** FK-027 pivot: oszlopcsoport (8 terület + összesítő, vagy 1 fiók). */
export interface AverageRateColumnGroup {
  groupCode: string
  groupName: string
  groupType: 'REGION' | 'TOTAL' | 'BRANCH'
}

/** FK-027 pivot: egy cella-négyes (Vétel/Eladás Árfolyam + Összeg). */
export interface AverageRateColumnValues {
  buyAvgRate: number
  buySumAmount: number
  sellAvgRate: number
  sellSumAmount: number
}

/** FK-027 pivot: egy valuta-sor — oszlopcsoport-kód → cella-négyes. */
export interface AverageRateCurrencyRow {
  currencyCode: string
  values: Record<string, AverageRateColumnValues>
}

/** FK-027 pivot riport válasz. */
export interface AverageRatePivotResponse {
  periodStart: string
  periodEnd: string
  columnGroups: AverageRateColumnGroup[]
  currencyRows: AverageRateCurrencyRow[]
}

export const averageRateApi = {
  /**
   * FK-027 pivot riport: sorok = 22 valuta, oszlopcsoportok = 8 terület + "EXCLUSIVE BEST
   * CHANGE ZRT" összesítő (branchId=null), vagy 1 fiók. Vétel és Eladás párhuzamosan.
   * Backend: GET /api/v1/reports/average-rate/pivot?from&to[&branchId]
   */
  getPivot: async (
    from: string,
    to: string,
    branchId?: string,
  ): Promise<AverageRatePivotResponse> => {
    const params: Record<string, string> = { from, to }
    if (branchId) params.branchId = branchId
    const response = await api.get<AverageRatePivotResponse>('/reports/average-rate/pivot', {
      params,
    })
    return response.data
  },

  /**
   * FK-027 Excel export (legacy Atlagarfolyam.xls). MINDIG a teljes 9-oszlopcsoportos
   * struktúra; csak from/to szűr. Backend: GET /api/v1/reports/average-rate/export
   */
  exportExcel: async (from: string, to: string): Promise<Blob> => {
    const response = await api.get('/reports/average-rate/export', {
      params: { from, to },
      responseType: 'blob',
    })
    return response.data as Blob
  },
}

// ================== DAILY BALANCE GRID (FK-047) API ==================

/** FK-047: Napi ellenőrző lista grid — egy valuta összesített napi mérleg-sora. */
export interface DailyBalanceGridRow {
  currencyCode: string
  openingBalance: number
  purchases: number
  sales: number
  transfersIn: number
  transfersOut: number
  closingBalance: number
  /** Pénztári SZÁMZÁR — null, ha az adott napon nincs rögzítve (a grid „–"-t mutat). */
  actualStock: number | null
  /** Értéktári banki átvétel (BANK+) — null, ha a scope-ban nincs értéktári mérleg-sor (a grid „–"-t mutat). */
  bankPlus: number | null
  /** Értéktári banki átadás (BANK−) — null-szemantika a bankPlus-szal azonos. */
  bankMinus: number | null
  /** TH-tranzakcióból számolt többlet (FR-6, NEM a matematikai difference). */
  surplus: number
  /** TH-tranzakcióból számolt hiány (FR-6). */
  shortage: number
}

export const dailyBalanceGridApi = {
  /**
   * FK-047: valutánkénti összesített napi mérleg a kért scope-ra (teljes cég / terület / pénztár).
   * Backend: GET /api/v1/reports/daily-balance-grid?date[&branchId][&vaultTerritoryId]
   */
  getGrid: async (
    date: string,
    branchId?: string,
    vaultTerritoryId?: number,
  ): Promise<DailyBalanceGridRow[]> => {
    const params: Record<string, string | number> = { date }
    if (branchId) params.branchId = branchId
    if (vaultTerritoryId != null) params.vaultTerritoryId = vaultTerritoryId
    const response = await api.get<DailyBalanceGridRow[]>('/reports/daily-balance-grid', { params })
    return response.data
  },
}

// ================== RECURRING CUSTOMER (AML) REPORT API ==================

/** Visszatérő ügyfél riport sor — Pmt. 16. § fokozott ügyfél-átvilágítás. */
export interface RecurringCustomer {
  customerId: string
  customerName: string
  transactionCount: number
  totalHufAmount: number
  periodStart: string
  periodEnd: string
}

export const recurringCustomerApi = {
  /**
   * Visszatérő ügyfelek (>= minTransactions tranzakció az időszakban).
   * Backend: GET /api/v1/reports/recurring-customers?from&to&minTransactions
   */
  getRecurring: async (
    from: string,
    to: string,
    minTransactions = 3,
  ): Promise<RecurringCustomer[]> => {
    const response = await api.get<RecurringCustomer[]>('/reports/recurring-customers', {
      params: { from, to, minTransactions },
    })
    return response.data
  },
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
  getTransactionList: async (
    branchId: string | undefined,
    startDate: string,
    endDate: string,
  ): Promise<TransactionListReport> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get<TransactionListReport>('/reports-extended/transaction-list', {
      params,
    })
    return response.data
  },
  getReceiptList: async (
    branchId: string | undefined,
    startDate: string,
    endDate: string,
  ): Promise<ReceiptListReport> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get<ReceiptListReport>('/reports-extended/receipt-list', { params })
    return response.data
  },
  getFeeSummary: async (
    branchId: string | undefined,
    startDate: string,
    endDate: string,
  ): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/fee-summary', { params })
    return response.data
  },
  getMonthlyInventory: async (
    branchId: string | undefined,
    year: number,
    month: number,
  ): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/monthly-inventory', { params })
    return response.data
  },
  getMonthlyTurnover: async (
    branchId: string | undefined,
    year: number,
    month: number,
  ): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/monthly-turnover', { params })
    return response.data
  },
  getMonthlyTransfers: async (
    branchId: string | undefined,
    year: number,
    month: number,
  ): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/monthly-transfers', { params })
    return response.data
  },
  getHandlingCost: async (
    branchId: string | undefined,
    startDate: string,
    endDate: string,
  ): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/handling-cost', { params })
    return response.data
  },
  getDailyCashDesk: async (cashDeskId: string, date: string): Promise<unknown> => {
    const response = await api.get('/reports-extended/daily-cash-desk', {
      params: { cashDeskId, date },
    })
    return response.data
  },
  getCurrentCashDeskStatus: async (cashDeskId: string): Promise<unknown> => {
    const response = await api.get('/reports-extended/current-cash-desk-status', {
      params: { cashDeskId },
    })
    return response.data
  },
  getSuspiciousTransactions: async (
    branchId: string | undefined,
    startDate: string,
    endDate: string,
  ): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/suspicious-transactions', { params })
    return response.data
  },
  getCardTransactionFees: async (
    branchId: string | undefined,
    startDate: string,
    endDate: string,
  ): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/reports-extended/card-transaction-fees', { params })
    return response.data
  },
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
  getSystemLogs: async (
    from?: string,
    to?: string,
    page = 0,
    size = 50,
  ): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/system', { params, _preservePaged: true } as Record<
      string,
      unknown
    >)
    return response.data
  },
  getPosLogs: async (
    from?: string,
    to?: string,
    page = 0,
    size = 50,
  ): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/pos', { params, _preservePaged: true } as Record<
      string,
      unknown
    >)
    return response.data
  },
  getNavLogs: async (
    from?: string,
    to?: string,
    page = 0,
    size = 50,
  ): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/nav', { params, _preservePaged: true } as Record<
      string,
      unknown
    >)
    return response.data
  },
  exportToCsv: async (from?: string, to?: string): Promise<Blob> => {
    const params: Record<string, string> = {}
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/logs/export', { params, responseType: 'blob' })
    return response.data
  },
}

// ================== AUDIT LOG API (érzékeny műveletek) ==================

export const auditLogApi = {
  getTrail: async (entityType: string, entityId: string): Promise<AuditLog[]> => {
    const response = await api.get<AuditLog[]>(
      `/audit/trail/${encodeURIComponent(entityType)}/${encodeURIComponent(entityId)}`,
    )
    return response.data
  },
  search: async (
    dateFrom?: string,
    dateTo?: string,
    workerId?: string,
    entityType?: string,
    action?: string,
    keyword?: string,
    page = 0,
    size = 50,
  ): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (dateFrom) params.dateFrom = dateFrom
    if (dateTo) params.dateTo = dateTo
    if (workerId) params.workerId = workerId
    if (entityType) params.entityType = entityType
    if (action) params.action = action
    if (keyword) params.keyword = keyword
    const response = await api.get('/audit/search', { params, _preservePaged: true } as Record<
      string,
      unknown
    >)
    return response.data
  },
  getByBranch: async (
    branchId: string,
    from?: string,
    to?: string,
    page = 0,
    size = 50,
  ): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get(`/audit/branch/${branchId}`, {
      params,
      _preservePaged: true,
    } as Record<string, unknown>)
    return response.data
  },
  exportCsv: async (dateFrom?: string, dateTo?: string): Promise<Blob> => {
    const params: Record<string, string> = {}
    if (dateFrom) params.dateFrom = dateFrom
    if (dateTo) params.dateTo = dateTo
    const response = await api.get('/audit/export', { params, responseType: 'blob' })
    return response.data as Blob
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
      params: { assignedToId },
    })
    return response.data
  },
  resolve: async (id: string, resolution: string): Promise<AnonymousReport> => {
    const response = await api.post<AnonymousReport>(`/anonymous-reports/${id}/resolve`, null, {
      params: { resolution },
    })
    return response.data
  },
}

// ================== DARIUS ===

export interface DariusReportLine {
  id: string
  branchId: string
  branchCode: string
  currencyCode: string
  buyCount: number
  buyCurrencyAmount: number
  buyHufAmount: number
  sellCount: number
  sellCurrencyAmount: number
  sellHufAmount: number
  avgBuyRate: number
  avgSellRate: number
  handlingFeeHuf: number
}
export interface DariusDailyReport {
  id: string
  reportDate: string
  status: string
  companyId: string
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFeeHuf: number
  transactionCount: number
  branchCount: number
  payloadHash?: string
  payloadFormat?: string
  submittedAt?: string
  submittedBy?: string
  ackReference?: string
  ackAt?: string
  errorMessage?: string
  retryCount: number
  maxRetries: number
  nextRetryAt?: string
  approvedBy?: string
  approvedAt?: string
  notes?: string
  lines?: DariusReportLine[]
}
export interface DariusMonthlyDto {
  year: number
  month: number
  totalReports: number
  acknowledgedCount: number
  failedCount: number
  pendingCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFeeHuf: number
  totalTransactionCount: number
  dailyReports: DariusDailyReport[]
}

export type DariusFixingRequestStatus = 'DRAFT' | 'APPROVED' | 'INCLUDED' | 'CANCELLED'

export interface DariusBankBranch {
  id: string
  bankBranchCode: string
  name: string
  active: boolean
}

export interface DariusFixingRequestLine {
  currencyCode: string
  deliveredAmount: number
  collectedAmount: number
}

export interface DariusFixingRequestCreate {
  bankBranchId: string
  requestDate: string
  note: string
  lines: DariusFixingRequestLine[]
}

export interface DariusFixingRequest extends DariusFixingRequestCreate {
  id: string
  bankBranchCode: string
  bankBranchName: string
  status: DariusFixingRequestStatus
  createdBy: string
  createdAt: string
  approvedBy?: string
  approvedAt?: string
  includedAt?: string
}

export const dariusApi = {
  generate: (date: string) => api.post<DariusDailyReport>(`/darius/generate?date=${date}`),
  approve: (id: string) => api.post<DariusDailyReport>(`/darius/${id}/approve`),
  submit: (id: string) => api.post<DariusDailyReport>(`/darius/${id}/submit`),
  acknowledge: (id: string, ref: string) =>
    api.post<DariusDailyReport>(
      `/darius/${id}/acknowledge?ackReference=${encodeURIComponent(ref)}`,
    ),
  retryFailed: () => api.post<DariusDailyReport[]>('/darius/retry-failed'),
  getById: (id: string) => api.get<DariusDailyReport>(`/darius/${id}`),
  getByDate: (date: string) => api.get<DariusDailyReport>(`/darius/by-date?date=${date}`),
  getRange: (from: string, to: string) =>
    api.get<DariusDailyReport[]>(`/darius/range?startDate=${from}&endDate=${to}`),
  getMonthly: (year: number, month: number) =>
    api.get<DariusMonthlyDto>(`/darius/monthly?year=${year}&month=${month}`),
  getMissingDates: (from: string, to: string) =>
    api.get<string[]>(`/darius/missing-dates?startDate=${from}&endDate=${to}`),
  downloadImportFile: (date: string, erteknap = 0) =>
    api.get<Blob>(`/darius/import-file?date=${date}&erteknap=${erteknap}`, {
      responseType: 'blob',
    }),
}

export const dariusFixingApi = {
  bankBranches: (includeInactive = false) =>
    api.get<DariusBankBranch[]>(`/darius/bank-branches?includeInactive=${includeInactive}`),
  createBankBranch: (body: { bankBranchCode: string; name: string }) =>
    api.post<DariusBankBranch>('/darius/bank-branches', body),
  deactivateBankBranch: (id: string) =>
    api.post<DariusBankBranch>(`/darius/bank-branches/${id}/deactivate`),
  list: (date: string) => api.get<DariusFixingRequest[]>(`/darius/fixing-requests?date=${date}`),
  create: (body: DariusFixingRequestCreate) =>
    api.post<DariusFixingRequest>('/darius/fixing-requests', body),
  updateLines: (id: string, body: DariusFixingRequestCreate) =>
    api.put<DariusFixingRequest>(`/darius/fixing-requests/${id}`, body),
  approve: (id: string) => api.post<DariusFixingRequest>(`/darius/fixing-requests/${id}/approve`),
  cancel: (id: string) => api.post<DariusFixingRequest>(`/darius/fixing-requests/${id}/cancel`),
}
