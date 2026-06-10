import { describe, it, expect, vi, beforeEach } from 'vitest'
import { transactionApi, transferApi } from './transactions'
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
      expect(mockApi.get).toHaveBeenCalledWith('/transactions', { params: undefined, _preservePaged: true })
      expect(result.content).toHaveLength(1)
      expect(result.totalElements).toBe(1)
    })

    it('passes filter params', async () => {
      const paged = { content: [], totalElements: 0, totalPages: 0, size: 20, number: 0 }
      mockApi.get.mockResolvedValue({ data: paged })

      await transactionApi.list({ branchId: 'b1', type: 'BUY', page: 0, size: 10 })
      expect(mockApi.get).toHaveBeenCalledWith('/transactions', {
        params: { branchId: 'b1', type: 'BUY', page: 0, size: 10 },
        _preservePaged: true,
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
      expect(mockApi.get).toHaveBeenCalledWith('/transactions/daily-turnover', { params: {} })
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

describe('transferApi storno contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('storno: calls POST /transfers/{id}/storno with mandatory reason body', async () => {
    const transfer = {
      id: 77,
      transferNumber: 'AT-000023',
      isCancelled: true,
      cancellationReason: 'Téves rögzítés',
      stornoSerialNumber: 'AT-000023-SZ',
    }
    mockApi.post.mockResolvedValue({ data: transfer })

    const result = await transferApi.storno(77, 'Téves rögzítés')

    expect(mockApi.post).toHaveBeenCalledWith('/transfers/77/storno', { reason: 'Téves rögzítés' })
    expect(result.stornoSerialNumber).toBe('AT-000023-SZ')
  })

  it('getStornoPreview: calls GET /transfers/{id}/storno-preview and preserves preview serial', async () => {
    const transfer = {
      id: 77,
      transferNumber: 'AT-000023',
      isCancelled: false,
      stornoSerialNumber: 'AT-000023-SZ',
    }
    mockApi.get.mockResolvedValue({ data: transfer })

    const result = await transferApi.getStornoPreview(77)

    expect(mockApi.get).toHaveBeenCalledWith('/transfers/77/storno-preview')
    expect(result.isCancelled).toBe(false)
    expect(result.stornoSerialNumber).toBe('AT-000023-SZ')
  })
})

import { receiptApi } from './transactions'

describe('receiptApi cancelled transaction receipt', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('calls POST /receipts/cancelled-transaction', async () => {
    const receipt = {
      id: '33333333-3333-3333-3333-333333333333',
      receiptNumber: 'M-20260609-101500-ABCDEF12',
      receiptType: 'CANCELLED_TRANSACTION',
      issueDate: '2026-06-09',
      isPrinted: false,
    }
    const request = {
      mode: 'BUY' as const,
      reason: 'USER_CANCELLED',
      customerName: 'Kovacs Janos',
      lines: [{ currencyCode: 'EUR', foreignAmount: 100, rate: 390, hufAmount: 39000 }],
    }
    mockApi.post.mockResolvedValue({ data: receipt })

    const result = await receiptApi.createCancelledTransaction(request)

    expect(mockApi.post).toHaveBeenCalledWith('/receipts/cancelled-transaction', request)
    expect(result.receiptType).toBe('CANCELLED_TRANSACTION')
  })
})

// ============ shipmentRequestApi tesztek (Fix 2026-04-24: /shipments endpoint) ============
import { shipmentRequestApi } from './transactions'

