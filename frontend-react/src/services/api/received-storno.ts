import { api } from './client'

export interface ReceivedStornoLine {
  currencyCode: string
  amount: number | string | null
  hufValue: number | string | null
  rateMissing?: boolean
}

export interface ReceivedStornoRow {
  type: 'SALE_PURCHASE' | 'TRANSFER' | string
  officeCode?: string | null
  officeName?: string | null
  date: string
  time?: string | null
  originalDocumentNumber?: string | null
  stornoDocumentNumber?: string | null
  workerName?: string | null
  reason?: string | null
  lines: ReceivedStornoLine[]
}

export interface ReceivedStorno {
  fromDate: string
  toDate: string
  branchId?: string | null
  vaultTerritoryId?: number | null
  branches: Array<{
    id: string
    code?: string | null
    name?: string | null
    isVault?: boolean | null
    vaultTerritoryId?: number | null
    region?: string | null
  }>
  territories: Array<{ id: number; name: string }>
  rows: ReceivedStornoRow[]
}

export type StornoScope = {
  branchId?: string | null
  vaultTerritoryId?: number | null
}

/** FK-115: manually triggered — never called on page load. Not re-exported from the API barrel. */
export const receivedStornoApi = {
  load: async (
    fromDate: string,
    toDate: string,
    scope: StornoScope = {},
  ): Promise<ReceivedStorno> => {
    const params: Record<string, string | number> = { fromDate, toDate }
    if (scope.branchId) params.branchId = scope.branchId
    if (scope.vaultTerritoryId != null) params.vaultTerritoryId = scope.vaultTerritoryId
    const response = await api.get<ReceivedStorno>('/central/received-data/storno', { params })
    return response.data
  },
}
