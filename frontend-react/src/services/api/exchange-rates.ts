import { api } from './client'

// ================== EXCHANGE RATES API ==================

export interface ExchangeRate {
  id: number
  currencyId: number
  currencyCode: string
  currencyName: string
  validDate: string
  validTime: string
  baseBuyRate: number
  baseSellRate: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  officialRate?: number
  active: boolean
  createdBy?: string
  createdAt: string
}

export interface CreateExchangeRateRequest {
  currencyId: number
  baseBuyRate: number
  baseSellRate: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  officialRate?: number
}

export const exchangeRateApi = {
  list: async (): Promise<ExchangeRate[]> => {
    const response = await api.get<ExchangeRate[]>('/exchange-rates')
    return response.data
  },
  getByCurrencyId: async (currencyId: number): Promise<ExchangeRate> => {
    const response = await api.get<ExchangeRate>(`/exchange-rates/currency/${currencyId}`)
    return response.data
  },
  getByCurrencyCode: async (currencyCode: string): Promise<ExchangeRate> => {
    const response = await api.get<ExchangeRate>(`/exchange-rates/code/${currencyCode}`)
    return response.data
  },
  getBuyRateForAmount: async (currencyId: number, hufAmount: number): Promise<number> => {
    const response = await api.get<number>('/exchange-rates/buy-rate', {
      params: { currencyId, hufAmount }
    })
    return response.data
  },
  getSellRateForAmount: async (currencyId: number, hufAmount: number): Promise<number> => {
    const response = await api.get<number>('/exchange-rates/sell-rate', {
      params: { currencyId, hufAmount }
    })
    return response.data
  },
  create: async (data: CreateExchangeRateRequest): Promise<ExchangeRate> => {
    const response = await api.post<ExchangeRate>('/exchange-rates', data)
    return response.data
  },
  getHistory: async (currencyId: number, startDate: string, endDate: string): Promise<ExchangeRate[]> => {
    const response = await api.get<ExchangeRate[]>('/exchange-rates/history', {
      params: { currencyId, startDate, endDate }
    })
    return response.data
  }
}

// Legacy alias for backward compatibility
export const rateApi = exchangeRateApi

// ================== CURRENCIES API ==================

export interface Currency {
  id: number
  code: string
  name: string
  symbol?: string
  decimals: number
  displayOrder?: number
  active: boolean
}

export const currencyApi = {
  list: async (): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies')
    return response.data
  },
  getAll: async (): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies/all')
    return response.data
  },
  getActive: async (): Promise<Currency[]> => {
    // Same as list - returns only active currencies
    const response = await api.get<Currency[]>('/currencies')
    return response.data
  },
  getByCode: async (code: string): Promise<Currency> => {
    const response = await api.get<Currency>(`/currencies/code/${code}`)
    return response.data
  },
  getById: async (id: number): Promise<Currency> => {
    const response = await api.get<Currency>(`/currencies/${id}`)
    return response.data
  },
  search: async (query: string): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies/search', { params: { q: query } })
    return response.data
  }
}

// ================== RATE CREATION API ==================

export interface BankRateDTO {
  id: string
  bankId: string
  bankCode: string
  bankName: string
  currencyId: string
  currencyCode: string
  currencyName: string
  buyRate: number
  sellRate: number
  middleRate: number
  validFrom: string
  validTo?: string
  isCurrent: boolean
  source?: string
}

export interface CompetitorRateDTO {
  id: string
  competitorId: string
  competitorCode: string
  competitorName: string
  currencyId: string
  currencyCode: string
  currencyName: string
  buyRate: number
  sellRate: number
  middleRate: number
  recordedAt: string
  source?: string
  recordedById?: string
  recordedByName?: string
}

export interface RateCreationDTO {
  currencyId: string
  currencyCode: string
  currencyName: string
  bankRates: BankRateDTO[]
  competitorRates: CompetitorRateDTO[]
  recommendedBuyRate: number
  recommendedSellRate: number
  recommendedMiddleRate: number
  minBuyRate: number
  maxBuyRate: number
  avgBuyRate: number
  minSellRate: number
  maxSellRate: number
  avgSellRate: number
  notes?: string
}

export interface GroupRateDTO {
  id: string
  currencyGroupId: string
  currencyGroupCode: string
  currencyGroupName: string
  currencyId: string
  currencyCode: string
  buyRate: number
  sellRate: number
  buyMargin: number
  sellMargin: number
  validFrom: string
  isCurrent: boolean
}

export interface GroupRateEntryDTO {
  currencyId: number
  buyRate: number
  sellRate: number
  officialRate?: number | null
  limit1Amount?: number | null
  limit1BuyRate?: number | null
  limit1SellRate?: number | null
  limit2Amount?: number | null
  limit2BuyRate?: number | null
  limit2SellRate?: number | null
  limit3Amount?: number | null
  limit3BuyRate?: number | null
  limit3SellRate?: number | null
}

export interface PublishGroupRateRequest {
  groupId: string
  rates: GroupRateEntryDTO[]
}

export interface RateOverviewDTO {
  generatedAt: string
  currencies: RateOverviewItem[]
}

export interface RateOverviewItem {
  currencyId: number
  currencyCode: string
  currencyName: string
  displayOrder: number
  currentBuyRate: number | null
  currentSellRate: number | null
  officialRate: number | null
  limit1Amount: number | null
  limit1BuyRate: number | null
  limit1SellRate: number | null
  limit2Amount: number | null
  limit2BuyRate: number | null
  limit2SellRate: number | null
  limit3Amount: number | null
  limit3BuyRate: number | null
  limit3SellRate: number | null
  buyMarginPercent: number | null
  sellMarginPercent: number | null
  spreadPercent: number | null
  middleRate: number | null
  lastUpdated: string | null
  hasRate: boolean
}

