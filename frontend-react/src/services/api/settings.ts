import { api } from './client'

// ================== BANK API (FK-005/C1) ==================

export interface BankInfo {
  id: string
  name: string
  regionCode?: string | null
}

/**
 * Bank-törzs (FK-005/C1) — a banki átadás-átvétel cél/forrás bankjai, területi szűréssel.
 * Az értéktáros a cég-szintű + a saját régió bankjait kapja (a backend AccessScopeService dönt).
 */
export const bankApi = {
  list: async (q?: string): Promise<BankInfo[]> => {
    const response = await api.get<BankInfo[]>('/banks', { params: q ? { q } : {} })
    return response.data ?? []
  },
  create: async (data: { name: string; regionCode?: string }): Promise<BankInfo> => {
    const response = await api.post<BankInfo>('/banks', data)
    return response.data
  },
  deactivate: async (id: string): Promise<void> => {
    await api.delete(`/banks/${id}`)
  },
}

// ================== BRANCH API ==================

export interface BranchInfo {
  id: string
  code: string
  name: string
  companyId?: string
  address?: string
  city?: string
  zipCode?: string
  isActive?: boolean
  isVault?: boolean
  vaultTerritoryId?: number | null
  branchTypeCode?: string
  /** Szöveges terület-név (pl. "SZEGED") — display-célú. */
  region?: string
  /** Numerikus KESZLEX terület-kód (pl. "20") — az értéktár "[azonosító]. [név]" fejléc-formátumához (Codex #1114). */
  regionCode?: string | null
  // FK-022: a szerkesztő form előtöltéséhez (elérhetőség + bankkód a BranchDto-ból).
  phone?: string
  email?: string
  bankCode?: string
  // Pénztár Törzs alapmodul (V293): rövid név + szolgáltatás-flagek + nyitvatartás —
  // a backend BranchDto-ból jönnek, hogy a ráépülő modulok (átadás-átvétel, zárás, készlet,
  // értéktár) a naprakész törzsadattal dolgozhassanak.
  shortName?: string
  hasAfa?: boolean
  hasWu?: boolean
  hasMg?: boolean
  hasPos?: boolean
  closedSaturday?: boolean
  closedSunday?: boolean
}

export interface VaultCounterpartiesResponse {
  territorialCashiers: BranchInfo[]
  peerVaults: BranchInfo[]
  fixedCounterparties: BranchInfo[]
}

export const branchApi = {
  listActive: async (): Promise<BranchInfo[]> => {
    const response = await api.get<BranchInfo[]>('/branches?activeOnly=true')
    return response.data
  },
  listRoots: async (): Promise<BranchInfo[]> => {
    const response = await api.get<BranchInfo[]>('/branches/roots')
    return response.data
  },
  listVaultOnly: async (activeOnly = true): Promise<BranchInfo[]> => {
    const response = await api.get<BranchInfo[]>('/branches/vault-only', { params: { activeOnly } })
    return response.data
  },
  // FK-005/B4: az aktuális felhasználó TERÜLETILEG illetékes aktív pénztárai.
  // Ha a felhasználó értéktárosként (ERTEKTAR/FOERTEKTAR authority) operál → CSAK a saját
  // region_code-jához tartozók (+ saját fiók); egyébként összes aktív. A backend
  // AccessScopeService dönt (a vault-authority precedál a base-role felett).
  listMyTerritory: async (): Promise<BranchInfo[]> => {
    const response = await api.get<BranchInfo[]>('/branches/my-territory')
    return response.data
  },
  /**
   * Bali Henriett / Kasza Helga FK-013 (2026-05-28): az egységes értéktári átadás-átvétel
   * "Cél iroda" legördülő tartalma 3 csoportban:
   *  - territorialCashiers (saját régió pénztárai)
   *  - peerVaults (másik 7 értéktár)
   *  - fixedCounterparties (10 fix VAULT_COUNTERPARTY: PRB/UPT/TRB/ERB/FRB/RB/JRB/MNB/TH/FOP1)
   *
   * Engedélyezett role-ok: ÉRTÉKTÁR / FŐÉRTÉKTÁR / cég-szintű.
   */
  /**
   * Bali Henriett / Kasza Helga FK-013 (2026-05-28) PÉNZTÁRI OLDAL: a pénztári F4
   * "Átadás-átvétel" "Cél iroda" — 3 elem (saját értéktár + TH + 1-es főpénztár).
   * A backend role-szinten korlátozza, csak CASHIER/PENZTAR/MANAGER/SUPERVISOR/ADMIN.
   */
  listCashierShipmentTargets: async (): Promise<BranchInfo[]> => {
    const response = await api.get<BranchInfo[]>('/branches/cashier-shipment-targets')
    return response.data
  },
  listVaultCounterparties: async (): Promise<VaultCounterpartiesResponse> => {
    const response = await api.get<VaultCounterpartiesResponse>('/branches/vault-counterparties')
    return response.data
  },
  getById: async (id: string): Promise<BranchInfo> => {
    const response = await api.get<BranchInfo>(`/branches/${id}`)
    return response.data
  },
  getByCode: async (code: string): Promise<BranchInfo> => {
    const response = await api.get<BranchInfo>(`/branches/code/${code}`)
    return response.data
  },
  /**
   * Bali Henriett 2. pont (2026-05-27): egyszerűsített lakossági pénztár-felrögzítés
   * értéktáros / főértéktáros által. Csak 3 kötelező mezőt vár; a backend kitölti
   * a default-okat (HU/PENZTAR/ACTIVE/today/bankCode=code).
   */
  createSimpleCashier: async (payload: {
    code: string
    address: string
    regionCode: string
    name?: string
    city?: string
    zipCode?: string
    // FK-021: teljes törzsadat-mezők (mind opcionális; elhagyva → backend default).
    shortName?: string
    phone?: string
    email?: string
    bankCode?: string
    isVault?: boolean
    isActive?: boolean
    hasAfa?: boolean
    hasWu?: boolean
    hasMg?: boolean
    hasPos?: boolean
    closedSaturday?: boolean
    closedSunday?: boolean
  }): Promise<BranchInfo> => {
    const response = await api.post<BranchInfo>('/branches/simple-cashier', payload)
    return response.data
  },
  /**
   * FK-022: meglévő iroda törzsadatainak frissítése (PUT /branches/{id}).
   * Partial update: csak a megadott mezők íródnak felül; a `code` nem küldhető (FR-3).
   */
  update: async (id: string, payload: BranchUpdateRequest): Promise<BranchInfo> => {
    const response = await api.put<BranchInfo>(`/branches/${id}`, payload)
    return response.data
  },
}

/** FK-022: a PUT /branches/{id} (UpdateBranchDto) frontend-oldali párja — partial update. */
export interface BranchUpdateRequest {
  name?: string
  shortName?: string
  address?: string
  zipCode?: string
  city?: string
  phone?: string
  email?: string
  bankCode?: string
  regionCode?: string
  isVault?: boolean
  isActive?: boolean
  hasAfa?: boolean
  hasWu?: boolean
  hasMg?: boolean
  hasPos?: boolean
  closedSaturday?: boolean
  closedSunday?: boolean
}

// ================== DICTIONARY API (lightweight) ==================

export interface DictionaryEntry {
  id: string
  category: string
  code: string
  name: string
  nameHu: string
  sortOrder: number
}

export const dictionaryApi = {
  /** Aktív dictionary-bejegyzések kategória szerint (sortOrder szerinti sorrend). */
  getByCategory: async (category: string): Promise<DictionaryEntry[]> => {
    const response = await api.get<DictionaryEntry[]>(`/dictionaries/${category}`)
    return response.data
  },
}

// ================== SYSTEM PARAMETER API ==================

export interface SystemParameter {
  id: string
  parameterKey: string
  parameterValue: string
  parameterType: string
  category: string
  description?: string
  isActive: boolean
  updatedAt: string
  updatedBy?: string
}

export interface SystemParameterCreateRequest {
  parameterKey: string
  parameterValue: string
  parameterType: string
  category: string
  description?: string
  isActive?: boolean
}

export interface SystemParameterManagementUpdateRequest {
  value: string
  description?: string
}

export interface SystemParameterBulkUpdateResponse {
  updated: string
}

