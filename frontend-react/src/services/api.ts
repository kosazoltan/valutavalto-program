import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '../stores/authStore'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'

// Create axios instance
export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor - add auth token
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = useAuthStore.getState().token
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error: AxiosError) => {
    console.error('Request interceptor error:', error)
    return Promise.reject(error)
  }
)

// Response interceptor - handle errors
api.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Token expired or invalid
      useAuthStore.getState().logout()
      window.location.href = '/login'
    }
    
    // Log error for debugging
    console.error('API Error:', {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
      message: error.message,
    })
    
    return Promise.reject(error)
  }
)

// Generic API response type
export interface ApiResponse<T> {
  data: T
  message?: string
  success: boolean
}

// Paginated response type
export interface PagedResponse<T> {
  content: T[]
  totalElements: number
  totalPages: number
  size: number
  number: number
}

// ================== AUTH API ==================

export interface LoginRequest {
  companyCode: string
  workerCode: string
  password: string
}

export interface LoginResponse {
  token: string
  tokenType: string
  expiresAt: string
  worker: {
    id: number
    workerCode: string
    firstName: string
    lastName: string
    fullName: string
    role: string
    branchId: string
    branchCode: string
    branchName: string
    companyId: string
    companyCode: string
    companyName: string
  }
}

export const authApi = {
  login: async (data: LoginRequest): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/auth/login', data)
    return response.data
  },
  logout: async (): Promise<void> => {
    await api.post('/auth/logout')
  },
  refreshToken: async (): Promise<{ token: string }> => {
    const response = await api.post<{ token: string }>('/auth/refresh')
    return response.data
  }
}

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

export interface Transaction {
  id: number
  receiptNumber: string
  transactionType: 'BUY' | 'SELL' | 'REVERSAL' | 'CONVERSION'
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
  customerNationality?: string
  originalTransactionId?: number
  reversalReason?: string
  approvedBy?: string
  notes?: string
  printed: boolean
  branchId: string
  branchName?: string
  workerId: number
  workerName?: string
  createdAt: string
  // Legacy compatibility aliases
  transactionNumber?: string // Same as receiptNumber
  type?: 'BUY' | 'SELL' | 'REVERSAL' | 'CONVERSION' // Same as transactionType
  foreignAmount?: number // Same as currencyAmount
  fee?: number // Same as handlingFee
  total?: number // Same as hufAmount
  amount?: number // Same as currencyAmount
  rate?: number // Same as exchangeRate
  createdBy?: string // Same as workerName
}

export interface BuyRequest {
  currencyId: number
  currencyAmount: number
  customExchangeRate?: number
  handlingFee?: number
  discountPercent?: number
  customerId?: string
  customerName?: string
  customerAddress?: string
  customerDocumentNumber?: string
  customerNationality?: string
  notes?: string
}

export interface SellRequest {
  currencyId: number
  hufAmount: number
  customExchangeRate?: number
  handlingFee?: number
  discountPercent?: number
  customerId?: string
  customerName?: string
  customerAddress?: string
  customerDocumentNumber?: string
  customerNationality?: string
  notes?: string
}

export interface ReversalRequest {
  originalTransactionId: number
  reason: string
  approvedBy?: string
}

