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
  teaorCode?: string
  active: boolean
  isVip: boolean
  isPep?: boolean
  notes?: string
  riskRating?: 'LOW' | 'MEDIUM' | 'HIGH'
  reviewStatus?: 'PENDING_REVIEW' | 'REVIEWED'
  reviewedBy?: string
  reviewedAt?: string
  // Megerősített eljárás (EDD, V.2.7 — V309/V310)
  eddUntil?: string
  eddReason?: string
  eddActive?: boolean
  lastTransactionDate?: string
  transactionCount: number
  createdAt: string
  updatedAt?: string
}

export interface CustomerRanking {
  customerId: number
  customerName: string
  transactionCount: number
  totalVolumeHuf: number
  rank: number
}

export interface CustomerStats {
  customerId: number
  customerName: string
  totalTransactions: number
  totalVolumeHuf: number
  averageAmount: number
  firstVisit?: string | null
  lastVisit?: string | null
  preferredCurrency?: string | null
}

export interface CustomerVersion {
  versionNo: number
  changedBy?: string
  changedAt: string
  changeSource: 'CASHIER' | 'COMPLIANCE'
  snapshot?: string
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
  teaorCode?: string
  isVip?: boolean
  isPep?: boolean
  notes?: string
}

export interface CustomerRestriction {
  id: string
  customerId: number
  restrictionType: 'BLOCKED' | 'SUSPICIOUS' | 'WATCH_LIST' | 'ANNUAL_LIMIT' | string
  reason: string
  addedBy?: number
  addedAt?: string
  expiresAt?: string | null
  active: boolean
}

export interface CreateCustomerRestrictionRequest {
  restrictionType: CustomerRestriction['restrictionType']
  reason: string
  expiresAt?: string | null
}

export interface CustomerScreeningLog {
  id: string
  customerId?: number
  screeningType: string
  result: string
  details?: string
  screenedAt?: string
  screenedBy?: number
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
  /** Pmt. 30.§ (1) manuális EDD-jelölés (V.2.7 c) — supervisor+ jogosultság. */
  markEdd: async (id: number, reason: string): Promise<Customer> => {
    const response = await api.post<Customer>(`/customers/${id}/edd-mark`, { reason })
    return response.data
  },
  /** FS-2 (MNB): kockázati besorolás állítása — MANAGER/ADMIN jogosultság. */
  setRiskRating: async (
    id: number,
    riskRating: 'LOW' | 'MEDIUM' | 'HIGH',
    reason: string,
  ): Promise<Customer> => {
    const response = await api.post<Customer>(`/customers/${id}/risk-rating`, {
      riskRating,
      reason,
    })
    return response.data
  },
  review: async (id: number): Promise<Customer> => {
    const response = await api.post<Customer>(`/customers/${id}/review`)
    return response.data
  },
  getPendingReview: async (): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers/pending-review')
    return response.data
  },
  getVersions: async (id: number): Promise<CustomerVersion[]> => {
    const response = await api.get<CustomerVersion[]>(`/customers/${id}/versions`)
    return response.data
  },
  getVersion: async (id: number, versionNo: number): Promise<CustomerVersion> => {
    const response = await api.get<CustomerVersion>(`/customers/${id}/versions/${versionNo}`)
    return response.data
  },
  getByDocumentNumber: async (documentNumber: string): Promise<Customer> => {
    const response = await api.get<Customer>(`/customers/document/${documentNumber}`)
    return response.data
  },
  getByIdCard: async (idCardNumber: string): Promise<Customer> => {
    const response = await api.get<Customer>(`/customers/id-card/${idCardNumber}`)
    return response.data
  },
  getByPassport: async (passportNumber: string): Promise<Customer> => {
    const response = await api.get<Customer>(`/customers/passport/${passportNumber}`)
    return response.data
  },
  getByCode: async (customerCode: string): Promise<Customer> => {
    const response = await api.get<Customer>(`/customers/code/${customerCode}`)
    return response.data
  },
  search: async (name: string): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers', { params: { query: name } })
    return response.data
  },
  searchByName: async (name: string): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers/search', { params: { name } })
    return response.data
  },
  getVip: async (): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers/vip')
    return response.data
  },
  getFrequent: async (params?: {
    branchId?: string
    minTx?: number
  }): Promise<CustomerRanking[]> => {
    const response = await api.get<CustomerRanking[]>('/customers/frequent', { params })
    return response.data
  },
  getTop: async (params?: {
    branchId?: string
    from?: string
    to?: string
    limit?: number
  }): Promise<CustomerRanking[]> => {
    const response = await api.get<CustomerRanking[]>('/customers/top', { params })
    return response.data
  },
  getStats: async (id: number): Promise<CustomerStats> => {
    const response = await api.get<CustomerStats>(`/customers/${id}/stats`)
    return response.data
  },
  getHistory: async (
    id: number,
    params?: { from?: string; to?: string },
  ): Promise<CustomerStats> => {
    const response = await api.get<CustomerStats>(`/customers/${id}/history`, { params })
    return response.data
  },
  getActive: async (): Promise<Customer[]> => {
    const response = await api.get<Customer[]>('/customers/active')
    return response.data
  },
  merge: async (primaryId: number, duplicateId: number): Promise<Customer> => {
    const response = await api.post<Customer>('/customers/merge', { primaryId, duplicateId })
    return response.data
  },
  deactivate: async (id: number): Promise<void> => {
    await api.post(`/customers/${id}/deactivate`)
  },
  activate: async (id: number): Promise<void> => {
    await api.post(`/customers/${id}/activate`)
  },
}

export const customerControlApi = {
  getRestrictions: async (id: number): Promise<CustomerRestriction[]> => {
    const response = await api.get<CustomerRestriction[]>(`/customer-control/${id}/restrictions`)
    return response.data
  },
  addRestriction: async (
    id: number,
    data: CreateCustomerRestrictionRequest,
  ): Promise<CustomerRestriction> => {
    const response = await api.post<CustomerRestriction>(`/customer-control/${id}/restrict`, data)
    return response.data
  },
  removeRestriction: async (restrictionId: string): Promise<void> => {
    await api.delete(`/customer-control/restrictions/${restrictionId}`)
  },
  getAnnualTotal: async (id: number, year?: number): Promise<number> => {
    const response = await api.get<number>(`/customer-control/${id}/annual-total`, {
      params: year ? { year } : undefined,
    })
    return response.data
  },
  getScreeningLog: async (id: number): Promise<CustomerScreeningLog[]> => {
    const response = await api.get<CustomerScreeningLog[]>(`/customer-control/${id}/screening-log`)
    return response.data
  },
}

export interface TeaorCode {
  code: string
  name: string
}

export const teaorApi = {
  search: async (q: string): Promise<TeaorCode[]> => {
    const response = await api.get<TeaorCode[]>('/teaor', { params: { q } })
    return response.data
  },
}

// ================== TRANSACTIONS API ==================

