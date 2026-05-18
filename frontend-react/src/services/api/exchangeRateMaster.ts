import { api } from './client'

// Matches backend ExchangeRateMaster.MasterRateStatus enum
export type MasterRateStatus = 'DRAFT' | 'APPROVED' | 'PUBLISHED' | 'REVOKED' | 'ARCHIVED'

export interface ExchangeRateMaster {
  id: string
  companyId: string
  currencyId: number
  currencyCode?: string  // joined from currency table
  baseBuyRate: number
  baseSellRate: number
  officialRate?: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  status: MasterRateStatus
  createdBy?: string
  createdAt: string
  approvedBy?: string
  approvedAt?: string
  publishedAt?: string
  validFrom?: string
  validUntil?: string
  isActive?: boolean
}

export type DistributionStatus = 'PENDING' | 'DISTRIBUTED' | 'ACKNOWLEDGED' | 'FAILED'

export interface ExchangeRateDistribution {
  id: string
  masterRateId: string
  branchId: string
  branchCode?: string
  branchName?: string
  status: DistributionStatus
  distributedAt?: string
  acknowledgedAt?: string
  errorMessage?: string
}

/**
 * DRAFT torzs arfolyam letrehozas payload (egy valuta, A-I oszlopok mapping):
 * - currencyId      = backend currencyId
 * - baseBuyRate     = E oszlop (Gyenge multis vetel)
 * - baseSellRate    = F oszlop (Gyenge multis eladas)
 * - officialRate    = A oszlop (Elszamolo)
 * - limit1Amount + limit1BuyRate + limit1SellRate = 0..50k sav
 * - limit2Amount + limit2BuyRate + limit2SellRate = 50k..300k sav
 * - limit3Amount + limit3BuyRate + limit3SellRate = 300k..1M sav
 */
export interface CreateMasterRateRequest {
  currencyId: number
  baseBuyRate: number
  baseSellRate: number
  officialRate?: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  notes?: string
}

export const exchangeRateMasterApi = {
  /** Osszes torzs arfolyam - opcionalisan status szerint szurve. */
  list: async (status?: MasterRateStatus): Promise<ExchangeRateMaster[]> => {
    const path = status ? `/exchange-rate-master/status/${status}` : '/exchange-rate-master'
    const response = await api.get<ExchangeRateMaster[]>(path)
    return response.data ?? []
  },

  /** Aktiv, publikalt torzs arfolyamok. */
  listActivePublished: async (): Promise<ExchangeRateMaster[]> => {
    const response = await api.get<ExchangeRateMaster[]>('/exchange-rate-master/active')
    return response.data ?? []
  },

  /** Uj torzs arfolyam letrehozas (DRAFT statusban). */
  create: async (payload: CreateMasterRateRequest): Promise<ExchangeRateMaster> => {
    const response = await api.post<ExchangeRateMaster>('/exchange-rate-master', payload)
    return response.data
  },

  /** DRAFT -> APPROVED. */
  approve: async (id: string): Promise<ExchangeRateMaster> => {
    const response = await api.post<ExchangeRateMaster>(`/exchange-rate-master/${id}/approve`)
    return response.data
  },

  /** APPROVED -> PUBLISHED + automata elosztas a penztaraknak. */
  publish: async (id: string, workgroupId?: string): Promise<ExchangeRateMaster> => {
    const params = workgroupId ? { workgroupId } : {}
    const response = await api.post<ExchangeRateMaster>(`/exchange-rate-master/${id}/publish`, null, { params })
    return response.data
  },

  /** Publikalt arfolyam visszavonasa. */
  revoke: async (id: string): Promise<ExchangeRateMaster> => {
    const response = await api.post<ExchangeRateMaster>(`/exchange-rate-master/${id}/revoke`)
    return response.data
  },

  /** Elosztas statusza - melyik penztar kapta meg (PENDING / DISTRIBUTED / ACKNOWLEDGED / FAILED). */
  getDistributionStatus: async (id: string): Promise<ExchangeRateDistribution[]> => {
    const response = await api.get<ExchangeRateDistribution[]>(`/exchange-rate-master/${id}/distribution`)
    return response.data ?? []
  },
}