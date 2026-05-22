import { api } from './client'
import { asArray } from '../../utils/asArray'
import type { PagedResponse } from './client'
import { branchApi } from './settings'
import type { BranchInfo } from './settings'

// ================== CUSTOMERS API ==================

export interface Customer {
  id: number
  customerCode?: string
  name: string
  birthName?: string
  motherName?: string
  birthDate?: string
  birthPlace?: string
  nationality?: string
  documentNumber?: string
  documentType?: string
  documentExpiry?: string
  residence?: string
  addressCardNumber?: string
  address?: string
  postalCode?: string
  city?: string
  country?: string
  phone?: string
  email?: string
  isCompany: boolean
  companyName?: string
  taxNumber?: string
  registrationNumber?: string
  active: boolean
  isVip: boolean
  notes?: string
  lastTransactionDate?: string
  transactionCount: number
  createdAt: string
  updatedAt?: string
}

export interface CustomerCreateRequest {
  name: string
  birthName?: string
  motherName?: string
  birthDate?: string
  birthPlace?: string
  nationality?: string
  documentNumber?: string
  documentType?: string
  documentExpiry?: string
  residence?: string
  addressCardNumber?: string
  address?: string
  postalCode?: string
  city?: string
  country?: string
  phone?: string
  email?: string
  isCompany?: boolean
  companyName?: string
  taxNumber?: string
  registrationNumber?: string
  isVip?: boolean
  notes?: string
}

export const customerApi = {
  create: async (data: CustomerCreateRequest): Promise<Customer> => {
    const response = await api.post<Customer>('/customers', data)
    return response.data
  },
  update: async (id: number, data: CustomerCreateRequest): Promise<Customer> => {
    const response = await api.put<Customer>(`/customers/${id}`, data)
    return response.data
  },
  getById: async (id: number): Promise<Customer> => {
    const response = await api.get<Customer>(`/customers/${id}`)
    return response.data
  },
  getByDocumentNumber: async (documentNumber: string): Promise<Customer> => {
    const response = await api.get<Customer>(`/customers/document/${documentNumber}`)
    return response.data
  },
  getByCode: async (customerCode: string): Promise<Customer> => {
    const response = await api.get<Customer>(`/customers/code/${customerCode}`)
    return response.data
  },
  search: async (name: string): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers/search', { params: { name } })
    return response.data
  },
  getVip: async (): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers/vip')
    return response.data
  },
  getActive: async (): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers/active')
    return response.data
  },
  deactivate: async (id: number): Promise<void> => {
    await api.post(`/customers/${id}/deactivate`)
  },
  activate: async (id: number): Promise<void> => {
    await api.post(`/customers/${id}/activate`)
  }
}

// ================== TRANSACTIONS API ==================

/**
 * A tranzakció-típusok kanonikus union-ja (a backend TransactionType enum-jával
 * összhangban). Egyetlen forrás, hogy a Transaction.transactionType, a legacy
 * `type` alias és a list() szűrő ne driftelhessen szét (Sourcery/Copilot #780).
 */
export type TransactionTypeName =
  | 'BUY'
  | 'SELL'
  | 'REVERSAL'
  | 'CONVERSION'
  | 'TRANSFER_OUT'
  | 'TRANSFER_IN'

export interface Transaction {
  id: number
  receiptNumber: string
  transactionType: TransactionTypeName
  status: 'PENDING' | 'COMPLETED' | 'REVERSED'
  transactionDate: string
  transactionTime: string
  currencyId: number
  currencyCode: string
  currencyAmount: number
  exchangeRate: number
  hufAmount: number
  handlingFee: number
  discountAmount: number
  discountPercent: number
  customerId?: string
  customerName?: string
  customerAddress?: string
  customerDocumentNumber?: string
  customerDocType?: string
  customerNationality?: string
  customerMotherName?: string
  customerBirthPlace?: string
  customerBirthDate?: string
  roundedHufAmount?: number
  roundingDiff?: number
  originalTransactionId?: number
  reversalReason?: string
  approvedBy?: string
  notes?: string
  printed: boolean
  branchId: string
  branchName?: string
  workerId: number
  workerName?: string
  workerCode?: string  // 2026-04-29 v2.3.12 (E-B2): backend mar adja, hozzaadtuk a tipust audit display-hez
  createdAt: string
  // G3-G4: PEP + Jogcím nyilatkozat (Legacy Gap Fix)
  customerIsPep?: boolean
  sourceOfFunds?: string
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
  // Legacy compatibility aliases
  transactionNumber?: string // Same as receiptNumber
  type?: TransactionTypeName // Same as transactionType
  foreignAmount?: number // Same as currencyAmount
  fee?: number // Same as handlingFee
  total?: number // Same as hufAmount
  amount?: number // Same as currencyAmount
  rate?: number // Same as exchangeRate
  createdBy?: string // Same as workerName
}

export interface BuyRequest {
  currencyId?: number
  currencyCode?: string
  currencyAmount: number
  customExchangeRate?: number
  handlingFee?: number
  discountPercent?: number
  customerId?: string | number
  customerName?: string
  customerAddress?: string
  customerDocumentNumber?: string
  customerDocumentType?: string
  customerNationality?: string
  customerBirthPlace?: string
  customerBirthDate?: string
  customerMotherName?: string
  sourceOfFunds?: string
  customerIsPep?: boolean
  // V229 (2026-05-15 HIBA #8): 300k+ JOGCIM nyilatkozat
  customerOnOwnBehalf?: boolean
  customerActorName?: string
  // V235 (2026-05-19 HIBA #15 + #17): PEP minoseg + actor teljes azonositasa
  customerPepKind?: 'CSALADTAG' | 'KOZELI_MUNKATARS' | 'KORMANYFO' | 'PARLAMENTI' | 'NAV_VEZETO' | 'EGYEB'
  customerActorBirthPlace?: string
  customerActorBirthDate?: string
  customerActorMotherName?: string
  customerActorNationality?: string
  customerActorDocumentType?: string
  customerActorDocumentNumber?: string
  customerActorAddress?: string
  notes?: string
  cashierCustomRate?: boolean
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
}