export interface ConversionRequest {
  fromCurrencyId: number
  toCurrencyId: number
  fromAmount: number
  customerId?: string
  customerName?: string
  notes?: string
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
    type?: 'BUY' | 'SELL' | 'REVERSAL' | 'CONVERSION'
    page?: number
    size?: number
  }): Promise<PagedResponse<Transaction>> => {
    const response = await api.get<PagedResponse<Transaction>>('/transactions', { params })
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
  getDailyTurnover: async (): Promise<DailyTurnoverSummary> => {
    const response = await api.get<DailyTurnoverSummary>('/transactions/daily-turnover')
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

// ================== EXCHANGE RATES API ==================

export interface ExchangeRate {
  id: number
  currencyId: number
  currencyCode: string
  currencyName: string
  validDate: string
  validTime: string
  baseBuyRate: number
  baseSellRate: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  officialRate?: number
  active: boolean
  createdBy?: string
  createdAt: string
}

export interface CreateExchangeRateRequest {
  currencyId: number
  baseBuyRate: number
  baseSellRate: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  officialRate?: number
}

export const exchangeRateApi = {
  list: async (): Promise<ExchangeRate[]> => {
    const response = await api.get<ExchangeRate[]>('/exchange-rates')
    return response.data
  },
  getByCurrencyId: async (currencyId: number): Promise<ExchangeRate> => {
    const response = await api.get<ExchangeRate>(`/exchange-rates/currency/${currencyId}`)
    return response.data
  },
  getByCurrencyCode: async (currencyCode: string): Promise<ExchangeRate> => {
    const response = await api.get<ExchangeRate>(`/exchange-rates/code/${currencyCode}`)
    return response.data
  },
  getBuyRateForAmount: async (currencyId: number, hufAmount: number): Promise<number> => {
    const response = await api.get<number>('/exchange-rates/buy-rate', {
      params: { currencyId, hufAmount }
    })
    return response.data
  },
  getSellRateForAmount: async (currencyId: number, hufAmount: number): Promise<number> => {
    const response = await api.get<number>('/exchange-rates/sell-rate', {
      params: { currencyId, hufAmount }
    })
    return response.data
  },
  create: async (data: CreateExchangeRateRequest): Promise<ExchangeRate> => {
    const response = await api.post<ExchangeRate>('/exchange-rates', data)
    return response.data
  },
  getHistory: async (currencyId: number, startDate: string, endDate: string): Promise<ExchangeRate[]> => {
    const response = await api.get<ExchangeRate[]>('/exchange-rates/history', {
      params: { currencyId, startDate, endDate }
    })
    return response.data
  }
}

// Legacy alias for backward compatibility
export const rateApi = exchangeRateApi

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
  isAddition: boolean
  notes?: string
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
    const response = await api.get<CashBalance[]>('/cash-balances/company')
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
    // Cash desks are now branches in the new architecture
    return []
  },
  getStatus: async (): Promise<CashDeskStatus> => {
    const balances = await cashBalanceApi.list()
    return { isOpen: true, balances }
  }
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
    const response = await api.get<StornoCheckResult>(`/v1/stornos/check/${transactionId}`, {
      params: { workerId }
    })
    return response.data
  },
  requestApproval: async (transactionId: string, workerId: string, reason: string): Promise<StornoApproval> => {
    const response = await api.post<StornoApproval>('/v1/stornos/request-approval', null, {
      params: { transactionId, workerId, reason }
    })
    return response.data
  },
  approve: async (approvalId: string, approvedByWorkerId: string, approved: boolean, reason?: string): Promise<StornoApproval> => {
    const response = await api.post<StornoApproval>(`/v1/stornos/approve/${approvalId}`, null, {
      params: { approvedByWorkerId, approved, reason }
    })
    return response.data
  },
  execute: async (request: StornoRequest, workerId: string): Promise<Transaction> => {
    const response = await api.post<Transaction>('/v1/stornos/execute', request, {
      params: { workerId }
    })
    return response.data
  },
  executePos: async (posTransactionId: string, workerId: string, reason: string): Promise<Transaction> => {
    const response = await api.post<Transaction>('/v1/stornos/pos', null, {
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
    const response = await api.post<ClosingWizard>('/v1/closing-wizard/start', null, {
      params: { branchId, cashDeskId, closingType, workerId }
    })
    return response.data
  },
  get: async (wizardId: string): Promise<ClosingWizard> => {
    const response = await api.get<ClosingWizard>(`/v1/closing-wizard/${wizardId}`)
    return response.data
  },
  getStep: async (wizardId: string, stepNumber: number): Promise<ClosingWizardStep> => {
    const response = await api.get<ClosingWizardStep>(`/v1/closing-wizard/${wizardId}/step/${stepNumber}`)
    return response.data
  },
  navigate: async (wizardId: string, targetStep: number): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/v1/closing-wizard/${wizardId}/navigate`, null, {
      params: { targetStep }
    })
    return response.data
  },
  complete: async (wizardId: string, workerId: string): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/v1/closing-wizard/${wizardId}/complete`, null, {
      params: { workerId }
    })
    return response.data
  },
  cancel: async (wizardId: string): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/v1/closing-wizard/${wizardId}/cancel`)
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
  documentExpiry?: string
  address?: string
  phone?: string
  email?: string
  relationship?: string
}

export interface AuthorizationCreateRequest {
  operationDid: string
  startDate: string
  endDate?: string
  transactionLimit?: number
  singleTransactionLimit?: number
  notes?: string
}

export const authorizedRepresentativeApi = {
  register: async (customerId: string, request: RepresentativeRegistrationRequest, workerId: string): Promise<AuthorizedRepresentative> => {
    const response = await api.post<AuthorizedRepresentative>(
      `/v1/authorized-representatives/customer/${customerId}/register`,
      request,
      { params: { workerId } }
    )
    return response.data
  },
  findByCustomer: async (customerId: string): Promise<AuthorizedRepresentative[]> => {
    const response = await api.get<AuthorizedRepresentative[]>(`/v1/authorized-representatives/customer/${customerId}`)
    return response.data
  },
  createAuthorization: async (representativeId: string, request: AuthorizationCreateRequest, workerId: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/v1/authorized-representatives/${representativeId}/authorizations`,
      request,
      { params: { workerId } }
    )
    return response.data
  },
  verifyAuthorization: async (authorizationId: string, workerId: string, notes?: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/v1/authorized-representatives/authorizations/${authorizationId}/verify`,
      null,
      { params: { workerId, notes } }
    )
    return response.data
  },
  verifyForTransaction: async (documentNumber: string, operationDid: string, amount?: number): Promise<{ authorized: boolean; representativeId?: string; authorizationId?: string }> => {
    const response = await api.post(
      '/v1/authorized-representatives/verify-for-transaction',
      null,
      { params: { documentNumber, operationDid, amount } }
    )
    return response.data
  },
  recordTransaction: async (representativeId: string, authorizationId: string, transactionId: string, workerId: string, branchId: string): Promise<void> => {
    await api.post('/v1/authorized-representatives/record-transaction', null, {
      params: { representativeId, authorizationId, transactionId, workerId, branchId }
    })
  },
  suspendAuthorization: async (authorizationId: string, workerId: string, reason: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/v1/authorized-representatives/authorizations/${authorizationId}/suspend`,
      null,
      { params: { workerId, reason } }
    )
    return response.data
  },
  revokeAuthorization: async (authorizationId: string, workerId: string, reason: string): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/v1/authorized-representatives/authorizations/${authorizationId}/revoke`,
      null,
      { params: { workerId, reason } }
    )
    return response.data
  },
  findAuthorizations: async (representativeId: string): Promise<Authorization[]> => {
    const response = await api.get<Authorization[]>(`/v1/authorized-representatives/${representativeId}/authorizations`)
    return response.data
  },
  findLogs: async (representativeId: string): Promise<RepresentativeLog[]> => {
    const response = await api.get<RepresentativeLog[]>(`/v1/authorized-representatives/${representativeId}/logs`)
    return response.data
  }
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
  currencyId: string
  currencyCode: string
  amount: number
  denominationPreferences?: string
}

export interface ShipmentCreateRequest {
  requestDate: string
  requestedDeliveryDate: string
  reason: string
  items: Array<{
    currencyId: string
    amount: number
    denominationPreferences?: string
  }>
  notes?: string
}

export const shipmentRequestApi = {
  create: async (branchId: string, request: ShipmentCreateRequest, workerId: string): Promise<ShipmentRequest> => {
    const response = await api.post<ShipmentRequest>(
      `/v1/shipment-requests/branch/${branchId}/create`,
      request,
      { params: { workerId } }
    )
    return response.data
  },
  approve: async (requestId: string, workerId: string, approvedItems?: ShipmentRequestItem[], notes?: string): Promise<ShipmentRequest> => {
    const response = await api.post<ShipmentRequest>(
      `/v1/shipment-requests/${requestId}/approve`,
      approvedItems || null,
      { params: { workerId, notes } }
    )
    return response.data
  },
  reject: async (requestId: string, workerId: string, reason: string): Promise<ShipmentRequest> => {
    const response = await api.post<ShipmentRequest>(
      `/v1/shipment-requests/${requestId}/reject`,
      null,
      { params: { workerId, reason } }
    )
    return response.data
  },
  prepare: async (requestId: string, sourceCashDeskId: string, targetCashDeskId: string, workerId: string): Promise<{ shipmentId: string; success: boolean }> => {
    const response = await api.post(
      `/v1/shipment-requests/${requestId}/prepare`,
      null,
      { params: { sourceCashDeskId, targetCashDeskId, workerId } }
    )
    return response.data
  },
  findByStatus: async (status: string): Promise<ShipmentRequest[]> => {
    const response = await api.get<ShipmentRequest[]>(`/v1/shipment-requests/status/${status}`)
    return response.data
  },
  findByBranch: async (branchId: string): Promise<ShipmentRequest[]> => {
    const response = await api.get<ShipmentRequest[]>(`/v1/shipment-requests/branch/${branchId}`)
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
  notes?: string
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
    const response = await api.get<PagedResponse<Transfer>>('/transfers', { params })
    return response.data
  },
  countPending: async (): Promise<number> => {
    const response = await api.get<number>('/transfers/pending/count')
    return response.data
  }
}

// ================== REPORTS API ==================

export interface CurrencyTurnover {
  currencyCode: string
  currencyName: string
  buyCount: number
  buyAmount: number
  buyHuf: number
  sellCount: number
  sellAmount: number
  sellHuf: number
}

export interface DailyClosingReport {
  reportDate: string
  branchId: string
  branchName: string
  sessionStatus: string
  openingBalanceHuf: number
  closingBalanceHuf?: number
  transactionCount: number
  buyCount: number
  sellCount: number
  reversalCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  currencyTurnovers: CurrencyTurnover[]
}

export interface PeriodReport {
  startDate: string
  endDate: string
  branchId: string
  branchName: string
  totalTransactionCount: number
  totalBuyCount: number
  totalSellCount: number
  totalReversalCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  dailyBreakdown: DailyClosingReport[]
}

export interface WorkerPerformanceReport {
  workerId: number
  workerName: string
  startDate: string
  endDate: string
  totalTransactionCount: number
  totalBuyCount: number
  totalSellCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  averageDailyTransactions: number
}

export interface CurrencyReport {
  currencyId: number
  currencyCode: string
  currencyName: string
  startDate: string
  endDate: string
  totalBuyCount: number
  totalSellCount: number
  totalBuyAmount: number
  totalSellAmount: number
  totalBuyHuf: number
  totalSellHuf: number
  averageBuyRate: number
  averageSellRate: number
}

export interface CashStatusReport {
  branchId: string
  branchName: string
  reportTime: string
  balances: CashBalance[]
  totalHufEquivalent: number
  lowBalanceAlerts: string[]
  highBalanceAlerts: string[]
}

export const reportApi = {
  getDailyClosing: async (date?: string): Promise<DailyClosingReport> => {
    const params = date ? { date } : {}
    const response = await api.get<DailyClosingReport>('/reports/daily-closing', { params })
    return response.data
  },
  getPeriod: async (startDate: string, endDate: string): Promise<PeriodReport> => {
    const response = await api.get<PeriodReport>('/reports/period', {
      params: { startDate, endDate }
    })
    return response.data
  },
  getWorkerPerformance: async (workerId: number, startDate: string, endDate: string): Promise<WorkerPerformanceReport> => {
    const response = await api.get<WorkerPerformanceReport>(`/reports/worker/${workerId}`, {
      params: { startDate, endDate }
    })
    return response.data
  },
  getCurrencyReport: async (currencyId: number, startDate: string, endDate: string): Promise<CurrencyReport> => {
    const response = await api.get<CurrencyReport>(`/reports/currency/${currencyId}`, {
      params: { startDate, endDate }
    })
    return response.data
  },
  getCashStatus: async (): Promise<CashStatusReport> => {
    const response = await api.get<CashStatusReport>('/reports/cash-status')
    return response.data
  },
  getTodaySummary: async (): Promise<DailyClosingReport> => {
    const response = await api.get<DailyClosingReport>('/reports/today-summary')
    return response.data
  }
}

// ================== CURRENCIES API ==================

export interface Currency {
  id: number
  code: string
  name: string
  symbol?: string
  decimals: number
  displayOrder?: number
  active: boolean
}

export const currencyApi = {
  list: async (): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies')
    return response.data
  },
  getAll: async (): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies/all')
    return response.data
  },
  getActive: async (): Promise<Currency[]> => {
    // Same as list - returns only active currencies
    const response = await api.get<Currency[]>('/currencies')
    return response.data
  },
  getByCode: async (code: string): Promise<Currency> => {
    const response = await api.get<Currency>(`/currencies/code/${code}`)
    return response.data
  },
  getById: async (id: number): Promise<Currency> => {
    const response = await api.get<Currency>(`/currencies/${id}`)
    return response.data
  },
  search: async (query: string): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies/search', { params: { q: query } })
    return response.data
  }
}

// ================== RATE CREATION API ==================

export interface BankRateDTO {
  id: string
  bankId: string
  bankCode: string
  bankName: string
  currencyId: string
  currencyCode: string
  currencyName: string
  buyRate: number
  sellRate: number
  middleRate: number
  validFrom: string
  validTo?: string
  isCurrent: boolean
  source?: string
}

export interface CompetitorRateDTO {
  id: string
  competitorId: string
  competitorCode: string
  competitorName: string
  currencyId: string
  currencyCode: string
  currencyName: string
  buyRate: number
  sellRate: number
  middleRate: number
  recordedAt: string
  source?: string
  recordedById?: string
  recordedByName?: string
}

export interface RateCreationDTO {
  currencyId: string
  currencyCode: string
  currencyName: string
  bankRates: BankRateDTO[]
  competitorRates: CompetitorRateDTO[]
  recommendedBuyRate: number
  recommendedSellRate: number
  recommendedMiddleRate: number
  minBuyRate: number
  maxBuyRate: number
  avgBuyRate: number
  minSellRate: number
  maxSellRate: number
  avgSellRate: number
  notes?: string
}

export interface GroupRateDTO {
  id: string
  currencyGroupId: string
  currencyGroupCode: string
  currencyGroupName: string
  currencyId: string
  currencyCode: string
  buyRate: number
  sellRate: number
  buyMargin: number
  sellMargin: number
  validFrom: string
  isCurrent: boolean
}

export const rateCreationApi = {
  prepareRateCreation: async (currencyId: string): Promise<RateCreationDTO> => {
    const response = await api.get<RateCreationDTO>(`/v1/rate-creation/prepare/${currencyId}`)
    return response.data
  },
  prepareAllCurrencies: async (): Promise<RateCreationDTO[]> => {
    const response = await api.get<RateCreationDTO[]>('/v1/rate-creation/prepare/all')
    return response.data
  },
  recordCompetitorRate: async (data: {
    competitorId: string
    currencyId: string
    buyRate: number
    sellRate: number
    source?: string
  }): Promise<CompetitorRateDTO> => {
    const response = await api.post<CompetitorRateDTO>('/v1/rate-creation/competitor-rates', data)
    return response.data
  },
  recordBankRate: async (data: {
    bankId: string
    currencyId: string
    buyRate: number
    sellRate: number
    middleRate?: number
    source?: string
  }): Promise<BankRateDTO> => {
    const response = await api.post<BankRateDTO>('/v1/rate-creation/bank-rates', data)
    return response.data
  },
  publishGroupRate: async (data: {
    currencyGroupId: string
    currencyId: string
    buyRate: number
    sellRate: number
  }): Promise<GroupRateDTO> => {
    const response = await api.post<GroupRateDTO>('/v1/rate-creation/publish-group-rate', data)
    return response.data
  }
}

// ================== CURRENCY GROUPS API ==================

export interface CurrencyGroupDTO {
  id: string
  code: string
  name: string
  description?: string
  sortOrder?: number
  isActive: boolean
}

export const currencyGroupApi = {
  list: async (): Promise<CurrencyGroupDTO[]> => {
    const response = await api.get<CurrencyGroupDTO[]>('/v1/currency-groups')
    return response.data
  },
  getById: async (id: string): Promise<CurrencyGroupDTO> => {
    const response = await api.get<CurrencyGroupDTO>(`/v1/currency-groups/${id}`)
    return response.data
  }
}

// ================== COMPETITORS API ==================

export interface CompetitorDTO {
  id: string
  code: string
  name: string
  address?: string
  city?: string
  website?: string
  apiUrl?: string
  notes?: string
  isActive: boolean
  sortOrder?: number
}

export const competitorApi = {
  list: async (): Promise<CompetitorDTO[]> => {
    const response = await api.get<CompetitorDTO[]>('/v1/competitors')
    return response.data
  },
  getById: async (id: string): Promise<CompetitorDTO> => {
    const response = await api.get<CompetitorDTO>(`/v1/competitors/${id}`)
    return response.data
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

// ================== DENOMINATION BALANCE API ==================

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
    const response = await api.get<DenominationBalanceDTO[]>(`/v1/cash-desks/${cashDeskId}/denominations`)
    return response.data
  },
  getCashDeskDenominationsByCurrency: async (cashDeskId: string, currencyId: string): Promise<DenominationBalanceDTO[]> => {
    const response = await api.get<DenominationBalanceDTO[]>(`/v1/cash-desks/${cashDeskId}/denominations/currency/${currencyId}`)
    return response.data
  },
  updateDenominationQuantity: async (cashDeskId: string, denominationId: string, quantity: number): Promise<DenominationBalanceDTO> => {
    const response = await api.put<DenominationBalanceDTO>(
      `/v1/cash-desks/${cashDeskId}/denominations/${denominationId}`,
      null,
      { params: { quantity } }
    )
    return response.data
  },
  setDenominationQuantities: async (cashDeskId: string, updates: DenominationQuantityUpdateRequest[]): Promise<DenominationBalanceDTO[]> => {
    const response = await api.post<DenominationBalanceDTO[]>(`/v1/cash-desks/${cashDeskId}/denominations/batch`, updates)
    return response.data
  },
  calculateTotalFromDenominations: async (cashDeskId: string, currencyId: string): Promise<number> => {
    const response = await api.get<number>(`/v1/cash-desks/${cashDeskId}/denominations/currency/${currencyId}/total`)
    return response.data
  }
}

// ================== USER API ==================

export interface User {
  id: string
  username: string
  name: string
  email: string
  role: string
  isActive: boolean
  lastLogin?: string
  createdAt: string
}

export interface UserDetail extends User {
  workerId?: string
  workerName?: string
  defaultBranchId?: string
  defaultBranchName?: string
  isLocked?: boolean
  lastLoginAt?: string
  mustChangePassword?: boolean
  roles?: string[]
  permissions?: string[]
}

export interface UserCreateRequest {
  username: string
  email: string
  password: string
  fullName?: string
  roleId?: string
  branchId?: string
}

export interface UserUpdateRequest {
  email?: string
  fullName?: string
  roleId?: string
  branchId?: string
  active?: boolean
}

export interface ChangePasswordRequest {
  newPassword: string
}

export const userApi = {
  list: async (): Promise<UserDetail[]> => {
    const response = await api.get<UserDetail[]>('/users')
    return response.data
  },
  getById: async (id: string): Promise<UserDetail> => {
    const response = await api.get<UserDetail>(`/users/${id}`)
    return response.data
  },
  getCurrentUser: async (): Promise<User> => {
    const response = await api.get<User>('/users/me')
    return response.data
  },
  create: async (data: UserCreateRequest): Promise<UserDetail> => {
    const response = await api.post<UserDetail>('/users', data)
    return response.data
  },
  update: async (id: string, data: UserUpdateRequest): Promise<UserDetail> => {
    const response = await api.put<UserDetail>(`/users/${id}`, data)
    return response.data
  },
  changePassword: async (id: string, newPassword: string): Promise<void> => {
    await api.post(`/users/${id}/change-password`, { newPassword })
  },
  toggleActive: async (id: string): Promise<UserDetail> => {
    const response = await api.post<UserDetail>(`/users/${id}/toggle-active`)
    return response.data
  },
  archive: async (id: string): Promise<void> => {
    await api.post(`/users/${id}/archive`)
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/users/${id}`)
  },
  updatePassword: async (oldPassword: string, newPassword: string): Promise<void> => {
    await api.put('/users/me/password', { oldPassword, newPassword })
  }
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
    const response = await api.get<SystemParameter[]>('/v1/system-parameters')
    return response.data
  },
  getActive: async (): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>('/v1/system-parameters/active')
    return response.data
  },
  getByCategory: async (category: string): Promise<SystemParameter[]> => {
    const response = await api.get<SystemParameter[]>(`/v1/system-parameters/category/${category}`)
    return response.data
  },
  getByKey: async (parameterKey: string): Promise<SystemParameter> => {
    const response = await api.get<SystemParameter>(`/v1/system-parameters/key/${parameterKey}`)
    return response.data
  },
  getValue: async (parameterKey: string): Promise<string> => {
    const response = await api.get<string>(`/v1/system-parameters/value/${parameterKey}`)
    return response.data
  },
  create: async (data: SystemParameterCreateRequest): Promise<SystemParameter> => {
    const response = await api.post<SystemParameter>('/v1/system-parameters', data)
    return response.data
  },
  update: async (id: string, data: Partial<SystemParameterCreateRequest>): Promise<SystemParameter> => {
    const response = await api.put<SystemParameter>(`/v1/system-parameters/${id}`, data)
    return response.data
  },
  toggleActive: async (id: string): Promise<SystemParameter> => {
    const response = await api.post<SystemParameter>(`/v1/system-parameters/${id}/toggle-active`)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/system-parameters/${id}`)
  }
}

// ================== PERMISSION API ==================

export interface Permission {
  id: string
  code: string
  name: string
  description?: string
  module: string
  isSystemPermission: boolean
  isActive: boolean
  createdAt: string
}

export interface PermissionCreateRequest {
  code: string
  name: string
  description?: string
  module: string
  isSystemPermission?: boolean
  isActive?: boolean
}

export const permissionApi = {
  list: async (): Promise<Permission[]> => {
    const response = await api.get<Permission[]>('/v1/permissions')
    return response.data
  },
  getActive: async (): Promise<Permission[]> => {
    const response = await api.get<Permission[]>('/v1/permissions/active')
    return response.data
  },
  getByModule: async (module: string): Promise<Permission[]> => {
    const response = await api.get<Permission[]>(`/v1/permissions/module/${module}`)
    return response.data
  },
  getById: async (id: string): Promise<Permission> => {
    const response = await api.get<Permission>(`/v1/permissions/${id}`)
    return response.data
  },
  create: async (data: PermissionCreateRequest): Promise<Permission> => {
    const response = await api.post<Permission>('/v1/permissions', data)
    return response.data
  },
  update: async (id: string, data: Partial<PermissionCreateRequest>): Promise<Permission> => {
    const response = await api.put<Permission>(`/v1/permissions/${id}`, data)
    return response.data
  },
  toggleActive: async (id: string): Promise<Permission> => {
    const response = await api.post<Permission>(`/v1/permissions/${id}/toggle-active`)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/permissions/${id}`)
  }
}

