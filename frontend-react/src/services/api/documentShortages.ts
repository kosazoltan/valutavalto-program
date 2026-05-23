import { api } from './index'

/** Okmányhiány-regiszter tétel (legacy OKMANYHIANY / OKMCTRL). */
export interface DocumentShortage {
  id: string
  branchCode?: string
  customerName?: string
  customerId?: string
  receiptNumber?: string
  missingDocument: string
  note?: string
  recordedAt?: string
  resolvedAt?: string
}

export interface DocumentShortageCreate {
  missingDocument: string
  customerName?: string
  customerId?: string
  branchCode?: string
  receiptNumber?: string
  note?: string
}

export const documentShortageApi = {
  list: async (openOnly = true): Promise<DocumentShortage[]> => {
    const res = await api.get<DocumentShortage[]>('/document-shortages', { params: { openOnly } })
    return res.data
  },
  create: async (data: DocumentShortageCreate): Promise<DocumentShortage> => {
    const res = await api.post<DocumentShortage>('/document-shortages', data)
    return res.data
  },
  resolve: async (id: string): Promise<DocumentShortage> => {
    const res = await api.post<DocumentShortage>(`/document-shortages/${id}/resolve`)
    return res.data
  },
}
