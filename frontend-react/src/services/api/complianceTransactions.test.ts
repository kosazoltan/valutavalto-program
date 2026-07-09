import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./client', () => {
  const mockApi = {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    defaults: { baseURL: '' },
    interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
  }
  return { api: mockApi }
})

import { api } from './client'
import {
  buildCriteriaParams,
  complianceTransactionsApi,
  type ComplianceTransactionSearchCriteria,
} from './complianceTransactions'

const mockApi = api as unknown as { get: ReturnType<typeof vi.fn> }

beforeEach(() => vi.clearAllMocks())

describe('complianceTransactionsApi', () => {
  it('buildCriteriaParams: üres criteria → {}', () => {
    expect(buildCriteriaParams({})).toEqual({})
  })

  it("buildCriteriaParams: false boolean, '' string, üres tömb, undefined kimarad", () => {
    const criteria: ComplianceTransactionSearchCriteria = {
      pepOnly: false,
      customerName: '',
      currencyIds: [],
      branchId: undefined,
    }

    expect(buildCriteriaParams(criteria)).toEqual({})
  })

  it('buildCriteriaParams: kitöltött mezők', () => {
    expect(
      buildCriteriaParams({
        startDate: '2026-01-01',
        pepOnly: true,
        currencyIds: [1, 2],
        minHufAmount: '3000000',
        type: 'BUY',
      }),
    ).toEqual({
      startDate: '2026-01-01',
      pepOnly: 'true',
      currencyIds: '1,2',
      minHufAmount: '3000000',
      type: 'BUY',
    })
  })

  it('buildCriteriaParams: SOHA nincs companyId kulcs', () => {
    const params = buildCriteriaParams({
      branchId: 'b1',
      startDate: '2026-01-01',
      pepOnly: true,
      currencyIds: [1, 2],
    })

    expect(Object.keys(params)).not.toContain('companyId')
  })

  it('search: _preservePaged + page/size stringként', async () => {
    const paged = { content: [{ id: 1 }], totalElements: 1, totalPages: 1, size: 50, number: 0 }
    mockApi.get.mockResolvedValue({ data: paged })

    const result = await complianceTransactionsApi.search({ pepOnly: true }, 0, 50)

    expect(mockApi.get).toHaveBeenCalledWith(
      '/compliance/transactions',
      expect.objectContaining({
        _preservePaged: true,
        params: expect.objectContaining({ page: '0', size: '50', pepOnly: 'true' }),
      }),
    )
    expect(result).toEqual(paged)
  })

  it('exportCsv: responseType blob, params page/size NÉLKÜL', async () => {
    const blob = new Blob(['csv'], { type: 'text/csv' })
    mockApi.get.mockResolvedValue({ data: blob })

    const result = await complianceTransactionsApi.exportCsv({
      startDate: '2026-01-01',
      currencyIds: [1, 2],
    })

    expect(mockApi.get).toHaveBeenCalledWith(
      '/compliance/transactions/export/csv',
      expect.objectContaining({
        responseType: 'blob',
        params: expect.objectContaining({ startDate: '2026-01-01', currencyIds: '1,2' }),
      }),
    )
    const config = mockApi.get.mock.calls[0]?.[1] as { params: Record<string, string> }
    expect(config.params).not.toHaveProperty('page')
    expect(config.params).not.toHaveProperty('size')
    expect(result).toBe(blob)
  })

  it('exportXlsx: /export/xlsx útvonal + blob', async () => {
    const blob = new Blob(['xlsx'], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    })
    mockApi.get.mockResolvedValue({ data: blob })

    const result = await complianceTransactionsApi.exportXlsx({ type: 'SELL' })

    expect(mockApi.get).toHaveBeenCalledWith(
      '/compliance/transactions/export/xlsx',
      expect.objectContaining({
        responseType: 'blob',
        params: expect.objectContaining({ type: 'SELL' }),
      }),
    )
    expect(result).toBe(blob)
  })
})
