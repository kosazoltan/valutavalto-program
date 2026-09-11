import { api } from './client'

/** FK-111: cell-level data quality flags produced by ReceivedDenominationsService. */
export type DenominationDataQualityFlag =
  | 'OK'
  | 'FRACTIONAL_FACE_VALUE'
  | 'NON_POSITIVE_FACE_VALUE'
  | 'VALUE_MISMATCH'

export interface ReceivedDenominationBranchOption {
  id: string
  code?: string | null
  name?: string | null
}

export interface ReceivedDenominationCell {
  faceValue: number
  denominationType: string
  quantity: number
  totalValue: number
  dataQualityFlag: DenominationDataQualityFlag | string
}

export interface ReceivedDenominationCurrencyRow {
  currencyCode: string
  totalValue: number
  totalQuantity: number
  cells: ReceivedDenominationCell[]
  hasDataQualityIssue: boolean
}

export interface ReceivedDenominations {
  date: string
  branchId?: string | null
  branches: ReceivedDenominationBranchOption[]
  rows: ReceivedDenominationCurrencyRow[]
  /** Own total of the HUF row; foreign currencies are NOT converted to HUF. */
  hufTotalValue: number
  currencyCount: number
  totalQuantity: number
  dataQualityIssueCount: number
}

export const receivedDenominationsApi = {
  /** FK-111: manually triggered — never called on page load. */
  load: async (date: string, branchId?: string | null): Promise<ReceivedDenominations> => {
    const response = await api.get<ReceivedDenominations>('/central/received-data/denominations', {
      params: branchId ? { date, branchId } : { date },
    })
    return response.data
  },
}