export interface SellRequest {
  currencyId?: number
  currencyCode?: string
  currencyAmount: number
  customExchangeRate?: number
  handlingFee?: number
  discountPercent?: number
  customerId?: string | number
  customerName?: string
  customerAddress?: string
  customerDocumentNumber?: string
  customerDocumentType?: string
  customerNationality?: string
  customerBirthPlace?: string
  customerBirthDate?: string
  customerMotherName?: string
  sourceOfFunds?: string
  customerIsPep?: boolean
  // V229 (2026-05-15 HIBA #8): 300k+ JOGCIM nyilatkozat
  customerOnOwnBehalf?: boolean
  customerActorName?: string
  // V235 (2026-05-19 HIBA #15 + #17): PEP minoseg + actor teljes azonositasa
  customerPepKind?: 'CSALADTAG' | 'KOZELI_MUNKATARS' | 'KORMANYFO' | 'PARLAMENTI' | 'NAV_VEZETO' | 'EGYEB'
  customerActorBirthPlace?: string
  customerActorBirthDate?: string
  customerActorMotherName?: string
  customerActorNationality?: string
  customerActorDocumentType?: string
  customerActorDocumentNumber?: string
  customerActorAddress?: string
  notes?: string
  cashierCustomRate?: boolean
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
}

export interface CashierCustomRateQuota {
  used: number
  limit: number
  remaining: number
  minAmountHuf: number
}

export interface ReversalRequest {
  originalTransactionId: number
  reason: string
  approvedBy?: string
}

export interface ConversionRequest {
  fromCurrencyId?: number
  fromCurrencyCode?: string
  toCurrencyId?: number
  toCurrencyCode?: string
  fromAmount: number
  handlingFee?: number
  customerId?: string
  customerName?: string
  customerAddress?: string
  customerDocumentNumber?: string
  customerNationality?: string
  sourceOfFunds?: string
  customerIsPep?: boolean
  notes?: string
  // V235 + V236 (2026-05-19 HIBA #19): Konverzio Pmt. azonositas
  customerBirthPlace?: string
  customerBirthDate?: string
  customerMotherName?: string
  customerDocumentType?: string
  customerOnOwnBehalf?: boolean
  customerActorName?: string
  customerPepKind?: 'CSALADTAG' | 'KOZELI_MUNKATARS' | 'KORMANYFO' | 'PARLAMENTI' | 'NAV_VEZETO' | 'EGYEB'
  customerActorBirthPlace?: string
  customerActorBirthDate?: string
  customerActorMotherName?: string
  customerActorNationality?: string
  customerActorDocumentType?: string
  customerActorDocumentNumber?: string
  customerActorAddress?: string
}

export interface DailyTurnoverSummary {
  totalBuyCount: number
  totalSellCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  totalReversalCount: number
}