// ================== ROLE API ==================

export interface Role {
  id: string
  code: string
  name: string
  description?: string
  roleType: string
  hierarchyLevel?: number
  isSystemRole: boolean
  isActive: boolean
  permissions: string[] // Permission names (not IDs)
}

export interface RoleCreateRequest {
  code: string
  name: string
  description?: string
  permissionIds?: string[]
}

export interface RoleUpdateRequest {
  name?: string
  description?: string
  active?: boolean
  permissionIds?: string[]
}

export const roleApi = {
  list: async (): Promise<Role[]> => {
    const response = await api.get<Role[]>('/roles')
    return response.data
  },
  getById: async (id: string): Promise<Role> => {
    const response = await api.get<Role>(`/roles/${id}`)
    return response.data
  },
  create: async (data: RoleCreateRequest): Promise<Role> => {
    const response = await api.post<Role>('/roles', data)
    return response.data
  },
  update: async (id: string, data: RoleUpdateRequest): Promise<Role> => {
    const response = await api.put<Role>(`/roles/${id}`, data)
    return response.data
  },
  addPermission: async (roleId: string, permissionId: string): Promise<Role> => {
    const response = await api.post<Role>(`/roles/${roleId}/permissions/${permissionId}`)
    return response.data
  },
  removePermission: async (roleId: string, permissionId: string): Promise<void> => {
    await api.delete(`/roles/${roleId}/permissions/${permissionId}`)
  },
  toggleActive: async (id: string): Promise<Role> => {
    const response = await api.post<Role>(`/roles/${id}/toggle-active`)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/roles/${id}`)
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
    const response = await api.get<WorkerCommission[]>('/v1/worker-commissions')
    return response.data
  },
  getByWorker: async (workerId: string): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>(`/v1/worker-commissions/worker/${workerId}`)
    return response.data
  },
  getByPeriod: async (startDate: string, endDate: string): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>('/v1/worker-commissions/period', {
      params: { startDate, endDate }
    })
    return response.data
  },
  calculate: async (
    workerId: string,
    calculatedByWorkerId: string,
    periodStart: string,
    periodEnd: string,
    branchId?: string
  ): Promise<WorkerCommission> => {
    const response = await api.post<WorkerCommission>('/v1/worker-commissions/calculate', null, {
      params: { workerId, calculatedByWorkerId, periodStart, periodEnd, branchId }
    })
    return response.data
  },
  approve: async (commissionId: string, approvedByWorkerId: string): Promise<WorkerCommission> => {
    const response = await api.post<WorkerCommission>(`/v1/worker-commissions/${commissionId}/approve`, null, {
      params: { approvedByWorkerId }
    })
    return response.data
  },
  getAccountingList: async (periodStart: string, periodEnd: string): Promise<WorkerCommission[]> => {
    const response = await api.get<WorkerCommission[]>('/v1/worker-commissions/accounting-list', {
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
    const response = await api.get<Workstation[]>('/v1/workstations')
    return response.data
  },
  getActive: async (): Promise<Workstation[]> => {
    const response = await api.get<Workstation[]>('/v1/workstations/active')
    return response.data
  },
  getByBranch: async (branchId: string): Promise<Workstation[]> => {
    const response = await api.get<Workstation[]>(`/v1/workstations/branch/${branchId}`)
    return response.data
  },
  getById: async (id: string): Promise<Workstation> => {
    const response = await api.get<Workstation>(`/v1/workstations/${id}`)
    return response.data
  },
  create: async (data: WorkstationCreateRequest): Promise<Workstation> => {
    const response = await api.post<Workstation>('/v1/workstations', data)
    return response.data
  },
  update: async (id: string, data: Partial<WorkstationCreateRequest>): Promise<Workstation> => {
    const response = await api.put<Workstation>(`/v1/workstations/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/workstations/${id}`)
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
    const response = await api.get<Contribution[]>('/v1/contributions')
    return response.data
  },
  getById: async (id: string): Promise<Contribution> => {
    const response = await api.get<Contribution>(`/v1/contributions/${id}`)
    return response.data
  },
  getByWorker: async (workerId: string): Promise<Contribution[]> => {
    const response = await api.get<Contribution[]>(`/v1/contributions/worker/${workerId}`)
    return response.data
  },
  getByPeriod: async (startDate: string, endDate: string): Promise<Contribution[]> => {
    const response = await api.get<Contribution[]>('/v1/contributions/period', {
      params: { startDate, endDate }
    })
    return response.data
  },
  calculate: async (
    workerId: string,
    periodStart: string,
    periodEnd: string,
    calculatedByWorkerId: string,
    branchId?: string
  ): Promise<Contribution> => {
    const response = await api.post<Contribution>('/v1/contributions/calculate', null, {
      params: { workerId, periodStart, periodEnd, calculatedByWorkerId, branchId }
    })
    return response.data
  },
  approve: async (contributionId: string, approvedByWorkerId: string): Promise<Contribution> => {
    const response = await api.post<Contribution>(`/v1/contributions/${contributionId}/approve`, null, {
      params: { approvedByWorkerId }
    })
    return response.data
  },
  update: async (id: string, data: Partial<Contribution>): Promise<Contribution> => {
    const response = await api.put<Contribution>(`/v1/contributions/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/contributions/${id}`)
  }
}

// ================== ORGANIZATION API ==================

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
  list: async (): Promise<Organization[]> => {
    const response = await api.get<Organization[]>('/v1/organizations')
    return response.data
  },
  getActive: async (): Promise<Organization[]> => {
    const response = await api.get<Organization[]>('/v1/organizations/active')
    return response.data
  },
  getRoots: async (): Promise<Organization[]> => {
    const response = await api.get<Organization[]>('/v1/organizations/root')
    return response.data
  },
  getById: async (id: string): Promise<Organization> => {
    const response = await api.get<Organization>(`/v1/organizations/${id}`)
    return response.data
  },
  create: async (data: Partial<Organization>, workerId: string): Promise<Organization> => {
    const response = await api.post<Organization>('/v1/organizations', data, {
      params: { workerId }
    })
    return response.data
  },
  update: async (id: string, data: Partial<Organization>): Promise<Organization> => {
    const response = await api.put<Organization>(`/v1/organizations/${id}`, data)
    return response.data
  },
  archive: async (id: string): Promise<void> => {
    await api.post(`/v1/organizations/${id}/archive`)
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/organizations/${id}`)
  }
}

