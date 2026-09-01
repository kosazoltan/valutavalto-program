import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  authorizedRepresentativeApi,
  closingWizardApi,
  customerApi,
  dailySessionApi,
  sessionOpenApi,
  stornoApi,
  transactionApi,
  transferApi,
} from './transactions'
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
  put: ReturnType<typeof vi.fn>
  delete: ReturnType<typeof vi.fn>
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
      const paged = {
        content: [mockTransaction],
        totalElements: 1,
        totalPages: 1,
        size: 20,
        number: 0,
      }
      mockApi.get.mockResolvedValue({ data: paged })

      const result = await transactionApi.list()
      expect(mockApi.get).toHaveBeenCalledWith('/transactions', {
        params: undefined,
        _preservePaged: true,
      })
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

  describe('conversion', () => {
    it('calls POST /transactions/conversion', async () => {
      mockApi.post.mockResolvedValue({ data: mockTransaction })
      const request = { fromCurrencyCode: 'EUR', toCurrencyCode: 'USD', fromAmount: 100 }
      await transactionApi.conversion(request)
      expect(mockApi.post).toHaveBeenCalledWith('/transactions/conversion', request)
    })
  })
})

describe('stornoApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('check: calls GET /stornos/check/:transactionId without workerId query param', async () => {
    mockApi.get.mockResolvedValue({ data: { requiresApproval: false } })

    await stornoApi.check('V076100003')

    expect(mockApi.get).toHaveBeenCalledWith('/stornos/check/V076100003')
  })

  it('requestApproval: delegates worker identity to backend security context', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'approval-1' } })

    await stornoApi.requestApproval('123', 'Napi limit felett')

    expect(mockApi.post).toHaveBeenCalledWith('/stornos/request-approval', null, {
      params: { transactionId: '123', reason: 'Napi limit felett' },
    })
  })

  it('approve: sends approval decision without approvedByWorkerId query param', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'approval-1' } })

    await stornoApi.approve('approval-1', false, 'Nem elfogadható indok')

    expect(mockApi.post).toHaveBeenCalledWith('/stornos/approve/approval-1', null, {
      params: { approved: false, reason: 'Nem elfogadható indok' },
    })
  })

  it('execute: calls POST /stornos/execute with request body only', async () => {
    mockApi.post.mockResolvedValue({ data: mockTransaction })
    const request = { transactionId: 'V076100003', reason: 'Hibás rögzítés' }

    await stornoApi.execute(request)

    expect(mockApi.post).toHaveBeenCalledWith('/stornos/execute', request)
  })
})

describe('customerApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('search: uses POS-compatible /customers query endpoint for name or document search', async () => {
    mockApi.get.mockResolvedValue({ data: [] })

    await customerApi.search('123456AB')

    expect(mockApi.get).toHaveBeenCalledWith('/customers', { params: { query: '123456AB' } })
  })

  it('searchByName: calls the legacy GET /customers/search endpoint', async () => {
    mockApi.get.mockResolvedValue({ data: [] })

    await customerApi.searchByName('Kiss')

    expect(mockApi.get).toHaveBeenCalledWith('/customers/search', { params: { name: 'Kiss' } })
  })

  it('getVip: calls GET /customers/vip', async () => {
    mockApi.get.mockResolvedValue({ data: [] })

    await customerApi.getVip()

    expect(mockApi.get).toHaveBeenCalledWith('/customers/vip')
  })

  it('getFrequent: calls GET /customers/frequent with params', async () => {
    mockApi.get.mockResolvedValue({ data: [] })

    await customerApi.getFrequent({ minTx: 5, branchId: 'branch-1' })

    expect(mockApi.get).toHaveBeenCalledWith('/customers/frequent', {
      params: { minTx: 5, branchId: 'branch-1' },
    })
  })

  it('getTop: calls GET /customers/top with params', async () => {
    mockApi.get.mockResolvedValue({ data: [] })

    await customerApi.getTop({ limit: 5, from: '2026-06-01', to: '2026-06-19' })

    expect(mockApi.get).toHaveBeenCalledWith('/customers/top', {
      params: { limit: 5, from: '2026-06-01', to: '2026-06-19' },
    })
  })

  it('getStats: calls GET /customers/:id/stats', async () => {
    mockApi.get.mockResolvedValue({ data: { customerId: 42, totalTransactions: 3 } })

    await customerApi.getStats(42)

    expect(mockApi.get).toHaveBeenCalledWith('/customers/42/stats')
  })

  it('getHistory: calls GET /customers/:id/history with optional date params', async () => {
    mockApi.get.mockResolvedValue({ data: { customerId: 42, totalTransactions: 2 } })

    await customerApi.getHistory(42, { from: '2026-06-01', to: '2026-06-19' })

    expect(mockApi.get).toHaveBeenCalledWith('/customers/42/history', {
      params: { from: '2026-06-01', to: '2026-06-19' },
    })
  })

  it('getByIdCard: calls the id-card lookup endpoint', async () => {
    mockApi.get.mockResolvedValue({ data: { id: 77, name: 'Teszt Ügyfél' } })

    await customerApi.getByIdCard('123456AB')

    expect(mockApi.get).toHaveBeenCalledWith('/customers/id-card/123456AB')
  })

  it('getByPassport: calls the passport lookup endpoint', async () => {
    mockApi.get.mockResolvedValue({ data: { id: 88, name: 'Passport Ügyfél' } })

    await customerApi.getByPassport('PA123456')

    expect(mockApi.get).toHaveBeenCalledWith('/customers/passport/PA123456')
  })

  it('merge: calls POST /customers/merge with primary and duplicate ids', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 42, name: 'Elsődleges ügyfél' } })

    await customerApi.merge(42, 99)

    expect(mockApi.post).toHaveBeenCalledWith('/customers/merge', {
      primaryId: 42,
      duplicateId: 99,
    })
  })
})