export const transactionApi = {
  list: async (params?: {
    branchId?: string
    startDate?: string
    endDate?: string
    type?: TransactionTypeName
    page?: number
    size?: number
  }): Promise<PagedResponse<Transaction>> => {
    const response = await api.get<PagedResponse<Transaction>>('/transactions', { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  getById: async (id: string | number): Promise<Transaction> => {
    // Get transaction by receipt number since we use that as primary lookup
    const response = await api.get<Transaction>(`/transactions/receipt/${id}`)
    return response.data
  },
  getByReceiptNumber: async (receiptNumber: string): Promise<Transaction> => {
    const response = await api.get<Transaction>(`/transactions/receipt/${receiptNumber}`)
    return response.data
  },
  getDaily: async (): Promise<Transaction[]> => {
    const response = await api.get<Transaction[]>('/transactions/daily')
    return response.data
  },
  getDailyTurnover: async (date?: string): Promise<DailyTurnoverSummary> => {
    const params = date ? { date } : {}
    const response = await api.get<DailyTurnoverSummary>('/transactions/daily-turnover', { params })
    return response.data
  },
  getCashierRateQuota: async (): Promise<CashierCustomRateQuota> => {
    const response = await api.get<CashierCustomRateQuota>('/transactions/cashier-rate-quota')
    return response.data
  },
  buy: async (data: BuyRequest): Promise<Transaction> => {
    const response = await api.post<Transaction>('/transactions/buy', data)
    return response.data
  },
  sell: async (data: SellRequest): Promise<Transaction> => {
    const response = await api.post<Transaction>('/transactions/sell', data)
    return response.data
  },
  reversal: async (data: ReversalRequest): Promise<Transaction> => {
    const response = await api.post<Transaction>('/transactions/reversal', data)
    return response.data
  },
  conversion: async (data: ConversionRequest): Promise<Transaction> => {
    const response = await api.post<Transaction>('/transactions/conversion', data)
    return response.data
  },
  cancel: async (id: string | number, reason: string): Promise<Transaction> => {
    // Use reversal endpoint for cancellation
    const response = await api.post<Transaction>('/transactions/reversal', {
      originalTransactionId: typeof id === 'string' ? parseInt(id) : id,
      reason
    })
    return response.data
  },
  getReceipt: async (id: number): Promise<Blob> => {
    const response = await api.get(`/transactions/${id}/receipt`, { responseType: 'blob' })
    return response.data
  }
}

// ================== CASH BALANCE API ==================

export interface CashBalance {
  id: number
  branchId: string
  branchCode?: string
  branchName?: string
  currencyId: number
  currencyCode: string
  currencyName?: string
  currentBalance: number
  openingBalance: number
  minBalance?: number
  maxBalance?: number
  lastTransactionAt?: string
  createdAt: string
  updatedAt?: string
}

export interface AdjustBalanceRequest {
  currencyId: number
  amount: number
  incoming: boolean
  reason?: string
}

export interface BranchBalanceSummary {
  branchId: string
  branchName: string
  totalHufEquivalent: number
  currencyCount: number
  lowBalanceAlerts: number
  highBalanceAlerts: number
}

export interface CurrencyTotalBalance {
  currencyId: number
  currencyCode: string
  currencyName: string
  totalBalance: number
  branchCount: number
}

export const cashBalanceApi = {
  list: async (): Promise<CashBalance[]> => {
    const response = await api.get<CashBalance[]>('/cash-balances')
    return response.data
  },
  getByCurrencyId: async (currencyId: number): Promise<CashBalance> => {
    const response = await api.get<CashBalance>(`/cash-balances/currency/${currencyId}`)
    return response.data
  },
  getByCurrencyCode: async (currencyCode: string): Promise<CashBalance> => {
    const response = await api.get<CashBalance>(`/cash-balances/code/${currencyCode}`)
    return response.data
  },
  getCompanyBalances: async (): Promise<CashBalance[]> => {
    // v2.5.3: 403 esetén NEM dobunk globális toast-ot — a TreasuryDashboard
    // SUPERVISOR és alacsonyabb role-okat is kiszolgál, de ehhez az endpointhoz
    // csak MANAGER+ ADMIN férhet hozzá. A hívó (.catch) csendben üres listát kap,
    // és a UI "Korlátozott jogosultság" panelt mutat helyette.
    const response = await api.get<CashBalance[]>('/cash-balances/company', {
      _skipGlobal403Toast: true,
    })
    return response.data
  },
  getLowAlerts: async (): Promise<CashBalance[]> => {
    const response = await api.get<CashBalance[]>('/cash-balances/alerts/low')
    return response.data
  },
  getHighAlerts: async (): Promise<CashBalance[]> => {
    const response = await api.get<CashBalance[]>('/cash-balances/alerts/high')
    return response.data
  },
  adjust: async (data: AdjustBalanceRequest): Promise<CashBalance> => {
    const response = await api.post<CashBalance>('/cash-balances/adjust', data)
    return response.data
  },
  getSummary: async (): Promise<BranchBalanceSummary> => {
    const response = await api.get<BranchBalanceSummary>('/cash-balances/summary')
    return response.data
  },
  getCompanyTotals: async (): Promise<CurrencyTotalBalance[]> => {
    const response = await api.get<CurrencyTotalBalance[]>('/cash-balances/company-totals')
    return response.data
  }
}

// CashDesk interface for legacy compatibility
export interface CashDesk {
  id: string
  code: string
  name: string
  branchId?: string
  branchName?: string
  isActive: boolean
}

export interface CashDeskStatus {
  isOpen: boolean
  openedAt?: string
  openedBy?: string
  balances: CashBalance[]
}

// Legacy alias
export const cashDeskApi = {
  list: async (): Promise<CashDesk[]> => {
    try {
      const branches = await branchApi.listActive()
      return branches.map((branch: BranchInfo) => ({
        id: branch.id,
        code: branch.code,
        name: branch.name,
        branchId: branch.id,
        branchName: branch.name,
        isActive: branch.isActive ?? true,
      }))
    } catch {
      if (!window.electronAPI?.getCachedCashDesks) return []
      const cached = await window.electronAPI.getCachedCashDesks()
      return cached
        .filter((cashDesk) => cashDesk.is_active === 1)
        .map((cashDesk) => ({
          id: cashDesk.id,
          code: cashDesk.code,
          name: cashDesk.name,
          branchId: cashDesk.id,
          branchName: cashDesk.name,
          isActive: cashDesk.is_active === 1,
        }))
    }
  },
  getStatus: async (): Promise<CashDeskStatus> => {
    const balances = await cashBalanceApi.list()
    return { isOpen: true, balances }
  }
}

export interface WorkerMaster {
  id: number
  workerCode: string | null
  fullName: string
  role: string | null
  branchId: string | null
  branchCode: string | null
  branchName: string | null
  companyId: string | null
  companyCode: string | null
  active: boolean
}

export const workerMasterApi = {
  listActive: async (): Promise<WorkerMaster[]> => {
    try {
      const response = await api.get<WorkerMaster[]>('/workers/active')
      return response.data
    } catch {
      if (!window.electronAPI?.getCachedWorkers) return []
      const cached = await window.electronAPI.getCachedWorkers()
      return cached
        .filter((worker) => worker.active === 1)
        .map((worker) => ({
          id: worker.id,
          workerCode: worker.worker_code,
          fullName: worker.full_name,
          role: worker.role,
          branchId: worker.branch_id,
          branchCode: worker.branch_code,
          branchName: worker.branch_name,
          companyId: worker.company_id,
          companyCode: worker.company_code,
          active: worker.active === 1,
        }))
    }
  },
}

// ================== DAILY SESSION API ==================

export interface DailySession {
  id: number
  branchId: string
  branchCode?: string
  branchName?: string
  sessionDate: string
  status: 'OPEN' | 'CLOSED'
  openedByWorkerId?: number
  openedByWorkerName?: string
  openedAt?: string
  openingBalanceHuf: number
  closedByWorkerId?: number
  closedByWorkerName?: string
  closedAt?: string
  closingBalanceHuf?: number
  denominationVerified: boolean
  transactionCount: number
  buyCount: number
  sellCount: number
  reversalCount: number
  buyTurnoverHuf: number
  sellTurnoverHuf: number
  handlingFeeTotal: number
  notes?: string
  qrCodeGenerated: boolean
  navUploaded: boolean
  createdAt: string
  updatedAt?: string
}

export const dailySessionApi = {
  open: async (): Promise<DailySession> => {
    const response = await api.post<DailySession>('/daily-sessions/open')
    return response.data
  },
  close: async (denominationVerified: boolean = false): Promise<DailySession> => {
    const response = await api.post<DailySession>('/daily-sessions/close', null, {
      params: { denominationVerified }
    })
    return response.data
  },
  getCurrent: async (): Promise<DailySession> => {
    const response = await api.get<DailySession>('/daily-sessions/current')
    return response.data
  },
  isOpen: async (): Promise<boolean> => {
    const response = await api.get<boolean>('/daily-sessions/is-open')
    return response.data
  },
  getReversalCount: async (): Promise<number> => {
    const response = await api.get<number>('/daily-sessions/reversal-count')
    return response.data
  },
  getHistory: async (startDate: string, endDate: string): Promise<DailySession[]> => {
    const response = await api.get<DailySession[]>('/daily-sessions/history', {
      params: { startDate, endDate }
    })
    return response.data
  }
}

// ================== STORNO API ==================

export interface StornoCheckResult {
  requiresApproval: boolean
  dailyStornoCount: number
  transactionId: string
  transactionNumber: string
  message: string
}

export interface StornoRequest {
  transactionId: string
  reason: string
  approvalId?: string
  customExchangeRate?: number
  paymentMethodDid?: string
}

export interface StornoApproval {
  id: string
  transactionId: string
  workerId: string
  branchId: string
  dailyStornoCount: number
  approvalStatusDid: string
  requestReason: string
  rejectionReason?: string
  approvedByWorkerId?: string
  approvedAt?: string
}

export const stornoApi = {
  check: async (transactionId: string, workerId: string): Promise<StornoCheckResult> => {
    const response = await api.get<StornoCheckResult>(`/stornos/check/${transactionId}`, {
      params: { workerId }
    })
    return response.data
  },
  requestApproval: async (transactionId: string, workerId: string, reason: string): Promise<StornoApproval> => {
    const response = await api.post<StornoApproval>('/stornos/request-approval', null, {
      params: { transactionId, workerId, reason }
    })
    return response.data
  },
  approve: async (approvalId: string, approvedByWorkerId: string, approved: boolean, reason?: string): Promise<StornoApproval> => {
    const response = await api.post<StornoApproval>(`/stornos/approve/${approvalId}`, null, {
      params: { approvedByWorkerId, approved, reason }
    })
    return response.data
  },
  execute: async (request: StornoRequest, workerId: string): Promise<Transaction> => {
    const response = await api.post<Transaction>('/stornos/execute', request, {
      params: { workerId }
    })
    return response.data
  },
  executePos: async (posTransactionId: string, workerId: string, reason: string): Promise<Transaction> => {
    const response = await api.post<Transaction>('/stornos/pos', null, {
      params: { posTransactionId, workerId, reason }
    })
    return response.data
  }
}

// ================== CLOSING WIZARD API ==================

export interface ClosingWizard {
  id: string
  branchId: string
  branchName: string
  cashDeskId?: string
  cashDeskCode?: string
  closingDate: string
  closingType: 'DAILY' | 'POS' | 'DECADE' | 'MONTHLY'
  currentStep: number
  totalSteps: number
  wizardStatus: 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
  startedByWorkerId: string
  startedByWorkerName: string
  startedAt: string
  completedByWorkerId?: string
  completedByWorkerName?: string
  completedAt?: string
  notes?: string
  steps?: ClosingWizardStep[]
}

export interface ClosingWizardStep {
  stepNumber: number
  stepTitle: string
  stepDescription: string
  completed: boolean
  canProceed: boolean
  stepData: Record<string, unknown>
}

export const closingWizardApi = {
  start: async (branchId: string, cashDeskId: string | undefined, closingType: string, workerId: string): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>('/closing-wizard/start', null, {
      params: { branchId, cashDeskId, closingType, workerId }
    })
    return response.data
  },
  get: async (wizardId: string): Promise<ClosingWizard> => {
    const response = await api.get<ClosingWizard>(`/closing-wizard/${wizardId}`)
    return response.data
  },
  getStep: async (wizardId: string, stepNumber: number): Promise<ClosingWizardStep> => {
    const response = await api.get<ClosingWizardStep>(`/closing-wizard/${wizardId}/step/${stepNumber}`)
    return response.data
  },
  navigate: async (wizardId: string, targetStep: number): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/closing-wizard/${wizardId}/navigate`, null, {
      params: { targetStep }
    })
    return response.data
  },
  complete: async (wizardId: string, workerId: string): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/closing-wizard/${wizardId}/complete`, null, {
      params: { workerId }
    })
    return response.data
  },
  cancel: async (wizardId: string): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/closing-wizard/${wizardId}/cancel`)
    return response.data
  },
  finalize: async (wizardId: string, workerId: string, discrepancyExplanation?: string): Promise<{ success: boolean; message: string }> => {
    const response = await api.post<{ success: boolean; message: string }>(`/closing-wizard/${wizardId}/finalize`, null, {
      // G3 (FR-13): opcionális eltérés-magyarázat az eltérés-gate-hez.
      params: { workerId, ...(discrepancyExplanation ? { discrepancyExplanation } : {}) }
    })
    return response.data
  },
  /** Submit denomination counts — body: { "HUF": { 500: 3, 1000: 5, ... } } */
  submitDenominations: async (wizardId: string, denomCounts: Record<string, Record<number, number>>): Promise<Record<string, unknown>> => {
    const response = await api.post<Record<string, unknown>>(`/closing-wizard/${wizardId}/denominations`, denomCounts)
    return response.data
  }
}

// ================== AUTHORIZED REPRESENTATIVE API ==================

export interface AuthorizedRepresentative {
  id: string
  customerId: string
  customerName: string
  firstName: string
  lastName: string
  fullName: string
  birthDate?: string
  birthPlace?: string
  nationalityDid?: string
  documentTypeDid?: string
  documentNumber?: string
  documentValidFrom?: string
  documentValidTo?: string
  address?: string
  phone?: string
  email?: string
  representativeTypeDid?: string
  relationshipDid?: string
  authorizationStart?: string
  authorizationEnd?: string
  isActive: boolean
  registeredAt: string
}

export interface Authorization {
  id: string
  representativeId: string
  authorizationTypeDid?: string
  issueDate?: string
  startDate?: string
  expiryDate?: string
  statusDid?: string
  maxAmount?: number
  maxTransactionCount?: number
  usedTransactionCount?: number
  documentPath?: string
  notes?: string
  verifiedByWorkerId?: string
  verificationDate?: string
  allowedOperations?: AllowedOperation[]
}

export interface AllowedOperation {
  id: string
  authorizationId: string
  operationDid?: string
}

export interface RepresentativeLog {
  id: string
  representativeId: string
  activityTypeDid?: string
  transactionId?: string
  workerId: string
  workerName?: string
  branchId: string
  branchName?: string
  activityDate: string
  notes?: string
}

export interface RepresentativeRegistrationRequest {
  name: string
  documentType: string
  documentNumber: string
  documentTypeDid?: string
  documentValidFrom?: string
  documentValidTo?: string
  address?: string
  phone?: string
  email?: string
  firstName?: string
  lastName?: string
  birthDate?: string
  birthPlace?: string
  nationalityDid?: string
  representativeTypeDid?: string
  relationshipDid?: string
  authorizationStart: string
  authorizationEnd?: string
}

export interface AuthorizationCreateRequest {
  operationDid: string
  startDate: string
  expiryDate?: string
  maxAmount?: number
  singleTransactionLimit?: number
  maxTransactionCount?: number
  notes?: string
}

export const authorizedRepresentativeApi = {
  register: async (customerId: string, request: RepresentativeRegistrationRequest, workerId: string): Promise<AuthorizedRepresentative> => {
    const response = await api.post<AuthorizedRepresentative>(
      `/authorized-representatives/customer/${customerId}/register`,
      request,
      { params: { workerId } }
    )
    return response.data
  },
  findByCustomer: async (customerId: string): Promise<AuthorizedRepresentative[]> => {
    const response = await api.get<AuthorizedRepresentative[]>(`/authorized-representatives/customer/${customerId}`)
    return response.data
  },
  getById: async (id: string): Promise<AuthorizedRepresentative> => {
    const response = await api.get<AuthorizedRepresentative>(`/authorized-representatives/${id}`)
    return response.data
  },
  createAuthorization: async (representativeId: string, request: AuthorizationCreateRequest, workerId: number): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/${representativeId}/authorizations`,
      request,
      { params: { workerId } }
    )
    return response.data
  },
  verifyAuthorization: async (authorizationId: string, workerId: number, notes?: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/verify`,
      null,
      { params: { workerId, notes } }
    )
    return response.data
  },
  resumeAuthorization: async (authorizationId: string, workerId: number, notes?: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/resume`,
      null,
      { params: { workerId, notes } }
    )
    return response.data
  },
  verifyForTransaction: async (documentNumber: string, operationDid: string, amount?: number): Promise<{ authorized: boolean; representativeId?: string; authorizationId?: string }> => {
    const response = await api.post(
      '/authorized-representatives/verify-for-transaction',
      null,
      { params: { documentNumber, operationDid, amount } }
    )
    return response.data
  },
  recordTransaction: async (representativeId: string, authorizationId: string, transactionId: string, workerId: string, branchId: string): Promise<void> => {
    await api.post('/authorized-representatives/record-transaction', null, {
      params: { representativeId, authorizationId, transactionId, workerId, branchId }
    })
  },
  suspendAuthorization: async (authorizationId: string, workerId: number, reason: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/suspend`,
      null,
      { params: { workerId, reason } }
    )
    return response.data
  },
  revokeAuthorization: async (authorizationId: string, workerId: number, reason: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/revoke`,
      null,
      { params: { workerId, reason } }
    )
    return response.data
  },
  findAuthorizations: async (representativeId: string): Promise<Authorization[]> => {
    const response = await api.get<Authorization[]>(`/authorized-representatives/${representativeId}/authorizations`)
    return response.data
  },
  findLogs: async (representativeId: string): Promise<RepresentativeLog[]> => {
    const response = await api.get<RepresentativeLog[]>(`/authorized-representatives/${representativeId}/logs`)
    return response.data
  }
}