/**
 * Multi-line (több-soros) bizonylat egy tételsora. A mezőnevek PONTOSAN a backend
 * TransactionLineRequestDto-t tükrözik, hogy a Jackson-deszerializáció ne csússzon el.
 * Ha a BuyRequest/SellRequest `lines` tömbje kitöltött, a backend executeMultiLineBuy/Sell
 * ágra fut (EGY tranzakció, EGY AML-grant fogyasztás), és a fejléc currencyAmount/
 * customExchangeRate értékeit FIGYELMEN KÍVÜL hagyja (az első sor adja a fejléc valutáját).
 */
export interface TransactionLineRequest {
  currencyCode: string
  banknoteCount: number
  customExchangeRate?: number | null
  discountType?: number | null
  foreignStatus?: string | null
}

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
  workerCode?: string // 2026-04-29 v2.3.12 (E-B2): backend mar adja, hozzaadtuk a tipust audit display-hez
  createdAt: string
  // G3-G4: PEP + Jogcím nyilatkozat (Legacy Gap Fix)
  customerIsPep?: boolean
  sourceOfFunds?: string
  // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum az 50M Ft feletti ügylethez.
  // A backend AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT flag aktiválásakor töltődik a pénztáros felületről.
  sourceOfFundsDocType?: string
  // ISO-8601 dátum (yyyy-MM-dd) — a backend java.time.LocalDate mezőként deszerializálja (Jackson default).
  sourceOfFundsDocDate?: string
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
  /** AML vezetoi jovahagyas (2026-06-04): jovahagyo workerId, ha a tranzakcio felsovezetoi jovahagyast igenyelt. */
  approverWorkerId?: number
  /** AML jovahagyas-session azonosito — a grantot a konkret nyugtahoz koti (Codex P1: receipt-scoping). */
  approvalSessionId?: string
  currencyId?: number
  currencyCode?: string
  currencyAmount: number
  customExchangeRate?: number
  handlingFee?: number
  // FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override) — a szerver validálja az engedély-mátrixot.
  handlingFeeOverrideType?: 'NONE' | 'HALF' | 'WAIVED' | 'SPECIAL'
  handlingFeeOverrideReason?: 'DIRECTOR_APPROVAL' | 'CUSTOMER_CARD' | 'PROMOTION'
  customerCardNumber?: string
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
  // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum az 50M Ft feletti ügylethez.
  // A backend AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT flag aktiválásakor töltődik a pénztáros felületről.
  sourceOfFundsDocType?: string
  // ISO-8601 dátum (yyyy-MM-dd) — a backend java.time.LocalDate mezőként deszerializálja (Jackson default).
  sourceOfFundsDocDate?: string
  customerIsPep?: boolean
  // V229 (2026-05-15 HIBA #8): 300k+ JOGCIM nyilatkozat
  customerOnOwnBehalf?: boolean
  customerActorName?: string
  // V235 (2026-05-19 HIBA #15 + #17): PEP minoseg + actor teljes azonositasa
  customerPepKind?:
    | 'CSALADTAG'
    | 'KOZELI_MUNKATARS'
    | 'KORMANYFO'
    | 'PARLAMENTI'
    | 'NAV_VEZETO'
    | 'EGYEB'
  /** V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok (max 4). */
  isLegalEntityCustomer?: boolean
  legalEntityName?: string
  legalEntitySeat?: string
  legalEntityTaxNumber?: string
  legalDeedNumber?: string
  beneficialOwners?: Array<{
    name: string
    address?: string
    birthPlace?: string
    birthDate?: string
    nationality?: string
    residenceAbroad?: string
    interestNature?: string
    interestExtent?: string
    isPep?: boolean
  }>
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
  /**
   * Multi-line aggregált vétel (Codex P1, 2026-06-04): ha kitöltött (>1 sor), a backend
   * executeMultiLineBuy ágra fut — EGY tranzakció, EGY AML-grant fogyasztás. A fejléc
   * currencyAmount/customExchangeRate ekkor az ELSŐ sort tükrözi (a backend a fejléc-összeget
   * figyelmen kívül hagyja). Egysoros esetben NE küldd (változatlan single-line viselkedés).
   */
  lines?: TransactionLineRequest[]
}

export interface SellRequest {
  /** AML vezetoi jovahagyas (2026-06-04): jovahagyo workerId, ha a tranzakcio felsovezetoi jovahagyast igenyelt. */
  approverWorkerId?: number
  /** AML jovahagyas-session azonosito — a grantot a konkret nyugtahoz koti (Codex P1: receipt-scoping). */
  approvalSessionId?: string
  currencyId?: number
  currencyCode?: string
  currencyAmount: number
  customExchangeRate?: number
  handlingFee?: number
  // FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override) — a szerver validálja az engedély-mátrixot.
  handlingFeeOverrideType?: 'NONE' | 'HALF' | 'WAIVED' | 'SPECIAL'
  handlingFeeOverrideReason?: 'DIRECTOR_APPROVAL' | 'CUSTOMER_CARD' | 'PROMOTION'
  customerCardNumber?: string
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
  // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum az 50M Ft feletti ügylethez.
  // A backend AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT flag aktiválásakor töltődik a pénztáros felületről.
  sourceOfFundsDocType?: string
  // ISO-8601 dátum (yyyy-MM-dd) — a backend java.time.LocalDate mezőként deszerializálja (Jackson default).
  sourceOfFundsDocDate?: string
  customerIsPep?: boolean
  // V229 (2026-05-15 HIBA #8): 300k+ JOGCIM nyilatkozat
  customerOnOwnBehalf?: boolean
  customerActorName?: string
  // V235 (2026-05-19 HIBA #15 + #17): PEP minoseg + actor teljes azonositasa
  customerPepKind?:
    | 'CSALADTAG'
    | 'KOZELI_MUNKATARS'
    | 'KORMANYFO'
    | 'PARLAMENTI'
    | 'NAV_VEZETO'
    | 'EGYEB'
  /** V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok (max 4). */
  isLegalEntityCustomer?: boolean
  legalEntityName?: string
  legalEntitySeat?: string
  legalEntityTaxNumber?: string
  legalDeedNumber?: string
  beneficialOwners?: Array<{
    name: string
    address?: string
    birthPlace?: string
    birthDate?: string
    nationality?: string
    residenceAbroad?: string
    interestNature?: string
    interestExtent?: string
    isPep?: boolean
  }>
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
  /**
   * Multi-line aggregált eladás (Codex P1, 2026-06-04): ha kitöltött (>1 sor), a backend
   * executeMultiLineSell ágra fut — EGY tranzakció, EGY AML-grant fogyasztás. A fejléc
   * currencyAmount/customExchangeRate ekkor az ELSŐ sort tükrözi (a backend a fejléc-összeget
   * figyelmen kívül hagyja). Egysoros esetben NE küldd (változatlan single-line viselkedés).
   */
  lines?: TransactionLineRequest[]
}

export interface CashierCustomRateQuota {
  used: number
  limit: number
  remaining: number
  minAmountHuf: number
}

