import { describe, it, expect, vi, beforeEach } from 'vitest'
import { transactionApi } from './transactions'
import { api } from './client'

vi.mock('./client', () => {
  const mockApi = {
    post: vi.fn(),
    get: vi.fn(),
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
  get: ReturnType<typeof vi.fn>
}

const mockTransaction = {
  id: 1,
  receiptNumber: 'E001000001',
  transactionType: 'SELL' as const,
  status: 'COMPLETED' as const,
  transactionDate: '2024-01-15',
  transactionTime: '10:00:00',
  currencyId: 1,
  currencyCode: 'EUR',
  currencyAmount: 100,
  exchangeRate: 380,
  hufAmount: 38000,
  handlingFee: 0,
  discountAmount: 0,
  discountPercent: 0,
  printed: false,
  branchId: 'b1',
  workerId: 1,
  createdAt: '2024-01-15T10:00:00Z',
}

describe('transactionApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('list', () => {
    it('calls GET /transactions and returns paged data', async () => {
      const paged = { content: [mockTransaction], totalElements: 1, totalPages: 1, size: 20, number: 0 }
      mockApi.get.mockResolvedValue({ data: paged })

      const result = await transactionApi.list()
      expect(mockApi.get).toHaveBeenCalledWith('/transactions', { params: undefined })
      expect(result.content).toHaveLength(1)
      expect(result.totalElements).toBe(1)
    })

    it('passes filter params', async () => {
      const paged = { content: [], totalElements: 0, totalPages: 0, size: 20, number: 0 }
      mockApi.get.mockResolvedValue({ data: paged })

      await transactionApi.list({ branchId: 'b1', type: 'BUY', page: 0, size: 10 })
      expect(mockApi.get).toHaveBeenCalledWith('/transactions', {
        params: { branchId: 'b1', type: 'BUY', page: 0, size: 10 },
      })
    })
  })

  describe('getById', () => {
    it('calls GET /transactions/receipt/:id', async () => {
      mockApi.get.mockResolvedValue({ data: mockTransaction })
      const result = await transactionApi.getById('E001000001')
      expect(mockApi.get).toHaveBeenCalledWith('/transactions/receipt/E001000001')
      expect(result.receiptNumber).toBe('E001000001')
    })
  })

  describe('getByReceiptNumber', () => {
    it('calls GET /transactions/receipt/:receiptNumber', async () => {
      mockApi.get.mockResolvedValue({ data: mockTransaction })
      await transactionApi.getByReceiptNumber('E001000001')
      expect(mockApi.get).toHaveBeenCalledWith('/transactions/receipt/E001000001')
    })
  })

  describe('getDaily', () => {
    it('calls GET /transactions/daily', async () => {
      mockApi.get.mockResolvedValue({ data: [mockTransaction] })
      const result = await transactionApi.getDaily()
      expect(mockApi.get).toHaveBeenCalledWith('/transactions/daily')
      expect(result).toHaveLength(1)
    })
  })

  describe('getDailyTurnover', () => {
    it('calls GET /transactions/daily-turnover', async () => {
      const summary = {
        totalBuyCount: 5,
        totalSellCount: 3,
        totalBuyHuf: 100000,
        totalSellHuf: 80000,
        totalHandlingFees: 5000,
        totalReversalCount: 0,
      }
      mockApi.get.mockResolvedValue({ data: summary })
      const result = await transactionApi.getDailyTurnover()
      expect(mockApi.get).toHaveBeenCalledWith('/transactions/daily-turnover')
      expect(result.totalBuyCount).toBe(5)
    })
  })

  describe('buy', () => {
    it('calls POST /transactions/buy', async () => {
      mockApi.post.mockResolvedValue({ data: mockTransaction })
      const request = { currencyCode: 'EUR', currencyAmount: 100 }
      const result = await transactionApi.buy(request)
      expect(mockApi.post).toHaveBeenCalledWith('/transactions/buy', request)
      expect(result.id).toBe(1)
    })
  })

  describe('sell', () => {
    it('calls POST /transactions/sell', async () => {
      mockApi.post.mockResolvedValue({ data: mockTransaction })
      const request = { currencyCode: 'USD', currencyAmount: 200 }
      await transactionApi.sell(request)
      expect(mockApi.post).toHaveBeenCalledWith('/transactions/sell', request)
    })
  })

  describe('reversal', () => {
    it('calls POST /transactions/reversal', async () => {
      mockApi.post.mockResolvedValue({ data: mockTransaction })
      const request = { originalTransactionId: 1, reason: 'Hiba' }
      await transactionApi.reversal(request)
      expect(mockApi.post).toHaveBeenCalledWith('/transactions/reversal', request)
    })
  })

  describe('conversion', () => {
    it('calls POST /transactions/conversion', async () => {
      mockApi.post.mockResolvedValue({ data: mockTransaction })
      const request = { fromCurrencyCode: 'EUR', toCurrencyCode: 'USD', fromAmount: 100 }
      await transactionApi.conversion(request)
      expect(mockApi.post).toHaveBeenCalledWith('/transactions/conversion', request)
    })
  })

  describe('cancel', () => {
    it('calls POST /transactions/reversal with originalTransactionId', async () => {
      mockApi.post.mockResolvedValue({ data: mockTransaction })
      await transactionApi.cancel(5, 'Rossz tranzakció')
      expect(mockApi.post).toHaveBeenCalledWith('/transactions/reversal', {
        originalTransactionId: 5,
        reason: 'Rossz tranzakció',
      })
    })

    it('parses string id to int', async () => {
      mockApi.post.mockResolvedValue({ data: mockTransaction })
      await transactionApi.cancel('10', 'ok')
      expect(mockApi.post).toHaveBeenCalledWith('/transactions/reversal', {
        originalTransactionId: 10,
        reason: 'ok',
      })
    })
  })
})
