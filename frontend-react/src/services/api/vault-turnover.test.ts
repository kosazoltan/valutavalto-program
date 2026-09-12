import { describe, it, expect, vi, beforeEach } from 'vitest'
import { vaultTurnoverApi } from './vault-turnover'
import { api } from './client'

vi.mock('./client', () => ({
  api: {
    get: vi.fn(),
  },
}))

const mockedGet = vi.mocked(api.get)

/**
 * FKH-066: the page suite mocks this whole module, so the request path itself would
 * otherwise never execute. These cases pin the URL, the query parameters and the
 * unwrapping of the axios envelope — a drift in any of them would silently send the
 * vault view to the wrong (or an unscoped) endpoint.
 */
describe('vaultTurnoverApi.daily', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('calls the territory-scoped endpoint with branchId and date', async () => {
    mockedGet.mockResolvedValue({ data: { byCurrency: [] } } as never)

    await vaultTurnoverApi.daily('branch-1', '2026-09-12')

    expect(mockedGet).toHaveBeenCalledWith('/turnover/vault-daily', {
      params: { branchId: 'branch-1', date: '2026-09-12' },
    })
  })

  it('returns the response body, not the axios envelope', async () => {
    const report = {
      period: '2026-09-12',
      byCurrency: [{ currencyCode: 'EUR', buyHuf: 1000, sellHuf: 2000, fee: 30 }],
    }
    mockedGet.mockResolvedValue({ data: report } as never)

    await expect(vaultTurnoverApi.daily('branch-1', '2026-09-12')).resolves.toEqual(report)
  })

  it('propagates a rejection so the caller can mark the desk unavailable', async () => {
    // A foreign-territory branch answers 404; the caller must see the failure instead of
    // an empty report that would render as a legitimate zero turnover.
    mockedGet.mockRejectedValue(new Error('Request failed with status code 404'))

    await expect(vaultTurnoverApi.daily('foreign-branch', '2026-09-12')).rejects.toThrow('404')
  })
})