export interface WorkgroupDetailDTO {
  id: string
  code: string
  name: string
  legacyGroupNumber: number | null
  active: boolean
  branches: WorkgroupBranchInfo[]
  limit1Boundary: number
  limit2Boundary: number
  limit3Boundary: number
}

export interface WorkgroupBranchInfo {
  id: string
  code: string
  name: string
}

export interface BranchListItem {
  id: string
  code: string
  name: string
  city: string
  assignedToCurrentWorkgroup: boolean
}

export const rateCreationApi = {
  getOverview: async (): Promise<RateOverviewDTO> => {
    const response = await api.get<RateOverviewDTO>('/rate-creation/overview')
    return response.data
  },
  getWorkgroupDetails: async (): Promise<WorkgroupDetailDTO[]> => {
    const response = await api.get<WorkgroupDetailDTO[]>('/rate-creation/workgroups')
    return response.data
  },
  prepareRateCreation: async (currencyId: string): Promise<RateCreationDTO> => {
    const response = await api.get<RateCreationDTO>(`/rate-creation/prepare/${currencyId}`)
    return response.data
  },
  prepareAllCurrencies: async (): Promise<RateCreationDTO[]> => {
    const response = await api.get<RateCreationDTO[]>('/rate-creation/prepare/all')
    return response.data
  },
  recordCompetitorRate: async (data: {
    competitorId: string
    currencyId: string
    buyRate: number
    sellRate: number
    source?: string
  }): Promise<CompetitorRateDTO> => {
    const response = await api.post<CompetitorRateDTO>('/rate-creation/competitor-rates', data)
    return response.data
  },
  recordBankRate: async (data: {
    bankId: string
    currencyId: string
    buyRate: number
    sellRate: number
    middleRate?: number
    source?: string
  }): Promise<BankRateDTO> => {
    const response = await api.post<BankRateDTO>('/rate-creation/bank-rates', data)
    return response.data
  },
  publishGroupRate: async (data: PublishGroupRateRequest): Promise<void> => {
    await api.post('/rate-creation/publish-group-rate', data)
  },
  getBranches: async (workgroupId: string): Promise<BranchListItem[]> => {
    const response = await api.get<BranchListItem[]>(`/rate-creation/branches?workgroupId=${workgroupId}`)
    return response.data
  },
  updateWorkgroupBranches: async (workgroupId: string, branchIds: string[]): Promise<void> => {
    await api.post(`/rate-creation/workgroups/${workgroupId}/branches`, { branchIds }, { _skipGlobal403Toast: true })
  },
  updateWorkgroupLimits: async (workgroupId: string, limits: { limit1Boundary: number; limit2Boundary: number; limit3Boundary: number }): Promise<void> => {
    await api.put(`/rate-creation/workgroups/${workgroupId}/limits`, limits, { _skipGlobal403Toast: true })
  }
}

// ================== CURRENCY GROUPS API ==================

export interface CurrencyGroupDTO {
  id: string
  code: string
  name: string
  description?: string
  sortOrder?: number
  isActive: boolean
}

export const currencyGroupApi = {
  list: async (): Promise<CurrencyGroupDTO[]> => {
    const response = await api.get<CurrencyGroupDTO[]>('/currency-groups')
    return response.data
  },
  getById: async (id: string): Promise<CurrencyGroupDTO> => {
    const response = await api.get<CurrencyGroupDTO>(`/currency-groups/${id}`)
    return response.data
  }
}

// ================== RATE WORKGROUPS API ==================

export interface RateWorkgroupDTO {
  id: string
  code: string
  name: string
  legacyGroupNumber?: number
  active: boolean
}

export const rateWorkgroupApi = {
  list: async (): Promise<RateWorkgroupDTO[]> => {
    const response = await api.get<RateWorkgroupDTO[]>('/rate-management/workgroups')
    return response.data
  },
  getById: async (id: string): Promise<RateWorkgroupDTO> => {
    const response = await api.get<RateWorkgroupDTO>(`/rate-management/workgroups/${id}`)
    return response.data
  }
}

// ================== COMPETITORS API ==================

export interface CompetitorDTO {
  id: string
  code: string
  name: string
  address?: string
  city?: string
  website?: string
  apiUrl?: string
  notes?: string
  isActive: boolean
  sortOrder?: number
}

export const competitorApi = {
  list: async (): Promise<CompetitorDTO[]> => {
    const response = await api.get<CompetitorDTO[]>('/competitors')
    return response.data
  },
  getById: async (id: string): Promise<CompetitorDTO> => {
    const response = await api.get<CompetitorDTO>(`/competitors/${id}`)
    return response.data
  }
}

// ================== EXCHANGE RATE DISPLAY API ==================

export interface ExchangeRateDisplay {
  id: string
  displayName: string
  currencyIds: string[]
  refreshInterval: number
  isActive: boolean
}

export const exchangeRateDisplayApi = {
  list: async (): Promise<ExchangeRateDisplay[]> => {
    const response = await api.get<ExchangeRateDisplay[]>('/exchange-rate-display')
    return response.data
  },
  getCurrentRates: async (displayId: string): Promise<Record<string, unknown>> => {
    const response = await api.get(`/exchange-rate-display/${displayId}/current-rates`)
    return response.data
  },
  updateDisplay: async (displayId: string, rates: Record<string, unknown>): Promise<void> => {
    await api.post(`/exchange-rate-display/${displayId}/update`, rates)
  }
}
