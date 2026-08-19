import { api } from './client'

export type ReconciliationStatus = 'EGYEZIK' | 'ELTERES' | 'FOLYAMATBAN'

export interface TransferReconciliationRow {
  transferId: number
  transferNumber: string
  date: string
  fromBranchCode?: string | null
  fromBranchName?: string | null
  toBranchCode?: string | null
  toBranchName?: string | null
  currencyCode: string
  sentAmount?: number | null
  receivedAmount?: number | null
  status: ReconciliationStatus | string
  discrepancyNote?: string | null
}

export interface TransferReconciliationResult {
  startDate: string
  endDate: string
  totalRows: number
  matchedRows: number
  discrepancyRows: number
  notifiedBranches: number
  generatedAt: string
  rows: TransferReconciliationRow[]
}

export const transferReconciliationApi = {
  /** FK-003: manuálisan indított egyeztetés egy -tól/-ig intervallumra. */
  run: async (startDate: string, endDate: string): Promise<TransferReconciliationResult> => {
    const response = await api.post<TransferReconciliationResult>(
      '/central/transfer-reconciliation/run',
      null,
      { params: { startDate, endDate } },
    )
    return response.data
  },
}