describe('shipmentRequestApi (backend /api/v1/shipments)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('create: a backend /shipments endpointot hivja backend mezonevekkel', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        id: 'shipment-1',
        status: 'DRAFT',
        fromBranchId: 'BR-A',
        toBranchId: 'BR-B',
        deliveryDate: '2026-05-08',
        requestedById: 7,
        createdAt: '2026-05-07T08:00:00Z',
      },
    })

    const result = await shipmentRequestApi.create({
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      deliveryDate: '2026-05-08',
      notes: ' teszt ',
      carrierName: "Brink's Hungary Kft.",
      sealNumber: 'ABC/12-3',
      items: [{ currencyId: '4', requestedAmount: 1000 }],
    })

    expect(mockApi.post).toHaveBeenCalledWith('/shipments', {
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      deliveryDate: '2026-05-08',
      notes: 'teszt',
      carrierName: "Brink's Hungary Kft.",
      sealNumber: 'ABC/12-3',
      items: [{ currencyId: 4, requestedAmount: 1000 }],
    })
    expect(result.requestStatus).toBe('DRAFT')
    expect(result.requestingBranchId).toBe('BR-A')
    expect(result.targetBranchId).toBe('BR-B')
    expect(result.requestedAt).toBe('2026-05-07T08:00:00Z')
  })

  it('submit: a /shipments/{id}/submit endpointot hivja', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1', status: 'SUBMITTED' } })
    const result = await shipmentRequestApi.submit('shipment-1')
    expect(mockApi.post).toHaveBeenCalledWith('/shipments/shipment-1/submit')
    expect(result.requestStatus).toBe('SUBMITTED')
  })

  it('findByStatus: a /shipments endpoint-ot hivja status param-mal', async () => {
    mockApi.get.mockResolvedValue({
      data: { content: [], totalElements: 0 }
    })
    await shipmentRequestApi.findByStatus('KERTE')
    expect(mockApi.get).toHaveBeenCalledWith(
      '/shipments',
      expect.objectContaining({
        params: expect.objectContaining({ status: 'KERTE', page: 0, size: 100 })
      })
    )
  })

  it('findByStatus: interceptor-unwrapped array-t ad vissza', async () => {
    // Fix PR #180 Codex P1: client.ts interceptor MAR unwrapped Page<T> -> T[]
    const mockShipment = { id: 'uuid-1', requestNumber: 'SH-001' }
    mockApi.get.mockResolvedValue({ data: [mockShipment] })
    const result = await shipmentRequestApi.findByStatus('SUBMITTED')
    expect(result).toEqual([mockShipment])
  })

  it('findByStatus: null/nem-array response nem-hibasan kezel', async () => {
    mockApi.get.mockResolvedValue({ data: null })
    const result = await shipmentRequestApi.findByStatus('SUBMITTED')
    expect(result).toEqual([])
  })

  it('findByBranch: a backend /shipments?branchId=... natív szűrőjét hívja (F2), nem kliens-oldalon szűr', async () => {
    // F2 (2026-06-01): a szűrés BACKEND-oldali (DB-szintű fromBranchId VAGY toBranchId).
    // A frontend a branchId paramétert delegálja és a választ csak mappeli — nincs kliens-szűrés.
    const shipments = [
      { id: '1', fromBranchId: 'BR-A', toBranchId: 'BR-B' },
      { id: '2', fromBranchId: 'BR-B', toBranchId: 'BR-A' },
    ]
    mockApi.get.mockResolvedValue({ data: { content: shipments, totalPages: 1, last: true } })
    const result = await shipmentRequestApi.findByBranch('BR-A')
    // a backend által (szűrten) visszaadott összes sort visszaadja, kliens-szűrés nélkül
    expect(result).toHaveLength(2)
    expect(result.map((s: { id: string }) => s.id)).toEqual(['1', '2'])
    // a branchId paraméter delegálva a backend natív szűrőjének
    expect(mockApi.get).toHaveBeenCalledWith('/shipments', expect.objectContaining({
      params: expect.objectContaining({ branchId: 'BR-A' }),
    }))
  })

  it('approve: a /shipments/{id}/approve endpoint-ot hivja', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1' } })
    await shipmentRequestApi.approve('shipment-1', 'worker-1')
    expect(mockApi.post).toHaveBeenCalledWith(
      '/shipments/shipment-1/approve',
      null,
      expect.objectContaining({ params: expect.objectContaining({ workerId: 'worker-1' }) })
    )
  })

  it('reject: a dedikált /shipments/{id}/reject endpoint-ot hivja (F3, NEM /cancel)', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1' } })
    await shipmentRequestApi.reject('shipment-1', 'worker-1', 'teszt ok')
    expect(mockApi.post).toHaveBeenCalledWith(
      '/shipments/shipment-1/reject',
      null,
      expect.objectContaining({
        params: expect.objectContaining({ workerId: 'worker-1', reason: 'teszt ok' })
      })
    )
  })
})
