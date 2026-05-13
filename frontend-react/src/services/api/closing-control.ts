import { api } from './client'

export type ClosingAlertLevel = 'NONE' | 'WARNING' | 'CRITICAL' | string

export interface ClosingControlStatus {
  id?: string | null
  branchId: string
  branchCode?: string
  branchName?: string
  branchCity?: string
  controlDate: string
  dailyClosingDone: boolean
  eveningClosingDone: boolean
  navClosingDone: boolean
  lastTransactionAt?: string | null
  alertLevel: ClosingAlertLevel
  notes?: string | null
  completedCount?: number
  requiredCount?: number
  missingRecord?: boolean
}

export interface ClosingAlertRequest {
  branchId: string
  message: string
}

export const closingControlApi = {
  list: async (date?: string): Promise<ClosingControlStatus[]> => {
    const params = date ? { date } : undefined
    const response = await api.get<ClosingControlStatus[]>('/closing-control/status', { params })
    return response.data
  },

  getBranch: async (branchId: string, date?: string): Promise<ClosingControlStatus> => {
    const params = date ? { date } : undefined
    const response = await api.get<ClosingControlStatus>(`/closing-control/branch/${branchId}`, { params })
    return response.data
  },

  sendAlert: async (request: ClosingAlertRequest): Promise<void> => {
    await api.post('/closing-control/alert', request)
  },
}