// ================== OWN COMPANY API ==================

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
  list: async (): Promise<OwnCompany[]> => {
    const response = await api.get<OwnCompany[]>('/v1/own-companies')
    return response.data
  },
  getActive: async (): Promise<OwnCompany[]> => {
    const response = await api.get<OwnCompany[]>('/v1/own-companies/active')
    return response.data
  },
  getById: async (id: string): Promise<OwnCompany> => {
    const response = await api.get<OwnCompany>(`/v1/own-companies/${id}`)
    return response.data
  },
  create: async (data: Partial<OwnCompany>): Promise<OwnCompany> => {
    const response = await api.post<OwnCompany>('/v1/own-companies', data)
    return response.data
  },
  update: async (id: string, data: Partial<OwnCompany>): Promise<OwnCompany> => {
    const response = await api.put<OwnCompany>(`/v1/own-companies/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/own-companies/${id}`)
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
    const response = await api.get<Receipt[]>('/v1/receipts', { params })
    return response.data
  },
  getById: async (id: string): Promise<Receipt> => {
    const response = await api.get<Receipt>(`/v1/receipts/${id}`)
    return response.data
  },
  print: async (id: string): Promise<void> => {
    await api.post(`/v1/receipts/${id}/print`)
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
    const response = await api.get<HandoverSheet[]>('/v1/handover-sheets')
    return response.data
  },
  getById: async (id: string): Promise<HandoverSheet> => {
    const response = await api.get<HandoverSheet>(`/v1/handover-sheets/${id}`)
    return response.data
  },
  generate: async (fromCashDeskId: string, toCashDeskId: string, transferDate: string, amounts: CurrencyAmounts): Promise<HandoverSheet> => {
    const response = await api.post<HandoverSheet>('/v1/handover-sheets/generate', {
      fromCashDeskId, toCashDeskId, transferDate, amounts
    })
    return response.data
  },
  print: async (id: string): Promise<void> => {
    await api.post(`/v1/handover-sheets/${id}/print`)
  },
  complete: async (id: string): Promise<HandoverSheet> => {
    const response = await api.post<HandoverSheet>(`/v1/handover-sheets/${id}/complete`)
    return response.data
  }
}