export const systemParameterApi = {
  list: async (): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>('/system-parameters')
    return response.data
  },
  listManaged: async (): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>('/system-params')
    return response.data
  },
  getActive: async (): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>('/system-parameters/active')
    return response.data
  },
  getByCategory: async (category: string): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>(`/system-parameters/category/${category}`)
    return response.data
  },
  getManagedByCategory: async (category: string): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>(`/system-params/category/${category}`)
    return response.data
  },
  getByKey: async (parameterKey: string): Promise<SystemParameter> => {
    const response = await api.get<SystemParameter>(`/system-parameters/key/${parameterKey}`)
    return response.data
  },
  getValue: async (parameterKey: string): Promise<string> => {
    const response = await api.get<string>(`/system-parameters/value/${parameterKey}`)
    return response.data
  },
  create: async (data: SystemParameterCreateRequest): Promise<SystemParameter> => {
    const response = await api.post<SystemParameter>('/system-parameters', data)
    return response.data
  },
  update: async (
    id: string,
    data: Partial<SystemParameterCreateRequest>,
  ): Promise<SystemParameter> => {
    const response = await api.put<SystemParameter>(`/system-parameters/${id}`, data)
    return response.data
  },
  updateByKey: async (
    parameterKey: string,
    data: SystemParameterManagementUpdateRequest,
  ): Promise<SystemParameter> => {
    const response = await api.put<SystemParameter>(`/system-params/${parameterKey}`, data)
    return response.data
  },
  bulkUpdate: async (
    parameters: Record<string, string>,
  ): Promise<SystemParameterBulkUpdateResponse> => {
    const response = await api.post<SystemParameterBulkUpdateResponse>(
      '/system-params/bulk-update',
      { parameters },
    )
    return response.data
  },
  toggleActive: async (id: string): Promise<SystemParameter> => {
    const response = await api.post<SystemParameter>(`/system-parameters/${id}/toggle-active`)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/system-parameters/${id}`)
  },
}

// ================== DENOMINATION API ==================

export interface Denomination {
  id: number
  currencyId: number
  currencyCode: string
  currencyName?: string
  faceValue: number
  denominationType: 'BANKNOTE' | 'COIN'
  quantity: number
  minQuantity?: number
  maxQuantity?: number
  active: boolean
}

export interface DenominationValidationResult {
  currencyId: number
  currencyCode: string
  expectedBalance: number
  actualBalance: number
  difference: number
  isValid: boolean
}

export interface DenominationSummary {
  currencyId: number
  currencyCode: string
  currencyName: string
  totalValue: number
  banknoteCount: number
  coinCount: number
  denominationCount: number
}

export const denominationApi = {
  list: async (): Promise<Denomination[]> => {
    const response = await api.get<Denomination[]>('/denominations')
    return response.data
  },
  getByCurrencyId: async (currencyId: number): Promise<Denomination[]> => {
    const response = await api.get<Denomination[]>(`/denominations/currency/${currencyId}`)
    return response.data
  },
  getByCurrencyCode: async (currencyCode: string): Promise<Denomination[]> => {
    const response = await api.get<Denomination[]>(`/denominations/code/${currencyCode}`)
    return response.data
  },
  getLowStockAlerts: async (): Promise<Denomination[]> => {
    const response = await api.get<Denomination[]>('/denominations/alerts/low-stock')
    return response.data
  },
  validate: async (
    currencyId: number,
    expectedBalance: number,
  ): Promise<DenominationValidationResult> => {
    const response = await api.post<DenominationValidationResult>('/denominations/validate', null, {
      params: { currencyId, expectedBalance },
    })
    return response.data
  },
  getSummary: async (currencyId: number): Promise<DenominationSummary> => {
    const response = await api.get<DenominationSummary>(`/denominations/summary/${currencyId}`)
    return response.data
  },
  getOptimalChange: async (currencyId: number, amount: number): Promise<Record<number, number>> => {
    const response = await api.get<Record<number, number>>('/denominations/optimal-change', {
      params: { currencyId, amount },
    })
    return response.data
  },
}

// ================== DENOMINATION CALCULATOR API ==================

export interface DenominationSuggestion {
  currencyCode: string
  requestedAmount: number
  denominations: Record<string, number>
  totalAmount: number
  remainder: number
}

export interface BalancedDenominationSuggestionRequest {
  currencyCode: string
  amount: number
  availableStock: Record<string, number>
}

export const denominationCalculatorApi = {
  suggest: async (currencyCode: string, amount: number): Promise<DenominationSuggestion> => {
    const response = await api.get<DenominationSuggestion>('/denomination-calculator/suggest', {
      params: { currencyCode, amount },
    })
    return response.data
  },
  suggestBalanced: async (
    request: BalancedDenominationSuggestionRequest,
  ): Promise<DenominationSuggestion> => {
    const response = await api.post<DenominationSuggestion>(
      '/denomination-calculator/suggest-balanced',
      request,
    )
    return response.data
  },
}

export interface DenominationBalanceDTO {
  id: string
  cashDeskId: string
  cashDeskCode: string
  denominationId: string
  denominationValue: number
  denominationType: string
  currencyCode: string
  quantity: number
  totalValue: number
  updatedAt: string
}

export interface DenominationQuantityUpdateRequest {
  denominationId: string
  quantity: number
}

/**
 * FK-078 (FR-3): a `denomination_balance` sor kategóriája. A becímletező oldal a csempe
 * szerint adja át — a backend `DenominationCategory` enum két itt használt értéke.
 */
export type DenominationBalanceCategory = 'EVENING' | 'HANDLING_FEE' | 'VAT'

/**
 * FK-078 (FR-4): napközbeni önellenőrzés egy pénznemre — a becímletezett összeg és a
 * könyv szerinti `cash_balance.currentBalance` összevetése. Kizárólag tájékoztató,
 * a mentés soha nem blokkolódik az eredménye alapján.
 */
export interface DenominationSelfCheck {
  currencyCode: string
  currencyId: number
  denominatedAmount: number
  expectedBalance: number
  /** denominatedAmount - expectedBalance (előjeles: pozitív = többlet). */
  difference: number
  matches: boolean
}

export const denominationBalanceApi = {
  getCashDeskDenominations: async (cashDeskId: string): Promise<DenominationBalanceDTO[]> => {
    const response = await api.get<DenominationBalanceDTO[]>(
      `/cash-desks/${cashDeskId}/denominations`,
    )
    return response.data
  },
  getCashDeskDenominationsByCurrency: async (
    cashDeskId: string,
    currencyId: string,
    category?: DenominationBalanceCategory,
  ): Promise<DenominationBalanceDTO[]> => {
    // FKH-038: a kategória opcionális query-paraméter — hiányában a backend EVENING-et
    // alkalmaz (visszamenőleg kompatibilis). A becímletező oldal a route kategóriáját küldi.
    const response = await api.get<DenominationBalanceDTO[]>(
      `/cash-desks/${cashDeskId}/denominations/currency/${currencyId}`,
      category ? { params: { category } } : undefined,
    )
    return response.data
  },
  setDenominationQuantities: async (
    cashDeskId: string,
    updates: DenominationQuantityUpdateRequest[],
    category?: DenominationBalanceCategory,
  ): Promise<DenominationBalanceDTO[]> => {
    // FK-078 (FR-2/FR-3): a kategória opcionális query-paraméter — hiányában a backend
    // a korábbi EVENING viselkedést tartja (visszamenőleg kompatibilis).
    const response = await api.post<DenominationBalanceDTO[]>(
      `/cash-desks/${cashDeskId}/denominations/batch`,
      updates,
      category ? { params: { category } } : undefined,
    )
    return response.data
  },
  /**
   * FK-078 (FR-4): napközbeni önellenőrzés — pénznemenkénti „egyezik / nem egyezik".
   * Kizárólag tájékoztató: a mentés soha nem blokkolódik az eredménye alapján.
   */
  selfCheck: async (
    cashDeskId: string,
    category: DenominationBalanceCategory,
  ): Promise<DenominationSelfCheck[]> => {
    const response = await api.get<DenominationSelfCheck[]>(
      `/cash-desks/${cashDeskId}/denominations/self-check`,
      { params: { category } },
    )
    return response.data
  },
  calculateTotalFromDenominations: async (
    cashDeskId: string,
    currencyId: string,
  ): Promise<number> => {
    const response = await api.get<number>(
      `/cash-desks/${cashDeskId}/denominations/currency/${currencyId}/total`,
    )
    return response.data
  },
}

// ================== WORKER COMMISSION API ==================

export interface WorkerCommission {
  id: string
  workerId: string
  workerName: string
  branchId?: string
  branchName?: string
  periodStart: string
  periodEnd: string
  transactionCount?: number
  totalTransactionAmount?: number
  commissionRate?: number
  commissionAmount?: number
  currencyId?: string
  currencyCode?: string
  statusDid: string
  statusName: string
  calculationDate: string
  calculatedById?: string
  calculatedByName?: string
  approvalDate?: string
  approvedById?: string
  approvedByName?: string
  paymentDate?: string
  notes?: string
}

export const workerCommissionApi = {
  list: async (): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>('/worker-commissions')
    return response.data
  },
  getById: async (id: string): Promise<WorkerCommission> => {
    const response = await api.get<WorkerCommission>(`/worker-commissions/${id}`)
    return response.data
  },
  getByPeriod: async (
    branchId: string,
    periodStart: string,
    periodEnd: string,
  ): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>('/worker-commissions/period', {
      params: { branchId, periodStart, periodEnd },
    })
    return response.data
  },
  calculate: async (
    branchId: string,
    periodStart: string,
    periodEnd: string,
  ): Promise<WorkerCommission[]> => {
    const response = await api.post<WorkerCommission[]>('/worker-commissions/calculate', null, {
      params: { branchId, periodStart, periodEnd },
    })
    return response.data
  },
  getAccountingList: async (
    branchId: string,
    periodStart: string,
    periodEnd: string,
  ): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>('/worker-commissions/accounting-list', {
      params: { branchId, periodStart, periodEnd },
    })
    return response.data
  },
}

export interface CommissionCalculation {
  id: string
  workerId: number
  branchId: string
  period: string
  calculationType: 'MONTHLY' | string
  totalTransactions: number
  totalVolumeHuf: number
  commissionRate?: number
  commissionAmount?: number
  bonusAmount?: number
  deductions?: number
  netCommission?: number
  status: 'CALCULATED' | 'APPROVED' | 'PAID' | string
  calculatedAt?: string
  approvedBy?: number
  approvedAt?: string
  createdAt?: string
}

export const commissionCalculationApi = {
  calculate: async (month: string, workerId?: number): Promise<CommissionCalculation> => {
    const params: { month: string; workerId?: number } = { month }
    if (workerId != null) params.workerId = workerId
    const response = await api.post<CommissionCalculation>('/commissions/calculate', null, {
      params,
    })
    return response.data
  },
  calculateAll: async (month: string, branchId?: string): Promise<CommissionCalculation[]> => {
    const params: { month: string; branchId?: string } = { month }
    if (branchId) params.branchId = branchId
    const response = await api.post<CommissionCalculation[]>('/commissions/calculate-all', null, {
      params,
    })
    return response.data
  },
  approve: async (id: string): Promise<CommissionCalculation> => {
    const response = await api.post<CommissionCalculation>(`/commissions/${id}/approve`)
    return response.data
  },
  report: async (month: string): Promise<CommissionCalculation[]> => {
    const response = await api.get<CommissionCalculation[]>('/commissions/report', {
      params: { month },
    })
    return response.data
  },
}

// ================== WORKSTATION API ==================

export interface Workstation {
  id: string
  code: string
  name: string
  branchId?: string
  branchName?: string
  machineName?: string
  ipAddress?: string
  macAddress?: string
  workstationType: string
  lastSyncTime?: string
  softwareVersion?: string
  isOnline?: boolean
  isActive: boolean
}

export interface WorkstationCreateRequest {
  code: string
  name: string
  branchId?: string
  machineName?: string
  ipAddress?: string
  macAddress?: string
  workstationType: string
  softwareVersion?: string
  isActive?: boolean
}

export const workstationApi = {
  list: async (): Promise<Workstation[]> => {
    const response = await api.get<Workstation[]>('/workstations')
    return response.data
  },
  getActive: async (): Promise<Workstation[]> => {
    const response = await api.get<Workstation[]>('/workstations/active')
    return response.data
  },
  getById: async (id: string): Promise<Workstation> => {
    const response = await api.get<Workstation>(`/workstations/${id}`)
    return response.data
  },
  create: async (data: WorkstationCreateRequest): Promise<Workstation> => {
    const response = await api.post<Workstation>('/workstations', data)
    return response.data
  },
  update: async (id: string, data: Partial<WorkstationCreateRequest>): Promise<Workstation> => {
    const response = await api.put<Workstation>(`/workstations/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/workstations/${id}`)
  },
}

// ================== CONTRIBUTION API ==================

export interface Contribution {
  id: string
  workerId: string
  workerFullName: string
  branchId?: string
  branchName?: string
  periodStart: string
  periodEnd: string
  contributionTypeDid: string
  contributionTypeName: string
  baseAmount: number
  rate?: number
  calculatedAmount: number
  transactionCount?: number
  totalVolume?: number
  currencyId?: string
  currencyCode?: string
  statusDid: string
  statusName: string
  calculationDate: string
  calculatedById?: string
  calculatedByName?: string
  approvalDate?: string
  approvedById?: string
  approvedByName?: string
  paymentDate?: string
  notes?: string
  calculationDetails?: string
}

export const contributionApi = {
  list: async (): Promise<Contribution[]> => {
    const response = await api.get<Contribution[]>('/contributions')
    return response.data
  },
  getById: async (id: string): Promise<Contribution> => {
    const response = await api.get<Contribution>(`/contributions/${id}`)
    return response.data
  },
  getByPeriod: async (
    branchId: string,
    periodStart: string,
    periodEnd: string,
  ): Promise<Contribution[]> => {
    const response = await api.get<Contribution[]>('/contributions/period', {
      params: { branchId, periodStart, periodEnd },
    })
    return response.data
  },
  calculate: async (
    branchId: string,
    periodStart: string,
    periodEnd: string,
  ): Promise<Contribution[]> => {
    const response = await api.post<Contribution[]>('/contributions/calculate', null, {
      params: { branchId, periodStart, periodEnd },
    })
    return response.data
  },
}

// ================== ORGANIZATION / COMPANY / BRANCH-GROUP / FEE / BLACKLIST ==================

export interface Organization {
  id: string
  code: string
  name: string
  description?: string
  parentId?: string
  parentName?: string
  organizationTypeDid?: string
  organizationTypeName?: string
  isActive: boolean
  createdAt?: string
  updatedAt?: string
}

export const organizationApi = {
  list: async (): Promise<Organization[]> => (await api.get<Organization[]>('/organizations')).data,
  getActive: async (): Promise<Organization[]> =>
    (await api.get<Organization[]>('/organizations/active')).data,
  getRoots: async (): Promise<Organization[]> =>
    (await api.get<Organization[]>('/organizations/root')).data,
  getById: async (id: string): Promise<Organization> =>
    (await api.get<Organization>(`/organizations/${id}`)).data,
  create: async (data: Partial<Organization>): Promise<Organization> =>
    (await api.post<Organization>('/organizations', data)).data,
  update: async (id: string, data: Partial<Organization>): Promise<Organization> =>
    (await api.put<Organization>(`/organizations/${id}`, data)).data,
  archive: async (id: string): Promise<void> => {
    await api.post(`/organizations/${id}/archive`)
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/organizations/${id}`)
  },
}

