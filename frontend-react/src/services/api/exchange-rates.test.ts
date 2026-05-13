import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('./client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
  },
}))

import { api } from './client'
import { rateCreationApi } from './exchange-rates'

const mockApi = vi.mocked(api)

describe('rateCreationApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a local rate-maker bootstrap dedikalt szervercsatornat hasznalja', async () => {
    const bootstrap = {
      generatedAt: '2026-05-12T10:00:00',
      mode: 'LOCAL_RATE_MAKER',
      publishEndpoint: '/api/v1/local-rate-maker/packages/publish',
      idempotencyRequired: true,
      overview: { generatedAt: '2026-05-12T10:00:00', currencies: [] },
      workgroups: [],
    }
    mockApi.get.mockResolvedValueOnce({ data: bootstrap })

    await expect(rateCreationApi.getLocalRateMakerBootstrap()).resolves.toBe(bootstrap)
    expect(mockApi.get).toHaveBeenCalledWith('/local-rate-maker/bootstrap')
  })
})