// ================== REPORT EXTENDED API ==================

export interface ReportSummary {
  totalCount: number
  totalAmount?: number
  totalProfit?: number
  [key: string]: string | number | undefined
}

export interface TransactionListReport {
  transactions: Transaction[]
  summary: ReportSummary
}

export interface ReceiptListReport {
  receipts: Receipt[]
  summary: ReportSummary
}

export const reportExtendedApi = {
  getTransactionList: async (branchId: string | undefined, startDate: string, endDate: string): Promise<TransactionListReport> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get<TransactionListReport>('/v1/reports-extended/transaction-list', { params })
    return response.data
  },
  getReceiptList: async (branchId: string | undefined, startDate: string, endDate: string): Promise<ReceiptListReport> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get<ReceiptListReport>('/v1/reports-extended/receipt-list', { params })
    return response.data
  },
  getFeeSummary: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/v1/reports-extended/fee-summary', { params })
    return response.data
  },
  getMonthlyInventory: async (branchId: string | undefined, year: number, month: number): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/v1/reports-extended/monthly-inventory', { params })
    return response.data
  },
  getMonthlyTurnover: async (branchId: string | undefined, year: number, month: number): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/v1/reports-extended/monthly-turnover', { params })
    return response.data
  },
  getMonthlyTransfers: async (branchId: string | undefined, year: number, month: number): Promise<unknown> => {
    const params: Record<string, string | number> = { year, month }
    if (branchId) params.branchId = branchId
    const response = await api.get('/v1/reports-extended/monthly-transfers', { params })
    return response.data
  },
  getHandlingCost: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/v1/reports-extended/handling-cost', { params })
    return response.data
  },
  getDailyCashDesk: async (cashDeskId: string, date: string): Promise<unknown> => {
    const response = await api.get('/v1/reports-extended/daily-cash-desk', {
      params: { cashDeskId, date }
    })
    return response.data
  },
  getCurrentCashDeskStatus: async (cashDeskId: string): Promise<unknown> => {
    const response = await api.get('/v1/reports-extended/current-cash-desk-status', {
      params: { cashDeskId }
    })
    return response.data
  },
  getSuspiciousTransactions: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/v1/reports-extended/suspicious-transactions', { params })
    return response.data
  },
  getCardTransactionFees: async (branchId: string | undefined, startDate: string, endDate: string): Promise<unknown> => {
    const params: Record<string, string> = { startDate, endDate }
    if (branchId) params.branchId = branchId
    const response = await api.get('/v1/reports-extended/card-transaction-fees', { params })
    return response.data
  }
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
    const response = await api.get<CashDeskBreak[]>('/v1/cash-desk-breaks', { params })
    return response.data
  },
  getActive: async (cashDeskId: string): Promise<CashDeskBreak | null> => {
    const response = await api.get<CashDeskBreak>(`/v1/cash-desk-breaks/active/${cashDeskId}`)
    return response.data
  },
  start: async (cashDeskId: string, breakType: string, reason?: string): Promise<CashDeskBreak> => {
    const response = await api.post<CashDeskBreak>('/v1/cash-desk-breaks/start', null, {
      params: { cashDeskId, breakType, reason }
    })
    return response.data
  },
  end: async (breakId: string): Promise<CashDeskBreak> => {
    const response = await api.post<CashDeskBreak>(`/v1/cash-desk-breaks/${breakId}/end`)
    return response.data
  }
}

