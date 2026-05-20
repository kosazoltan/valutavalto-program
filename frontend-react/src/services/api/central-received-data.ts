import { api } from './client'

export type CentralReceivedDataStatus = 'SUBMITTED' | 'RECEIVED' | 'MISSING' | 'WAITING' | 'CRITICAL' | string

export interface CentralReceivedDataRow {
  branchId: string
  branchCode?: string
  branchName?: string
  branchCity?: string
  reportDate: string
  dataStatus: CentralReceivedDataStatus
  dailyReportId?: number | null
  reportReceived: boolean
  reportSubmitted: boolean
  reportCreatedAt?: string | null
  submittedAt?: string | null
  submittedByName?: string | null
  transactionCount?: number
  totalBuyHuf?: number
  totalSellHuf?: number
  totalFeeHuf?: number
  totalProfit?: number
  dailyClosingDone: boolean
  eveningClosingDone: boolean
  navClosingDone: boolean
  closingAlertLevel: string
  closingControlMissing: boolean
  notes?: string | null
}

export interface CentralReceivedDataOverview {
  reportDate: string
  totalBranches: number
  receivedReports: number
  submittedReports: number
  missingReports: number
  warningClosings: number
  criticalClosings: number
  totalTransactions: number
  totalBuyHuf: number
  totalSellHuf: number
  totalFeeHuf: number
  totalProfit: number
  generatedAt: string
  /** A legfrissebb átvett branch-adat ideje (null, ha még egyik branch sem küldött adatot). */
  lastSyncedAt: string | null
  rows: CentralReceivedDataRow[]
}

export const centralReceivedDataApi = {
  status: async (date?: string): Promise<CentralReceivedDataOverview> => {
    const params = date ? { date } : undefined
    const response = await api.get<CentralReceivedDataOverview>('/central/received-data/status', { params })
    return response.data
  },
}