export interface OwnCompany {
  id: string
  name: string
  taxNumber?: string
  registrationNumber?: string
  address?: string
  phone?: string
  email?: string
  bankAccountNumber?: string
  iban?: string
  swift?: string
  licenseNumber?: string
  isActive: boolean
}

export interface AdminCompanyBranchSummary {
  id: string
  code: string
  name: string
  city?: string
  active: boolean
}

export interface AdminCompanyDetails {
  id: string
  code?: string
  name: string
  taxNumber?: string
  registrationNumber?: string
  address?: string
  phone?: string
  email?: string
  active: boolean
  activeBranchCount: number
  totalWorkerCount: number
  dailyTurnoverHuf: number
  branches: AdminCompanyBranchSummary[]
}

export interface AdminCompanyUpdateRequest {
  name?: string
  taxNumber?: string
  registrationNumber?: string
  address?: string
  phone?: string
  email?: string
}

export const ownCompanyApi = {
  list: async (): Promise<OwnCompany[]> => (await api.get<OwnCompany[]>('/own-companies')).data,
  getActive: async (): Promise<OwnCompany[]> =>
    (await api.get<OwnCompany[]>('/own-companies/active')).data,
  getById: async (id: string): Promise<OwnCompany> =>
    (await api.get<OwnCompany>(`/own-companies/${id}`)).data,
  create: async (data: Partial<OwnCompany>): Promise<OwnCompany> =>
    (await api.post<OwnCompany>('/own-companies', data)).data,
  update: async (id: string, data: Partial<OwnCompany>): Promise<OwnCompany> =>
    (await api.put<OwnCompany>(`/own-companies/${id}`, data)).data,
  delete: async (id: string): Promise<void> => {
    await api.delete(`/own-companies/${id}`)
  },
}

export const adminCompanyApi = {
  getDetails: async (id: string): Promise<AdminCompanyDetails> =>
    (await api.get<AdminCompanyDetails>(`/admin/companies/${id}`)).data,
  updateCompany: async (id: string, data: AdminCompanyUpdateRequest): Promise<void> => {
    await api.put(`/admin/companies/${id}`, data)
  },
}

export interface BranchGroup {
  id: string
  code: string
  name: string
  description?: string
  groupTypeDid?: string
  groupTypeName?: string
  parentGroupId?: string
  parentGroupName?: string
  isActive: boolean
  branchIds?: string[]
  branchNames?: string[]
  childGroups?: BranchGroup[]
}

export const branchGroupApi = {
  list: async (): Promise<BranchGroup[]> => (await api.get<BranchGroup[]>('/branch-groups')).data,
  getRoots: async (): Promise<BranchGroup[]> =>
    (await api.get<BranchGroup[]>('/branch-groups/roots')).data,
  getById: async (id: string): Promise<BranchGroup> =>
    (await api.get<BranchGroup>(`/branch-groups/${id}`)).data,
  create: async (data: Partial<BranchGroup>, workerId: string): Promise<BranchGroup> =>
    (await api.post<BranchGroup>('/branch-groups', data, { params: { workerId } })).data,
  update: async (id: string, data: Partial<BranchGroup>): Promise<BranchGroup> =>
    (await api.put<BranchGroup>(`/branch-groups/${id}`, data)).data,
  delete: async (id: string): Promise<void> => {
    await api.delete(`/branch-groups/${id}`)
  },
}

export interface FeeType {
  id: string
  code: string
  name: string
  description?: string
  calculationMethod: string
  isActive: boolean
}
export interface FeeRate {
  id: string
  feeTypeId: string
  feeTypeName?: string
  currencyId?: string
  currencyCode?: string
  branchId?: string
  branchName?: string
  minAmount?: number
  maxAmount?: number
  rate: number
  fixedAmount?: number
  validFrom: string
  validTo?: string
  isActive: boolean
}
export interface FeeDiscount {
  id: string
  code: string
  name: string
  discountType: string
  discountValue: number
  minTransactionAmount?: number
  validFrom: string
  validTo?: string
  isActive: boolean
}

export interface DiscountThresholdApplyResult {
  originalFee: number
  adjustedFee: number
  discountCode: string
  discountName: string
}