// ================== TRANSACTION BANKNOTE API ==================

export interface TransactionBanknote {
  id: number
  transactionId: number
  transactionLineId?: number
  currencyCode: string
  faceValue: number
  quantity: number
  direction: 'IN' | 'OUT'
  totalValue: number
}

export interface TransactionBanknoteCreateRequest {
  currencyCode: string
  faceValue: number
  quantity: number
  direction: 'IN' | 'OUT'
}

export const transactionBanknoteApi = {
  getByTransaction: async (transactionId: number): Promise<TransactionBanknote[]> => {
    const response = await api.get<TransactionBanknote[]>(`/transactions/${transactionId}/banknotes`)
    return response.data
  },
  create: async (transactionId: number, request: TransactionBanknoteCreateRequest): Promise<TransactionBanknote> => {
    const response = await api.post<TransactionBanknote>(`/transactions/${transactionId}/banknotes`, request)
    return response.data
  },
}

// ================== SHIPMENT REQUEST API ==================

export interface ShipmentRequest {
  id: string
  requestNumber: string
  requestingBranchId: string
  requestingBranchName: string
  targetBranchId: string
  targetBranchName: string
  sourceBranchId?: string
  sourceBranchName?: string
  shipmentType: string
  requestedDeliveryDate: string
  priorityDid?: string
  requestStatus: string
  requestedByWorkerId: string
  requestedByWorkerName: string
  requestedAt: string
  approvedByWorkerId?: string
  approvedByWorkerName?: string
  approvedAt?: string
  rejectedByWorkerId?: string
  rejectedByWorkerName?: string
  rejectedAt?: string
  rejectionReason?: string
  modificationNotes?: string
  notes?: string
  transferId?: string
  items?: ShipmentRequestItem[]
}

