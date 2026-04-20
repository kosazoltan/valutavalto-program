import { api } from "./client"

export interface TransitItem {
  type: "DISTRIBUTION" | "COLLECTION"
  id: number
  distributionId?: number
  documentNumber: string
  fromBranchCode?: string
  fromBranchName?: string
  toBranchCode?: string
  toBranchName?: string
  currencyCode: string
  amount: number
  status: string
  createdAt: string
  completedAt?: string
  note?: string
}

export const transitApi = {
  getIncoming: async (branchCode?: string): Promise<TransitItem[]> => {
    const r = await api.get<TransitItem[]>("/transit/incoming", {
      params: branchCode ? { branchCode } : undefined,
    })
    return r.data ?? []
  },
  getOutgoing: async (branchCode?: string): Promise<TransitItem[]> => {
    const r = await api.get<TransitItem[]>("/transit/outgoing", {
      params: branchCode ? { branchCode } : undefined,
    })
    return r.data ?? []
  },
  acknowledgeDistribution: async (id: number): Promise<TransitItem> => {
    const r = await api.post<TransitItem>(`/transit/distribution/${id}/acknowledge`)
    return r.data
  },
  acknowledgeCollection: async (id: number): Promise<TransitItem> => {
    const r = await api.post<TransitItem>(`/transit/collection/${id}/acknowledge`)
    return r.data
  },
}