// ================== LOGGING API ==================

export interface AuditLog {
  id: string
  action: string
  entityType: string
  entityId: string
  userId?: string
  userName?: string
  branchId?: string
  branchName?: string
  changes?: string
  ipAddress?: string
  userAgent?: string
  createdAt: string
}

export const loggingApi = {
  getSystemLogs: async (from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/v1/logs/system', { params })
    return response.data
  },
  getPosLogs: async (from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/v1/logs/pos', { params })
    return response.data
  },
  getNavLogs: async (from?: string, to?: string, page = 0, size = 50): Promise<{ content: AuditLog[]; totalElements: number }> => {
    const params: Record<string, string | number> = { page, size }
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/v1/logs/nav', { params })
    return response.data
  },
  exportToCsv: async (from?: string, to?: string): Promise<Blob> => {
    const params: Record<string, string> = {}
    if (from) params.from = from
    if (to) params.to = to
    const response = await api.get('/v1/logs/export', { params, responseType: 'blob' })
    return response.data
  }
}

// ================== BRANCH GROUP API ==================

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
  list: async (): Promise<BranchGroup[]> => {
    const response = await api.get<BranchGroup[]>('/v1/branch-groups')
    return response.data
  },
  getActive: async (): Promise<BranchGroup[]> => {
    const response = await api.get<BranchGroup[]>('/v1/branch-groups/active')
    return response.data
  },
  getRoots: async (): Promise<BranchGroup[]> => {
    const response = await api.get<BranchGroup[]>('/v1/branch-groups/roots')
    return response.data
  },
  getById: async (id: string): Promise<BranchGroup> => {
    const response = await api.get<BranchGroup>(`/v1/branch-groups/${id}`)
    return response.data
  },
  create: async (data: Partial<BranchGroup>, workerId: string): Promise<BranchGroup> => {
    const response = await api.post<BranchGroup>('/v1/branch-groups', data, {
      params: { workerId }
    })
    return response.data
  },
  update: async (id: string, data: Partial<BranchGroup>): Promise<BranchGroup> => {
    const response = await api.put<BranchGroup>(`/v1/branch-groups/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/branch-groups/${id}`)
  }
}

