import { api } from './index'

export interface VaultTerritory {
  id: number
  companyId?: string | null
  name: string
  baseCapital: number | string
  baseCapitalApprovedAt?: string | null
  active?: boolean
}

export interface VaultTerritoryRequest {
  name: string
  baseCapital: number | string
  baseCapitalApprovedAt?: string | null
}

export interface TerritoryProfitSummary {
  totalProfit: number | string
  transactionCount: number
  sellCount: number
  buyCount: number
  profitByCurrency: Record<string, number | string>
}

export interface CashierLine {
  branchId: string
  branchCode: string
  branchName: string
  realizedMargin: number
  allocatedRevaluation: number
  totalProfit: number
}

export interface CurrencyReval {
  currencyCode: string
  vaultHeldQty: number
  weightedAvgCost: number
  mnbRate: number
  revaluation: number
}

export interface TerritoryReconciliation {
  territoryId: number
  fromDate: string
  toDate: string
  cashiers: CashierLine[]
  currencyRevaluations: CurrencyReval[]
  territoryRealizedMargin: number
  territoryRevaluation: number
  territoryTotalProfit: number
  reconciliationOk: boolean
}

export const territoryReconciliationApi = {
  listTerritories: async (): Promise<VaultTerritory[]> => {
    const res = await api.get<VaultTerritory[]>('/territories')
    return res.data
  },
  getTerritory: async (id: number): Promise<VaultTerritory> => {
    const res = await api.get<VaultTerritory>(`/territories/${id}`)
    return res.data
  },
  createTerritory: async (request: VaultTerritoryRequest): Promise<VaultTerritory> => {
    const res = await api.post<VaultTerritory>('/territories', {
      name: request.name.trim(),
      baseCapital: request.baseCapital,
      baseCapitalApprovedAt: request.baseCapitalApprovedAt || undefined,
    })
    return res.data
  },
  getTerritoryProfit: async (id: number, from: string, to: string): Promise<TerritoryProfitSummary> => {
    const res = await api.get<TerritoryProfitSummary>(`/territories/${id}/profit`, {
      params: { from, to },
    })
    return res.data
  },
  get: async (territoryId: number, yearMonth: string): Promise<TerritoryReconciliation> => {
    const res = await api.get<TerritoryReconciliation>('/reports/territory-reconciliation', {
      params: { territoryId, yearMonth },
    })
    return res.data
  },
}