export interface ConversionRequest {
  /** AML vezetoi jovahagyas (2026-06-04): jovahagyo workerId, ha a tranzakcio felsovezetoi jovahagyast igenyelt. */
  approverWorkerId?: number
  /** AML jovahagyas-session azonosito — a grantot a konkret nyugtahoz koti (Codex P1: receipt-scoping). */
  approvalSessionId?: string
  fromCurrencyId?: number
  fromCurrencyCode?: string
  toCurrencyId?: number
  toCurrencyCode?: string
  fromAmount: number
  /** Címletezéshez lefelé módosított cél-összeg (HIBA 2026-05-26 #4/#5). */
  toAmount?: number
  /** Ügyfél deviza-státusza (HIBA 2026-05-26 #2). */
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
  handlingFee?: number
  customerId?: string
  customerName?: string
  customerAddress?: string
  customerDocumentNumber?: string
  customerNationality?: string
  sourceOfFunds?: string
  // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum az 50M Ft feletti ügylethez.
  // A backend AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT flag aktiválásakor töltődik a pénztáros felületről.
  sourceOfFundsDocType?: string
  // ISO-8601 dátum (yyyy-MM-dd) — a backend java.time.LocalDate mezőként deszerializálja (Jackson default).
  sourceOfFundsDocDate?: string
  customerIsPep?: boolean
  notes?: string
  // V235 + V236 (2026-05-19 HIBA #19): Konverzio Pmt. azonositas
  customerBirthPlace?: string
  customerBirthDate?: string
  customerMotherName?: string
  customerDocumentType?: string
  customerOnOwnBehalf?: boolean
  customerActorName?: string
  customerPepKind?:
    | 'CSALADTAG'
    | 'KOZELI_MUNKATARS'
    | 'KORMANYFO'
    | 'PARLAMENTI'
    | 'NAV_VEZETO'
    | 'EGYEB'
  /** V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok (max 4). */
  isLegalEntityCustomer?: boolean
  legalEntityName?: string
  legalEntitySeat?: string
  legalEntityTaxNumber?: string
  legalDeedNumber?: string
  beneficialOwners?: Array<{
    name: string
    address?: string
    birthPlace?: string
    birthDate?: string
    nationality?: string
    residenceAbroad?: string
    interestNature?: string
    interestExtent?: string
    isPep?: boolean
  }>
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
    customerOnly?: boolean
    page?: number
    size?: number
  }): Promise<PagedResponse<Transaction>> => {
    const response = await api.get<PagedResponse<Transaction>>('/transactions', {
      params,
      _preservePaged: true,
    } as Record<string, unknown>)
    return response.data
  },
  getById: async (id: string | number): Promise<Transaction> => {
    // Get transaction by receipt number since we use that as primary lookup
    const response = await api.get<Transaction>(`/transactions/receipt/${id}`)
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
  conversion: async (data: ConversionRequest): Promise<Transaction> => {
    const response = await api.post<Transaction>('/transactions/conversion', data)
    return response.data
  },
  // Megj.: a korábbi `getReceipt` (GET /transactions/{id}/receipt blob) HOLT KÓD volt és NEM létező
  // végpontra mutatott (404). Eltávolítva (architect-mode audit, 2026-05-27). A valódi bizonylat-PDF
  // backend-végpontja: GET /api/v1/receipts/transaction/{id}/pdf (ReceiptController) — ehhez jelenleg
  // nincs kliens-wrapper ebben a fájlban; ha kell, blob/arraybuffer responseType-tal érdemes felvenni.
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
  currencySymbol?: string
  currentBalance: number
  openingBalance: number
  dailyChange?: number
  minBalance?: number
  maxBalance?: number
  lowBalanceAlert?: boolean
  highBalanceAlert?: boolean
  lastTransactionAt?: string
  createdAt?: string
  updatedAt?: string
}

/**
 * FK-075 FR-5/FR-6 (2026-08-06): a "Mai statisztika" panel élő, tranzakció-alapú
 * adatai — GET /cash-balances/today-stats (a tárolt napi-munkamenet-számláló
 * helyett). Backend: CashBalanceService.TodayStats.
 */
export interface TodayStats {
  transactions: number
  buyTotal: number
  sellTotal: number
  handlingFee: number
}

export interface BranchBalanceSummary {
  totalCurrencies: number
  hufBalance: number
  lowBalanceAlerts: number
  highBalanceAlerts: number
  balances?: CashBalance[]
}

export interface CurrencyTotalBalance {
  currencyId: number
  currencyCode: string
  currencyName: string
  totalBalance: number
  branchCount: number
}

export interface CompanyCurrencyPosition {
  currencyCode: string
  totalBalance: number
  branchCount: number
  hufValue: number
}

export interface CompanyCashPosition {
  companyId: string
  timestamp: string
  currencyPositions: CompanyCurrencyPosition[]
  grandTotalHuf: number
}

export interface CashPositionItem {
  currencyId: number
  currencyCode: string
  currencyName: string
  currentBalance: number
  openingBalance: number
  dailyChange: number
  buyRate?: number
  sellRate?: number
  midRate: number
  hufValue: number
  openingHufValue: number
  dailyChangeHuf: number
  minBalance?: number
  maxBalance?: number
  isLowBalance: boolean
  isHighBalance: boolean
  lastTransactionAt?: string
}