// ================== FEE API ==================

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

export const feeApi = {
  getTypes: async (): Promise<FeeType[]> => {
    const response = await api.get<FeeType[]>('/v1/fees/types')
    return response.data
  },
  createType: async (data: Partial<FeeType>): Promise<FeeType> => {
    const response = await api.post<FeeType>('/v1/fees/types', data)
    return response.data
  },
  updateType: async (id: string, data: Partial<FeeType>): Promise<FeeType> => {
    const response = await api.put<FeeType>(`/v1/fees/types/${id}`, data)
    return response.data
  },
  deleteType: async (id: string): Promise<void> => {
    await api.delete(`/v1/fees/types/${id}`)
  },
  getRates: async (): Promise<FeeRate[]> => {
    const response = await api.get<FeeRate[]>('/v1/fees/rates')
    return response.data
  },
  createRate: async (data: Partial<FeeRate>): Promise<FeeRate> => {
    const response = await api.post<FeeRate>('/v1/fees/rates', data)
    return response.data
  },
  updateRate: async (id: string, data: Partial<FeeRate>): Promise<FeeRate> => {
    const response = await api.put<FeeRate>(`/v1/fees/rates/${id}`, data)
    return response.data
  },
  deleteRate: async (id: string): Promise<void> => {
    await api.delete(`/v1/fees/rates/${id}`)
  },
  getDiscounts: async (): Promise<FeeDiscount[]> => {
    const response = await api.get<FeeDiscount[]>('/v1/fees/discounts')
    return response.data
  },
  createDiscount: async (data: Partial<FeeDiscount>): Promise<FeeDiscount> => {
    const response = await api.post<FeeDiscount>('/v1/fees/discounts', data)
    return response.data
  },
  updateDiscount: async (id: string, data: Partial<FeeDiscount>): Promise<FeeDiscount> => {
    const response = await api.put<FeeDiscount>(`/v1/fees/discounts/${id}`, data)
    return response.data
  },
  deleteDiscount: async (id: string): Promise<void> => {
    await api.delete(`/v1/fees/discounts/${id}`)
  }
}

// ================== BLACKLIST API ==================

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
  getPersons: async (): Promise<ProhibitedPerson[]> => {
    const response = await api.get<ProhibitedPerson[]>('/v1/blacklist/persons')
    return response.data
  },
  createPerson: async (data: Partial<ProhibitedPerson>): Promise<ProhibitedPerson> => {
    const response = await api.post<ProhibitedPerson>('/v1/blacklist/persons', data)
    return response.data
  },
  updatePerson: async (id: string, data: Partial<ProhibitedPerson>): Promise<ProhibitedPerson> => {
    const response = await api.put<ProhibitedPerson>(`/v1/blacklist/persons/${id}`, data)
    return response.data
  },
  deletePerson: async (id: string): Promise<void> => {
    await api.delete(`/v1/blacklist/persons/${id}`)
  },
  getCompanies: async (): Promise<ProhibitedCompany[]> => {
    const response = await api.get<ProhibitedCompany[]>('/v1/blacklist/companies')
    return response.data
  },
  createCompany: async (data: Partial<ProhibitedCompany>): Promise<ProhibitedCompany> => {
    const response = await api.post<ProhibitedCompany>('/v1/blacklist/companies', data)
    return response.data
  },
  updateCompany: async (id: string, data: Partial<ProhibitedCompany>): Promise<ProhibitedCompany> => {
    const response = await api.put<ProhibitedCompany>(`/v1/blacklist/companies/${id}`, data)
    return response.data
  },
  deleteCompany: async (id: string): Promise<void> => {
    await api.delete(`/v1/blacklist/companies/${id}`)
  },
  importPersons: async (file: File): Promise<void> => {
    const formData = new FormData()
    formData.append('file', file)
    await api.post('/v1/blacklist/persons/import', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
  },
  importCompanies: async (file: File): Promise<void> => {
    const formData = new FormData()
    formData.append('file', file)
    await api.post('/v1/blacklist/companies/import', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
  }
}

// ================== ANONYMOUS REPORT API ==================

export interface AnonymousReport {
  id: string
  reportType: string
  subject?: string
  description: string
  reportedAt: string
  status: string
  assignedToId?: string
  assignedToName?: string
  resolution?: string
}

export const anonymousReportApi = {
  list: async (): Promise<AnonymousReport[]> => {
    const response = await api.get<AnonymousReport[]>('/v1/anonymous-reports')
    return response.data
  },
  getById: async (id: string): Promise<AnonymousReport> => {
    const response = await api.get<AnonymousReport>(`/v1/anonymous-reports/${id}`)
    return response.data
  },
  create: async (data: Partial<AnonymousReport>): Promise<AnonymousReport> => {
    const response = await api.post<AnonymousReport>('/v1/anonymous-reports', data)
    return response.data
  },
  assign: async (id: string, assignedToId: string): Promise<AnonymousReport> => {
    const response = await api.post<AnonymousReport>(`/v1/anonymous-reports/${id}/assign`, null, {
      params: { assignedToId }
    })
    return response.data
  },
  resolve: async (id: string, resolution: string): Promise<AnonymousReport> => {
    const response = await api.post<AnonymousReport>(`/v1/anonymous-reports/${id}/resolve`, null, {
      params: { resolution }
    })
    return response.data
  }
}

// ================== COMMISSION RATE API ==================

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
  list: async (): Promise<CommissionRate[]> => {
    const response = await api.get<CommissionRate[]>('/v1/commission-rates')
    return response.data
  },
  getById: async (id: string): Promise<CommissionRate> => {
    const response = await api.get<CommissionRate>(`/v1/commission-rates/${id}`)
    return response.data
  },
  create: async (data: Partial<CommissionRate>): Promise<CommissionRate> => {
    const response = await api.post<CommissionRate>('/v1/commission-rates', data)
    return response.data
  },
  update: async (id: string, data: Partial<CommissionRate>): Promise<CommissionRate> => {
    const response = await api.put<CommissionRate>(`/v1/commission-rates/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/commission-rates/${id}`)
  }
}

