/**
 * FS-11 S3a: cégszintű compliance tranzakció-kereső API-kliens.
 * Backend: ComplianceTransactionController @ /api/v1/compliance/transactions
 * A companyId SOHA nincs a requestben — a backend a SecurityContextből scope-ol.
 */
import { api } from './client'
import type { PagedResponse } from './client'

export type ComplianceTransactionType =
  | 'BUY'
  | 'SELL'
  | 'REVERSAL'
  | 'PARTIAL_REFUND'
  | 'CONVERSION'
  | 'TRANSFER_OUT'
  | 'TRANSFER_IN'
  | 'WESTERN_UNION_SEND'
  | 'WESTERN_UNION_RECEIVE'
  | 'MONEYGRAM_SEND'
  | 'MONEYGRAM_RECEIVE'
  | 'VIGNETTE'
  | 'PHONE_TOPUP'
  | 'OTHER'
export type CompliancePaymentMethod = 'CASH' | 'CARD'
export type ComplianceTransactionStatus =
  'PENDING' | 'COMPLETED' | 'REVERSED' | 'FAILED' | 'CANCELLED' | 'ARCHIVED'

// name → magyar display (forrás: TransactionType.java:19-32, PaymentMethod.java:10-11)
export const TRANSACTION_TYPE_LABELS: Record<string, string> = {
  BUY: 'Vétel',
  SELL: 'Eladás',
  REVERSAL: 'Sztornó',
  PARTIAL_REFUND: 'Részleges visszatérítés',
  CONVERSION: 'Konverzió',
  TRANSFER_OUT: 'Átutalás',
  TRANSFER_IN: 'Átvétel',
  WESTERN_UNION_SEND: 'WU küldés',
  WESTERN_UNION_RECEIVE: 'WU fogadás',
  MONEYGRAM_SEND: 'MG küldés',
  MONEYGRAM_RECEIVE: 'MG fogadás',
  VIGNETTE: 'Autópálya matrica',
  PHONE_TOPUP: 'Telefon feltöltés',
  OTHER: 'Egyéb',
}
export const PAYMENT_METHOD_LABELS: Record<string, string> = {
  CASH: 'Készpénz',
  CARD: 'Bankkártya',
}
export const TRANSACTION_STATUS_LABELS: Record<string, string> = {
  PENDING: 'Folyamatban',
  COMPLETED: 'Befejezett',
  REVERSED: 'Sztornózott',
  FAILED: 'Sikertelen',
  CANCELLED: 'Megszakított',
  ARCHIVED: 'Archivált',
}

/** Tükrözi a backend ComplianceTransactionSearchCriteria-t (24 mező, mind opcionális).
 *  companyId SZÁNDÉKOSAN nem létezik. Dátum: 'YYYY-MM-DD'. Összeg: string (Jackson/Spring köti BigDecimal-ra). */
export interface ComplianceTransactionSearchCriteria {
  branchId?: string
  startDate?: string
  endDate?: string
  type?: ComplianceTransactionType
  minHufAmount?: string
  maxHufAmount?: string
  currencyIds?: number[]
  paymentMethod?: CompliancePaymentMethod
  customRateOnly?: boolean
  kkDiscountOnly?: boolean
  onBehalfOfOtherOnly?: boolean
  pepOnly?: boolean
  customerName?: string
  customerBirthDate?: string
  customerNationality?: string
  customerDocumentNumber?: string
  legalEntityOnly?: boolean
  legalEntityName?: string
  legalEntityTaxNumber?: string
  legalDeedNumber?: string
  legalEntitySeat?: string
  beneficialOwnerName?: string
  customerCountry?: string
  customerBirthName?: string
}

/** Tükrözi a ComplianceTransactionRowDto-t (Boolean wrapper → boolean | null). */
export interface ComplianceTransactionRowDto {
  id: number
  receiptNumber: string | null
  transactionType: ComplianceTransactionType | string
  status: ComplianceTransactionStatus | string
  transactionDate: string
  transactionTime: string | null
  branchId: string | null
  branchName: string | null
  branchCode: string | null
  currencyId: number | null
  currencyCode: string | null
  currencyAmount: string | number | null
  exchangeRate: string | number | null
  hufAmount: string | number | null
  paymentMethod: CompliancePaymentMethod | string | null
  cashierCustomRate: boolean | null
  kkDiscount: boolean | null
  customerIsPep: boolean | null
  customerOnOwnBehalf: boolean | null
  amlSuspicious: boolean | null
  customerId: string | null
  customerName: string | null
  customerBirthDate: string | null
  customerNationality: string | null
  customerDocumentNumber: string | null
  isLegalEntityCustomer: boolean | null
  legalEntityName: string | null
  legalEntityTaxNumber: string | null
  workerCode: string | null
  workerName: string | null
  originalReceiptNumber: string | null
}