export interface DetailedCashPosition {
  branchId: string
  timestamp: string
  items: CashPositionItem[]
  totalHufValue: number
  totalOpeningHufValue: number
  totalDailyChangeHuf: number
  currencyCount: number
  lowBalanceAlerts: number
  highBalanceAlerts: number
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
  getTodayStats: async (): Promise<TodayStats> => {
    // FK-075 FR-5/FR-6: élő, tranzakció-alapú Mai statisztika (darabszám,
    // BUY/SELL összesen, beszedett kezelési díj) — dedikált végpont, mert a
    // GET /daily-sessions/current-ot más felület (MainLayout) is használja.
    const response = await api.get<TodayStats>('/cash-balances/today-stats')
    return response.data
  },
  getSummary: async (): Promise<BranchBalanceSummary> => {
    const response = await api.get<BranchBalanceSummary>('/cash-balances/summary')
    return response.data
  },
  getDetailedPosition: async (): Promise<DetailedCashPosition> => {
    const response = await api.get<DetailedCashPosition>('/cash-balances/position')
    return response.data
  },
  getCompanyTotals: async (): Promise<CurrencyTotalBalance[]> => {
    // v2.5.3 / FK-037: 403 esetén NEM globális toast — a TreasuryDashboard "Korlátozott
    // jogosultság" panelt mutat (összhangban getCompanyBalances/getCompanyPosition viselkedésével).
    const response = await api.get<CurrencyTotalBalance[]>('/cash-balances/company-totals', {
      _skipGlobal403Toast: true,
    })
    return response.data
  },
  getCompanyPosition: async (): Promise<CompanyCashPosition> => {
    const response = await api.get<CompanyCashPosition>('/cash-balances/company-position', {
      _skipGlobal403Toast: true,
    })
    return response.data
  },
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

export interface DailyClosingValidation {
  validationDate: string
  errorCode: number
  errorMessage: string
  allValid: boolean
  currencyDenominationOk: boolean
  handlingFeeDenominationOk: boolean
  westernUnionDenominationOk: boolean
  vatDenominationOk: boolean
  ecommerceDenominationOk: boolean
}

export interface SessionOpenRequest {
  workerId: number
  branchId: string
}

export interface SessionOpenData {
  sessionId: number
  branchId: string
  branchName?: string
  workerId: number
  workerName?: string
  sessionDate: string
  status: string
  openedAt?: string
  closedAt?: string | null
  openingBalances?: Record<string, number>
  warnings?: string[]
}

export const sessionOpenApi = {
  open: async (request: SessionOpenRequest): Promise<SessionOpenData> => {
    const response = await api.post<SessionOpenData>('/sessions/open', request)
    return response.data
  },
  getOpeningBalance: async (sessionId: number): Promise<Record<string, number>> => {
    const response = await api.get<Record<string, number>>(`/sessions/opening-balance/${sessionId}`)
    return response.data
  },
  validateOpen: async (branchId: string): Promise<string[]> => {
    const response = await api.get<string[]>(`/sessions/validate-open/${branchId}`)
    return response.data
  },
}

export const dailySessionApi = {
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
      params: { startDate, endDate },
    })
    return response.data
  },
  validateClosing: async (): Promise<DailyClosingValidation> => {
    const response = await api.get<DailyClosingValidation>('/daily-sessions/validate-closing')
    return response.data
  },
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
  /** A jóváhagyási státusz Dictionary UUID-ja (NEM a kód). Megjelenítéshez/azonosításhoz. */
  approvalStatusDid: string
  /** #868: a jóváhagyási státusz KÓDJA (PENDING/APPROVED/REJECTED) — a státusz-logika ez ellen hasonlít. */
  approvalStatusCode?: string
  requestReason: string
  rejectionReason?: string
  approvedByWorkerId?: string
  approvedAt?: string
  /** Supervisor jóváhagyó-lista megjelenítési mezői (kérelmező neve, bizonylatszám, kérés ideje). */
  workerName?: string
  receiptNumber?: string
  createdAt?: string
}