export interface DiscountThresholdResolveResult {
  hasDiscount: boolean
  code?: string
  name?: string
  type?: string
  value?: number
}

export const feeApi = {
  getTypes: async (): Promise<FeeType[]> => (await api.get<FeeType[]>('/fees/types')).data,
  createType: async (data: Partial<FeeType>): Promise<FeeType> =>
    (await api.post<FeeType>('/fees/types', data)).data,
  updateType: async (id: string, data: Partial<FeeType>): Promise<FeeType> =>
    (await api.put<FeeType>(`/fees/types/${id}`, data)).data,
  deleteType: async (id: string): Promise<void> => {
    await api.delete(`/fees/types/${id}`)
  },
  getRates: async (): Promise<FeeRate[]> => (await api.get<FeeRate[]>('/fees/rates')).data,
  createRate: async (data: Partial<FeeRate>): Promise<FeeRate> =>
    (await api.post<FeeRate>('/fees/rates', data)).data,
  updateRate: async (id: string, data: Partial<FeeRate>): Promise<FeeRate> =>
    (await api.put<FeeRate>(`/fees/rates/${id}`, data)).data,
  deleteRate: async (id: string): Promise<void> => {
    await api.delete(`/fees/rates/${id}`)
  },
  getDiscounts: async (): Promise<FeeDiscount[]> =>
    (await api.get<FeeDiscount[]>('/fees/discounts')).data,
  createDiscount: async (data: Partial<FeeDiscount>): Promise<FeeDiscount> =>
    (await api.post<FeeDiscount>('/fees/discounts', data)).data,
  updateDiscount: async (id: string, data: Partial<FeeDiscount>): Promise<FeeDiscount> =>
    (await api.put<FeeDiscount>(`/fees/discounts/${id}`, data)).data,
  deleteDiscount: async (id: string): Promise<void> => {
    await api.delete(`/fees/discounts/${id}`)
  },
}

export interface HandlingFeeBracketConfig {
  id?: number
  bracketOrder: number
  upperLimit: number
  feeAmount: number
  active?: boolean
}
export interface HandlingFeeConfig {
  feeType: 'NONE' | 'PER_MILLE' | 'BRACKET'
  perMilleRate: number
  perMilleMaxAmount: number | null
  brackets: HandlingFeeBracketConfig[]
}
export interface HandlingFeeCalculationRequest {
  transactionId?: number | null
  hufAmount: number
}
export interface HandlingFeeDiscountRequest {
  discountPercent: number
  reason?: string
}
export interface HandlingFeeTransactionResult {
  id?: string
  transactionId?: number | null
  paymentMethod?: string | null
  feeType?: string | null
  amount: number
  discountPercent?: number | null
  discountReason?: string | null
  netFee: number
  workerCommissionShare?: number | null
  createdAt?: string | null
}

export const handlingFeeConfigApi = {
  get: async (): Promise<HandlingFeeConfig> =>
    (await api.get<HandlingFeeConfig>('/handling-fee-config')).data,
  update: async (data: HandlingFeeConfig): Promise<HandlingFeeConfig> =>
    (await api.put<HandlingFeeConfig>('/handling-fee-config', data)).data,
  saveBrackets: async (data: HandlingFeeBracketConfig[]): Promise<HandlingFeeBracketConfig[]> =>
    (await api.post<HandlingFeeBracketConfig[]>('/handling-fee-config/brackets', data)).data,
}

// ============================================================================
// FK-096 — iroda-szintű kezelési díj konfiguráció (branch-fee-config)
// A legacy handlingFeeConfigApi kompatibilitásból megmaradt; a díjszámítás
// az új, iroda-szintű végpontokból oldódik fel (fail-closed, FR-5).
// ============================================================================

export interface BranchFeeConfigRow {
  branchId: string
  branchCode: string
  branchName: string
  region: string | null
  liveFeeMode: 'NONE' | 'BRACKET' | 'PER_MILLE' | null
  livePerMilleRate: number | null
  livePerMilleCap: number | null
  hasDraft: boolean
  draftFeeMode: 'BRACKET' | 'PER_MILLE' | null
  draftPerMilleRate: number | null
  draftPerMilleCap: number | null
  /** A DRAFT sor verziója (publish expectedVersion); DRAFT nélkül a LIVE verziója. */
  version: number
}

export interface BranchFeeSummary {
  totalBranches: number
  configuredBranches: number
  bracketBranches: number
  perMilleBranches: number
}

export interface BranchFeeConfigList {
  summary: BranchFeeSummary
  rows: BranchFeeConfigRow[]
}

export interface BranchFeeConfigLive {
  branchId: string
  branchCode: string
  feeMode: 'NONE' | 'BRACKET' | 'PER_MILLE'
  perMilleRate: number | null
  perMilleCap: number | null
  validFrom: string
  brackets: HandlingFeeBracketConfig[]
}

export interface BranchFeeConfigDraftBody {
  feeMode: 'BRACKET' | 'PER_MILLE'
  perMilleRate: number | null
  perMilleCap: number | null
}

export const branchFeeConfigApi = {
  list: async (): Promise<BranchFeeConfigList> =>
    (await api.get<BranchFeeConfigList>('/branch-fee-config')).data,
  saveDraft: async (
    branchId: string,
    body: BranchFeeConfigDraftBody,
  ): Promise<BranchFeeConfigRow> =>
    (await api.post<BranchFeeConfigRow>(`/branch-fee-config/${branchId}/draft`, body)).data,
  // N11: expectedVersion a TÖRZSBEN utazik; 0 legitim első-publikálás érték (B2).
  publish: async (branchId: string, expectedVersion: number): Promise<BranchFeeConfigRow> =>
    (
      await api.post<BranchFeeConfigRow>(`/branch-fee-config/${branchId}/publish`, {
        expectedVersion,
      })
    ).data,
  own: async (): Promise<BranchFeeConfigLive> =>
    (await api.get<BranchFeeConfigLive>('/branch-fee-config/own')).data,
  live: async (branchId: string): Promise<BranchFeeConfigLive> =>
    (await api.get<BranchFeeConfigLive>(`/branch-fee-config/${branchId}/live`)).data,
}

export interface BracketSet {
  live: HandlingFeeBracketConfig[]
  draft: HandlingFeeBracketConfig[]
}

export const handlingFeeBracketApi = {
  get: async (): Promise<BracketSet> => (await api.get<BracketSet>('/handling-fee-bracket')).data,
  saveDraft: async (rows: HandlingFeeBracketConfig[]): Promise<BracketSet> =>
    (await api.post<BracketSet>('/handling-fee-bracket/draft', rows)).data,
  publish: async (): Promise<BracketSet> =>
    (await api.post<BracketSet>('/handling-fee-bracket/publish')).data,
}

export const handlingFeeTransactionApi = {
  calculate: async (data: HandlingFeeCalculationRequest): Promise<HandlingFeeTransactionResult> =>
    (await api.post<HandlingFeeTransactionResult>('/handling-fees/calculate', data)).data,
  applyDiscount: async (
    id: string,
    data: HandlingFeeDiscountRequest,
  ): Promise<HandlingFeeTransactionResult> =>
    (await api.post<HandlingFeeTransactionResult>(`/handling-fees/${id}/discount`, data)).data,
}

export interface ProhibitedPerson {
  id: string
  fullName: string
  documentNumber?: string
  identityNumber?: string
  passportNumber?: string
  dateOfBirth?: string
  nationality?: string
  listType: string
  listSource: string
  reason?: string
  isActive: boolean
}
export interface ProhibitedCompany {
  id: string
  companyName: string
  taxNumber?: string
  registrationNumber?: string
  listType: string
  listSource: string
  reason?: string
  isActive: boolean
}