export interface ShipmentRequestItem {
  id: string
  currencyId: string | number
  currencyCode?: string
  amount?: number
  requestedAmount?: number
  denominationPreferences?: string
}

export interface ShipmentCreateRequest {
  fromBranchId: string
  toBranchId: string
  deliveryDate?: string
  items: Array<{
    currencyId: string | number
    requestedAmount: number
  }>
  notes?: string
}

/**
 * AI review (Codex PR #187 P1): backend ShipmentRequest entity mezonevek ELTERNEK
 * a frontend ShipmentRequest interface-tol. A normalizer leforditja a backend
 * `{status, deliveryDate, fromBranchId, toBranchId, requestedBy, ...}`-t a
 * frontend `{requestStatus, requestedDeliveryDate, requestingBranchId, targetBranchId, ...}`-ra.
 */
function normalizeShipmentRequest(raw: Record<string, unknown>): ShipmentRequest {
    const r = raw as Partial<ShipmentRequest> & Record<string, unknown>
    return {
        ...r,
        // Ha a backend raw mezot kuldott, de frontend-kompat mezoje hianyzik, masoljuk at
        requestStatus: (r.requestStatus ?? r['status']) as ShipmentRequest['requestStatus'],
        requestedDeliveryDate: (r.requestedDeliveryDate ?? r['deliveryDate']) as ShipmentRequest['requestedDeliveryDate'],
        requestingBranchId: (r.requestingBranchId ?? r['fromBranchId']) as ShipmentRequest['requestingBranchId'],
        targetBranchId: (r.targetBranchId ?? r['toBranchId']) as ShipmentRequest['targetBranchId'],
        requestingBranchName: (r.requestingBranchName ?? r['fromBranchName']) as ShipmentRequest['requestingBranchName'],
        targetBranchName: (r.targetBranchName ?? r['toBranchName']) as ShipmentRequest['targetBranchName'],
        requestedByWorkerName: (r.requestedByWorkerName ?? r['requestedBy']) as ShipmentRequest['requestedByWorkerName'],
        requestedByWorkerId: (r.requestedByWorkerId ?? r['requestedById']) as ShipmentRequest['requestedByWorkerId'],
        requestedAt: (r.requestedAt ?? r['createdAt'] ?? r['requestDate']) as ShipmentRequest['requestedAt'],
        requestNumber: (r.requestNumber ?? r['number']) as ShipmentRequest['requestNumber'],
    } as ShipmentRequest
}

