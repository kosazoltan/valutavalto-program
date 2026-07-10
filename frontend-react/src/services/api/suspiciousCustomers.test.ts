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
import { buildSuspiciousParams, suspiciousCustomersApi } from './suspiciousCustomers'

const mockApi = api as unknown as { get: ReturnType<typeof vi.fn> }

beforeEach(() => vi.clearAllMocks())

describe('suspiciousCustomersApi', () => {
  it('buildSuspiciousParams: false boolean is elküldve, üres string kimarad', () => {
    expect(
      buildSuspiciousParams({
        startDate: '2026-07-01',
        endDate: '',
        byTransactionCount: false,
        minTransactionCount: ' 12 ',
        byTotalValue: true,
        minTotalHuf: '   ',
        byBranchCount: false,
      }),
    ).toEqual({
      startDate: '2026-07-01',
      byTransactionCount: 'false',
      minTransactionCount: '12',
      byTotalValue: 'true',
      byBranchCount: 'false',
    })
  })

  it('search: _preservePaged + page/size stringként, companyId nélkül', async () => {
    const paged = {
      content: [{ customerId: 'C-1', totalHufAmount: '12000000' }],
      totalElements: 1,
      totalPages: 1,
      size: 50,
      number: 0,
    }
    mockApi.get.mockResolvedValue({ data: paged })

    const result = await suspiciousCustomersApi.search({ byTransactionCount: false }, 2, 25)

    expect(mockApi.get).toHaveBeenCalledWith(
      '/compliance/suspicious-customers',
      expect.objectContaining({
        _preservePaged: true,
        params: expect.objectContaining({
          byTransactionCount: 'false',
          page: '2',
          size: '25',
        }),
      }),
    )
    const config = mockApi.get.mock.calls[0]?.[1] as { params: Record<string, string> }
    expect(config.params).not.toHaveProperty('companyId')
    expect(result).toEqual(paged)
  })

  it('exportXlsx: blob responseType + csak dátumparaméterek', async () => {
    const blob = new Blob(['xlsx'], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    })
    mockApi.get.mockResolvedValue({ data: blob })

    const result = await suspiciousCustomersApi.exportXlsx('2026-07-01', '2026-07-31')

    expect(mockApi.get).toHaveBeenCalledWith(
      '/compliance/suspicious-customers/export/xlsx',
      expect.objectContaining({
        responseType: 'blob',
        params: { startDate: '2026-07-01', endDate: '2026-07-31' },
      }),
    )
    expect(result).toBe(blob)
  })
})
