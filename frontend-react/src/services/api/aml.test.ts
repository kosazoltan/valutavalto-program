import { beforeEach, describe, expect, it, vi } from 'vitest'
import { amlApi } from './aml'
import { api } from './client'

vi.mock('./client', () => {
  const mockApi = {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    defaults: { baseURL: '' },
    interceptors: {
      request: { use: vi.fn() },
      response: { use: vi.fn() },
    },
  }
  return { api: mockApi }
})

const mockApi = api as unknown as {
  post: ReturnType<typeof vi.fn>
}

describe('amlApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.post.mockResolvedValue({ data: { transactionType: 0, warnings: [] } })
  })

  it('checkTransaction calls POST /aml/check with the backend DTO body', async () => {
    await amlApi.checkTransaction({
      amountHuf: 1250000,
      customerId: 'cust-42',
      currencyCode: 'EUR',
    })

    expect(mockApi.post).toHaveBeenCalledWith('/aml/check', {
      amountHuf: 1250000,
      customerId: 'cust-42',
      currencyCode: 'EUR',
    })
  })
})
