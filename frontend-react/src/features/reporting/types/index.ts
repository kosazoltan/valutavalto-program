/**
 * Reporting modul típusok
 *
 * @since 2026-01-13
 */

/**
 * Tranzakció összesítés napi riporthoz
 */
export interface TransactionSummary {
  id: number
  receiptNumber: string
  transactionType: string
  status: string
  currencyCode: string
  currencyAmount: number
  exchangeRate: number
  hufAmount: number
  handlingFee: number | null
  customerName: string | null
  workerName: string
  transactionTime: string
}

/**
 * Napi riport DTO
 */
export interface DailyReport {
  reportDate: string
  branchId: string
  branchName: string
  totalTransactionCount: number
  buyCount: number
  sellCount: number
  reversalCount: number
  conversionCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalReversalHuf: number
  netTurnoverHuf: number
  totalHandlingFees: number
  totalDiscounts: number
  transactions: TransactionSummary[]
  generatedAt: string
}

/**
 * Valuta összesítés napi összesítéshez
 */
export interface CurrencySummary {
  currencyId: number
  currencyCode: string
  currencyName: string
  buyCount: number
  sellCount: number
  buyAmount: number
  sellAmount: number
  buyHufTotal: number
  sellHufTotal: number
  avgBuyRate: number
  avgSellRate: number
}

/**
 * Kassza egyenleg összesítés
 */
export interface CashBalanceSummary {
  currencyId: number
  currencyCode: string
  openingBalance: number
  currentBalance: number
  change: number
}

/**
 * Napi összesítés DTO
 */
export interface DailySummary {
  date: string
  branchId: string
  branchName: string
  transactionCount: number
  totalTurnoverHuf: number
  netProfitHuf: number
  currencySummaries: CurrencySummary[]
  cashBalances: CashBalanceSummary[]
  generatedAt: string
}

/**
 * Napi bontás időszaki riporthoz
 */
export interface DailyBreakdown {
  date: string
  transactionCount: number
  buyHuf: number
  sellHuf: number
  netHuf: number
}

/**
 * Időszaki riport DTO
 */
export interface PeriodReport {
  startDate: string
  endDate: string
  branchId: string
  branchName: string
  dayCount: number
  totalTransactionCount: number
  totalBuyCount: number
  totalSellCount: number
  totalReversalCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalReversalHuf: number
  netTurnoverHuf: number
  totalHandlingFees: number
  totalDiscounts: number
  avgDailyTransactions: number
  avgDailyTurnover: number
  dailyBreakdown: DailyBreakdown[]
  generatedAt: string
}

/**
 * Valuta részletezés forgalom riporthoz
 */
export interface CurrencyDetail {
  currencyId: number
  currencyCode: string
  currencyName: string
  buyTransactionCount: number
  buyTotalAmount: number
  buyTotalHuf: number
  buyAvgRate: number
  buyMinRate: number
  buyMaxRate: number
  sellTransactionCount: number
  sellTotalAmount: number
  sellTotalHuf: number
  sellAvgRate: number
  sellMinRate: number
  sellMaxRate: number
  netAmount: number
  netHuf: number
  avgSpread: number
  spreadProfit: number
}

/**
 * Valuta forgalom riport DTO
 */
export interface CurrencyTurnover {
  startDate: string
  endDate: string
  branchId: string
  branchName: string
  currencies: CurrencyDetail[]
  generatedAt: string
}

/**
 * Pénztáros részletezés
 */
export interface WorkerDetail {
  workerId: number
  workerCode: string
  workerName: string
  role: string
  totalTransactions: number
  buyCount: number
  sellCount: number
  reversalCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalTurnoverHuf: number
  totalHandlingFees: number
  totalDiscountsGiven: number
  avgTransactionValue: number
  workingDays: number
  avgTransactionsPerDay: number
}

/**
 * Pénztáros statisztika DTO
 */
export interface WorkerStats {
  startDate: string
  endDate: string
  branchId: string
  branchName: string
  workers: WorkerDetail[]
  generatedAt: string
}