export const stornoApi = {
  check: async (transactionId: string): Promise<StornoCheckResult> => {
    const response = await api.get<StornoCheckResult>(`/stornos/check/${transactionId}`)
    return response.data
  },
  requestApproval: async (transactionId: string, reason: string): Promise<StornoApproval> => {
    const response = await api.post<StornoApproval>('/stornos/request-approval', null, {
      params: { transactionId, reason },
    })
    return response.data
  },
  approve: async (
    approvalId: string,
    approved: boolean,
    reason?: string,
  ): Promise<StornoApproval> => {
    const response = await api.post<StornoApproval>(`/stornos/approve/${approvalId}`, null, {
      params: { approved, reason },
    })
    return response.data
  },
  // Supervisor jóváhagyó-lista: a saját iroda függő (PENDING) sztornó-kérései.
  // Backend: GET /stornos/approvals/pending (SUPERVISOR/MANAGER/ADMIN role-gate).
  pendingApprovals: async (): Promise<StornoApproval[]> => {
    const response = await api.get<StornoApproval[]>('/stornos/approvals/pending')
    return response.data
  },
  // Telefonos supervisor-PIN jóváhagyás (egyszemélyes iroda): a pénztáros sessionjéből
  // hívható; a PIN BODY-ban megy (nem query-paramban — access-log védelem).
  approveByPin: async (
    approvalId: string,
    approverWorkerId: number,
    pin: string,
    approved: boolean,
    reason?: string,
  ): Promise<StornoApproval> => {
    const response = await api.post<StornoApproval>('/stornos/approve-by-pin', {
      approvalId,
      approverWorkerId,
      pin,
      approved,
      reason,
    })
    return response.data
  },
  execute: async (request: StornoRequest): Promise<Transaction> => {
    const response = await api.post<Transaction>('/stornos/execute', request)
    return response.data
  },
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
  // FK-065: a backend WizardStatus enum teljes értékkészlete (FAILED + EXPIRED is)
  wizardStatus: 'IN_PROGRESS' | 'COMPLETED' | 'FAILED' | 'CANCELLED' | 'EXPIRED'
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

export interface ClosingWizardInventoryItem {
  currencyCode: string
  openingBalance?: number
  currentBalance?: number
  dailyChange?: number
}

export interface ClosingWizardReport {
  wizardId: string
  branchName: string
  closingDate: string
  closingType: string
  transactionCount?: number
  buyCount?: number
  sellCount?: number
  reversalCount?: number
  buyTurnoverHuf?: number
  sellTurnoverHuf?: number
  handlingFeeTotal?: number
  openingBalanceHuf?: number
  closingBalanceHuf?: number
  inventory?: ClosingWizardInventoryItem[]
}

export interface ClosingWizardDifference {
  currencyCode: string
  expected: number | string
  actual: number | string
  difference: number | string
  status: 'OK' | 'DISCREPANCY' | string
}

export interface ClosingWizardStatus {
  branchId: string
  closingDate: string
  vaultContext: boolean
  denominationRecorded: boolean
  exactMatch: boolean
  message: string
  differences: ClosingWizardDifference[]
  /**
   * FK-065 FR-2 (egyhívásos FR-3 szerződés): a napra vonatkozó beragadt/aktív
   * wizard — IN_PROGRESS elsőbbség, EXPIRED fallback, különben null/hiányzó.
   * A kliens ebből dönt (Folytatás / Új zárás indítása), külön get() hívás nélkül.
   */
  activeWizardId?: string | null
  activeWizardStatus?: string | null
  /** FKH-036 FR-5: vault-kontextusban a blokkoló (kötelező) valutakódok; pénztár ágon hiányzik. */
  requiredCurrencies?: string[] | null
  /** FKH-036 FR-6: vault-kontextusban true, ha aznap volt KK kezelési díj mozgás. */
  handlingFeeRequired?: boolean
}

export const closingWizardApi = {
  start: async (
    branchId: string,
    cashDeskId: string | undefined,
    closingType: string,
    workerId: string,
  ): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>('/closing-wizard/start', null, {
      params: { branchId, cashDeskId, closingType, workerId },
    })
    return response.data
  },
  get: async (wizardId: string): Promise<ClosingWizard> => {
    const response = await api.get<ClosingWizard>(`/closing-wizard/${wizardId}`)
    return response.data
  },
  getStep: async (wizardId: string, stepNumber: number): Promise<ClosingWizardStep> => {
    const response = await api.get<ClosingWizardStep>(
      `/closing-wizard/${wizardId}/step/${stepNumber}`,
    )
    return response.data
  },
  navigate: async (wizardId: string, targetStep: number): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/closing-wizard/${wizardId}/navigate`, null, {
      params: { targetStep },
    })
    return response.data
  },
  validateTransactions: async (): Promise<string[]> => {
    const response = await api.get<string[]>('/closing-wizard/validate-transactions')
    return response.data
  },
  getStatus: async (date: string): Promise<ClosingWizardStatus> => {
    const response = await api.get<ClosingWizardStatus>('/closing-wizard/status', {
      params: { date },
    })
    return response.data
  },
  cancel: async (wizardId: string): Promise<ClosingWizard> => {
    const response = await api.post<ClosingWizard>(`/closing-wizard/${wizardId}/cancel`)
    return response.data
  },
  finalize: async (
    wizardId: string,
    workerId: string,
    discrepancyExplanation?: string,
  ): Promise<{ success: boolean; message: string }> => {
    // G3 (FR-13): az eltérés-magyarázat a body-ban (akár 1000 karakter) — Sourcery #791.
    const response = await api.post<{ success: boolean; message: string }>(
      `/closing-wizard/${wizardId}/finalize`,
      discrepancyExplanation ? { discrepancyExplanation } : {},
      { params: { workerId } },
    )
    return response.data
  },
  /** Submit denomination counts — body: { "HUF": { 500: 3, 1000: 5, ... } } */
  submitDenominations: async (
    wizardId: string,
    denomCounts: Record<string, Record<number, number>>,
  ): Promise<Record<string, unknown>> => {
    const response = await api.post<Record<string, unknown>>(
      `/closing-wizard/${wizardId}/denominations`,
      denomCounts,
    )
    return response.data
  },
  calculateDifferences: async (
    wizardId: string,
    physicalCounts: Record<string, number>,
  ): Promise<ClosingWizardDifference[]> => {
    const response = await api.post<ClosingWizardDifference[]>(
      `/closing-wizard/${wizardId}/differences`,
      physicalCounts,
    )
    return response.data
  },
  getReport: async (wizardId: string): Promise<ClosingWizardReport> => {
    const response = await api.get<ClosingWizardReport>(`/closing-wizard/${wizardId}/report`)
    return response.data
  },
  /**
   * FK-063 FR-1: a bejelentkezett pénztár branch-ének készleten lévő (nem-nulla
   * cash_balance) pénznemei — HUF mindig benne van. A multi-devizás pénztári
   * becímletező forma ebből épül fel.
   */
  getCurrenciesWithBalance: async (): Promise<string[]> => {
    const response = await api.get<string[]>('/closing-wizard/currencies-with-balance')
    return response.data
  },
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
  register: async (
    customerId: string,
    request: RepresentativeRegistrationRequest,
    workerId: string,
  ): Promise<AuthorizedRepresentative> => {
    const response = await api.post<AuthorizedRepresentative>(
      `/authorized-representatives/customer/${customerId}/register`,
      request,
      { params: { workerId } },
    )
    return response.data
  },
  findByCustomer: async (customerId: string): Promise<AuthorizedRepresentative[]> => {
    const response = await api.get<AuthorizedRepresentative[]>(
      `/authorized-representatives/customer/${customerId}`,
    )
    return response.data
  },
  list: async (customerId?: string): Promise<AuthorizedRepresentative[]> => {
    const response = await api.get<AuthorizedRepresentative[]>('/authorized-representatives', {
      params: customerId ? { customerId } : undefined,
    })
    return response.data
  },
  getById: async (id: string): Promise<AuthorizedRepresentative> => {
    const response = await api.get<AuthorizedRepresentative>(`/authorized-representatives/${id}`)
    return response.data
  },
  update: async (
    id: string,
    request: RepresentativeRegistrationRequest,
  ): Promise<AuthorizedRepresentative> => {
    const response = await api.put<AuthorizedRepresentative>(
      `/authorized-representatives/${id}`,
      request,
    )
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/authorized-representatives/${id}`)
  },
  createAuthorization: async (
    representativeId: string,
    request: AuthorizationCreateRequest,
    workerId: number,
  ): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/${representativeId}/authorizations`,
      request,
      { params: { workerId } },
    )
    return response.data
  },
  verifyAuthorization: async (
    authorizationId: string,
    workerId: number,
    notes?: string,
  ): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/verify`,
      null,
      { params: { workerId, notes } },
    )
    return response.data
  },
  resumeAuthorization: async (
    authorizationId: string,
    workerId: number,
    notes?: string,
  ): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/resume`,
      null,
      { params: { workerId, notes } },
    )
    return response.data
  },
  suspendAuthorization: async (
    authorizationId: string,
    workerId: number,
    reason: string,
  ): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/suspend`,
      null,
      { params: { workerId, reason } },
    )
    return response.data
  },
  revokeAuthorization: async (
    authorizationId: string,
    workerId: number,
    reason: string,
  ): Promise<Authorization> => {
    const response = await api.post<Authorization>(
      `/authorized-representatives/authorizations/${authorizationId}/revoke`,
      null,
      { params: { workerId, reason } },
    )
    return response.data
  },
  findAuthorizations: async (representativeId: string): Promise<Authorization[]> => {
    const response = await api.get<Authorization[]>(
      `/authorized-representatives/${representativeId}/authorizations`,
    )
    return response.data
  },
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
    const response = await api.get<TransactionBanknote[]>(
      `/transactions/${transactionId}/banknotes`,
    )
    return response.data
  },
  create: async (
    transactionId: number,
    request: TransactionBanknoteCreateRequest,
  ): Promise<TransactionBanknote> => {
    const response = await api.post<TransactionBanknote>(
      `/transactions/${transactionId}/banknotes`,
      request,
    )
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
  fromBranchCode?: string
  fromBranchName?: string
  toBranchCode?: string
  toBranchName?: string
  sourceBranchId?: string
  sourceBranchName?: string
  shipmentType: string
  requestedDeliveryDate: string
  priorityDid?: string
  requestStatus: string
  requestedByWorkerId: string
  requestedByWorkerName: string
  requestedAt: string
  staleForDelivery?: boolean
  staleThresholdHours?: number
  approvedByWorkerId?: string
  approvedByWorkerName?: string
  approvedAt?: string
  rejectedByWorkerId?: string
  rejectedByWorkerName?: string
  rejectedAt?: string
  rejectionReason?: string
  cancelledByWorkerId?: string
  cancelledByWorkerName?: string
  cancelledAt?: string
  modificationNotes?: string
  notes?: string
  transferId?: string
  /** FK02 (átadás-átvétel): a fizikai szállítást végző neve + a szállítmány plombaszáma. */
  carrierName?: string
  sealNumber?: string
  vaultAddress?: string
  vaultPhone?: string
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
  /** FK02 (átadás-átvétel): KÖTELEZŐ — a szállító neve + a plombaszám. */
  carrierName: string
  sealNumber: string
}

export interface ShipmentHandlingFeeCreatePayload {
  fromBranchId: string
  toBranchId: string
  hufAmount: number
  deliveryDate?: string
  notes?: string
  carrierName: string
  sealNumber: string
}

