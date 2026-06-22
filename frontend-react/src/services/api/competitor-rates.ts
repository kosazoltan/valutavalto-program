import { api } from './client'

// FK-041/II — versenytárs-árfolyam BEVITEL az „árfolyam néző" szerepkörnek.

export interface CompetitorOption {
  id: string
  name: string
  branchName?: string | null
}

export interface WatchCurrency {
  id: number
  code: string
  name: string
}

export interface CompetitorWatchBootstrap {
  competitors: CompetitorOption[]
  currencies: WatchCurrency[]
}

export interface CompetitorTodayRate {
  currencyId: number
  currencyCode: string
  buyRate: number | null
  sellRate: number | null
}

export interface CompetitorRateLine {
  currencyId: number
  buyRate: number
  sellRate: number
}

export interface CompetitorRateSubmit {
  competitorId: string
  rates: CompetitorRateLine[]
}

export const competitorRatesApi = {
  bootstrap: async (): Promise<CompetitorWatchBootstrap> => {
    const response = await api.get<CompetitorWatchBootstrap>('/competitor-rates/bootstrap')
    return response.data
  },
  today: async (competitorId: string): Promise<CompetitorTodayRate[]> => {
    const response = await api.get<CompetitorTodayRate[]>('/competitor-rates/today', {
      params: { competitorId },
    })
    return response.data
  },
  submit: async (data: CompetitorRateSubmit): Promise<void> => {
    await api.post('/competitor-rates', data)
  },
}