// FS-11 S2a/S2b válasz-DTO-k (criteria: backend Jackson-alak; primitív booleanok mindig jelen lehetnek).
export interface ComplianceSearchTemplateDto {
  id: string
  name: string
  criteria: ComplianceTransactionSearchCriteria & Record<string, unknown>
  createdByWorkerCode: string | null
  createdAt: string
}

export interface ComplianceSearchAuditDto {
  id: string
  title: string
  description: string | null
  criteria: ComplianceTransactionSearchCriteria & Record<string, unknown>
  resultCount: number | null
  createdByWorkerCode: string | null
  createdAt: string
}

/**
 * Query-param builder. Kihagyja: undefined/null, '', false, üres tömb.
 * currencyIds → CSV ('1,2'): a Spring ConversionService List<Long>-ra köti,
 * és az Electron IPC-adapter (client.ts:221-227) is bájtra ugyanezt a query-t adja.
 */
export function buildCriteriaParams(
  criteria: ComplianceTransactionSearchCriteria,
): Record<string, string> {
  const params: Record<string, string> = {}
  for (const [key, value] of Object.entries(criteria)) {
    if (value === undefined || value === null) continue
    if (typeof value === 'boolean') {
      if (value) params[key] = 'true'
      continue
    }
    if (Array.isArray(value)) {
      if (value.length > 0) params[key] = value.join(',')
      continue
    }
    const str = String(value).trim()
    if (str !== '') params[key] = str
  }
  return params
}

export const complianceTransactionsApi = {
  // _preservePaged: a backend Page<T>-t ad; e flag nélkül a client.ts interceptor
  // content-tömbbé bontaná és a totalPages elveszne (ld. bankOrders.ts:52-62 minta).
  search: async (
    criteria: ComplianceTransactionSearchCriteria,
    page = 0,
    size = 50,
  ): Promise<PagedResponse<ComplianceTransactionRowDto>> => {
    const response = await api.get<PagedResponse<ComplianceTransactionRowDto>>(
      '/compliance/transactions',
      {
        params: { ...buildCriteriaParams(criteria), page: String(page), size: String(size) },
        _preservePaged: true,
      },
    )
    return response.data
  },

  // Export: criteria-paramok page/size NÉLKÜL (a backend a teljes találatot exportálja).
  exportCsv: async (criteria: ComplianceTransactionSearchCriteria): Promise<Blob> => {
    const response = await api.get<Blob>('/compliance/transactions/export/csv', {
      params: buildCriteriaParams(criteria),
      responseType: 'blob',
    })
    return response.data
  },

  exportXlsx: async (criteria: ComplianceTransactionSearchCriteria): Promise<Blob> => {
    const response = await api.get<Blob>('/compliance/transactions/export/xlsx', {
      params: buildCriteriaParams(criteria),
      responseType: 'blob',
    })
    return response.data
  },
}

export const complianceSearchTemplatesApi = {
  list: async (): Promise<ComplianceSearchTemplateDto[]> => {
    const response = await api.get<ComplianceSearchTemplateDto[]>('/compliance/search-templates')
    return response.data
  },

  create: async (
    name: string,
    criteria: ComplianceTransactionSearchCriteria,
  ): Promise<ComplianceSearchTemplateDto> => {
    if (!name.trim()) throw new Error('A sablon neve kötelező')
    const response = await api.post<ComplianceSearchTemplateDto>('/compliance/search-templates', {
      name: name.trim(),
      criteria,
    })
    return response.data
  },

  remove: async (id: string): Promise<void> => {
    await api.delete(`/compliance/search-templates/${id}`)
  },
}

export const complianceSearchAuditApi = {
  create: async (
    title: string,
    description: string,
    criteria: ComplianceTransactionSearchCriteria,
  ): Promise<ComplianceSearchAuditDto> => {
    if (!title.trim()) throw new Error('A cím kötelező')
    const response = await api.post<ComplianceSearchAuditDto>('/compliance/search-audit', {
      title: title.trim(),
      description: description.trim() || null,
      criteria,
    })
    return response.data
  },

  list: async (): Promise<ComplianceSearchAuditDto[]> => {
    const response = await api.get<ComplianceSearchAuditDto[]>('/compliance/search-audit')
    return response.data
  },

  downloadPdf: async (id: string): Promise<Blob> => {
    const response = await api.get<Blob>(`/compliance/search-audit/${id}/pdf`, {
      responseType: 'blob',
    })
    return response.data
  },
}