export interface ShipmentHandlingFeeDto {
  id: string
  shipmentRequestId: string
  sourceBranchId: string
  hufAmount: number
  calculatedFee: number
  status: string
  createdAt?: string
  approvedAt?: string | null
}

export interface ShipmentVatSupplyCreatePayload {
  fromBranchId: string
  toBranchId: string
  hufAmount: number
  deliveryDate?: string
  notes?: string
  carrierName: string
  sealNumber: string
}

export interface ShipmentVatSupplyDto {
  id: string
  shipmentRequestId: string
  fromBranchId: string
  toBranchId: string
  hufAmount: number
  status: string
  createdAt?: string
  approvedAt?: string
}

export interface ShipmentUpdateRequest {
  fromBranchId: string
  toBranchId: string
  deliveryDate?: string
  notes?: string
  carrierName: string
  sealNumber: string
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
    requestedDeliveryDate: (r.requestedDeliveryDate ??
      r['deliveryDate']) as ShipmentRequest['requestedDeliveryDate'],
    requestingBranchId: (r.requestingBranchId ??
      r['fromBranchId']) as ShipmentRequest['requestingBranchId'],
    targetBranchId: (r.targetBranchId ?? r['toBranchId']) as ShipmentRequest['targetBranchId'],
    fromBranchName: (r.fromBranchName ??
      r['requestingBranchName']) as ShipmentRequest['fromBranchName'],
    toBranchName: (r.toBranchName ?? r['targetBranchName']) as ShipmentRequest['toBranchName'],
    requestingBranchName: (r.requestingBranchName ??
      r['fromBranchName']) as ShipmentRequest['requestingBranchName'],
    targetBranchName: (r.targetBranchName ??
      r['toBranchName']) as ShipmentRequest['targetBranchName'],
    requestedByWorkerName: (r.requestedByWorkerName ??
      r['requestedBy']) as ShipmentRequest['requestedByWorkerName'],
    requestedByWorkerId: (r.requestedByWorkerId ??
      r['requestedById']) as ShipmentRequest['requestedByWorkerId'],
    requestedAt: (r.requestedAt ??
      r['createdAt'] ??
      r['requestDate']) as ShipmentRequest['requestedAt'],
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
  opts: { maxPages?: number; pageSize?: number } = {},
): Promise<T[]> {
  const pageSize = opts.pageSize ?? 100
  const maxPages = opts.maxPages ?? 20
  const all: T[] = []
  let page = 0
  let lastPageReached = false
  while (page < maxPages) {
    const response = await api.get<{ content: T[]; totalPages?: number; last?: boolean }>(path, {
      params: { ...extraParams, page, size: pageSize },
      _preservePaged: true,
    } as Record<string, unknown>)
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
      `[fetchPaged] MAX_PAGES=${maxPages} (size=${pageSize}) elerve ${path}-on, ` +
        `lehetseges silent truncation. Backend-oldali filter kell vagy maxPages emelese.`,
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
      // FK02 (átadás-átvétel): a backend ShipmentRequest entity @NotBlank/@Pattern validálja.
      // Trim itt is (mint a notes), hogy MINDEN hívó egységesen normalizált értéket küldjön
      // (Sourcery/Copilot): a ShipmentNewPage már trimmel, de más/jövőbeli hívó ne csússzon el.
      carrierName: request.carrierName.trim(),
      sealNumber: request.sealNumber.trim(),
      items: request.items.map((item) => ({
        currencyId: Number(item.currencyId),
        requestedAmount: item.requestedAmount,
        // D követelmény (Codex P1): a backend MINDIG a server-oldali aktuális elszámoló
        // árfolyamból dolgozik — a frontend NEM küldi az appliedRate / hufValue mezőt,
        // csak display-célból számolja és jeleníti meg a UI-ban (audit-szigorúság:
        // a kliens nem manipulálhatja a beemelt rate-et).
      })),
    }
    const response = await api.post<Record<string, unknown>>('/shipments', payload)
    return normalizeShipmentRequest(response.data)
  },
  createHandlingFee: async (
    payload: ShipmentHandlingFeeCreatePayload,
  ): Promise<{ shipment: ShipmentRequest; handlingFee: ShipmentHandlingFeeDto }> => {
    const response = await api.post<{
      shipment: Record<string, unknown>
      handlingFee: ShipmentHandlingFeeDto
    }>('/shipments/handling-fee', {
      ...payload,
      notes: payload.notes?.trim() || undefined,
      carrierName: payload.carrierName.trim(),
      sealNumber: payload.sealNumber.trim(),
      deliveryDate: payload.deliveryDate || undefined,
    })
    return {
      shipment: normalizeShipmentRequest(response.data.shipment),
      handlingFee: response.data.handlingFee,
    }
  },
  createVatSupply: async (
    payload: ShipmentVatSupplyCreatePayload,
  ): Promise<{ shipment: ShipmentRequest; vatSupply: ShipmentVatSupplyDto }> => {
    // Backend ShipmentVatSupplyCreateResponseDto mező: vatSupply (nem vatSupplyItem)
    const response = await api.post<{
      shipment: Record<string, unknown>
      vatSupply: ShipmentVatSupplyDto
    }>('/shipments/vat-supply', {
      ...payload,
      notes: payload.notes?.trim() || undefined,
      carrierName: payload.carrierName.trim(),
      sealNumber: payload.sealNumber.trim(),
      deliveryDate: payload.deliveryDate || undefined,
    })
    return {
      shipment: normalizeShipmentRequest(response.data.shipment),
      vatSupply: response.data.vatSupply,
    }
  },
  submit: async (requestId: string): Promise<ShipmentRequest> => {
    const response = await api.post<Record<string, unknown>>(`/shipments/${requestId}/submit`)
    return normalizeShipmentRequest(response.data)
  },
  get: async (requestId: string): Promise<ShipmentRequest> => {
    const response = await api.get<Record<string, unknown>>(`/shipments/${requestId}`)
    return normalizeShipmentRequest(response.data)
  },
  update: async (requestId: string, request: ShipmentUpdateRequest): Promise<ShipmentRequest> => {
    const payload = {
      fromBranchId: request.fromBranchId,
      toBranchId: request.toBranchId,
      deliveryDate: request.deliveryDate || undefined,
      notes: request.notes?.trim() || undefined,
      carrierName: request.carrierName.trim(),
      sealNumber: request.sealNumber.trim(),
    }
    const response = await api.put<Record<string, unknown>>(`/shipments/${requestId}`, payload)
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
    const response = await api.get<unknown[]>(`/shipments`, {
      params: { status, page: 0, size: 100 },
    })
    return asArray<Record<string, unknown>>(response.data).map(normalizeShipmentRequest)
  },
  findByBranch: async (branchId: string): Promise<ShipmentRequest[]> => {
    // F2 (2026-06-01): a szűrést a BACKEND végzi DB-szinten (GET /shipments?branchId=... →
    // fromBranchId VAGY toBranchId). Megszünteti a korábbi kliens-oldali "összes letöltése +
    // filter" mintát (memóriaszivárgás / silent truncation). A fetchPaged a branchId paramétert
    // minden lap-kérésen továbbítja; a szűrt eredmény jellemzően egy lapra fér.
    const rawPages = await fetchPaged<Record<string, unknown>>(`/shipments`, { branchId })
    return rawPages.map(normalizeShipmentRequest)
  },
  getPendingForBranch: async (): Promise<ShipmentRequest[]> => {
    const response = await api.get<unknown[]>('/shipments/pending')
    return asArray<Record<string, unknown>>(response.data).map(normalizeShipmentRequest)
  },
  // Approve: backend POST /api/v1/shipments/{id}/approve (params ignoralva: workerId + approvedItems + notes)
  /**
   * @deprecated since 2.28.45. Use direct {@link shipmentRequestApi.deliver} instead.
   * Kept for mixed-client compatibility; the backend returns `Deprecation: true` and a `Sunset` header.
   */
  approve: async (
    requestId: string,
    workerId: string,
    approvedItems?: ShipmentRequestItem[],
    notes?: string,
  ): Promise<ShipmentRequest> => {
    const response = await api.post<ShipmentRequest>(
      `/shipments/${requestId}/approve`,
      approvedItems || null,
      { params: { workerId, notes } },
    )
    return response.data
  },
  // F3 (2026-06-01): dedikált /reject végpont (audit-helyesség) — az elutasítás (reject) külön
  // folyamat a visszavonástól (cancel). A státusz REJECTED lesz, és a backend rögzíti a
  // rejectionReason + rejectedByWorkerId (a hitelesített user) mezőket. A workerId paramétert a
  // backend a security-contextből származtatja (mint approve), a kliens-érték nem authoritative.
  /**
   * @deprecated since 2.28.45. Use sender-side {@link shipmentRequestApi.cancel} instead.
   * Kept for mixed-client compatibility; the backend returns `Deprecation: true` and a `Sunset` header.
   */
  reject: async (requestId: string, workerId: string, reason: string): Promise<ShipmentRequest> => {
    const response = await api.post<ShipmentRequest>(`/shipments/${requestId}/reject`, null, {
      params: { workerId, reason },
    })
    return response.data
  },
  deliver: async (
    requestId: string,
    idempotencyKey: string = globalThis.crypto.randomUUID(),
    options?: { confirmedStale?: boolean },
  ): Promise<ShipmentRequest> => {
    const response = await api.post<Record<string, unknown>>(
      `/shipments/${requestId}/deliver`,
      options?.confirmedStale === true ? { confirmedStale: true } : null,
      { headers: { 'Idempotency-Key': idempotencyKey } },
    )
    return normalizeShipmentRequest(response.data)
  },
  cancel: async (requestId: string): Promise<ShipmentRequest> => {
    const response = await api.post<Record<string, unknown>>(`/shipments/${requestId}/cancel`)
    return normalizeShipmentRequest(response.data)
  },
}

