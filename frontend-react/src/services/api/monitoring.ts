import { api } from './client'

export interface BranchStatusResponse {
  id?: string
  branchId: string
  lastHeartbeat?: string | null
  lastSync?: string | null
  isOnline?: boolean | null
  online?: boolean | null
  lastTransactionAt?: string | null
  dailyTransactionCount?: number | null
  dailyVolumeHuf?: number | null
  openAlerts?: number | null
}

export type BranchMonitoringDashboard = Record<string, BranchStatusResponse>

export const branchMonitoringApi = {
  dashboard: async (): Promise<BranchMonitoringDashboard> =>
    (await api.get<BranchMonitoringDashboard>('/monitoring/dashboard')).data,

  online: async (): Promise<BranchStatusResponse[]> =>
    (await api.get<BranchStatusResponse[]>('/monitoring/online')).data,

  offline: async (minutes = 5): Promise<BranchStatusResponse[]> =>
    (await api.get<BranchStatusResponse[]>('/monitoring/offline', { params: { minutes } })).data,
}
