import { api } from './client'

/**
 * FK-099 — pénzügyi tranzakciós illeték riport + append-only ráta-history
 * kézi interfész (az `averageRateApi` idióma).
 *
 * Backend végpontok (additívak — régi kliens nem törik):
 *   GET  /api/v1/reports/transaction-levy?from&to[&branchId]
 *   GET  /api/v1/transaction-levy-rates
 *   POST /api/v1/transaction-levy-rates
 * A ráta-erőforráson PUT/PATCH/DELETE SZÁNDÉKOSAN nincs (FR-1).
 */

export interface TypeGroup {
  normalBaseLevy: number
  normalSupplementLevy: number
  aboveThresholdCount: number
  aboveThresholdBaseLevy: number
  aboveThresholdSupplementLevy: number
}

export interface TransactionLevyRow {
  date: string | null
  branchId: string | null
  branchCode: string | null
  branchName: string | null
  buy: TypeGroup
  sell: TypeGroup
  conversion: TypeGroup
  largeBaseHuf: number
  levyTotal: number
}

export interface AppliedRate {
  effectiveFrom: string
  baseRatePercent: number
  baseRateCapHuf: number
  supplementRatePercent: number
  supplementRateCapHuf: number
  conversionSingleSideFlag: boolean
  thresholdHuf: number | null
}

export interface MonthlySummary {
  buyCount: number
  sellCount: number
  customerCount: number
  belowThresholdBuyHuf: number
  belowThresholdSellHuf: number
  aboveThresholdBuyHuf: number
  aboveThresholdSellHuf: number
}

export interface TransactionLevyReport {
  from: string
  to: string
  appliedRates: AppliedRate[]
  rows: TransactionLevyRow[]
  totals: TransactionLevyRow
  monthlySummary: MonthlySummary
}

export interface TransactionLevyRate {
  id: string
  effectiveFrom: string
  baseRatePercent: number
  baseRateCapHuf: number
  supplementRatePercent: number
  supplementRateCapHuf: number
  conversionSingleSideFlag: boolean
  createdBy: string | null
  createdAt: string
  thresholdHuf: number | null
}

export interface TransactionLevyRateCreateRequest {
  effectiveFrom: string
  baseRatePercent: number
  baseRateCapHuf: number
  supplementRatePercent: number
  supplementRateCapHuf: number
  conversionSingleSideFlag: boolean
}

export const transactionLevyApi = {
  /** FK-099 riport: pénztár+nap sorok, ÖSSZESEN, havi panel, appliedRates. */
  /**
   * FK-099 riport: pénztár+nap sorok, ÖSSZESEN, havi panel, appliedRates.
   * FK-100 FR-6: opcionális `region` (dictionary REGION kód) — csak truthy
   * érték esetén kerül a query-paraméterekbe, a régi `(from, to)` hívók
   * paraméter-kontraktusa változatlan.
   */
  getReport: async (from: string, to: string, region?: string): Promise<TransactionLevyReport> => {
    const response = await api.get<TransactionLevyReport>('/reports/transaction-levy', {
      params: region ? { from, to, region } : { from, to },
    })
    return response.data
  },

  /** Append-only ráta-history, effectiveFrom DESC, derived küszöbbel. */
  listRates: async (): Promise<TransactionLevyRate[]> => {
    const response = await api.get<TransactionLevyRate[]>('/transaction-levy-rates')
    return response.data
  },

  /** Új ráta-sor (jövőbeli és monoton effective_from; 409 helyett batchelt 400). */
  createRate: async (body: TransactionLevyRateCreateRequest): Promise<TransactionLevyRate> => {
    const response = await api.post<TransactionLevyRate>('/transaction-levy-rates', body)
    return response.data
  },
}
