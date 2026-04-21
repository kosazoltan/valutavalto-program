import { api } from './client'

// ================== BRANCH API ==================

export interface BranchInfo {
  id: string
  code: string
  name: string
  companyId?: string
  city?: string
  isActive?: boolean
}

export const branchApi = {
  list: async (): Promise<BranchInfo[]> => {
    const response = await api.get<BranchInfo[]>('/branches')
    return response.data
  },
  listActive: async (): Promise<BranchInfo[]> => {
    const response = await api.get<BranchInfo[]>('/branches?activeOnly=true')
    return response.data
  },
  getById: async (id: string): Promise<BranchInfo> => {
    const response = await api.get<BranchInfo>(`/branches/${id}`)
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

export const systemParameterApi = {
  list: async (): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>('/system-parameters')
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
  update: async (id: string, data: Partial<SystemParameterCreateRequest>): Promise<SystemParameter> => {
    const response = await api.put<SystemParameter>(`/system-parameters/${id}`, data)
    return response.data
  },
  toggleActive: async (id: string): Promise<SystemParameter> => {
    const response = await api.post<SystemParameter>(`/system-parameters/${id}/toggle-active`)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/system-parameters/${id}`)
  }
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

export interface UpdateDenominationRequest {
  currencyId: number
  faceValue: number
  quantity: number
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
  update: async (data: UpdateDenominationRequest): Promise<Denomination> => {
    const response = await api.put<Denomination>('/denominations', data)
    return response.data
  },
  bulkUpdate: async (data: UpdateDenominationRequest[]): Promise<Denomination[]> => {
    const response = await api.put<Denomination[]>('/denominations/bulk', data)
    return response.data
  },
  validate: async (currencyId: number, expectedBalance: number): Promise<DenominationValidationResult> => {
    const response = await api.post<DenominationValidationResult>('/denominations/validate', null, {
      params: { currencyId, expectedBalance }
    })
    return response.data
  },
  getSummary: async (currencyId: number): Promise<DenominationSummary> => {
    const response = await api.get<DenominationSummary>(`/denominations/summary/${currencyId}`)
    return response.data
  },
  getOptimalChange: async (currencyId: number, amount: number): Promise<Record<number, number>> => {
    const response = await api.get<Record<number, number>>('/denominations/optimal-change', {
      params: { currencyId, amount }
    })
    return response.data
  }
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

export const denominationBalanceApi = {
  getCashDeskDenominations: async (cashDeskId: string): Promise<DenominationBalanceDTO[]> => {
    const response = await api.get<DenominationBalanceDTO[]>(`/cash-desks/${cashDeskId}/denominations`)
    return response.data
  },
  getCashDeskDenominationsByCurrency: async (cashDeskId: string, currencyId: string): Promise<DenominationBalanceDTO[]> => {
    const response = await api.get<DenominationBalanceDTO[]>(`/cash-desks/${cashDeskId}/denominations/currency/${currencyId}`)
    return response.data
  },
  updateDenominationQuantity: async (cashDeskId: string, denominationId: string, quantity: number): Promise<DenominationBalanceDTO> => {
    const response = await api.put<DenominationBalanceDTO>(
      `/cash-desks/${cashDeskId}/denominations/${denominationId}`,
      null,
      { params: { quantity } }
    )
    return response.data
  },
  setDenominationQuantities: async (cashDeskId: string, updates: DenominationQuantityUpdateRequest[]): Promise<DenominationBalanceDTO[]> => {
    const response = await api.post<DenominationBalanceDTO[]>(`/cash-desks/${cashDeskId}/denominations/batch`, updates)
    return response.data
  },
  calculateTotalFromDenominations: async (cashDeskId: string, currencyId: string): Promise<number> => {
    const response = await api.get<number>(`/cash-desks/${cashDeskId}/denominations/currency/${currencyId}/total`)
    return response.data
  }
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
  getByWorker: async (workerId: string): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>(`/worker-commissions/worker/${workerId}`)
    return response.data
  },
  getByPeriod: async (startDate: string, endDate: string): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>('/worker-commissions/period', {
      params: { startDate, endDate }
    })
    return response.data
  },
  calculate: async (workerId: string, calculatedByWorkerId: string, periodStart: string, periodEnd: string, branchId?: string): Promise<WorkerCommission> => {
    const response = await api.post<WorkerCommission>('/worker-commissions/calculate', null, {
      params: { workerId, calculatedByWorkerId, periodStart, periodEnd, branchId }
    })
    return response.data
  },
  approve: async (commissionId: string, approvedByWorkerId: string): Promise<WorkerCommission> => {
    const response = await api.post<WorkerCommission>(`/worker-commissions/${commissionId}/approve`, null, {
      params: { approvedByWorkerId }
    })
    return response.data
  },
  getAccountingList: async (periodStart: string, periodEnd: string): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>('/worker-commissions/accounting-list', {
      params: { periodStart, periodEnd }
    })
    return response.data
  }
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
  getByBranch: async (branchId: string): Promise<Workstation[]> => {
    const response = await api.get<Workstation[]>(`/workstations/branch/${branchId}`)
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
  }
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
  getByWorker: async (workerId: string): Promise<Contribution[]> => {
    const response = await api.get<Contribution[]>(`/contributions/worker/${workerId}`)
    return response.data
  },
  getByPeriod: async (startDate: string, endDate: string): Promise<Contribution[]> => {
    const response = await api.get<Contribution[]>('/contributions/period', { params: { startDate, endDate } })
    return response.data
  },
  calculate: async (workerId: string, periodStart: string, periodEnd: string, calculatedByWorkerId: string, branchId?: string): Promise<Contribution> => {
    const response = await api.post<Contribution>('/contributions/calculate', null, {
      params: { workerId, periodStart, periodEnd, calculatedByWorkerId, branchId }
    })
    return response.data
  },
  approve: async (contributionId: string, approvedByWorkerId: string): Promise<Contribution> => {
    const response = await api.post<Contribution>(`/contributions/${contributionId}/approve`, null, { params: { approvedByWorkerId } })
    return response.data
  },
  update: async (id: string, data: Partial<Contribution>): Promise<Contribution> => {
    const response = await api.put<Contribution>(`/contributions/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/contributions/${id}`)
  }
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
  getActive: async (): Promise<Organization[]> => (await api.get<Organization[]>('/organizations/active')).data,
  getRoots: async (): Promise<Organization[]> => (await api.get<Organization[]>('/organizations/root')).data,
  getById: async (id: string): Promise<Organization> => (await api.get<Organization>(`/organizations/${id}`)).data,
  create: async (data: Partial<Organization>): Promise<Organization> => (await api.post<Organization>('/organizations', data)).data,
  update: async (id: string, data: Partial<Organization>): Promise<Organization> => (await api.put<Organization>(`/organizations/${id}`, data)).data,
  archive: async (id: string): Promise<void> => { await api.post(`/organizations/${id}/archive`) },
  delete: async (id: string): Promise<void> => { await api.delete(`/organizations/${id}`) },
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

export const ownCompanyApi = {
  list: async (): Promise<OwnCompany[]> => (await api.get<OwnCompany[]>('/own-companies')).data,
  getActive: async (): Promise<OwnCompany[]> => (await api.get<OwnCompany[]>('/own-companies/active')).data,
  getById: async (id: string): Promise<OwnCompany> => (await api.get<OwnCompany>(`/own-companies/${id}`)).data,
  create: async (data: Partial<OwnCompany>): Promise<OwnCompany> => (await api.post<OwnCompany>('/own-companies', data)).data,
  update: async (id: string, data: Partial<OwnCompany>): Promise<OwnCompany> => (await api.put<OwnCompany>(`/own-companies/${id}`, data)).data,
  delete: async (id: string): Promise<void> => { await api.delete(`/own-companies/${id}`) },
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
  getActive: async (): Promise<BranchGroup[]> => (await api.get<BranchGroup[]>('/branch-groups/active')).data,
  getRoots: async (): Promise<BranchGroup[]> => (await api.get<BranchGroup[]>('/branch-groups/roots')).data,
  getById: async (id: string): Promise<BranchGroup> => (await api.get<BranchGroup>(`/branch-groups/${id}`)).data,
  create: async (data: Partial<BranchGroup>, workerId: string): Promise<BranchGroup> => (await api.post<BranchGroup>('/branch-groups', data, { params: { workerId } })).data,
  update: async (id: string, data: Partial<BranchGroup>): Promise<BranchGroup> => (await api.put<BranchGroup>(`/branch-groups/${id}`, data)).data,
  delete: async (id: string): Promise<void> => { await api.delete(`/branch-groups/${id}`) },
}

export interface FeeType { id: string; code: string; name: string; description?: string; calculationMethod: string; isActive: boolean }
export interface FeeRate { id: string; feeTypeId: string; feeTypeName?: string; currencyId?: string; currencyCode?: string; branchId?: string; branchName?: string; minAmount?: number; maxAmount?: number; rate: number; fixedAmount?: number; validFrom: string; validTo?: string; isActive: boolean }
export interface FeeDiscount { id: string; code: string; name: string; discountType: string; discountValue: number; minTransactionAmount?: number; validFrom: string; validTo?: string; isActive: boolean }

export const feeApi = {
  getTypes: async (): Promise<FeeType[]> => (await api.get<FeeType[]>('/fees/types')).data,
  createType: async (data: Partial<FeeType>): Promise<FeeType> => (await api.post<FeeType>('/fees/types', data)).data,
  updateType: async (id: string, data: Partial<FeeType>): Promise<FeeType> => (await api.put<FeeType>(`/fees/types/${id}`, data)).data,
  deleteType: async (id: string): Promise<void> => { await api.delete(`/fees/types/${id}`) },
  getRates: async (): Promise<FeeRate[]> => (await api.get<FeeRate[]>('/fees/rates')).data,
  createRate: async (data: Partial<FeeRate>): Promise<FeeRate> => (await api.post<FeeRate>('/fees/rates', data)).data,
  updateRate: async (id: string, data: Partial<FeeRate>): Promise<FeeRate> => (await api.put<FeeRate>(`/fees/rates/${id}`, data)).data,
  deleteRate: async (id: string): Promise<void> => { await api.delete(`/fees/rates/${id}`) },
  getDiscounts: async (): Promise<FeeDiscount[]> => (await api.get<FeeDiscount[]>('/fees/discounts')).data,
  createDiscount: async (data: Partial<FeeDiscount>): Promise<FeeDiscount> => (await api.post<FeeDiscount>('/fees/discounts', data)).data,
  updateDiscount: async (id: string, data: Partial<FeeDiscount>): Promise<FeeDiscount> => (await api.put<FeeDiscount>(`/fees/discounts/${id}`, data)).data,
  deleteDiscount: async (id: string): Promise<void> => { await api.delete(`/fees/discounts/${id}`) },
}

export interface ProhibitedPerson { id: string; fullName: string; documentNumber?: string; identityNumber?: string; passportNumber?: string; dateOfBirth?: string; nationality?: string; listType: string; listSource: string; reason?: string; isActive: boolean }
export interface ProhibitedCompany { id: string; companyName: string; taxNumber?: string; registrationNumber?: string; listType: string; listSource: string; reason?: string; isActive: boolean }

export const blacklistApi = {
  getPersons: async (): Promise<ProhibitedPerson[]> => (await api.get<ProhibitedPerson[]>('/blacklist/persons')).data,
  createPerson: async (data: Partial<ProhibitedPerson>): Promise<ProhibitedPerson> => (await api.post<ProhibitedPerson>('/blacklist/persons', data)).data,
  updatePerson: async (id: string, data: Partial<ProhibitedPerson>): Promise<ProhibitedPerson> => (await api.put<ProhibitedPerson>(`/blacklist/persons/${id}`, data)).data,
  deletePerson: async (id: string): Promise<void> => { await api.delete(`/blacklist/persons/${id}`) },
  getCompanies: async (): Promise<ProhibitedCompany[]> => (await api.get<ProhibitedCompany[]>('/blacklist/companies')).data,
  createCompany: async (data: Partial<ProhibitedCompany>): Promise<ProhibitedCompany> => (await api.post<ProhibitedCompany>('/blacklist/companies', data)).data,
  updateCompany: async (id: string, data: Partial<ProhibitedCompany>): Promise<ProhibitedCompany> => (await api.put<ProhibitedCompany>(`/blacklist/companies/${id}`, data)).data,
  deleteCompany: async (id: string): Promise<void> => { await api.delete(`/blacklist/companies/${id}`) },
  importPersons: async (file: File): Promise<void> => { const formData = new FormData(); formData.append('file', file); await api.post('/blacklist/persons/import', formData, { headers: { 'Content-Type': 'multipart/form-data' } }) },
  importCompanies: async (file: File): Promise<void> => { const formData = new FormData(); formData.append('file', file); await api.post('/blacklist/companies/import', formData, { headers: { 'Content-Type': 'multipart/form-data' } }) },
}

// ================== OTHER SETTINGS / OPS API ==================

export interface CommissionRate { id: string; entityType: string; entityId?: string; entityName?: string; currencyId?: string; currencyCode?: string; rate: number; validFrom: string; validTo?: string; isActive: boolean }
export const commissionRateApi = {
  list: async (): Promise<CommissionRate[]> => (await api.get<CommissionRate[]>('/commission-rates')).data,
  getById: async (id: string): Promise<CommissionRate> => (await api.get<CommissionRate>(`/commission-rates/${id}`)).data,
  create: async (data: Partial<CommissionRate>): Promise<CommissionRate> => (await api.post<CommissionRate>('/commission-rates', data)).data,
  update: async (id: string, data: Partial<CommissionRate>): Promise<CommissionRate> => (await api.put<CommissionRate>(`/commission-rates/${id}`, data)).data,
  delete: async (id: string): Promise<void> => { await api.delete(`/commission-rates/${id}`) },
}

export interface ArchiveTask { id: string; taskType: string; entityType: string; criteria: Record<string, unknown>; status: string; startedAt?: string; completedAt?: string; archiveLocation?: string }
export const archivingApi = {
  listTasks: async (): Promise<ArchiveTask[]> => (await api.get<ArchiveTask[]>('/archiving/tasks')).data,
  createTask: async (data: Partial<ArchiveTask>): Promise<ArchiveTask> => (await api.post<ArchiveTask>('/archiving/tasks', data)).data,
  executeTask: async (id: string): Promise<ArchiveTask> => (await api.post<ArchiveTask>(`/archiving/tasks/${id}/execute`)).data,
  monthlyArchive: async (branchId: string, yearMonth: string) => (await api.post('/archiving/monthly', null, { params: { branchId, yearMonth } })).data,
  getMonthlyStatus: async (branchId: string, yearMonth: string) => (await api.get(`/archiving/monthly/${branchId}/${yearMonth}/status`)).data,
}

export interface Reservation {
  id: string
  customerId?: string
  customerName?: string
  currencyCode: string
  amount: number
  reservationType: string
  reservationDate: string
  expiryDate?: string
  status: string
  branchId?: string
  branchName?: string
  notes?: string
  createdAt: string
}
export interface CreateReservationRequest {
  customerId?: string
  customerName?: string
  currencyCode: string
  amount: number
  reservationType: string
  expiryDate?: string
  notes?: string
}

export const reservationsApi = {
  create: async (data: CreateReservationRequest): Promise<Reservation> => (await api.post<Reservation>('/reservations', data)).data,
  getById: async (id: string): Promise<Reservation> => (await api.get<Reservation>(`/reservations/${id}`)).data,
  list: async (params?: { status?: string; customerId?: string }): Promise<Reservation[]> => (await api.get<Reservation[]>('/reservations', { params })).data,
  cancel: async (id: string): Promise<Reservation> => (await api.post<Reservation>(`/reservations/${id}/cancel`)).data,
  fulfill: async (id: string, transactionId: string): Promise<Reservation> => (await api.post<Reservation>(`/reservations/${id}/fulfill`, null, { params: { transactionId } })).data,
}

export interface SynchronizationResult { success: boolean; recordsSynced: number; errors: string[] }
export const synchronizationApi = {
  synchronize: async (branchId: string, workerId: string, options?: { direction?: string; entityTypes?: string[] }): Promise<SynchronizationResult> => (await api.post<SynchronizationResult>('/synchronization/sync', options || null, { params: { branchId, workerId } })).data,
  shouldSync: async (): Promise<{ shouldSync: boolean; pendingCount: number }> => (await api.get<{ shouldSync: boolean; pendingCount: number }>('/synchronization/should-sync')).data,
  shouldAutoSync: async (branchId: string): Promise<boolean> => (await api.get<boolean>('/synchronization/should-sync', { params: { branchId } })).data,
  getLogs: async (): Promise<unknown[]> => {
    try { return (await api.get<unknown[]>('/synchronization/logs')).data } catch { return [] }
  },
}

export interface PosTerminal { id: string; terminalId: string; terminalName: string; branchId?: string; branchName?: string; isActive: boolean; lastTransactionAt?: string; connectionType?: string; comPort?: string; baudRate?: number; ipAddress?: string; port?: number }
export const posTerminalApi = {
  list: async (): Promise<PosTerminal[]> => (await api.get<PosTerminal[]>('/pos-terminal')).data,
  getById: async (id: string): Promise<PosTerminal> => (await api.get<PosTerminal>(`/pos-terminal/${id}`)).data,
  create: async (data: Partial<PosTerminal>): Promise<PosTerminal> => (await api.post<PosTerminal>('/pos-terminal', data)).data,
  update: async (id: string, data: Partial<PosTerminal>): Promise<PosTerminal> => (await api.put<PosTerminal>(`/pos-terminal/${id}`, data)).data,
  delete: async (id: string): Promise<void> => { await api.delete(`/pos-terminal/${id}`) },
  testConnection: async (id: string): Promise<{ success: boolean; message?: string }> => (await api.post<{ success: boolean; message?: string }>(`/pos-terminal/${id}/test`)).data,
  processTransaction: async (terminalId: string, amount: number, currency: string): Promise<Record<string, unknown>> => (await api.post('/pos-terminal/process-transaction', null, { params: { terminalId, amount, currency } })).data,
}

export interface NavSendResult { success: boolean; receiptNumber?: string; error?: string }
export const navIntegrationApi = {
  sendTransaction: async (transactionId: string, comPort: string): Promise<NavSendResult> => (await api.post<NavSendResult>('/nav-integration/send-transaction', null, { params: { transactionId, comPort } })).data,
  receiveReceiptNumber: async (comPort: string): Promise<string> => (await api.get<string>('/nav-integration/receive-receipt-number', { params: { comPort } })).data,
  sendQrCode: async (qrCode: string, comPort: string): Promise<boolean> => (await api.post<boolean>('/nav-integration/send-qr-code', null, { params: { qrCode, comPort } })).data,
  getStatus: async (branchId: string) => (await api.get(`/nav-integration/status`, { params: { branchId } })).data,
  retryFailed: async (branchId: string) => (await api.post('/nav-integration/retry-failed', null, { params: { branchId } })).data,
}

export interface Document { id: string; fileName: string; fileType: string; fileSize: number; entityType?: string; entityId?: string; uploadedAt: string; uploadedById?: string; uploadedByName?: string }
export const documentStorageApi = {
  list: async (entityType?: string, entityId?: string): Promise<Document[]> => {
    const params: Record<string, string> = {}
    if (entityType) params.entityType = entityType
    if (entityId) params.entityId = entityId
    return (await api.get<Document[]>('/documents', { params })).data
  },
  upload: async (file: File, entityType?: string, entityId?: string): Promise<Document> => {
    const formData = new FormData(); formData.append('file', file)
    if (entityType) formData.append('entityType', entityType)
    if (entityId) formData.append('entityId', entityId)
    return (await api.post<Document>('/documents', formData, { headers: { 'Content-Type': 'multipart/form-data' } })).data
  },
  download: async (id: string): Promise<Blob> => (await api.get(`/documents/${id}/download`, { responseType: 'blob' })).data,
  delete: async (id: string): Promise<void> => { await api.delete(`/documents/${id}`) },
}

export interface Notification { id: string; title: string; message: string; type: string; userId?: string; isRead: boolean; createdAt: string }
export const notificationApi = {
  list: async (): Promise<Notification[]> => (await api.get<Notification[]>('/notifications')).data,
  getUnread: async (): Promise<Notification[]> => (await api.get<Notification[]>('/notifications/unread')).data,
  unreadCount: async (): Promise<number> => (await api.get<number>('/notifications/unread-count')).data,
  markAsRead: async (id: string): Promise<void> => { await api.post(`/notifications/${id}/mark-read`) },
  markAllAsRead: async (): Promise<void> => { await api.post('/notifications/mark-all-read') },
  send: async (data: Record<string, unknown>): Promise<Notification> => (await api.post<Notification>('/notifications/send', data)).data,
  broadcast: async (data: Record<string, unknown>): Promise<void> => { await api.post('/notifications/broadcast', data) },
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
    return (await api.get<OrganizationalSystemParameter[]>('/organizational-system-parameters', { params })).data
  },
  getById: async (id: string): Promise<OrganizationalSystemParameter> => (await api.get<OrganizationalSystemParameter>(`/organizational-system-parameters/${id}`)).data,
  create: async (data: Partial<OrganizationalSystemParameter>): Promise<OrganizationalSystemParameter> => (await api.post<OrganizationalSystemParameter>('/organizational-system-parameters', data)).data,
  update: async (id: string, data: Partial<OrganizationalSystemParameter>): Promise<OrganizationalSystemParameter> => (await api.put<OrganizationalSystemParameter>(`/organizational-system-parameters/${id}`, data)).data,
  delete: async (id: string): Promise<void> => { await api.delete(`/organizational-system-parameters/${id}`) },
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
  getActive: async (cashDeskId: string): Promise<CashDeskBreak | null> => (await api.get<CashDeskBreak>(`/cash-desk-breaks/active/${cashDeskId}`)).data,
  start: async (cashDeskId: string, breakType: string, reason?: string): Promise<CashDeskBreak> => (await api.post<CashDeskBreak>('/cash-desk-breaks/start', null, { params: { cashDeskId, breakType, reason } })).data,
  end: async (breakId: string): Promise<CashDeskBreak> => (await api.post<CashDeskBreak>(`/cash-desk-breaks/${breakId}/end`)).data,
}

// ================== CAMERA EXPORT API ==================

export interface CameraExportRequest {
  id: string; branchId: string; cameraId?: string
  periodFrom: string; periodTo: string; reason: string; referenceNumber?: string
  status: string; requestedBy: string; createdAt: string
  approvedBy?: string; approvedAt?: string; rejectionReason?: string
  exportPath?: string; exportSizeBytes?: number; manifestHash?: string; completedAt?: string; errorMessage?: string
}

export interface ChainOfCustodyRecord {
  id: string; exportRequestId?: string; branchId: string; cameraId?: string
  eventType: string; actor: string; eventTimestamp: string; details?: string
  periodFrom?: string; periodTo?: string; manifestHash?: string
}

export const cameraExportApi = {
  createRequest: (p: { branchId: string; cameraId?: string; from: string; to: string; reason: string; referenceNumber?: string }) =>
    api.post<CameraExportRequest>('/camera/export/request', null, { params: { ...p } }),
  approve: (id: string) => api.post<CameraExportRequest>(`/camera/export/${id}/approve`),
  reject: (id: string, reason: string) => api.post<CameraExportRequest>(`/camera/export/${id}/reject?reason=${encodeURIComponent(reason)}`),
  execute: (id: string) => api.post<CameraExportRequest>(`/camera/export/${id}/execute`),
  getById: (id: string) => api.get<CameraExportRequest>(`/camera/export/${id}`),
  getPending: () => api.get<CameraExportRequest[]>('/camera/export/pending'),
  getByBranch: (branchId: string) => api.get<CameraExportRequest[]>(`/camera/export/branch/${branchId}`),
  getCustody: (id: string) => api.get<ChainOfCustodyRecord[]>(`/camera/export/${id}/custody`),
  verifyChain: (branchId: string, cameraId: string) =>
    api.post<{ branchId: string; cameraId: string; chainIntact: boolean; verifiedAt: string }>('/camera/export/verify-chain', null, { params: { branchId, cameraId } }),
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
  getBankTransactions: async (): Promise<BankTransaction[]> => (await api.get<BankTransaction[]>('/ertektar/bank-transactions')).data,
  getBankTransactionsByType: async (type: string): Promise<BankTransaction[]> => (await api.get<BankTransaction[]>('/ertektar/bank-transactions/by-type', { params: { type } })).data,
  createBankTransaction: async (data: BankTransactionRequest): Promise<BankTransaction> => (await api.post<BankTransaction>('/ertektar/bank-transactions', data)).data,
  confirmBankTransactionReceived: async (id: number): Promise<BankTransaction> => (await api.post<BankTransaction>(`/ertektar/bank-transactions/${id}/confirm-received`)).data,
  confirmBankTransactionPaid: async (id: number): Promise<BankTransaction> => (await api.post<BankTransaction>(`/ertektar/bank-transactions/${id}/confirm-paid`)).data,
  getTransfers: async (): Promise<VaultTransferItem[]> => (await api.get<VaultTransferItem[]>('/ertektar/transfers')).data,
  getPendingTransfers: async (): Promise<VaultTransferItem[]> => (await api.get<VaultTransferItem[]>('/ertektar/transfers/pending')).data,
  createTransfer: async (data: VaultTransferRequest): Promise<VaultTransferItem> => (await api.post<VaultTransferItem>('/ertektar/transfers', data)).data,
  supervisorApproveTransfer: async (id: number): Promise<VaultTransferItem> => (await api.post<VaultTransferItem>(`/ertektar/transfers/${id}/supervisor-approve`)).data,
  completeTransfer: async (id: number): Promise<VaultTransferItem> => (await api.post<VaultTransferItem>(`/ertektar/transfers/${id}/complete`)).data,
  rejectTransfer: async (id: number): Promise<VaultTransferItem> => (await api.post<VaultTransferItem>(`/ertektar/transfers/${id}/reject`)).data,
  getReceipts: async (): Promise<MaterialReceiptItem[]> => (await api.get<MaterialReceiptItem[]>('/ertektar/receipts')).data,
  getReceiptsByType: async (type: string): Promise<MaterialReceiptItem[]> => (await api.get<MaterialReceiptItem[]>('/ertektar/receipts/by-type', { params: { type } })).data,
  createReceipt: async (data: MaterialReceiptRequest): Promise<MaterialReceiptItem> => (await api.post<MaterialReceiptItem>('/ertektar/receipts', data)).data,
  finalizeReceipt: async (id: number): Promise<MaterialReceiptItem> => (await api.post<MaterialReceiptItem>(`/ertektar/receipts/${id}/finalize`)).data,
  getCorrections: async (): Promise<StockCorrectionItem[]> => (await api.get<StockCorrectionItem[]>('/ertektar/corrections')).data,
  getPendingCorrections: async (): Promise<StockCorrectionItem[]> => (await api.get<StockCorrectionItem[]>('/ertektar/corrections/pending')).data,
  createCorrection: async (data: StockCorrectionRequest): Promise<StockCorrectionItem> => (await api.post<StockCorrectionItem>('/ertektar/corrections', data)).data,
  approveCorrection: async (id: number): Promise<StockCorrectionItem> => (await api.post<StockCorrectionItem>(`/ertektar/corrections/${id}/approve`)).data,
  rejectCorrection: async (id: number): Promise<StockCorrectionItem> => (await api.post<StockCorrectionItem>(`/ertektar/corrections/${id}/reject`)).data,
  getCollections: async () => (await api.get('/ertektar/collections')).data,
  createCollection: async (data: { sourceBranchCode: string; currencyCode: string; amount: number; note?: string }) => (await api.post('/ertektar/collections', data)).data,
  getDistributions: async () => (await api.get('/ertektar/distribution')).data,
  createDistribution: async (data: { items: Array<{ targetBranchCode: string; currencyCode: string; amount: number }>; note?: string }) => (await api.post('/ertektar/distribution', data)).data,
  getVatRefunds: async (from?: string, to?: string): Promise<VatRefundItem[]> => {
    const params = new URLSearchParams()
    if (from) params.set('from', from)
    if (to) params.set('to', to)
    const qs = params.toString()
    return (await api.get<VatRefundItem[]>(`/v1/vat-refund${qs ? `?${qs}` : ''}`)).data
  },
  createVatRefund: async (data: VatRefundRequest): Promise<VatRefundItem> => (await api.post<VatRefundItem>('/v1/vat-refund', data)).data,
  stornoVatRefund: async (id: number): Promise<VatRefundItem> => (await api.post<VatRefundItem>(`/v1/vat-refund/${id}/reverse`, {})).data,
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

// ================== DAILY REPORT / DAYBOOK API ==================
export const dailyReportApi = {
  get: async (branchId: string, date: string) => (await api.get(`/daily-reports/${branchId}/${date}`)).data,
  generate: async (branchId: string, date: string) => (await api.post(`/daily-reports/${branchId}/generate`, null, { params: { date } })).data,
  submit: async (reportId: string) => (await api.post(`/daily-reports/${reportId}/submit`)).data,
}

// ================== TURNOVER API ==================
export const turnoverApi = {
  daily: async (branchId: string, date: string) => (await api.get('/turnover/daily', { params: { branchId, date } })).data,
  weekly: async (branchId: string, date: string) => (await api.get('/turnover/weekly', { params: { branchId, date } })).data,
  monthly: async (branchId: string, date: string) => (await api.get('/turnover/monthly', { params: { branchId, date } })).data,
  yearly: async (branchId: string, date: string) => (await api.get('/turnover/yearly', { params: { branchId, date } })).data,
  byPeriod: async (period: string, branchId: string, date: string) => (await api.get(`/turnover/${period}`, { params: { branchId, date } })).data,
}

// ================== EVENING CLOSING API ==================
export const eveningClosingApi = {
  preview: async (branchId: string, date: string) => (await api.get(`/evening-closing/${branchId}/${date}/preview`)).data,
  send: async (branchId: string, date: string) => (await api.post(`/evening-closing/${branchId}/${date}/send`)).data,
  report: async (branchId: string, date: string) => (await api.get(`/evening-closing/${branchId}/${date}/report`)).data,
}

// ================== DAILY CHECKLIST API ==================
export const dailyChecklistApi = {
  get: async (branchId: string, date: string) => (await api.get(`/daily-checklist/${branchId}/${date}`)).data,
  updateItem: async (checklistId: string, itemNumber: number, data: Record<string, unknown>) => (await api.put(`/daily-checklist/${checklistId}/items/${itemNumber}`, data)).data,
  complete: async (checklistId: string) => (await api.post(`/daily-checklist/${checklistId}/complete`)).data,
  status: async (branchId: string, date: string) => (await api.get(`/daily-checklist/${branchId}/${date}/status`)).data,
}
