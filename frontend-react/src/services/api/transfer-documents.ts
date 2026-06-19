import { api } from './client'

export type TransferDocumentStatus = 'PENDING' | 'PICKED_UP' | 'DELIVERED' | 'CONFIRMED' | string

export interface TransferDocument {
  id: string | number
  documentNumber?: string
  sourceType?: string
  sourceId?: string
  destinationType?: string
  destinationId?: string
  currencyCode?: string
  quantity?: number | string
  status?: TransferDocumentStatus
  createdAt?: string
  pickedUpAt?: string
  deliveredAt?: string
  confirmedAt?: string
  notes?: string | null
}

export interface TransferDocumentCreateRequest {
  senderId: number
  currencyCode: string
  quantity: number
  sourceType: string
  sourceId: string
  destinationType: string
  destinationId: string
  courierPin?: string
  notes?: string
}

export const transferDocumentApi = {
  list: async (params: { status?: string; courierId?: number } = {}): Promise<TransferDocument[]> => {
    const response = await api.get<TransferDocument[]>('/transfer-documents', { params })
    return response.data
  },
  get: async (id: string | number): Promise<TransferDocument> => {
    const response = await api.get<TransferDocument>(`/transfer-documents/${id}`)
    return response.data
  },
  create: async (request: TransferDocumentCreateRequest): Promise<TransferDocument> => {
    const response = await api.post<TransferDocument>('/transfer-documents', {
      ...request,
      courierPin: request.courierPin?.trim() || undefined,
      notes: request.notes?.trim() || undefined,
    })
    return response.data
  },
  pickup: async (id: string | number, courierId: number, courierPin?: string): Promise<TransferDocument> => {
    const response = await api.put<TransferDocument>(`/transfer-documents/${id}/pickup`, {
      courierId,
      courierPin: courierPin?.trim() || undefined,
    })
    return response.data
  },
  deliver: async (id: string | number): Promise<TransferDocument> => {
    const response = await api.put<TransferDocument>(`/transfer-documents/${id}/deliver`)
    return response.data
  },
  confirm: async (id: string | number, receiverId: number): Promise<TransferDocument> => {
    const response = await api.put<TransferDocument>(`/transfer-documents/${id}/confirm`, { receiverId })
    return response.data
  },
}
