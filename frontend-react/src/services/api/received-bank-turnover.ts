import { api } from './client'

export interface ReceivedBankTurnoverBranchOption {
  id: string
  code?: string | null
  name?: string | null
  isVault?: boolean | null
  vaultTerritoryId?: number | null
  region?: string | null
}

export interface ReceivedBankTurnoverTerritoryOption {
  id: number
  name: string
}

export interface ReceivedBankTurnoverRow {
  currencyCode: string
  bankIn: number | string
  bankOut: number | string
}

export interface ReceivedBankTurnoverMissingDay {
  branchId: string
  branchCode?: string | null
  branchName?: string | null
  date: string
}

export interface ReceivedBankTurnover {
  fromDate: string
  toDate: string
  branchId?: string | null
  vaultTerritoryId?: number | null
  branches: ReceivedBankTurnoverBranchOption[]
  territories: ReceivedBankTurnoverTerritoryOption[]
  rows: ReceivedBankTurnoverRow[]
  missingClosingDays: ReceivedBankTurnoverMissingDay[]
}

export type BankTurnoverScope = {
  branchId?: string | null
  vaultTerritoryId?: number | null
}

/** FK-114: manually triggered — never called on page load. Not re-exported from the API barrel. */
export const receivedBankTurnoverApi = {
  load: async (
    fromDate: string,
    toDate: string,
    scope: BankTurnoverScope = {},
  ): Promise<ReceivedBankTurnover> => {
    const params: Record<string, string | number> = { fromDate, toDate }
    if (scope.branchId) params.branchId = scope.branchId
    if (scope.vaultTerritoryId != null) params.vaultTerritoryId = scope.vaultTerritoryId
    const response = await api.get<ReceivedBankTurnover>('/central/received-data/bank-turnover', {
      params,
    })
    return response.data
  },
}
