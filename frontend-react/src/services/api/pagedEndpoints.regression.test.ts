import { describe, it, expect, vi, beforeEach } from 'vitest'
import { api } from './client'
import { bankOrdersApi } from './bankOrders'
import { diagnosticsApi } from './diagnostics'
import { decadeReportApi } from './decade-reports'
import { complianceTransactionsApi } from './complianceTransactions'
import { suspiciousCustomersApi } from './suspiciousCustomers'

// Regresszió: a Spring Page<T>-et adó végpontoknak `_preservePaged: true`-t KELL
// küldeniük, különben a client.ts axios-interceptor content-tömbbé bontja a választ,
// és a fogyasztó oldalak `.content` / `.totalPages` mezője undefined lesz (üres/törött
// lista). Ezek a tesztek a flag hiányát kapnák el.
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

const mockApi = api as unknown as { get: ReturnType<typeof vi.fn> }

describe('paginált végpontok _preservePaged regressziója', () => {
  beforeEach(() => vi.clearAllMocks())

  it('bankOrdersApi.list — _preservePaged:true (különben a banki megbízás-lista mindig üres)', async () => {
    const paged = { content: [{ id: 'bo1' }], totalElements: 1, totalPages: 1, size: 50, number: 0 }
    mockApi.get.mockResolvedValue({ data: paged })

    const result = await bankOrdersApi.list('PENDING', 0, 50)
    expect(mockApi.get).toHaveBeenCalledWith(
      '/bank-orders',
      expect.objectContaining({ _preservePaged: true }),
    )
    expect(result.content).toHaveLength(1)
  })

  it('diagnosticsApi.listErrors — _preservePaged:true (különben az ErrorMonitorPage törött)', async () => {
    const paged = { content: [{ id: 1 }], totalElements: 1, totalPages: 1, size: 50, number: 0 }
    mockApi.get.mockResolvedValue({ data: paged })

    const result = await diagnosticsApi.listErrors(0, 50)
    expect(mockApi.get).toHaveBeenCalledWith(
      '/diagnostics/errors',
      expect.objectContaining({ _preservePaged: true }),
    )
    expect(result.content).toHaveLength(1)
    expect(result.totalPages).toBe(1)
  })

  it('decadeReportApi.list — _preservePaged:true (különben a dekád-jelentés lista mindig üres)', async () => {
    const paged = { content: [{ id: 'd1' }], totalElements: 1 }
    mockApi.get.mockResolvedValue({ data: paged })

    await decadeReportApi.list('b1', 2026)
    expect(mockApi.get).toHaveBeenCalledWith(
      '/decade-reports',
      expect.objectContaining({ _preservePaged: true }),
    )
  })

  it('complianceTransactionsApi.search — _preservePaged:true (különben a compliance-találati lista mindig üres)', async () => {
    const paged = { content: [{ id: 1 }], totalElements: 1, totalPages: 1, size: 50, number: 0 }
    mockApi.get.mockResolvedValue({ data: paged })

    const result = await complianceTransactionsApi.search({}, 0, 50)
    expect(mockApi.get).toHaveBeenCalledWith(
      '/compliance/transactions',
      expect.objectContaining({ _preservePaged: true }),
    )
    expect(result.content).toHaveLength(1)
  })

  it('suspiciousCustomersApi.search — _preservePaged:true (különben a gyanús ügyfél lista mindig üres)', async () => {
    const paged = {
      content: [{ customerId: 'C-1' }],
      totalElements: 1,
      totalPages: 1,
      size: 50,
      number: 0,
    }
    mockApi.get.mockResolvedValue({ data: paged })

    const result = await suspiciousCustomersApi.search({}, 0, 50)
    expect(mockApi.get).toHaveBeenCalledWith(
      '/compliance/suspicious-customers',
      expect.objectContaining({ _preservePaged: true }),
    )
    expect(result.content).toHaveLength(1)
  })
})
