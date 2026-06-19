import { api, type PagedResponse } from './client'

export type TradeStatus = 'PROPOSED' | 'ACCEPTED' | 'REJECTED' | 'COMPLETED' | 'CANCELLED' | string

export interface TradeDto {
  id: string
  fromBranchId: string
  fromBranchName: string
  toBranchId: string
  toBranchName: string
  currencyCode: string
  amount: number
  rate: number
  status: TradeStatus
  proposedBy: number
  acceptedBy?: number
  proposedAt: string
  acceptedAt?: string
  completedAt?: string
  notes?: string
}

export interface ProposeTradeRequest {
  fromBranchId: string
  toBranchId: string
  currencyCode: string
  amount: number
  rate: number
  notes?: string
}

export interface TradeHistoryParams {
  branchId?: string
  from: string
  to: string
  page?: number
  size?: number
}

export const tradeApi = {
  propose: async (request: ProposeTradeRequest): Promise<TradeDto> =>
    (await api.post<TradeDto>('/trades/propose', request)).data,

  accept: async (id: string): Promise<TradeDto> =>
    (await api.post<TradeDto>(`/trades/${id}/accept`)).data,

  reject: async (id: string, reason?: string): Promise<TradeDto> =>
    (await api.post<TradeDto>(`/trades/${id}/reject`, reason?.trim() ? { reason: reason.trim() } : undefined)).data,

  complete: async (id: string): Promise<TradeDto> =>
    (await api.post<TradeDto>(`/trades/${id}/complete`)).data,

  cancel: async (id: string): Promise<TradeDto> =>
    (await api.delete<TradeDto>(`/trades/${id}`)).data,

  pending: async (branchId?: string): Promise<TradeDto[]> =>
    (await api.get<TradeDto[]>('/trades/pending', { params: branchId ? { branchId } : undefined })).data,

  history: async ({ branchId, from, to, page = 0, size = 20 }: TradeHistoryParams): Promise<PagedResponse<TradeDto>> =>
    (await api.get<PagedResponse<TradeDto>>('/trades/history', {
      params: { branchId, from, to, page, size },
      _preservePaged: true,
    })).data,
}
