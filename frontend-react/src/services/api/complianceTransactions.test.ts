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
  complianceSearchAuditApi,
  complianceSearchTemplatesApi,
  complianceTransactionsApi,
  type ComplianceTransactionSearchCriteria,
} from './complianceTransactions'

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
  delete: ReturnType<typeof vi.fn>
}

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

  it('buildCriteriaParams: beneficialOwnerName átengedve és trimmelve', () => {
    expect(buildCriteriaParams({ beneficialOwnerName: '  Kovács Tulaj Béla  ' })).toEqual({
      beneficialOwnerName: 'Kovács Tulaj Béla',
    })
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

  it('template create: trim + kötelező név, criteria objektumként megy', async () => {
    const template = {
      id: 'tpl-1',
      name: 'Havi PEP',
      criteria: { startDate: '2026-07-01', pepOnly: true },
      createdByWorkerCode: 'W001',
      createdAt: '2026-07-09T10:00:00',
    }
    mockApi.post.mockResolvedValue({ data: template })

    await expect(
      complianceSearchTemplatesApi.create('   ', { startDate: '2026-07-01' }),
    ).rejects.toThrow('A sablon neve kötelező')
    expect(mockApi.post).not.toHaveBeenCalled()

    const result = await complianceSearchTemplatesApi.create('  Havi PEP  ', {
      startDate: '2026-07-01',
      pepOnly: true,
    })

    expect(mockApi.post).toHaveBeenCalledWith('/compliance/search-templates', {
      name: 'Havi PEP',
      criteria: { startDate: '2026-07-01', pepOnly: true },
    })
    expect(result).toEqual(template)
  })

  it('template list/remove: megfelelő útvonalakat hív', async () => {
    const templates = [
      {
        id: 'tpl-1',
        name: 'Havi PEP',
        criteria: { pepOnly: true },
        createdByWorkerCode: null,
        createdAt: '2026-07-09T10:00:00',
      },
    ]
    mockApi.get.mockResolvedValue({ data: templates })

    await expect(complianceSearchTemplatesApi.list()).resolves.toEqual(templates)
    await complianceSearchTemplatesApi.remove('tpl-1')

    expect(mockApi.get).toHaveBeenCalledWith('/compliance/search-templates')
    expect(mockApi.delete).toHaveBeenCalledWith('/compliance/search-templates/tpl-1')
  })

  it('audit create: body-alak, trim és üres description → null', async () => {
    const audit = {
      id: 'aud-1',
      title: 'PEP keresés',
      description: null,
      criteria: { pepOnly: true },
      resultCount: 3,
      createdByWorkerCode: 'W001',
      createdAt: '2026-07-09T10:00:00',
    }
    mockApi.post.mockResolvedValue({ data: audit })

    await expect(complianceSearchAuditApi.create('   ', '', { pepOnly: true })).rejects.toThrow(
      'A cím kötelező',
    )
    expect(mockApi.post).not.toHaveBeenCalled()

    const result = await complianceSearchAuditApi.create('  PEP keresés  ', '   ', {
      pepOnly: true,
    })

    expect(mockApi.post).toHaveBeenCalledWith('/compliance/search-audit', {
      title: 'PEP keresés',
      description: null,
      criteria: { pepOnly: true },
    })
    expect(result).toEqual(audit)
  })

  it('audit list: /compliance/search-audit útvonal', async () => {
    const audits = [
      {
        id: 'aud-1',
        title: 'PEP keresés',
        description: 'Leírás',
        criteria: { pepOnly: true },
        resultCount: 3,
        createdByWorkerCode: 'W001',
        createdAt: '2026-07-09T10:00:00',
      },
    ]
    mockApi.get.mockResolvedValue({ data: audits })

    await expect(complianceSearchAuditApi.list()).resolves.toEqual(audits)

    expect(mockApi.get).toHaveBeenCalledWith('/compliance/search-audit')
  })

  it('audit downloadPdf: responseType blob + id-s útvonal', async () => {
    const blob = new Blob(['pdf'], { type: 'application/pdf' })
    mockApi.get.mockResolvedValue({ data: blob })

    const result = await complianceSearchAuditApi.downloadPdf('aud-1')

    expect(mockApi.get).toHaveBeenCalledWith('/compliance/search-audit/aud-1/pdf', {
      responseType: 'blob',
    })
    expect(result).toBe(blob)
  })
})