describe('authorizedRepresentativeApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('list: calls the top-level GET /authorized-representatives endpoint', async () => {
    mockApi.get.mockResolvedValue({ data: [] })

    await authorizedRepresentativeApi.list()

    expect(mockApi.get).toHaveBeenCalledWith('/authorized-representatives', { params: undefined })
  })

  it('list: passes optional customerId filter to GET /authorized-representatives', async () => {
    mockApi.get.mockResolvedValue({ data: [] })

    await authorizedRepresentativeApi.list('123')

    expect(mockApi.get).toHaveBeenCalledWith('/authorized-representatives', {
      params: { customerId: '123' },
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

describe('closingWizardApi report contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('getReport: calls GET /closing-wizard/{wizardId}/report', async () => {
    mockApi.get.mockResolvedValue({
      data: {
        wizardId: 'wizard-1',
        branchName: 'Korut',
        closingDate: '2026-06-18',
        closingType: 'DAILY',
        transactionCount: 7,
        inventory: [{ currencyCode: 'HUF', currentBalance: 620000 }],
      },
    })

    const result = await closingWizardApi.getReport('wizard-1')

    expect(mockApi.get).toHaveBeenCalledWith('/closing-wizard/wizard-1/report')
    expect(result.branchName).toBe('Korut')
    expect(result.inventory?.[0]?.currencyCode).toBe('HUF')
  })

  it('calculateDifferences: calls POST /closing-wizard/{wizardId}/differences with physical counts', async () => {
    mockApi.post.mockResolvedValue({
      data: [
        {
          currencyCode: 'HUF',
          expected: 100000,
          actual: 120000,
          difference: 20000,
          status: 'DISCREPANCY',
        },
      ],
    })

    const result = await closingWizardApi.calculateDifferences('wizard-1', { HUF: 120000 })

    expect(mockApi.post).toHaveBeenCalledWith('/closing-wizard/wizard-1/differences', {
      HUF: 120000,
    })
    expect(result[0]?.status).toBe('DISCREPANCY')
  })

  it('validateTransactions: calls GET /closing-wizard/validate-transactions', async () => {
    mockApi.get.mockResolvedValue({
      data: ['Van folyamatban lévő (PENDING) tranzakció!'],
    })

    const result = await closingWizardApi.validateTransactions()

    expect(mockApi.get).toHaveBeenCalledWith('/closing-wizard/validate-transactions')
    expect(result).toEqual(['Van folyamatban lévő (PENDING) tranzakció!'])
  })
})

describe('dailySessionApi closing validation contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('validateClosing: calls GET /daily-sessions/validate-closing', async () => {
    mockApi.get.mockResolvedValue({
      data: {
        validationDate: '2026-06-18',
        errorCode: 0,
        errorMessage: 'Minden címletezés rendben',
        allValid: true,
        currencyDenominationOk: true,
        handlingFeeDenominationOk: true,
        westernUnionDenominationOk: true,
        vatDenominationOk: true,
        ecommerceDenominationOk: true,
      },
    })

    const result = await dailySessionApi.validateClosing()

    expect(mockApi.get).toHaveBeenCalledWith('/daily-sessions/validate-closing')
    expect(result.allValid).toBe(true)
  })
})