// ================== TRANSFER API ==================

export interface Transfer {
  id: number
  transferNumber: string
  fromBranchId: string
  fromBranchCode: string
  fromBranchName: string
  /** FR-1 (bizonylat-doc 2. kör): branch.region_code — az értéktár "[azonosító]. [név]" fejléc-formátumához. */
  fromBranchRegionCode?: string | null
  toBranchId: string
  toBranchCode: string
  toBranchName: string
  /** FR-1 (bizonylat-doc 2. kör): branch.region_code — az értéktár "[azonosító]. [név]" fejléc-formátumához. */
  toBranchRegionCode?: string | null
  fromWorkerId: number
  fromWorkerName: string
  toWorkerId?: number
  toWorkerName?: string
  transferType:
    | 'CURRENCY'
    | 'CASH'
    | 'HANDLING_FEE'
    | 'VAULT_DEPOSIT'
    | 'VAULT_WITHDRAW'
    | 'CORRECTION'
    | 'OTHER'
    | 'ERB'
    | 'FRB'
    | 'TRB'
    | 'PRB'
  transferTypeDisplay: string
  direction?: 'F' | 'U' | 'UF' | 'FF'
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
  // Értéktári átadás-átvétel bizonylat bővítések:
  /** FR-1: a bejelentkezett értéktár (Branch) saját helyi címe a bizonylat fejlécéhez. */
  vaultAddress?: string
  /** FR-2 (fejléc-javítás 2026-06-11): az értéktár telefonszáma a `branch.phone`-ból (NULL → nincs telefon sor). */
  vaultPhone?: string
  /** FR-14: sztornózva van-e (lista-jelölés). */
  isCancelled?: boolean
  /** FR-12/15: sztornó indoklása. */
  cancellationReason?: string
  cancelledAt?: string
  /** FR-13: a sztornó bizonylat sorszáma (<eredeti>-SZ). */
  stornoSerialNumber?: string
  /** FR-17..19: opcionális címletezés sorai. */
  denominations?: TransferDenomination[]
  /**
   * #6 / penztar-batch A.1 (2026-06-12): a több-valutás átadólap sorai — a backend
   * TransferDto.lines tükre (transfer_lines tábla, V243). A fejléc currencyCode/amount
   * az ELSŐ sort hordozza; több-valutás átadásnál a lista + bizonylat EZEKET listázza.
   */
  lines?: TransferLine[]
}

/** #6: egy valuta-sor a több-valutás átadólapon (backend TransferLineDto tükre). */
export interface TransferLine {
  currencyId: number
  amount: number
  currencyCode?: string
  currencyName?: string
  receivedAmount?: number
  difference?: number
  lineNo?: number
}

/** FR-17..19: egy címletezési sor (darab × névleges = összesen). */
export interface TransferDenomination {
  quantity: number
  faceValue: number
  currencyCode?: string
  lineTotal: number
}