/**
 * Paginazott lekeres helper a Spring Data Page<T> formatumhoz.
 *
 * AI review (Sourcery PR #193): extract pagination loop -> reusable helper.
 * A `_preservePaged: true` flag miatt a client.ts interceptor NEM unwrap-olja
 * a Page<T> strukturat, igy a `last`/`totalPages` mezok elerhetoek.
 *
 * @param path Backend URL (pl. '/shipments')
 * @param extraParams Kiegeszito query paramok (size override, filter stb.)
 * @param opts.maxPages safety cap (default 20 = 2000 rekord ha size=100).
 *                      Ha elerjuk es NINCS `last=true`, console.warn-olunk,
 *                      hogy ne legyen silent truncation.
 * @param opts.pageSize oldal meret (default 100)
 */
async function fetchPaged<T>(
  path: string,
  extraParams: Record<string, unknown> = {},
  opts: { maxPages?: number; pageSize?: number } = {}
): Promise<T[]> {
  const pageSize = opts.pageSize ?? 100
  const maxPages = opts.maxPages ?? 20
  const all: T[] = []
  let page = 0
  let lastPageReached = false
  while (page < maxPages) {
    const response = await api.get<{ content: T[]; totalPages?: number; last?: boolean }>(
      path,
      {
        params: { ...extraParams, page, size: pageSize },
        _preservePaged: true,
      } as Record<string, unknown>
    )
    const batch = asArray<T>(response.data?.content)
    all.push(...batch)
    if (
      response.data?.last === true ||
      response.data?.totalPages === undefined ||
      page + 1 >= response.data.totalPages
    ) {
      lastPageReached = true
      break
    }
    page++
  }
  if (!lastPageReached) {
    // AI review (Sourcery PR #193): silent truncation risk elleni explicit figyelmeztetes.
    // A no-console rule a projektben most mar nem tiltja a console.warn-t, igy az
    // eslint-disable directive feleslegesse valt (PR #222 post-merge CI fix).
    console.warn(
      `[fetchPaged] MAX_PAGES=${maxPages} (size=${pageSize}) elerve ${path}-on, `
      + `lehetseges silent truncation. Backend-oldali filter kell vagy maxPages emelese.`
    )
  }
  return all
}