describe('sessionOpenApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('open: calls POST /sessions/open with worker and branch identifiers', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        sessionId: 42,
        branchId: '11111111-1111-1111-1111-111111111111',
        workerId: 77,
        sessionDate: '2026-06-19',
        status: 'OPEN',
      },
    })

    const result = await sessionOpenApi.open({
      workerId: 77,
      branchId: '11111111-1111-1111-1111-111111111111',
    })

    expect(mockApi.post).toHaveBeenCalledWith('/sessions/open', {
      workerId: 77,
      branchId: '11111111-1111-1111-1111-111111111111',
    })
    expect(result.sessionId).toBe(42)
  })

  it('getOpeningBalance: calls GET /sessions/opening-balance/{sessionId}', async () => {
    mockApi.get.mockResolvedValue({ data: { HUF: 125000, EUR: 500 } })

    const result = await sessionOpenApi.getOpeningBalance(42)

    expect(mockApi.get).toHaveBeenCalledWith('/sessions/opening-balance/42')
    expect(result.HUF).toBe(125000)
  })

  it('validateOpen: calls GET /sessions/validate-open/{branchId}', async () => {
    mockApi.get.mockResolvedValue({ data: ['Van nyitott zárási eltérés.'] })

    const result = await sessionOpenApi.validateOpen('11111111-1111-1111-1111-111111111111')

    expect(mockApi.get).toHaveBeenCalledWith(
      '/sessions/validate-open/11111111-1111-1111-1111-111111111111',
    )
    expect(result).toEqual(['Van nyitott zárási eltérés.'])
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

  it('calls GET /receipts/transaction/:id/pdf as blob', async () => {
    const blob = new Blob(['pdf'], { type: 'application/pdf' })
    mockApi.get.mockResolvedValue({ data: blob })

    const result = await receiptApi.downloadTransactionPdf(42)

    expect(mockApi.get).toHaveBeenCalledWith('/receipts/transaction/42/pdf', {
      responseType: 'blob',
    })
    expect(result).toBe(blob)
  })

  it('calls GET /receipts/transaction/:id/escpos as blob', async () => {
    const blob = new Blob(['escpos'], { type: 'application/octet-stream' })
    mockApi.get.mockResolvedValue({ data: blob })

    const result = await receiptApi.downloadTransactionEscPos(42)

    expect(mockApi.get).toHaveBeenCalledWith('/receipts/transaction/42/escpos', {
      responseType: 'blob',
    })
    expect(result).toBe(blob)
  })

  it('calls GET /receipts/closing/:closingId/pdf as blob', async () => {
    const blob = new Blob(['closing'], { type: 'application/pdf' })
    mockApi.get.mockResolvedValue({ data: blob })

    const result = await receiptApi.downloadClosingPdf('closing-1')

    expect(mockApi.get).toHaveBeenCalledWith('/receipts/closing/closing-1/pdf', {
      responseType: 'blob',
    })
    expect(result).toBe(blob)
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
        fromBranchCode: 'BR075',
        fromBranchName: 'Szeged Értéktár',
        toBranchId: 'BR-B',
        toBranchCode: 'BR027',
        toBranchName: 'Szeged Tesco',
        deliveryDate: '2026-05-08',
        requestedById: 7,
        requestedByWorkerName: 'Bali Henriett',
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
    expect(result.fromBranchCode).toBe('BR075')
    expect(result.fromBranchName).toBe('Szeged Értéktár')
    expect(result.toBranchCode).toBe('BR027')
    expect(result.toBranchName).toBe('Szeged Tesco')
    expect(result.requestingBranchName).toBe('Szeged Értéktár')
    expect(result.targetBranchName).toBe('Szeged Tesco')
    expect(result.requestedByWorkerName).toBe('Bali Henriett')
    expect(result.requestedAt).toBe('2026-05-07T08:00:00Z')
  })

  it('createHandlingFee: a /shipments/handling-fee endpointot hívja és normalizálja a shipmentet', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        shipment: {
          id: 'shipment-1',
          requestNumber: 'KK-000001',
          status: 'DRAFT',
          fromBranchId: 'BR-A',
          fromBranchName: 'Szeged Móra',
          toBranchId: 'BR-B',
          toBranchName: 'Szeged Értéktár',
          createdAt: '2026-07-14T08:00:00Z',
        },
        handlingFee: {
          id: 'fee-1',
          shipmentRequestId: 'shipment-1',
          sourceBranchId: 'BR-A',
          hufAmount: 125000,
          calculatedFee: 625,
          status: 'DRAFT',
          createdAt: '2026-07-14T08:00:00Z',
          approvedAt: null,
        },
      },
    })

    const result = await shipmentRequestApi.createHandlingFee({
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      hufAmount: 125000,
      deliveryDate: '',
      notes: ' kezelési költség ',
      carrierName: ' Teszt Szállító ',
      sealNumber: ' KK-123 ',
    })

    expect(mockApi.post).toHaveBeenCalledWith('/shipments/handling-fee', {
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      hufAmount: 125000,
      deliveryDate: undefined,
      notes: 'kezelési költség',
      carrierName: 'Teszt Szállító',
      sealNumber: 'KK-123',
    })
    expect(result.shipment.requestStatus).toBe('DRAFT')
    expect(result.shipment.requestingBranchId).toBe('BR-A')
    expect(result.shipment.targetBranchId).toBe('BR-B')
    expect(result.handlingFee.calculatedFee).toBe(625)
  })

  it('createVatSupply: a /shipments/vat-supply endpointot hívja és normalizálja a shipmentet', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        shipment: {
          id: 'shipment-2',
          requestNumber: 'KK-000002',
          status: 'DRAFT',
          fromBranchId: 'BR-A',
          fromBranchName: 'Szeged Móra',
          toBranchId: 'BR-B',
          toBranchName: 'Szeged Értéktár',
          createdAt: '2026-07-14T09:00:00Z',
        },
        vatSupply: {
          id: 'vat-1',
          shipmentRequestId: 'shipment-2',
          fromBranchId: 'BR-A',
          toBranchId: 'BR-B',
          hufAmount: 50000,
          status: 'DRAFT',
          createdAt: '2026-07-14T09:00:00Z',
        },
      },
    })

    const result = await shipmentRequestApi.createVatSupply({
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      hufAmount: 50000,
      deliveryDate: '',
      notes: ' áfa ellátmány ',
      carrierName: ' Teszt Szállító ',
      sealNumber: ' KK-456 ',
    })

    expect(mockApi.post).toHaveBeenCalledWith('/shipments/vat-supply', {
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      hufAmount: 50000,
      deliveryDate: undefined,
      notes: 'áfa ellátmány',
      carrierName: 'Teszt Szállító',
      sealNumber: 'KK-456',
    })
    expect(result.shipment.requestStatus).toBe('DRAFT')
    expect(result.shipment.requestingBranchId).toBe('BR-A')
    expect(result.shipment.targetBranchId).toBe('BR-B')
    expect(result.vatSupply.hufAmount).toBe(50000)
  })

  it('submit: a /shipments/{id}/submit endpointot hivja', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1', status: 'SUBMITTED' } })
    const result = await shipmentRequestApi.submit('shipment-1')
    expect(mockApi.post).toHaveBeenCalledWith('/shipments/shipment-1/submit')
    expect(result.requestStatus).toBe('SUBMITTED')
  })

  it('get: a /shipments/{id} detail endpointot hivja', async () => {
    mockApi.get.mockResolvedValue({ data: { id: 'shipment-1', status: 'APPROVED' } })
    const result = await shipmentRequestApi.get('shipment-1')
    expect(mockApi.get).toHaveBeenCalledWith('/shipments/shipment-1')
    expect(result.requestStatus).toBe('APPROVED')
  })

  it('update: a PUT /shipments/{id} endpointot hivja DRAFT szerkeszteshez', async () => {
    mockApi.put.mockResolvedValue({
      data: { id: 'shipment-1', status: 'DRAFT', notes: 'uj megjegyzes' },
    })
    const result = await shipmentRequestApi.update('shipment-1', {
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      deliveryDate: '2026-06-20',
      notes: ' uj megjegyzes ',
      carrierName: ' Teszt Szallito ',
      sealNumber: ' PL-999 ',
    })

    expect(mockApi.put).toHaveBeenCalledWith('/shipments/shipment-1', {
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      deliveryDate: '2026-06-20',
      notes: 'uj megjegyzes',
      carrierName: 'Teszt Szallito',
      sealNumber: 'PL-999',
    })
    expect(result.requestStatus).toBe('DRAFT')
  })

  it('findByStatus: a /shipments endpoint-ot hivja status param-mal', async () => {
    mockApi.get.mockResolvedValue({
      data: { content: [], totalElements: 0 },
    })
    await shipmentRequestApi.findByStatus('KERTE')
    expect(mockApi.get).toHaveBeenCalledWith(
      '/shipments',
      expect.objectContaining({
        params: expect.objectContaining({ status: 'KERTE', page: 0, size: 100 }),
      }),
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
    expect(mockApi.get).toHaveBeenCalledWith(
      '/shipments',
      expect.objectContaining({
        params: expect.objectContaining({ branchId: 'BR-A' }),
      }),
    )
  })

  it('approve: a /shipments/{id}/approve endpoint-ot hivja', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1' } })
    await shipmentRequestApi.approve('shipment-1', 'worker-1')
    expect(mockApi.post).toHaveBeenCalledWith(
      '/shipments/shipment-1/approve',
      null,
      expect.objectContaining({ params: expect.objectContaining({ workerId: 'worker-1' }) }),
    )
  })

  it('reject: a dedikált /shipments/{id}/reject endpoint-ot hivja (F3, NEM /cancel)', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1' } })
    await shipmentRequestApi.reject('shipment-1', 'worker-1', 'teszt ok')
    expect(mockApi.post).toHaveBeenCalledWith(
      '/shipments/shipment-1/reject',
      null,
      expect.objectContaining({
        params: expect.objectContaining({ workerId: 'worker-1', reason: 'teszt ok' }),
      }),
    )
  })

  it('deliver: a /shipments/{id}/deliver workflow endpointot hivja', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1', status: 'DELIVERED' } })
    const result = await shipmentRequestApi.deliver('shipment-1', 'stable-receipt-key')
    expect(mockApi.post).toHaveBeenCalledWith('/shipments/shipment-1/deliver', null, {
      headers: { 'Idempotency-Key': 'stable-receipt-key' },
    })
    expect(result.requestStatus).toBe('DELIVERED')
  })

  it('deliver: stale megerősítéskor bodyt küld, az idempotenciakulcs változatlan marad', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        id: 'shipment-1',
        status: 'DELIVERED',
        staleForDelivery: true,
        staleThresholdHours: 48,
      },
    })

    const result = await shipmentRequestApi.deliver('shipment-1', 'stable-receipt-key', {
      confirmedStale: true,
    })

    expect(mockApi.post).toHaveBeenCalledWith(
      '/shipments/shipment-1/deliver',
      { confirmedStale: true },
      { headers: { 'Idempotency-Key': 'stable-receipt-key' } },
    )
    expect(result.staleForDelivery).toBe(true)
    expect(result.staleThresholdHours).toBe(48)
  })

  it('cancel: a /shipments/{id}/cancel workflow endpointot hivja', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'shipment-1', status: 'CANCELLED' } })
    const result = await shipmentRequestApi.cancel('shipment-1')
    expect(mockApi.post).toHaveBeenCalledWith('/shipments/shipment-1/cancel')
    expect(result.requestStatus).toBe('CANCELLED')
  })
})

// kanban #4 (2026-09-01): a napzaras UTANI telepitesi ablak (FR-3) allapotforrasa
// a GET /daily-sessions/today. A /current ugyanazzal a kulccsal szuri a napot
// (companyId+branchId+today+OPEN), mint az isOpen(), ezert CLOSED napra mindig
// hibazna — erre a kerdesre nem tud valaszolni. A 204 nem hiba: nincs mai rekord.
describe('dailySessionApi.getTodaySession contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('T4: 200 + CLOSED session -> visszaadja az objektumot es a /daily-sessions/today-t hivja', async () => {
    const closedSession = { status: 'CLOSED', closedAt: '2026-09-01T18:00:00Z' }
    mockApi.get.mockResolvedValue({ status: 200, data: closedSession })

    const result = await dailySessionApi.getTodaySession()

    expect(mockApi.get).toHaveBeenCalledWith('/daily-sessions/today')
    expect(result).toEqual(closedSession)
  })

  it('T5: 204 No Content -> null (nincs mai rekord: a nap meg el sem indult)', async () => {
    mockApi.get.mockResolvedValue({ status: 204, data: '' })

    const result = await dailySessionApi.getTodaySession()

    expect(result).toBeNull()
  })
})
