/**
 * E-B8 Banki rendelés API kliens.
 * Backend: BankOrderController @ /api/v1/bank-orders
 */
import { api } from './client'

export type BankOrderStatus = 'PENDING' | 'APPROVED' | 'EXECUTED' | 'CANCELLED'
export type BankOrderUrgency = 'NORMAL' | 'URGENT' | 'EMERGENCY'

export interface BankOrder {
  id: string
  branchId: string
  branchCode: string
  branchName: string
  currencyId: number
  currencyCode: string
  amount: string
  status: BankOrderStatus
  urgency: BankOrderUrgency
  requestedByWorkerId: number
  requestedByWorkerName?: string
  requestedAt: string
  approvedByWorkerId?: number
  approvedByWorkerName?: string
  approvedAt?: string
  executedByWorkerId?: number
  executedByWorkerName?: string
  executedAt?: string
  cancelledByWorkerId?: number
  cancelledAt?: string
  cancellationReason?: string
  bankReference?: string
  notes?: string
}

export interface BankOrderPage {
  content: BankOrder[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}

export interface CreateBankOrderRequest {
  branchId: string
  currencyId: number
  amount: number | string
  urgency?: BankOrderUrgency
  notes?: string
}

export const bankOrdersApi = {
  list: async (status?: BankOrderStatus, page = 0, size = 50): Promise<BankOrderPage> => {
    // _preservePaged: a backend Page<BankOrderDto>-t ad; e flag nélkül az axios
    // interceptor content-tömbbé bontaná → a BankOrderPage `result.content` undefined,
    // a lista MINDIG üresnek látszana. Lásd client.ts unwrap (Page<T> → T[]).
    const response = await api.get<BankOrderPage>('/bank-orders', {
      params: { status, page, size },
      _preservePaged: true,
    })
    return response.data
  },

  get: async (id: string): Promise<BankOrder> => {
    const response = await api.get<BankOrder>(`/bank-orders/${id}`)
    return response.data
  },

  create: async (req: CreateBankOrderRequest): Promise<BankOrder> => {
    const response = await api.post<BankOrder>('/bank-orders', req)
    return response.data
  },

  approve: async (id: string): Promise<BankOrder> => {
    const response = await api.post<BankOrder>(`/bank-orders/${id}/approve`)
    return response.data
  },

  execute: async (id: string, bankReference?: string): Promise<BankOrder> => {
    const response = await api.post<BankOrder>(`/bank-orders/${id}/execute`, {
      bankReference,
    })
    return response.data
  },

  cancel: async (id: string, reason: string): Promise<BankOrder> => {
    const response = await api.post<BankOrder>(`/bank-orders/${id}/cancel`, { reason })
    return response.data
  },
}
