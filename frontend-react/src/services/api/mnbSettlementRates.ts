import { api } from './client'

export interface MnbSettlementRateRow {
  currencyCode: string
  currencyName: string
  officialRate: number
  availableToOfficesAt: string | null
}

export interface MnbQueryRate {
  currencyCode: string
  officialRate: number
}

export interface MnbSettlementRateUpdateItem {
  currencyCode: string
  officialRate: number
}

export const mnbSettlementRateApi = {
  /** GET /api/v1/mnb-settlement-rates */
  list: async (): Promise<MnbSettlementRateRow[]> => {
    const r = await api.get<MnbSettlementRateRow[]>('/mnb-settlement-rates')
    return r.data
  },

  /** GET /api/v1/mnb-settlement-rates/mnb-query — csak olvasó preview (FR-4/FR-5) */
  mnbQuery: async (): Promise<MnbQueryRate[]> => {
    const r = await api.get<MnbQueryRate[]>('/mnb-settlement-rates/mnb-query')
    return r.data
  },

  /** PUT /api/v1/mnb-settlement-rates — "Rögzítés" (FR-9) */
  update: async (items: MnbSettlementRateUpdateItem[]): Promise<MnbSettlementRateRow[]> => {
    const r = await api.put<MnbSettlementRateRow[]>('/mnb-settlement-rates', { items })
    return r.data
  },

  /** PUT /api/v1/mnb-settlement-rates/publish — "Rögzítés + Küldés irodáknak" (FR-10) */
  publish: async (items: MnbSettlementRateUpdateItem[]): Promise<MnbSettlementRateRow[]> => {
    const r = await api.put<MnbSettlementRateRow[]>('/mnb-settlement-rates/publish', { items })
    return r.data
  },
}
