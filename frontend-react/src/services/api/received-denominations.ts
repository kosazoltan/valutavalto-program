import { api } from './client'

/** FK-111: cell-level data quality flags produced by ReceivedDenominationsService. */
export type DenominationDataQualityFlag =
  | 'OK'
  | 'FRACTIONAL_FACE_VALUE'
  | 'NON_POSITIVE_FACE_VALUE'
  | 'VALUE_MISMATCH'

export type DenominationRateSource = 'MNB' | 'MANUAL_SETTLEMENT' | string

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

export interface ReceivedDenominationFixedColumn {
  faceValue: number
  /** Null means the catalog has no such face value and there is no snapshot stock ("–"). */
  quantity: number | null
  inCatalog: boolean
  dataQualityFlag?: DenominationDataQualityFlag | string | null
}

export interface ReceivedDenominationCurrencyRow {
  currencyCode: string
  totalValue: number
  totalQuantity: number
  cells: ReceivedDenominationCell[]
  fixedColumns?: ReceivedDenominationFixedColumn[]
  otherCells?: ReceivedDenominationCell[]
  allowedFaceValues?: number[]
  hasDataQualityIssue: boolean
  rate?: number | null
  rateDate?: string | null
  rateSource?: DenominationRateSource | null
  hufEquivalent?: number | null
  rateMissing?: boolean
}

export interface ReceivedDenominations {
  date: string
  branchId?: string | null
  branches: ReceivedDenominationBranchOption[]
  rows: ReceivedDenominationCurrencyRow[]
  hufTotalValue: number
  /** FK-112: HUF equivalent of foreign rows that had a resolvable rate. */
  currencyValueHuf?: number | null
  grandTotalHuf?: number | null
  fixedFaceValues?: number[]
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
