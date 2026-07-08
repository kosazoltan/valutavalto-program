import { api } from './client'

export type OptimizationStrategy =
  'GREEDY' | 'DYNAMIC' | 'MIN_COINS' | 'MIN_BANKNOTES' | 'MIN_TOTAL' | 'CUSTOM' | 'BRANCH_SPECIFIC'

export type DenominationRuleType =
  | 'FIXED'
  | 'AMOUNT_BASED'
  | 'CUSTOMER_TYPE'
  | 'TRANSACTION_TYPE'
  | 'BRANCH_DEFAULT'
  | 'TIME_BASED'
  | 'AVAILABILITY'
  | 'PRIORITY'

export interface DenominationOptimization {
  id: string
  name: string
  description?: string | null
  strategy: OptimizationStrategy
  priorityOrderJson?: string | null
  minCoins?: boolean | null
  minBanknotes?: boolean | null
  minTotalCount?: boolean | null
  isDefault?: boolean | null
  isActive?: boolean | null
}

export interface DenominationRule {
  id: string
  ruleName: string
  currencyId?: number | null
  ruleType: DenominationRuleType
  minAmount?: number | null
  maxAmount?: number | null
  branchId?: string | null
  optimization?: DenominationOptimization | null
  ruleConfigJson?: string | null
  priority: number
  isActive?: boolean | null
}

export interface DenominationRuleSelectionPreview {
  strategy: OptimizationStrategy
  ruleId?: string | null
  ruleName?: string | null
  optimizationName?: string | null
  source: 'RULE_MATCH' | 'DEFAULT_OPTIMIZATION' | 'HARD_FALLBACK' | string
}

export interface DenominationOptimizationSaveRequest {
  name: string
  description?: string | null
  strategy: OptimizationStrategy
  priorityOrderJson?: string | null
  minCoins?: boolean | null
  minBanknotes?: boolean | null
  minTotalCount?: boolean | null
  isDefault?: boolean | null
}

export interface DenominationRuleSaveRequest {
  ruleName: string
  currencyId?: number | null
  ruleType: DenominationRuleType
  minAmount?: number | null
  maxAmount?: number | null
  branchId?: string | null
  optimizationId: string
  ruleConfigJson?: string | null
  priority?: number | null
}

export const denominationOptimizationApi = {
  listOptimizations: async (): Promise<DenominationOptimization[]> =>
    (await api.get<DenominationOptimization[]>('/admin/denomination/optimizations')).data,

  createOptimization: async (
    request: DenominationOptimizationSaveRequest,
  ): Promise<DenominationOptimization> =>
    (await api.post<DenominationOptimization>('/admin/denomination/optimizations', request)).data,

  updateOptimization: async (
    id: string,
    request: DenominationOptimizationSaveRequest,
  ): Promise<DenominationOptimization> =>
    (await api.put<DenominationOptimization>(`/admin/denomination/optimizations/${id}`, request))
      .data,

  listRules: async (): Promise<DenominationRule[]> =>
    (await api.get<DenominationRule[]>('/admin/denomination/rules')).data,

  createRule: async (request: DenominationRuleSaveRequest): Promise<DenominationRule> =>
    (await api.post<DenominationRule>('/admin/denomination/rules', request)).data,

  deleteRule: async (id: string): Promise<void> => {
    await api.delete(`/admin/denomination/rules/${id}`)
  },

  previewSelection: async (params: {
    branchId: string
    currencyId: number
    hufAmount: number
  }): Promise<DenominationRuleSelectionPreview> =>
    (
      await api.get<DenominationRuleSelectionPreview>('/admin/denomination/selection-preview', {
        params,
      })
    ).data,
}
