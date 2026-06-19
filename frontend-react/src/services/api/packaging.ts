import { api } from './client'

export interface PackagingRecord {
  id: string
  branchId: string
  currencyCode: string
  packagingDate: string
  bundleCount: number
  denomination: number
  bundleSize?: number
  notes?: string | null
  createdAt?: string
}

export interface CreatePackagingRecordRequest {
  branchId: string
  currencyCode: string
  packagingDate: string
  bundleCount: number
  denomination: number
  bundleSize?: number
  notes?: string
}

export const packagingApi = {
  list: async (branchId: string, from?: string, to?: string): Promise<PackagingRecord[]> => {
    const response = await api.get<PackagingRecord[]>('/packaging', {
      params: { branchId, from: from || undefined, to: to || undefined },
    })
    return response.data
  },
  create: async (request: CreatePackagingRecordRequest): Promise<PackagingRecord> => {
    const response = await api.post<PackagingRecord>('/packaging', {
      ...request,
      notes: request.notes?.trim() || undefined,
      bundleSize: request.bundleSize || undefined,
    })
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/packaging/${id}`)
  },
}