export const blacklistApi = {
  getPersons: async (): Promise<ProhibitedPerson[]> =>
    (await api.get<ProhibitedPerson[]>('/blacklist/persons')).data,
  createPerson: async (data: Partial<ProhibitedPerson>): Promise<ProhibitedPerson> =>
    (await api.post<ProhibitedPerson>('/blacklist/persons', data)).data,
  updatePerson: async (id: string, data: Partial<ProhibitedPerson>): Promise<ProhibitedPerson> =>
    (await api.put<ProhibitedPerson>(`/blacklist/persons/${id}`, data)).data,
  deletePerson: async (id: string): Promise<void> => {
    await api.delete(`/blacklist/persons/${id}`)
  },
  getCompanies: async (): Promise<ProhibitedCompany[]> =>
    (await api.get<ProhibitedCompany[]>('/blacklist/companies')).data,
  createCompany: async (data: Partial<ProhibitedCompany>): Promise<ProhibitedCompany> =>
    (await api.post<ProhibitedCompany>('/blacklist/companies', data)).data,
  updateCompany: async (id: string, data: Partial<ProhibitedCompany>): Promise<ProhibitedCompany> =>
    (await api.put<ProhibitedCompany>(`/blacklist/companies/${id}`, data)).data,
  deleteCompany: async (id: string): Promise<void> => {
    await api.delete(`/blacklist/companies/${id}`)
  },
  importPersons: async (file: File): Promise<void> => {
    const formData = new FormData()
    formData.append('file', file)
    await api.post('/blacklist/persons/import', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
  importCompanies: async (file: File): Promise<void> => {
    const formData = new FormData()
    formData.append('file', file)
    await api.post('/blacklist/companies/import', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
}

// ================== OTHER SETTINGS / OPS API ==================

export interface CommissionRate {
  id: string
  entityType: string
  entityId?: string
  entityName?: string
  currencyId?: string
  currencyCode?: string
  rate: number
  validFrom: string
  validTo?: string
  isActive: boolean
}
export const commissionRateApi = {
  list: async (): Promise<CommissionRate[]> =>
    (await api.get<CommissionRate[]>('/commission-rates')).data,
  getById: async (id: string): Promise<CommissionRate> =>
    (await api.get<CommissionRate>(`/commission-rates/${id}`)).data,
  create: async (data: Partial<CommissionRate>): Promise<CommissionRate> =>
    (await api.post<CommissionRate>('/commission-rates', data)).data,
  update: async (id: string, data: Partial<CommissionRate>): Promise<CommissionRate> =>
    (await api.put<CommissionRate>(`/commission-rates/${id}`, data)).data,
  delete: async (id: string): Promise<void> => {
    await api.delete(`/commission-rates/${id}`)
  },
}

export interface ArchiveTask {
  id: string
  taskType: string
  entityType: string
  criteria: Record<string, unknown>
  status: string
  startedAt?: string
  completedAt?: string
  archiveLocation?: string
}
export interface ArchivedTransaction {
  id: number
  archiveMonth: string
  originalId: number
  receiptNumber?: string
  transactionType?: string
  currencyCode?: string
  amount?: number
  hufAmount?: number
  handlingFee?: number
  originalDate?: string
  customerName?: string
  archivedAt?: string
  archiveStatus?: string
}

export const discountThresholdApi = {
  listActive: async (): Promise<FeeDiscount[]> =>
    (await api.get<FeeDiscount[]>('/discount-threshold/active')).data,
  resolve: async (hufAmount: number): Promise<DiscountThresholdResolveResult> =>
    (
      await api.get<DiscountThresholdResolveResult>('/discount-threshold/resolve', {
        params: { hufAmount },
      })
    ).data,
  apply: async (hufAmount: number, originalFee: number): Promise<DiscountThresholdApplyResult> =>
    (
      await api.get<DiscountThresholdApplyResult>('/discount-threshold/apply', {
        params: { hufAmount, originalFee },
      })
    ).data,
}
export const archivingApi = {
  listTasks: async (): Promise<ArchiveTask[]> =>
    (await api.get<ArchiveTask[]>('/archiving/tasks')).data,
  createTask: async (data: Partial<ArchiveTask>): Promise<ArchiveTask> =>
    (await api.post<ArchiveTask>('/archiving/tasks', data)).data,
  executeTask: async (id: string): Promise<ArchiveTask> =>
    (await api.post<ArchiveTask>(`/archiving/tasks/${id}/execute`)).data,
  monthlyArchive: async (branchId: string, yearMonth: string) =>
    (await api.post('/archiving/monthly', { branchId, yearMonth })).data,
  getMonthlyStatus: async (branchId: string, yearMonth: string) =>
    (await api.get(`/archiving/monthly/${branchId}/${yearMonth}/status`)).data,
  getArchivedTransactions: async (
    branchId: string,
    yearMonth: string,
  ): Promise<ArchivedTransaction[]> =>
    (await api.get<ArchivedTransaction[]>(`/archiving/monthly/${branchId}/${yearMonth}`)).data,
}

export interface Reservation {
  id: string
  customerId?: string | number | null
  customerName?: string
  currencyCode: string
  amount?: number
  reservedAmount?: number
  exchangeRate?: number
  depositAmount?: number
  reservationType?: string
  reservationDate?: string
  expiresAt?: string
  expiryDate?: string
  status: string
  branchId?: string
  branchName?: string
  receiptNumber?: string | null
  cancellationReason?: string | null
  refundAmount?: number | null
  expired?: boolean | null
  notes?: string
  createdAt: string
}
export interface ReservedStock {
  currencyCode: string
  reservedAmount: number
  activeCount: number
}
export interface CreateReservationRequest {
  customerId?: string | number
  customerName?: string
  currencyCode: string
  amount: number
  exchangeRate?: number
  reservationType?: string
  expiresAt?: string
  expiryDate?: string
  notes?: string
}

export const reservationsApi = {
  create: async (data: CreateReservationRequest): Promise<Reservation> =>
    (await api.post<Reservation>('/reservations', data)).data,
  getById: async (id: string): Promise<Reservation> =>
    (await api.get<Reservation>(`/reservations/${id}`)).data,
  reservedStock: async (branchId: string): Promise<ReservedStock[]> =>
    (await api.get<ReservedStock[]>('/reservations/reserved-stock', { params: { branchId } })).data,
  list: async (params?: {
    status?: string
    customerId?: string
    branchId?: string
  }): Promise<Reservation[]> => {
    const status = params?.status?.toUpperCase()
    const path = status === 'EXPIRED' ? '/reservations/expired' : '/reservations/active'
    const requestParams: Record<string, string> = {}
    if (params?.customerId) requestParams.customerId = params.customerId
    if (params?.branchId) requestParams.branchId = params.branchId
    const response = await api.get<Reservation[]>(path, {
      params: Object.keys(requestParams).length ? requestParams : undefined,
    })
    return response.data
  },
  cancel: async (id: string | number, reason?: string): Promise<Reservation> =>
    (
      await api.post<Reservation>(
        `/reservations/${id}/cancel-by-customer`,
        reason ? { reason } : undefined,
      )
    ).data,
  cancelByCompany: async (
    id: string | number,
    data: { reason: string; supervisorWorkerId: number },
  ): Promise<Reservation> =>
    (await api.post<Reservation>(`/reservations/${id}/cancel-by-company`, data)).data,
  fulfill: async (id: string | number): Promise<Reservation> =>
    (await api.post<Reservation>(`/reservations/${id}/fulfill`)).data,
  receipt: async (id: string | number, refund: boolean): Promise<Blob> =>
    (
      await api.get<Blob>(`/reservations/${id}/receipt`, {
        params: { refund },
        responseType: 'blob',
      })
    ).data,
}

export interface SynchronizationResult {
  success: boolean
  recordsSynced: number
  errors: string[]
}
export interface SynchronizationProbe {
  shouldSync: boolean
  pendingCount: number
}
export const synchronizationApi = {
  synchronize: async (
    branchId: string,
    workerId: string,
    options?: { direction?: string; entityTypes?: string[] },
  ): Promise<SynchronizationResult> =>
    (
      await api.post<SynchronizationResult>('/synchronization/sync', options || null, {
        params: { branchId, workerId },
      })
    ).data,
  shouldSync: async (branchId?: string): Promise<SynchronizationProbe> => {
    const response = await api.get<boolean | SynchronizationProbe>('/synchronization/should-sync', {
      params: branchId ? { branchId } : undefined,
    })
    if (typeof response.data === 'boolean') {
      return { shouldSync: response.data, pendingCount: 0 }
    }
    return response.data
  },
}

export interface PosTerminal {
  id: string
  terminalId: string
  terminalName: string
  branchId?: string
  branchName?: string
  isActive: boolean
  lastTransactionAt?: string
  connectionType?: string
  comPort?: string
  baudRate?: number
  ipAddress?: string
  port?: number
}
export interface PosTerminalRuntimeStatus {
  terminalId: string
  connected: boolean
  active: boolean
  reachable: boolean
  terminalName?: string
  terminalType?: string
  lastTransactionAt?: string
  message?: string
}
export const posTerminalApi = {
  list: async (): Promise<PosTerminal[]> => (await api.get<PosTerminal[]>('/pos-terminal')).data,
  getById: async (id: string): Promise<PosTerminal> =>
    (await api.get<PosTerminal>(`/pos-terminal/${id}`)).data,
  status: async (terminalId: string): Promise<PosTerminalRuntimeStatus> =>
    (
      await api.get<PosTerminalRuntimeStatus>('/pos-terminal-stub/status', {
        params: { terminalId },
      })
    ).data,
}

export interface NavSendResult {
  success: boolean
  receiptNumber?: string
  error?: string
}
export const navIntegrationApi = {
  sendTransaction: async (transactionId: string, comPort: string): Promise<NavSendResult> =>
    (
      await api.post<NavSendResult>('/nav-integration/send-transaction', null, {
        params: { transactionId, comPort },
      })
    ).data,
  receiveReceiptNumber: async (comPort: string): Promise<string> =>
    (await api.get<string>('/nav-integration/receive-receipt-number', { params: { comPort } }))
      .data,
  sendQrCode: async (qrCode: string, comPort: string): Promise<boolean> =>
    (
      await api.post<boolean>('/nav-integration/send-qr-code', null, {
        params: { qrCode, comPort },
      })
    ).data,
}

export interface Document {
  id: string
  fileName: string
  fileType: string
  fileSize: number
  entityType?: string
  entityId?: string
  uploadedAt: string
  uploadedById?: string
  uploadedByName?: string
}
export interface DocumentScannerDevicesResponse {
  devices: unknown[]
  mode: string
  message: string
}
export interface ScannedDocument {
  id: string
  customerId?: number | null
  transactionId?: number | null
  documentType: string
  fileName: string
  mimeType: string
  fileSizeBytes: number
  storagePath?: string
  scannedBy?: number | null
  scannedAt: string
  notes?: string | null
  validUntil?: string | null
  hasFrontImage?: boolean | null
  hasBackImage?: boolean | null
}
export interface DocumentScannerUploadRequest {
  documentType?: 'ID_CARD' | 'PASSPORT' | 'DRIVERS_LICENSE' | 'COMPANY_REGISTRY' | 'OTHER'
  customerId?: number
  transactionId?: number
  notes?: string
}
export const documentStorageApi = {
  list: async (entityType?: string, entityId?: string): Promise<Document[]> => {
    const params: Record<string, string> = {}
    if (entityType) params.entityType = entityType
    if (entityId) params.entityId = entityId
    return (await api.get<Document[]>('/documents', { params })).data
  },
  upload: async (file: File, entityType?: string, entityId?: string): Promise<Document> => {
    const formData = new FormData()
    formData.append('file', file)
    if (entityType) formData.append('entityType', entityType)
    if (entityId) formData.append('entityId', entityId)
    return (
      await api.post<Document>('/documents', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
    ).data
  },
  download: async (id: string): Promise<Blob> =>
    (await api.get(`/documents/${id}/download`, { responseType: 'blob' })).data,
  delete: async (id: string): Promise<void> => {
    await api.delete(`/documents/${id}`)
  },
}
export const documentScannerApi = {
  devices: async (): Promise<DocumentScannerDevicesResponse> =>
    (await api.get<DocumentScannerDevicesResponse>('/document-scanner/devices')).data,
  scan: async (
    file: File,
    request: DocumentScannerUploadRequest = {},
  ): Promise<ScannedDocument> => {
    const formData = createScannerFormData(file, request)
    return (
      await api.post<ScannedDocument>('/document-scanner/scan', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
    ).data
  },
  upload: async (
    file: File,
    request: DocumentScannerUploadRequest = {},
  ): Promise<ScannedDocument> => {
    const formData = createScannerFormData(file, request)
    return (
      await api.post<ScannedDocument>('/document-scanner/upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
    ).data
  },
  uploadScannedDocument: async (
    file: File,
    request: DocumentScannerUploadRequest = {},
  ): Promise<ScannedDocument> => {
    const formData = createScannerFormData(file, request)
    return (
      await api.post<ScannedDocument>('/scanned-documents/upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
    ).data
  },
  getCustomerDocuments: async (customerId: number): Promise<ScannedDocument[]> =>
    (await api.get<ScannedDocument[]>(`/scanned-documents/customer/${customerId}`)).data,
  getTransactionDocuments: async (transactionId: number): Promise<ScannedDocument[]> =>
    (await api.get<ScannedDocument[]>(`/scanned-documents/transaction/${transactionId}`)).data,
  deleteScannedDocument: async (id: string): Promise<void> => {
    await api.delete(`/scanned-documents/${id}`)
  },
  uploadScannedDocumentPair: async (
    front: File,
    back: File,
    request: DocumentScannerUploadRequest = {},
  ): Promise<ScannedDocument> => {
    const formData = new FormData()
    formData.append('front', front)
    formData.append('back', back)
    formData.append('documentType', request.documentType ?? 'OTHER')
    if (request.customerId != null) formData.append('customerId', String(request.customerId))
    if (request.transactionId != null)
      formData.append('transactionId', String(request.transactionId))
    if (request.notes) formData.append('notes', request.notes)
    return (await api.post<ScannedDocument>('/scanned-documents/upload-pair', formData)).data
  },
  getThumbnail: async (id: string, side: 'FRONT' | 'BACK'): Promise<Blob> =>
    (await api.get(`/scanned-documents/${id}/image/${side}/thumbnail`, { responseType: 'blob' }))
      .data,
  issueViewGrant: async (id: string, approverWorkerId: number, pin: string): Promise<void> => {
    await api.post(`/scanned-documents/${id}/view-grant`, { approverWorkerId, pin })
  },
  getFullImage: async (id: string, side: 'FRONT' | 'BACK'): Promise<Blob> =>
    (await api.get(`/scanned-documents/${id}/image/${side}/full`, { responseType: 'blob' })).data,
}

// ================== VALUE BAND (AML ÉRTÉKSÁV) API ==================

export interface ValueBandConfig {
  id: string
  simplifiedIdentificationLimitHuf: number
  identificationLimitHuf: number
  incomeProofLimitHuf: number
  rollingWindowDays: number
  effectiveFrom: string
  createdBy?: string
  createdAt?: string
  updatedAt?: string
}

export interface ValueBandConfigRequest {
  simplifiedIdentificationLimitHuf: number
  identificationLimitHuf: number
  incomeProofLimitHuf: number
  rollingWindowDays: number
  effectiveFrom: string
}

export const valueBandApi = {
  list: async (): Promise<ValueBandConfig[]> =>
    (await api.get<ValueBandConfig[]>('/value-bands')).data,
  create: async (req: ValueBandConfigRequest): Promise<ValueBandConfig> =>
    (await api.post<ValueBandConfig>('/value-bands', req)).data,
  update: async (id: string, req: ValueBandConfigRequest): Promise<ValueBandConfig> =>
    (await api.put<ValueBandConfig>(`/value-bands/${id}`, req)).data,
  remove: async (id: string): Promise<void> => {
    await api.delete(`/value-bands/${id}`)
  },
}

function createScannerFormData(file: File, request: DocumentScannerUploadRequest): FormData {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('documentType', request.documentType ?? 'OTHER')
  if (request.customerId != null) formData.append('customerId', String(request.customerId))
  if (request.transactionId != null) formData.append('transactionId', String(request.transactionId))
  if (request.notes) formData.append('notes', request.notes)
  return formData
}

export interface Notification {
  id: string
  title: string
  message: string
  type: string
  userId?: string
  isRead: boolean
  createdAt: string
}
export const notificationApi = {
  list: async (): Promise<Notification[]> => (await api.get<Notification[]>('/notifications')).data,
  getUnread: async (): Promise<Notification[]> =>
    (await api.get<Notification[]>('/notifications/unread')).data,
  unreadCount: async (): Promise<number> => {
    const data = (await api.get<number | { count?: number }>('/notifications/unread-count')).data
    return typeof data === 'number' ? data : (data.count ?? 0)
  },
  markAsRead: async (id: string): Promise<void> => {
    await api.put(`/notifications/${id}/read`)
  },
  markAllAsRead: async (): Promise<void> => {
    await api.post('/notifications/mark-all-read')
  },
  sendInApp: async (data: {
    userId: string
    title: string
    message: string
    type?: string
  }): Promise<Notification> => (await api.post<Notification>('/notifications', data)).data,
  send: async (data: Record<string, unknown>): Promise<Notification> =>
    (await api.post<Notification>('/notifications/send', data)).data,
  broadcast: async (data: Record<string, unknown>): Promise<void> => {
    await api.post('/notifications/broadcast', data)
  },
}

export interface SupervisorPinResponse {
  ok: boolean
  message?: string
  error?: string
}

export const supervisorPinApi = {
  set: async (currentPassword: string, pin: string): Promise<SupervisorPinResponse> =>
    (await api.post<SupervisorPinResponse>('/supervisor-pin/set', { currentPassword, pin })).data,
  clear: async (currentPassword: string): Promise<SupervisorPinResponse> =>
    (await api.post<SupervisorPinResponse>('/supervisor-pin/clear', { currentPassword })).data,
}

export interface MfaAdminDisableResponse {
  workerId: number
  message: string
}

export const mfaAdminApi = {
  disable: async (workerId: number | string): Promise<MfaAdminDisableResponse> =>
    (await api.post<MfaAdminDisableResponse>(`/mfa/admin/${workerId}/disable`)).data,
}

export interface OrganizationalSystemParameter {
  id: string
  organizationId: string
  organizationName?: string
  parameterKey: string
  parameterValue: string
  currencyId?: string
  currencyCode?: string
  validFrom: string
  validTo?: string
  isActive: boolean
  description?: string
}

export const organizationalSystemParameterApi = {
  list: async (organizationId?: string): Promise<OrganizationalSystemParameter[]> => {
    const params = organizationId ? { organizationId } : {}
    return (
      await api.get<OrganizationalSystemParameter[]>('/organizational-system-parameters', {
        params,
      })
    ).data
  },
  getById: async (id: string): Promise<OrganizationalSystemParameter> =>
    (await api.get<OrganizationalSystemParameter>(`/organizational-system-parameters/${id}`)).data,
  create: async (
    data: Partial<OrganizationalSystemParameter>,
  ): Promise<OrganizationalSystemParameter> =>
    (await api.post<OrganizationalSystemParameter>('/organizational-system-parameters', data)).data,
  update: async (
    id: string,
    data: Partial<OrganizationalSystemParameter>,
  ): Promise<OrganizationalSystemParameter> =>
    (await api.put<OrganizationalSystemParameter>(`/organizational-system-parameters/${id}`, data))
      .data,
  delete: async (id: string): Promise<void> => {
    await api.delete(`/organizational-system-parameters/${id}`)
  },
}

// ================== CASH DESK BREAK API ==================

export interface CashDeskBreak {
  id: string
  cashDeskId: string
  cashDeskName?: string
  breakStart: string
  breakEnd?: string
  breakType: string
  reason?: string
  isActive: boolean
}

export const cashDeskBreakApi = {
  list: async (cashDeskId?: string): Promise<CashDeskBreak[]> => {
    const params = cashDeskId ? { cashDeskId } : {}
    return (await api.get<CashDeskBreak[]>('/cash-desk-breaks', { params })).data
  },
  getActive: async (cashDeskId: string): Promise<CashDeskBreak | null> =>
    (await api.get<CashDeskBreak>(`/cash-desk-breaks/active/${cashDeskId}`)).data,
  start: async (cashDeskId: string, breakType: string, reason?: string): Promise<CashDeskBreak> =>
    (
      await api.post<CashDeskBreak>('/cash-desk-breaks/start', null, {
        params: { cashDeskId, breakType, reason },
      })
    ).data,
  end: async (breakId: string): Promise<CashDeskBreak> =>
    (await api.post<CashDeskBreak>(`/cash-desk-breaks/${breakId}/end`)).data,
}

// ================== CAMERA EXPORT API ==================

export interface CameraExportRequest {
  id: string
  branchId: string
  cameraId?: string
  periodFrom: string
  periodTo: string
  reason: string
  referenceNumber?: string
  status: string
  requestedBy: string
  createdAt: string
  approvedBy?: string
  approvedAt?: string
  rejectionReason?: string
  requiresDualApproval?: boolean
  secondApprovedBy?: string
  secondApprovedAt?: string
  exportPath?: string
  exportSizeBytes?: number
  manifestHash?: string
  completedAt?: string
  errorMessage?: string
}

export interface ChainOfCustodyRecord {
  id: string
  exportRequestId?: string
  branchId: string
  cameraId?: string
  eventType: string
  actor: string
  eventTimestamp: string
  details?: string
  periodFrom?: string
  periodTo?: string
  manifestHash?: string
}

export const cameraExportApi = {
  createRequest: (p: {
    branchId: string
    cameraId?: string
    from: string
    to: string
    reason: string
    referenceNumber?: string
  }) => api.post<CameraExportRequest>('/camera/export/request', null, { params: { ...p } }),
  approve: (id: string) => api.post<CameraExportRequest>(`/camera/export/${id}/approve`),
  approveSecond: (id: string) =>
    api.post<CameraExportRequest>(`/camera/export/${id}/approve-second`),
  reject: (id: string, reason: string) =>
    api.post<CameraExportRequest>(
      `/camera/export/${id}/reject?reason=${encodeURIComponent(reason)}`,
    ),
  execute: (id: string) => api.post<CameraExportRequest>(`/camera/export/${id}/execute`),
  getById: (id: string) => api.get<CameraExportRequest>(`/camera/export/${id}`),
  getPending: () => api.get<CameraExportRequest[]>('/camera/export/pending'),
  getByBranch: (branchId: string) =>
    api.get<CameraExportRequest[]>(`/camera/export/branch/${branchId}`),
  getCustody: (id: string) => api.get<ChainOfCustodyRecord[]>(`/camera/export/${id}/custody`),
  verifyChain: (branchId: string, cameraId: string) =>
    api.post<{ branchId: string; cameraId: string; chainIntact: boolean; verifiedAt: string }>(
      '/camera/export/verify-chain',
      null,
      { params: { branchId, cameraId } },
    ),
}

// ================== ÉRTÉKTÁR API ==================

export interface BankTransaction {
  id: number
  transactionType: 'BUY' | 'SELL'
  currencyCode: string
  amount: number
  exchangeRate: number
  hufAmount: number
  bankName?: string
  bankReference?: string
  status: string
  note?: string
  createdAt: string
  completedAt?: string
  receivedAt?: string
  receivedBy?: number
  paidAt?: string
  paidBy?: number
  vaultTerritoryId?: number
  vaultTerritoryName?: string
}

export type VaultOperationStatus = 'REQUESTED' | 'IN_PROGRESS' | 'COMPLETED' | 'REJECTED'

export interface BankTransactionRequest {
  transactionType: 'BUY' | 'SELL'
  currencyCode: string
  amount: number
  exchangeRate: number
  vaultTerritoryId?: number
  bankName?: string
  bankReference?: string
  note?: string
}

export interface ErtektarCollection {
  id: number
  sourceBranchCode?: string
  sourceBranchName?: string
  currencyCode?: string
  amount?: number
  status: string
  requestedAt?: string
  completedAt?: string
  note?: string
}

export interface ErtektarDistributionLine {
  targetBranchCode?: string
  targetBranchName?: string
  currencyCode?: string
  amount?: number
}

export interface ErtektarDistribution {
  id: number
  status: string
  note?: string
  createdAt?: string
  completedAt?: string
  lines?: ErtektarDistributionLine[]
}

export interface VaultTransferItem {
  id: number
  transferNumber: string
  sourceVaultId?: number
  sourceVaultName?: string
  targetVaultId?: number
  targetVaultName?: string
  sourceBranchCode?: string
  targetBranchCode?: string
  currencyCode: string
  amount: number
  wacAtTransfer?: number
  status: string
  requiresSupervisor: boolean
  note?: string
  createdAt: string
  completedAt?: string
  receivedAt?: string
}

export interface VaultTransferRequest {
  sourceVaultId?: number
  targetVaultId?: number
  sourceBranchCode?: string
  targetBranchCode?: string
  currencyCode: string
  amount: number
  note?: string
}

export interface MaterialReceiptLine {
  currencyCode: string
  amount: number
  exchangeRate?: number
  hufEquivalent?: number
}

export interface MaterialReceiptItem {
  id: number
  receiptNumber: string
  receiptType: 'B' | 'K'
  vaultTerritoryId?: number
  vaultTerritoryName?: string
  branchCode?: string
  counterpartName?: string
  note?: string
  status: string
  createdAt: string
  finalizedAt?: string
  lines: MaterialReceiptLine[]
}

export interface MaterialReceiptRequest {
  receiptType: 'B' | 'K'
  vaultTerritoryId?: number
  branchCode?: string
  counterpartName?: string
  note?: string
  lines: MaterialReceiptLine[]
}

export interface StockCorrectionItem {
  id: number
  entityType: string
  entityId: string
  currencyCode: string
  oldQuantity: number
  newQuantity: number
  difference: number
  reason: string
  status: string
  createdAt: string
  approvedAt?: string
}

export interface StockCorrectionRequest {
  entityType: string
  entityId: string
  currencyCode: string
  newQuantity: number
  reason: string
}

export const ertektarApi = {
  getBankTransactions: async (): Promise<BankTransaction[]> =>
    (await api.get<BankTransaction[]>('/ertektar/bank-transactions')).data,
  getBankTransactionsByType: async (type: string): Promise<BankTransaction[]> =>
    (await api.get<BankTransaction[]>('/ertektar/bank-transactions/by-type', { params: { type } }))
      .data,
  createBankTransaction: async (data: BankTransactionRequest): Promise<BankTransaction> =>
    (await api.post<BankTransaction>('/ertektar/bank-transactions', data)).data,
  updateBankTransactionStatus: async (
    id: number,
    status: VaultOperationStatus,
  ): Promise<BankTransaction> =>
    (
      await api.patch<BankTransaction>(`/ertektar/bank-transactions/${id}/status`, null, {
        params: { status },
      })
    ).data,
  confirmBankTransactionReceived: async (id: number): Promise<BankTransaction> =>
    (await api.post<BankTransaction>(`/ertektar/bank-transactions/${id}/confirm-received`)).data,
  confirmBankTransactionPaid: async (id: number): Promise<BankTransaction> =>
    (await api.post<BankTransaction>(`/ertektar/bank-transactions/${id}/confirm-paid`)).data,
  getTransfers: async (): Promise<VaultTransferItem[]> =>
    (await api.get<VaultTransferItem[]>('/ertektar/transfers')).data,
  getPendingTransfers: async (): Promise<VaultTransferItem[]> =>
    (await api.get<VaultTransferItem[]>('/ertektar/transfers/pending')).data,
  createTransfer: async (data: VaultTransferRequest): Promise<VaultTransferItem> =>
    (await api.post<VaultTransferItem>('/ertektar/transfers', data)).data,
  supervisorApproveTransfer: async (id: number): Promise<VaultTransferItem> =>
    (await api.post<VaultTransferItem>(`/ertektar/transfers/${id}/supervisor-approve`)).data,
  completeTransfer: async (id: number): Promise<VaultTransferItem> =>
    (await api.post<VaultTransferItem>(`/ertektar/transfers/${id}/complete`)).data,
  rejectTransfer: async (id: number): Promise<VaultTransferItem> =>
    (await api.post<VaultTransferItem>(`/ertektar/transfers/${id}/reject`)).data,
  getReceipts: async (): Promise<MaterialReceiptItem[]> =>
    (await api.get<MaterialReceiptItem[]>('/ertektar/receipts')).data,
  getReceiptsByType: async (type: string): Promise<MaterialReceiptItem[]> =>
    (await api.get<MaterialReceiptItem[]>('/ertektar/receipts/by-type', { params: { type } })).data,
  createReceipt: async (data: MaterialReceiptRequest): Promise<MaterialReceiptItem> =>
    (await api.post<MaterialReceiptItem>('/ertektar/receipts', data)).data,
  finalizeReceipt: async (id: number): Promise<MaterialReceiptItem> =>
    (await api.post<MaterialReceiptItem>(`/ertektar/receipts/${id}/finalize`)).data,
  getCorrections: async (): Promise<StockCorrectionItem[]> =>
    (await api.get<StockCorrectionItem[]>('/ertektar/corrections')).data,
  getPendingCorrections: async (): Promise<StockCorrectionItem[]> =>
    (await api.get<StockCorrectionItem[]>('/ertektar/corrections/pending')).data,
  createCorrection: async (data: StockCorrectionRequest): Promise<StockCorrectionItem> =>
    (await api.post<StockCorrectionItem>('/ertektar/corrections', data)).data,
  approveCorrection: async (id: number): Promise<StockCorrectionItem> =>
    (await api.post<StockCorrectionItem>(`/ertektar/corrections/${id}/approve`)).data,
  rejectCorrection: async (id: number): Promise<StockCorrectionItem> =>
    (await api.post<StockCorrectionItem>(`/ertektar/corrections/${id}/reject`)).data,
  getCollections: async (): Promise<ErtektarCollection[]> =>
    (await api.get<ErtektarCollection[]>('/ertektar/collections')).data,
  createCollection: async (data: {
    sourceBranchCode: string
    currencyCode: string
    amount: number
    note?: string
  }): Promise<ErtektarCollection> =>
    (await api.post<ErtektarCollection>('/ertektar/collections', data)).data,
  updateCollectionStatus: async (
    id: number,
    status: VaultOperationStatus,
  ): Promise<ErtektarCollection> =>
    (
      await api.patch<ErtektarCollection>(`/ertektar/collections/${id}/status`, null, {
        params: { status },
      })
    ).data,
  getDistributions: async (): Promise<ErtektarDistribution[]> =>
    (await api.get<ErtektarDistribution[]>('/ertektar/distribution')).data,
  createDistribution: async (data: {
    items: Array<{ targetBranchCode: string; currencyCode: string; amount: number }>
    note?: string
  }): Promise<ErtektarDistribution> =>
    (await api.post<ErtektarDistribution>('/ertektar/distribution', data)).data,
  updateDistributionStatus: async (
    id: number,
    status: VaultOperationStatus,
  ): Promise<ErtektarDistribution> =>
    (
      await api.patch<ErtektarDistribution>(`/ertektar/distribution/${id}/status`, null, {
        params: { status },
      })
    ).data,
  getVatRefunds: async (from?: string, to?: string): Promise<VatRefundItem[]> => {
    const params = new URLSearchParams()
    if (from) params.set('from', from)
    if (to) params.set('to', to)
    const qs = params.toString()
    return (await api.get<VatRefundItem[]>(`/vat-refund${qs ? `?${qs}` : ''}`)).data
  },
  getVatRefund: async (id: number): Promise<VatRefundItem> =>
    (await api.get<VatRefundItem>(`/vat-refund/${id}`)).data,
  getDailyVatRefunds: async (date?: string): Promise<VatRefundItem[]> => {
    const params = date ? { date } : undefined
    return (await api.get<VatRefundItem[]>('/vat-refund/daily', { params })).data
  },
  createVatRefund: async (data: VatRefundRequest): Promise<VatRefundItem> =>
    (await api.post<VatRefundItem>('/vat-refund', data)).data,
  stornoVatRefund: async (id: number): Promise<VatRefundItem> =>
    (await api.post<VatRefundItem>(`/vat-refund/${id}/reverse`, {})).data,
}

// ================== ÁFA VISSZATÉRÍTÉS ==================

/** Bizonylat típus — backend enum: AK=külföldi, AB=céges, AV=Innova */
export type VatRefundType = 'AK' | 'AB' | 'AV'

export interface VatRefundItem {
  id: number
  companyId: string
  voucherType: VatRefundType
  serialNumber: string
  transactionDate: string
  transactionTime?: string
  mainUnit?: number
  supplyAmount?: number
  grossAmount: number
  vatAmount: number
  vatPercentage?: number
  customerName?: string
  customerAddress?: string
  customerIdentifier?: string
  bankAccountNumber?: string
  companyName?: string
  siteAddress?: string
  deedNumber?: string
  isReversed: boolean
  originalTransactionId?: number
  createdByWorker?: string
  createdAt: string
}

export interface VatRefundRequest {
  voucherType: VatRefundType
  grossAmount: number
  vatAmount: number
  vatPercentage?: number
  mainUnit?: number
  supplyAmount?: number
  customerName?: string
  customerAddress?: string
  customerIdentifier?: string
  bankAccountNumber?: string
  companyName?: string
  siteAddress?: string
  deedNumber?: string
}

// ================== DAYBOOK API ==================
// FKH-027 FR-8 (9.1/6.): a `downloadPdf` kliens-metódus törölve — a Naplókönyv
// nyomtatása böngészős `window.print()`-tel megy (DaybookPage), nincs PDF-letöltés.
// A backend `/daybook/{branchId}/{date}/pdf` végpont SZÁNDÉKOSAN megmarad (TBD-1).
export const dailyReportApi = {
  get: async (branchId: string, date: string) =>
    (await api.get(`/daybook/${branchId}/${date}`)).data,
}

// ================== CASH FLOW REPORT API (FKH-030) ==================
// A terület-szűrést a BACKEND alkalmazza (AccessScopeService) — a kliens SOHA nem
// küld scope-ot, így nem is tágíthatja (FR-9, biztonsági követelmény).
export interface CashFlowReportRow {
  date: string
  receiptNumber: string
  partnerCode: string | null
  partnerCategory: string
  currency: string | null
  receivedAmount: number | null
  handedOverAmount: number | null
  storno: boolean
}

export interface CashFlowReport {
  from: string
  to: string
  rows: CashFlowReportRow[]
}

export const cashFlowReportApi = {
  get: async (from: string, to: string): Promise<CashFlowReport> =>
    (await api.get('/reports/cash-flow', { params: { from, to } })).data,
}

// ================== TURNOVER API ==================
export const turnoverApi = {
  byPeriod: async (period: string, branchId: string, date: string) => {
    if (period === 'daily') {
      return (await api.get('/turnover/daily', { params: { branchId, date } })).data
    }
    if (period === 'weekly') {
      const weekStart = startOfIsoWeek(date)
      return (await api.get('/turnover/weekly', { params: { branchId, weekStart } })).data
    }
    if (period === 'monthly') {
      const { year, month } = parseYearMonthParams(date)
      return (await api.get('/turnover/monthly', { params: { branchId, year, month } })).data
    }
    if (period === 'yearly') {
      const year = parseYearParam(date)
      return (await api.get('/turnover/yearly', { params: { branchId, year } })).data
    }
    throw new Error(`Unsupported turnover period: ${period}`)
  },
  company: async (from: string, to: string) =>
    (await api.get('/turnover/company', { params: { from, to } })).data,
  // FK-045 FR-9: területi (vault_territory) összesített forgalom. A vaultTerritoryId Integer
  // (a backend Branch.vaultTerritoryId típusa), a companyId szerveroldalon a JWT-ből.
  territory: async (vaultTerritoryId: number, from: string, to: string) =>
    (await api.get('/turnover/territory', { params: { vaultTerritoryId, from, to } })).data,
  // FK-045 FR-2/FR-3: pénztár forgalma tetszőleges dátumtartományra (a /daily csak 1 napot adott).
  branchRange: async (branchId: string, from: string, to: string) =>
    (await api.get('/turnover/branch-range', { params: { branchId, from, to } })).data,
}

function parseYearParam(date: string): number {
  return parseIsoDateParts(date).year
}

function parseYearMonthParams(date: string): { year: number; month: number } {
  const { year, month } = parseIsoDateParts(date)
  return { year, month }
}

function startOfIsoWeek(date: string): string {
  const { year, month, day } = parseIsoDateParts(date)
  const utc = new Date(Date.UTC(year, month - 1, day))
  const weekday = utc.getUTCDay() || 7
  utc.setUTCDate(utc.getUTCDate() - weekday + 1)
  return utc.toISOString().slice(0, 10)
}

function parseIsoDateParts(date: string): { year: number; month: number; day: number } {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date)
  if (!match) {
    throw new Error(`Invalid turnover date: ${date}`)
  }
  const year = Number(match[1])
  const month = Number(match[2])
  const day = Number(match[3])
  const parsed = new Date(Date.UTC(year, month - 1, day))
  if (
    parsed.getUTCFullYear() !== year ||
    parsed.getUTCMonth() !== month - 1 ||
    parsed.getUTCDate() !== day
  ) {
    throw new Error(`Invalid turnover date: ${date}`)
  }
  return { year, month, day }
}

// ================== EVENING CLOSING API ==================
export const eveningClosingApi = {
  preview: async (branchId: string, date: string) =>
    (await api.get(`/evening-closing/${branchId}/${date}/preview`)).data,
  send: async (branchId: string, date: string) =>
    (await api.post(`/evening-closing/${branchId}/${date}/send`)).data,
  report: async (branchId: string, date: string) =>
    (await api.get(`/evening-closing/${branchId}/${date}/report`)).data,
}

// ================== DAILY CHECKLIST API ==================
export const dailyChecklistApi = {
  get: async (branchId: string, date: string) =>
    (await api.get(`/daily-checklist/${branchId}/${date}`)).data,
  updateItem: async (checklistId: string, itemNumber: number, data: Record<string, unknown>) =>
    (await api.put(`/daily-checklist/${checklistId}/items/${itemNumber}`, data)).data,
  complete: async (checklistId: string) =>
    (await api.post(`/daily-checklist/${checklistId}/complete`)).data,
  status: async (branchId: string, date: string) =>
    (await api.get(`/daily-checklist/${branchId}/${date}/status`)).data,
}
