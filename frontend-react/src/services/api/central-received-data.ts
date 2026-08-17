import { api } from './client'

export type CentralReceivedDataStatus =
  | 'SUBMITTED'
  | 'RECEIVED'
  | 'MISSING'
  | 'WAITING'
  | 'CRITICAL'
  | string

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
  /**
   * A legfrissebb átvett branch-adat ideje. A backend NON_NULL Jackson-inclusion miatt a mező
   * HIÁNYZIK a JSON-ból (undefined), ha még egyik branch sem küldött adatot — ezért opcionális.
   */
  lastSyncedAt?: string | null
  rows: CentralReceivedDataRow[]
}

export const centralReceivedDataApi = {
  status: async (endDate?: string): Promise<CentralReceivedDataOverview> => {
    // FK-088 FR-3: a referencia-dátum az intervallum VÉGE. A backend az additív
    // `endDate` paramétert fogadja (a legacy `date`-et is megtartja).
    const params = endDate ? { endDate } : undefined
    const response = await api.get<CentralReceivedDataOverview>('/central/received-data/status', {
      params,
    })
    return response.data
  },
}
