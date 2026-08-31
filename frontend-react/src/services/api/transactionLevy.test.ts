import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * FK-100 FR-6 A-sorozat — a kézi `transactionLevyApi` kliens region-paramétere.
 * A1 pin: a régi kéargumentumú hívás kontraktusa változatlan (nincs region kulcs).
 * A2: a harmadik argumentum region-ként megy a query-paraméterekbe.
 */

const mockGet = vi.fn()

vi.mock('./client', () => ({
  api: {
    get: (...args: unknown[]) => mockGet(...args),
    post: vi.fn(),
  },
}))

import { transactionLevyApi } from './transactionLevy'

describe('transactionLevyApi.getReport — FK-100 FR-6', () => {
  beforeEach(() => {
    mockGet.mockReset()
    mockGet.mockResolvedValue({ data: {} })
  })

  it('A1: getReport(from, to) → params { from, to }, region kulcs NÉLKÜL (régi hívók kontraktusa)', async () => {
    await transactionLevyApi.getReport('2026-08-01', '2026-08-31')

    expect(mockGet).toHaveBeenCalledTimes(1)
    const [url, config] = mockGet.mock.calls[0] as [string, { params: Record<string, string> }]
    expect(url).toBe('/reports/transaction-levy')
    expect(config.params).toEqual({ from: '2026-08-01', to: '2026-08-31' })
    expect(Object.keys(config.params)).not.toContain('region')
  })

  it('A2: getReport(from, to, "SZEGED") → a params region: "SZEGED"-del egészül ki', async () => {
    await transactionLevyApi.getReport('2026-08-01', '2026-08-31', 'SZEGED')

    expect(mockGet).toHaveBeenCalledTimes(1)
    const [url, config] = mockGet.mock.calls[0] as [string, { params: Record<string, string> }]
    expect(url).toBe('/reports/transaction-levy')
    expect(config.params).toEqual({
      from: '2026-08-01',
      to: '2026-08-31',
      region: 'SZEGED',
    })
  })
})