export const shipmentRequestApi = {
  create: async (request: ShipmentCreateRequest): Promise<ShipmentRequest> => {
    const payload = {
      fromBranchId: request.fromBranchId,
      toBranchId: request.toBranchId,
      deliveryDate: request.deliveryDate || undefined,
      notes: request.notes?.trim() || undefined,
      items: request.items.map((item) => ({
        currencyId: Number(item.currencyId),
        requestedAmount: item.requestedAmount,
      })),
    }
    const response = await api.post<Record<string, unknown>>('/shipments', payload)
    return normalizeShipmentRequest(response.data)
  },
  /**
   * @deprecated Sourcery PR #180 + PR #187 improvement: backend
   *   `/shipment-requests/{}/prepare` NEM letezik. Promise<never> return-tipus
   *   TypeScript compile-time jelzesre.
   */
  prepare: async (_requestId: string, _sourceCashDeskId: string, _targetCashDeskId: string, _workerId: string): Promise<never> => {
    throw new Error('shipmentRequestApi.prepare() DEPRECATED: backend /shipment-requests/{}/prepare endpoint nem letezik.')
  },
  submit: async (requestId: string): Promise<ShipmentRequest> => {
    const response = await api.post<Record<string, unknown>>(`/shipments/${requestId}/submit`)
    return normalizeShipmentRequest(response.data)
  },
  // Fix 2026-04-24: a backend /api/v1/shipments endpoint-ot hasznalja.
  // AI review (Codex PR #180 P1): a shared client.ts interceptor MAR auto-unwrappel-i
  // a Spring Page<T>-et plain array-ra (kivéve _preservePaged=true). Tehat a
  // response.data MAR maga az array, NEM {content: [...]}. Ha paginated UI kell,
  // a config-ra `_preservePaged: true` kell.
  findByStatus: async (status: string): Promise<ShipmentRequest[]> => {
    if (!status) {
      // Sourcery PR #180: empty status == 'Mind' -> omit param
      const response = await api.get<unknown[]>(`/shipments`, { params: { page: 0, size: 100 } })
      return asArray<Record<string, unknown>>(response.data).map(normalizeShipmentRequest)
    }
    const response = await api.get<unknown[]>(
      `/shipments`,
      { params: { status, page: 0, size: 100 } }
    )
    return asArray<Record<string, unknown>>(response.data).map(normalizeShipmentRequest)
  },
  findByBranch: async (branchId: string): Promise<ShipmentRequest[]> => {
    // Backend jelenleg nem tamogatja a branch-parametert kozvetlenul.
    // Megoldas: paginazott osszes lista lekeres + client-side filter.
    // AI review (Codex PR #180 P1): backend mezonevek `fromBranchId` / `toBranchId`
    // (NEM `requestingBranchId` / `targetBranchId`). A korabbi filter SOHA NEM illesztett.
    // AI review (Sourcery PR #180 + #193): pagination loop `fetchPaged<T>` helperbe
    // kiemelve, MAX_PAGES cap eseten console.warn (silent truncation elkerulese).
    // TODO: backend /api/v1/shipments?branchId=... nativ filter - GitHub Issue.
    const rawPages = await fetchPaged<Record<string, unknown>>(`/shipments`)
    const all: ShipmentRequest[] = rawPages.map(normalizeShipmentRequest)
    type ShipmentWithBackendFields = ShipmentRequest & { fromBranchId?: string; toBranchId?: string }
    return all.filter(s => {
      const sb = s as ShipmentWithBackendFields
      return sb.fromBranchId === branchId || sb.toBranchId === branchId
        || s.requestingBranchId === branchId || s.targetBranchId === branchId
    })
  },
  // Approve: backend POST /api/v1/shipments/{id}/approve (params ignoralva: workerId + approvedItems + notes)
  approve: async (requestId: string, workerId: string, approvedItems?: ShipmentRequestItem[], notes?: string): Promise<ShipmentRequest> => {
    const response = await api.post<ShipmentRequest>(
      `/shipments/${requestId}/approve`,
      approvedItems || null,
      { params: { workerId, notes } }
    )
    return response.data
  },
  // Reject: backend jelenleg NINCS /reject endpoint - a /cancel legkozelebbi ekvivalens.
  // TODO: backend dedikalt /reject endpoint (audit trail szempontjabol) - kulon issue.
  reject: async (requestId: string, workerId: string, reason: string): Promise<ShipmentRequest> => {
    const response = await api.post<ShipmentRequest>(
      `/shipments/${requestId}/cancel`,
      null,
      { params: { workerId, reason } }
    )
    return response.data
  }
}

// ================== TRANSFER API ==================

export interface Transfer {
  id: number
  transferNumber: string
  fromBranchId: string
  fromBranchCode: string
  fromBranchName: string
  toBranchId: string
  toBranchCode: string
  toBranchName: string
  fromWorkerId: number
  fromWorkerName: string
  toWorkerId?: number
  toWorkerName?: string
  transferType: 'CURRENCY' | 'CASH' | 'HANDLING_FEE' | 'VAULT_DEPOSIT' | 'VAULT_WITHDRAW' | 'CORRECTION' | 'OTHER'
  transferTypeDisplay: string
  status: 'PENDING' | 'IN_TRANSIT' | 'RECEIVED' | 'COMPLETED' | 'REJECTED' | 'CANCELLED'
  statusDisplay: string
  transferDate: string
  transferTime: string
  receivedDate?: string
  receivedTime?: string
  currencyId: number
  currencyCode: string
  currencyName: string
  amount: number
  hufValue?: number
  receivedAmount?: number
  difference?: number
  notes?: string
  carrierName?: string
  sealNumber?: string
  handoverPrinted: boolean
  receiptPrinted: boolean
  createdAt: string
  hasDifference: boolean
  isCompleted: boolean
  isPending: boolean
}

export interface CreateTransferRequest {
  toBranchId: string
  currencyId: number
  amount: number
  hufValue?: number
  transferType: 'CURRENCY' | 'CASH' | 'HANDLING_FEE' | 'VAULT_DEPOSIT' | 'VAULT_WITHDRAW' | 'CORRECTION' | 'OTHER'
  direction?: 'F' | 'U' | 'UF' | 'FF'
  notes?: string
  carrierName?: string
  sealNumber?: string
  /** #6: több-valutás átadólap sorai. Ha kitöltött, a currencyId/amount az ELSŐ sort tükrözi. */
  lines?: Array<{ currencyId: number; amount: number }>
}

export interface ReceiveTransferRequest {
  receivedAmount: number
  notes?: string
}