// ================== ARCHIVING API ==================

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

export const archivingApi = {
  listTasks: async (): Promise<ArchiveTask[]> => {
    const response = await api.get<ArchiveTask[]>('/v1/archiving/tasks')
    return response.data
  },
  createTask: async (data: Partial<ArchiveTask>): Promise<ArchiveTask> => {
    const response = await api.post<ArchiveTask>('/v1/archiving/tasks', data)
    return response.data
  },
  executeTask: async (id: string): Promise<ArchiveTask> => {
    const response = await api.post<ArchiveTask>(`/v1/archiving/tasks/${id}/execute`)
    return response.data
  }
}

// ================== EXCHANGE RATE DISPLAY API ==================

export interface ExchangeRateDisplay {
  id: string
  displayName: string
  currencyIds: string[]
  refreshInterval: number
  isActive: boolean
}

export const exchangeRateDisplayApi = {
  list: async (): Promise<ExchangeRateDisplay[]> => {
    const response = await api.get<ExchangeRateDisplay[]>('/v1/exchange-rate-display')
    return response.data
  },
  getCurrentRates: async (displayId: string): Promise<Record<string, unknown>> => {
    const response = await api.get(`/v1/exchange-rate-display/${displayId}/current-rates`)
    return response.data
  },
  updateDisplay: async (displayId: string, rates: Record<string, unknown>): Promise<void> => {
    await api.post(`/v1/exchange-rate-display/${displayId}/update`, rates)
  }
}

// ================== SYNCHRONIZATION API ==================

export interface SynchronizationResult {
  success: boolean
  recordsSynced: number
  errors: string[]
}

export const synchronizationApi = {
  synchronize: async (branchId: string, workerId: string): Promise<SynchronizationResult> => {
    const response = await api.post<SynchronizationResult>('/v1/synchronization/sync', null, {
      params: { branchId, workerId }
    })
    return response.data
  },
  shouldAutoSync: async (branchId: string): Promise<boolean> => {
    const response = await api.get<boolean>('/v1/synchronization/should-sync', {
      params: { branchId }
    })
    return response.data
  }
}

// ================== POS TERMINAL API ==================

export interface PosTerminal {
  id: string
  terminalId: string
  terminalName: string
  branchId?: string
  branchName?: string
  isActive: boolean
  lastTransactionAt?: string
}

export const posTerminalApi = {
  list: async (): Promise<PosTerminal[]> => {
    const response = await api.get<PosTerminal[]>('/v1/pos-terminal')
    return response.data
  },
  getById: async (id: string): Promise<PosTerminal> => {
    const response = await api.get<PosTerminal>(`/v1/pos-terminal/${id}`)
    return response.data
  },
  processTransaction: async (terminalId: string, amount: number, currency: string): Promise<Record<string, unknown>> => {
    const response = await api.post('/v1/pos-terminal/process-transaction', null, {
      params: { terminalId, amount, currency }
    })
    return response.data
  }
}

// ================== NAV INTEGRATION API ==================

export interface NavSendResult {
  success: boolean
  receiptNumber?: string
  error?: string
}

export const navIntegrationApi = {
  sendTransaction: async (transactionId: string, comPort: string): Promise<NavSendResult> => {
    const response = await api.post<NavSendResult>('/v1/nav-integration/send-transaction', null, {
      params: { transactionId, comPort }
    })
    return response.data
  },
  receiveReceiptNumber: async (comPort: string): Promise<string> => {
    const response = await api.get<string>('/v1/nav-integration/receive-receipt-number', {
      params: { comPort }
    })
    return response.data
  },
  sendQrCode: async (qrCode: string, comPort: string): Promise<boolean> => {
    const response = await api.post<boolean>('/v1/nav-integration/send-qr-code', null, {
      params: { qrCode, comPort }
    })
    return response.data
  }
}

// ================== DOCUMENT STORAGE API ==================

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

export const documentStorageApi = {
  list: async (entityType?: string, entityId?: string): Promise<Document[]> => {
    const params: Record<string, string> = {}
    if (entityType) params.entityType = entityType
    if (entityId) params.entityId = entityId
    const response = await api.get<Document[]>('/v1/documents', { params })
    return response.data
  },
  upload: async (file: File, entityType?: string, entityId?: string): Promise<Document> => {
    const formData = new FormData()
    formData.append('file', file)
    if (entityType) formData.append('entityType', entityType)
    if (entityId) formData.append('entityId', entityId)
    const response = await api.post<Document>('/v1/documents', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return response.data
  },
  download: async (id: string): Promise<Blob> => {
    const response = await api.get(`/v1/documents/${id}/download`, {
      responseType: 'blob'
    })
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/documents/${id}`)
  }
}

// ================== NOTIFICATION API ==================

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
  list: async (): Promise<Notification[]> => {
    const response = await api.get<Notification[]>('/v1/notifications')
    return response.data
  },
  getUnread: async (): Promise<Notification[]> => {
    const response = await api.get<Notification[]>('/v1/notifications/unread')
    return response.data
  },
  markAsRead: async (id: string): Promise<void> => {
    await api.post(`/v1/notifications/${id}/mark-read`)
  },
  markAllAsRead: async (): Promise<void> => {
    await api.post('/v1/notifications/mark-all-read')
  },
  send: async (userId: string, title: string, message: string, type: string): Promise<Notification> => {
    const response = await api.post<Notification>('/v1/notifications', {
      userId, title, message, type
    })
    return response.data
  }
}

// ================== ORGANIZATIONAL SYSTEM PARAMETER API ==================

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
}

export const organizationalSystemParameterApi = {
  list: async (organizationId?: string): Promise<OrganizationalSystemParameter[]> => {
    const params = organizationId ? { organizationId } : {}
    const response = await api.get<OrganizationalSystemParameter[]>('/v1/organizational-system-parameters', { params })
    return response.data
  },
  getById: async (id: string): Promise<OrganizationalSystemParameter> => {
    const response = await api.get<OrganizationalSystemParameter>(`/v1/organizational-system-parameters/${id}`)
    return response.data
  },
  create: async (data: Partial<OrganizationalSystemParameter>): Promise<OrganizationalSystemParameter> => {
    const response = await api.post<OrganizationalSystemParameter>('/v1/organizational-system-parameters', data)
    return response.data
  },
  update: async (id: string, data: Partial<OrganizationalSystemParameter>): Promise<OrganizationalSystemParameter> => {
    const response = await api.put<OrganizationalSystemParameter>(`/v1/organizational-system-parameters/${id}`, data)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/v1/organizational-system-parameters/${id}`)
  }
}
