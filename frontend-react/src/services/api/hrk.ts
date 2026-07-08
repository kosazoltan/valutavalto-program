import { api } from './client'

export interface HrkCurrencySummary {
  currencyCode: string
  handoverCount: number
  handoverAmount: number
  handoverHuf: number
  receiveCount: number
  receiveAmount: number
  receiveHuf: number
  netAmount: number
  netHuf: number
}

export interface HrkMonthlySummary {
  branchId: string
  yearMonth: string
  totalTransactions: number
  totalHandoverHuf: number
  totalReceiveHuf: number
  netHuf: number
  currencyBreakdown: HrkCurrencySummary[]
  breakdownJson?: string
}

export interface HrkTransaction {
  id: string
  branchId: string
  type: string
  currencyCode: string
  amount: number | string
  hufAmount: number | string
  bankAccountNumber?: string | null
  reference?: string | null
  note?: string | null
  status?: string | null
  workerId?: number | string | null
  createdAt?: string | null
  completedAt?: string | null
}

export interface CreateHrkTransactionRequest {
  currencyCode: string
  amount: number
  hufAmount: number
  bankAccountNumber?: string
  note?: string
}

export const hrkMonthlyApi = {
  getSummary: async (yearMonth: string): Promise<HrkMonthlySummary> => {
    const response = await api.get<HrkMonthlySummary>('/hrk/monthly/summary', {
      params: { yearMonth },
    })
    return response.data
  },
  close: async (yearMonth: string): Promise<HrkMonthlySummary> => {
    const response = await api.post<HrkMonthlySummary>('/hrk/monthly/close', undefined, {
      params: { yearMonth },
    })
    return response.data
  },
}

export const hrkDailyApi = {
  handover: async (
    branchId: string,
    data: CreateHrkTransactionRequest,
  ): Promise<HrkTransaction> => {
    const response = await api.post<HrkTransaction>('/hrk/handover', data, {
      headers: { 'X-Branch-Id': branchId },
    })
    return response.data
  },
  receive: async (branchId: string, data: CreateHrkTransactionRequest): Promise<HrkTransaction> => {
    const response = await api.post<HrkTransaction>('/hrk/receive', data, {
      headers: { 'X-Branch-Id': branchId },
    })
    return response.data
  },
  getJournal: async (branchId: string): Promise<HrkTransaction[]> => {
    const response = await api.get<HrkTransaction[]>('/hrk/journal', {
      headers: { 'X-Branch-Id': branchId },
    })
    return response.data
  },
  closeDaily: async (branchId: string, date?: string): Promise<HrkTransaction[]> => {
    const response = await api.post<HrkTransaction[]>('/hrk/close-daily', undefined, {
      headers: { 'X-Branch-Id': branchId },
      params: date ? { date } : undefined,
    })
    return response.data
  },
  cancel: async (id: string): Promise<void> => {
    await api.delete(`/hrk/${id}`)
  },
}