export const transferApi = {
  create: async (request: CreateTransferRequest): Promise<Transfer> => {
    const response = await api.post<Transfer>('/transfers', request)
    return response.data
  },
  receive: async (id: number, request: ReceiveTransferRequest): Promise<Transfer> => {
    const response = await api.post<Transfer>(`/transfers/${id}/receive`, request)
    return response.data
  },
  reject: async (id: number, reason: string): Promise<Transfer> => {
    const response = await api.post<Transfer>(`/transfers/${id}/reject`, null, { params: { reason } })
    return response.data
  },
  cancel: async (id: number): Promise<void> => {
    await api.post(`/transfers/${id}/cancel`)
  },
  getById: async (id: number): Promise<Transfer> => {
    const response = await api.get<Transfer>(`/transfers/${id}`)
    return response.data
  },
  getByTransferNumber: async (transferNumber: string): Promise<Transfer> => {
    const response = await api.get<Transfer>(`/transfers/number/${transferNumber}`)
    return response.data
  },
  getPending: async (): Promise<Transfer[]> => {
    const response = await api.get<Transfer[]>('/transfers/pending')
    return response.data
  },
  getOutgoing: async (): Promise<Transfer[]> => {
    const response = await api.get<Transfer[]>('/transfers/outgoing')
    return response.data
  },
  getIncoming: async (): Promise<Transfer[]> => {
    const response = await api.get<Transfer[]>('/transfers/incoming')
    return response.data
  },
  search: async (params?: {
    branchId?: string
    startDate?: string
    endDate?: string
    status?: string
    type?: string
    page?: number
    size?: number
  }): Promise<PagedResponse<Transfer>> => {
    const response = await api.get<PagedResponse<Transfer>>('/transfers', { params, _preservePaged: true } as Record<string, unknown>)
    return response.data
  },
  countPending: async (): Promise<number> => {
    const response = await api.get<number>('/transfers/pending/count')
    return response.data
  }
}

// ================== HANDOVER SHEET API ==================

export interface CurrencyAmounts {
  [currencyCode: string]: number
}

export interface HandoverSheet {
  id: string
  sheetNumber: string
  fromCashDeskId: string
  fromCashDeskName?: string
  toCashDeskId: string
  toCashDeskName?: string
  transferDate: string
  amounts: CurrencyAmounts
  notes?: string
  status: string
  createdById?: string
  createdByName?: string
}

export const handoverSheetApi = {
  list: async (): Promise<HandoverSheet[]> => {
    const response = await api.get<HandoverSheet[]>('/handover-sheets')
    return response.data
  },
  getById: async (id: string): Promise<HandoverSheet> => {
    const response = await api.get<HandoverSheet>(`/handover-sheets/${id}`)
    return response.data
  },
  generate: async (fromCashDeskId: string, toCashDeskId: string, transferDate: string, amounts: CurrencyAmounts): Promise<HandoverSheet> => {
    const response = await api.post<HandoverSheet>('/handover-sheets/generate', {
      fromCashDeskId, toCashDeskId, transferDate, amounts
    })
    return response.data
  },
  print: async (id: string): Promise<void> => {
    await api.post(`/handover-sheets/${id}/print`)
  },
  complete: async (id: string): Promise<HandoverSheet> => {
    const response = await api.post<HandoverSheet>(`/handover-sheets/${id}/complete`)
    return response.data
  }
}

// ================== RECEIPT API ==================

export interface Receipt {
  id: string
  receiptNumber: string
  transactionId?: string
  receiptType: string
  issueDate: string
  content?: string
  navReceiptNumber?: string
  isPrinted: boolean
  printedAt?: string
}

export const receiptApi = {
  list: async (transactionId?: string): Promise<Receipt[]> => {
    const params = transactionId ? { transactionId } : {}
    const response = await api.get<Receipt[]>('/receipts', { params })
    return response.data
  },
  getById: async (id: string): Promise<Receipt> => {
    const response = await api.get<Receipt>(`/receipts/${id}`)
    return response.data
  },
  print: async (id: string): Promise<void> => {
    await api.post(`/receipts/${id}/print`)
  }
}

// ================== AML ENHANCED API ==================

export interface AmlCheckResultDto {
  transactionType: number
  weeklyTotal: number
  yearlyMax: number
  quarterlyCount: number
  quarterlyTotal: number
  requiresId: boolean
  requiresEnhanced: boolean
  blocked: boolean
  warnings: string[]
}

export const amlApi = {
  checkAllThresholds: async (customerId: string, hufAmount: number, currencyCode?: string): Promise<AmlCheckResultDto> => {
    const response = await api.get<AmlCheckResultDto>('/aml/check-all-thresholds', {
      params: { customerId, hufAmount, currencyCode }
    })
    return response.data
  }
}

// ================== MONTHLY CLOSING API ==================

export interface MonthlyClosingSummary {
  id: number
  branchId: string
  branchName?: string
  yearMonth: string
  closedAt: string
  closedByWorkerId?: number
  closedByWorkerName?: string
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFee: number
  transactionCount: number
  currencyBreakdown?: string
  createdAt: string
}

export const monthlyClosingApi = {
  performClosing: async (branchId: string, yearMonth: string): Promise<MonthlyClosingSummary> => {
    const response = await api.post<MonthlyClosingSummary>(`/closing/monthly/${branchId}/${yearMonth}`)
    return response.data
  },
  getReport: async (branchId: string, yearMonth: string): Promise<MonthlyClosingSummary> => {
    const response = await api.get<MonthlyClosingSummary>(`/closing/monthly/${branchId}/${yearMonth}`)
    return response.data
  },
  getAllClosedMonths: async (branchId: string): Promise<MonthlyClosingSummary[]> => {
    const response = await api.get<MonthlyClosingSummary[]>(`/closing/monthly/${branchId}`)
    return response.data
  }
}