export interface CreateTransferRequest {
  toBranchId: string
  currencyId: number
  amount: number
  hufValue?: number
  transferType:
    | 'CURRENCY'
    | 'CASH'
    | 'HANDLING_FEE'
    | 'VAULT_DEPOSIT'
    | 'VAULT_WITHDRAW'
    | 'CORRECTION'
    | 'OTHER'
    | 'ERB'
    | 'FRB'
    | 'TRB'
    | 'PRB'
  direction?: 'F' | 'U' | 'UF' | 'FF'
  notes?: string
  carrierName?: string
  sealNumber?: string
  /** #6: több-valutás átadólap sorai. Ha kitöltött, a currencyId/amount az ELSŐ sort tükrözi. */
  lines?: Array<{ currencyId: number; amount: number }>
  /** FR-17..20b: opcionális címletezés (darab × névleges érték). Ha van sor, összege = amount. */
  denominations?: Array<{ quantity: number; faceValue: number }>
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
    const response = await api.post<Transfer>(`/transfers/${id}/reject`, null, {
      params: { reason },
    })
    return response.data
  },
  /**
   * PENDING átadás visszavonása — a végpont a backendben a BIZTONSÁGOS sztornó-útvonalra irányít
   * (kassza-visszapótlás + `-SZ` bizonylat + STORNO audit), ezért az indoklás KÖTELEZŐ.
   */
  cancel: async (id: number, reason: string): Promise<void> => {
    await api.post(`/transfers/${id}/cancel`, { reason })
  },
  /** FR-12..16: átadás-átvétel bizonylat sztornózása indoklással (COMPLETED bizonylatra). */
  storno: async (id: number, reason: string): Promise<Transfer> => {
    const response = await api.post<Transfer>(`/transfers/${id}/storno`, { reason })
    return response.data
  },
  /** FR-15: sztornó bizonylat előnézet-adatai (eredeti + indoklás + <eredeti>-SZ sorszám). */
  getStornoPreview: async (id: number): Promise<Transfer> => {
    const response = await api.get<Transfer>(`/transfers/${id}/storno-preview`)
    return response.data
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
    const response = await api.get<PagedResponse<Transfer>>('/transfers', {
      params,
      _preservePaged: true,
    } as Record<string, unknown>)
    return response.data
  },
  countPending: async (): Promise<number> => {
    const response = await api.get<number>('/transfers/pending/count')
    return response.data
  },
}

// ================== SEAL NUMBER API ==================

export interface SealNumberPreview {
  sealNumber: string
}

export const sealNumberApi = {
  getNext: async (branchCode: string): Promise<SealNumberPreview> => {
    const response = await api.get<SealNumberPreview>('/seal-numbers/next', {
      params: { branchCode },
    })
    return response.data
  },
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
  generate: async (
    fromCashDeskId: string,
    toCashDeskId: string,
    transferDate: string,
    amounts: CurrencyAmounts,
  ): Promise<HandoverSheet> => {
    const response = await api.post<HandoverSheet>('/handover-sheets/generate', {
      fromCashDeskId,
      toCashDeskId,
      transferDate,
      amounts,
    })
    return response.data
  },
  print: async (id: string): Promise<void> => {
    await api.post(`/handover-sheets/${id}/print`)
  },
  complete: async (id: string): Promise<HandoverSheet> => {
    const response = await api.post<HandoverSheet>(`/handover-sheets/${id}/complete`)
    return response.data
  },
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
  // EXCMD b5b (FR-BSZUR-02 "csak ügyfeles" + FR-BSZUR-05 10M Ft AML-jelölő): a backend a
  // kapcsolt Transaction-ből dúsítja (@Transient → Jackson serializálja). Opcionális —
  // backward-compatible: a többi fogyasztó (pl. reports.ts) figyelmen kívül hagyja.
  customerName?: string
  hufAmount?: number
  // EXCMD b5b FR-BSZUR-03: természetes személy ügyfél-adatlap szűrőmezők (a tx-snapshotból).
  customerMotherName?: string
  customerBirthPlace?: string
  customerBirthDate?: string
  customerNationality?: string
  customerAddress?: string
  customerDocumentType?: string
  customerDocumentNumber?: string
  // EXCMD b5b FR-BSZUR-04: képviselő / meghatalmazott neve (jogi személy képviselője) a tx-snapshotból.
  customerActorName?: string
  // EXCMD b5b FR-BSZUR-05 (V312): ENGEDÉLYEZŐ neve + beosztása az AML-jóváhagyás audit-rekordból
  // (csak akkor kitöltött, ha a tranzakcióhoz felsővezetői jóváhagyás tartozott). Csak olvasható.
  approvedByName?: string
  approvedByRole?: string
}

export interface CancelledTransactionReceiptRequest {
  mode: 'BUY' | 'SELL'
  reason?: string
  customerName?: string
  customerDocumentNumber?: string
  lines: Array<{
    currencyCode?: string
    foreignAmount?: number
    rate?: number
    hufAmount?: number
  }>
}

export const receiptApi = {
  // EXCMD b5b FR-BSZUR-02/03: opcionális from/to (ISO dátum) + ügyfél-adatlap LIKE-szűrők — a szűrés
  // a backenden fut (a synthesized top-500 limit ELŐTT), így nem csonkol a kliens-oldali szűrés előtt.
  list: async (params?: {
    transactionId?: string
    from?: string
    to?: string
    customerFilters?: Record<string, string>
  }): Promise<Receipt[]> => {
    const query: Record<string, string> = {}
    if (params?.transactionId) query.transactionId = params.transactionId
    if (params?.from) query.from = params.from
    if (params?.to) query.to = params.to
    if (params?.customerFilters) {
      for (const [k, v] of Object.entries(params.customerFilters)) {
        if (v && v.trim()) query[k] = v.trim()
      }
    }
    const response = await api.get<Receipt[]>('/receipts', { params: query })
    return response.data
  },
  getById: async (id: string): Promise<Receipt> => {
    const response = await api.get<Receipt>(`/receipts/${id}`)
    return response.data
  },
  createCancelledTransaction: async (
    request: CancelledTransactionReceiptRequest,
  ): Promise<Receipt> => {
    const response = await api.post<Receipt>('/receipts/cancelled-transaction', request)
    return response.data
  },
  print: async (id: string): Promise<void> => {
    await api.post(`/receipts/${id}/print`)
  },
  downloadTransactionPdf: async (transactionId: string | number): Promise<Blob> => {
    const response = await api.get<Blob>(`/receipts/transaction/${transactionId}/pdf`, {
      responseType: 'blob',
    })
    return response.data
  },
  downloadTransactionEscPos: async (transactionId: string | number): Promise<Blob> => {
    const response = await api.get<Blob>(`/receipts/transaction/${transactionId}/escpos`, {
      responseType: 'blob',
    })
    return response.data
  },
  downloadClosingPdf: async (closingId: string): Promise<Blob> => {
    const response = await api.get<Blob>(`/receipts/closing/${closingId}/pdf`, {
      responseType: 'blob',
    })
    return response.data
  },
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
  checkAllThresholds: async (
    customerId: string,
    hufAmount: number,
    currencyCode?: string,
  ): Promise<AmlCheckResultDto> => {
    const response = await api.get<AmlCheckResultDto>('/aml/check-all-thresholds', {
      params: { customerId, hufAmount, currencyCode },
    })
    return response.data
  },
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
    const response = await api.post<MonthlyClosingSummary>(
      `/closing/monthly/${branchId}/${yearMonth}`,
    )
    return response.data
  },
  getReport: async (branchId: string, yearMonth: string): Promise<MonthlyClosingSummary> => {
    const response = await api.get<MonthlyClosingSummary>(
      `/closing/monthly/${branchId}/${yearMonth}`,
    )
    return response.data
  },
  getAllClosedMonths: async (branchId: string): Promise<MonthlyClosingSummary[]> => {
    const response = await api.get<MonthlyClosingSummary[]>(`/closing/monthly/${branchId}`)
    return response.data
  },
}
