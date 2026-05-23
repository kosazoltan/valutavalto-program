import { api } from './index'

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
  get: async (territoryId: number, yearMonth: string): Promise<TerritoryReconciliation> => {
    const res = await api.get<TerritoryReconciliation>('/reports/territory-reconciliation', {
      params: { territoryId, yearMonth },
    })
    return res.data
  },
}
