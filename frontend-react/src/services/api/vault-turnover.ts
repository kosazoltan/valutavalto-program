import { api } from './client'

/**
 * FKH-066: a cash desk's ACTUAL daily turnover for the vault arm.
 *
 * Mirrors the `TurnoverReportDto.byCurrency` shape of the existing head-vault endpoints, because
 * the backend reuses the very same aggregation - this view can therefore never drift from the
 * numbers `/turnover/daily` reports for the same branch and day.
 */
export interface VaultTurnoverCurrencyRow {
  currencyCode: string
  buyVolume?: number | null
  sellVolume?: number | null
  /** Customer-facing BUY turnover in HUF (not a bank withdrawal). */
  buyHuf?: number | null
  /** Customer-facing SELL turnover in HUF (not a bank deposit). */
  sellHuf?: number | null
  /** Handling fee collected FROM THE CUSTOMER; not the shipment handling fee. */
  fee?: number | null
  transactionCount?: number | null
}

export interface VaultTurnoverReport {
  period?: string
  totalBuy?: number | null
  totalSell?: number | null
  fees?: number | null
  byCurrency?: VaultTurnoverCurrencyRow[]
}

export const vaultTurnoverApi = {
  /**
   * Territory-scoped: a branch outside the caller's territory answers 404, never another
   * territory's data. Callers treat a rejection as "no turnover data" and keep the view usable.
   */
  daily: async (branchId: string, date: string): Promise<VaultTurnoverReport> => {
    const response = await api.get<VaultTurnoverReport>('/turnover/vault-daily', {
      params: { branchId, date },
    })
    return response.data
  },
}
