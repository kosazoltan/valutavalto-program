/**
 * FS-12: gyanús ügyfél lekérdezés + hatályos értéksávot elért ügyfelek XLSX exportja.
 * Backend: SuspiciousCustomerController @ /api/v1/compliance/suspicious-customers
 * A companyId SOHA nincs a requestben — a backend a SecurityContextből scope-ol.
 */
import { api } from './client'
import type { PagedResponse } from './client'

export interface SuspiciousCustomerDto {
  customerId: string
  customerName: string | null
  transactionCount: number
  totalHufAmount: string | number
  branchCount: number
  highTransactionCount: boolean
  highTotalValue: boolean
  manyBranches: boolean
}

export interface SuspiciousCustomerQuery {
  startDate?: string
  endDate?: string
  byTransactionCount?: boolean
  minTransactionCount?: string
  byTotalValue?: boolean
  minTotalHuf?: string
  byBranchCount?: boolean
  minBranchCount?: string
}

/**
 * Query-param builder: üres/undefined kimarad; boolean false is elküldendő,
 * mert a backend defaultValue=true kapcsolókkal dolgozik.
 */
export function buildSuspiciousParams(query: SuspiciousCustomerQuery): Record<string, string> {
  const params: Record<string, string> = {}
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null) continue
    if (typeof value === 'boolean') {
      params[key] = value ? 'true' : 'false'
      continue
    }
    const str = String(value).trim()
    if (str !== '') params[key] = str
  }
  return params
}

export const suspiciousCustomersApi = {
  search: async (
    query: SuspiciousCustomerQuery,
    page = 0,
    size = 50,
  ): Promise<PagedResponse<SuspiciousCustomerDto>> => {
    const response = await api.get<PagedResponse<SuspiciousCustomerDto>>(
      '/compliance/suspicious-customers',
      {
        params: { ...buildSuspiciousParams(query), page: String(page), size: String(size) },
        _preservePaged: true,
      },
    )
    return response.data
  },

  exportXlsx: async (startDate?: string, endDate?: string): Promise<Blob> => {
    const response = await api.get<Blob>('/compliance/suspicious-customers/export/xlsx', {
      params: buildSuspiciousParams({ startDate, endDate }),
      responseType: 'blob',
    })
    return response.data
  },
}
