import { beforeEach, describe, expect, it, vi } from 'vitest'
import { hrkDailyApi, hrkMonthlyApi } from './hrk'
import { api } from './client'

vi.mock('./client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
  delete: ReturnType<typeof vi.fn>
}

describe('hrkMonthlyApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('getSummary calls GET /hrk/monthly/summary with yearMonth', async () => {
    const summary = {
      branchId: 'branch-1',
      yearMonth: '2026-06',
      totalTransactions: 2,
      totalHandoverHuf: 100000,
      totalReceiveHuf: 250000,
      netHuf: 150000,
      currencyBreakdown: [],
    }
    mockApi.get.mockResolvedValue({ data: summary })

    const result = await hrkMonthlyApi.getSummary('2026-06')

    expect(mockApi.get).toHaveBeenCalledWith('/hrk/monthly/summary', { params: { yearMonth: '2026-06' } })
    expect(result.totalTransactions).toBe(2)
  })

  it('close calls POST /hrk/monthly/close with yearMonth', async () => {
    const summary = {
      branchId: 'branch-1',
      yearMonth: '2026-06',
      totalTransactions: 2,
      totalHandoverHuf: 100000,
      totalReceiveHuf: 250000,
      netHuf: 150000,
      currencyBreakdown: [],
    }
    mockApi.post.mockResolvedValue({ data: summary })

    const result = await hrkMonthlyApi.close('2026-06')

    expect(mockApi.post).toHaveBeenCalledWith('/hrk/monthly/close', undefined, { params: { yearMonth: '2026-06' } })
    expect(result.netHuf).toBe(150000)
  })
})

describe('hrkDailyApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('handover calls POST /hrk/handover with X-Branch-Id header and payload', async () => {
    const transaction = {
      id: 'hrk-tx-handover',
      branchId: 'branch-1',
      type: 'HANDOVER',
      currencyCode: 'EUR',
      amount: 250,
      hufAmount: 100000,
      status: 'COMPLETED',
    }
    const payload = {
      currencyCode: 'EUR',
      amount: 250,
      hufAmount: 100000,
      bankAccountNumber: '11700000-00000000',
      note: 'Pénztár-bank átadás',
    }
    mockApi.post.mockResolvedValue({ data: transaction })

    const result = await hrkDailyApi.handover('branch-1', payload)

    expect(mockApi.post).toHaveBeenCalledWith('/hrk/handover', payload, { headers: { 'X-Branch-Id': 'branch-1' } })
    expect(result.type).toBe('HANDOVER')
  })

  it('receive calls POST /hrk/receive with X-Branch-Id header and payload', async () => {
    const transaction = {
      id: 'hrk-tx-receive',
      branchId: 'branch-1',
      type: 'RECEIVE',
      currencyCode: 'USD',
      amount: 100,
      hufAmount: 35000,
      status: 'COMPLETED',
    }
    const payload = {
      currencyCode: 'USD',
      amount: 100,
      hufAmount: 35000,
    }
    mockApi.post.mockResolvedValue({ data: transaction })

    const result = await hrkDailyApi.receive('branch-1', payload)

    expect(mockApi.post).toHaveBeenCalledWith('/hrk/receive', payload, { headers: { 'X-Branch-Id': 'branch-1' } })
    expect(result.type).toBe('RECEIVE')
  })

  it('getJournal calls GET /hrk/journal with X-Branch-Id header', async () => {
    const journal = [
      {
        id: 'hrk-tx-1',
        branchId: 'branch-1',
        type: 'HANDOVER',
        currencyCode: 'EUR',
        amount: 250,
        hufAmount: 100000,
        status: 'COMPLETED',
      },
    ]
    mockApi.get.mockResolvedValue({ data: journal })

    const result = await hrkDailyApi.getJournal('branch-1')

    expect(mockApi.get).toHaveBeenCalledWith('/hrk/journal', { headers: { 'X-Branch-Id': 'branch-1' } })
    expect(result[0]?.reference).toBeUndefined()
    expect(result[0]?.currencyCode).toBe('EUR')
  })

  it('closeDaily calls POST /hrk/close-daily with X-Branch-Id header and date', async () => {
    const rows = [
      {
        id: 'hrk-tx-2',
        branchId: 'branch-1',
        type: 'RECEIVE',
        currencyCode: 'USD',
        amount: 100,
        hufAmount: 35000,
        status: 'COMPLETED',
      },
    ]
    mockApi.post.mockResolvedValue({ data: rows })

    const result = await hrkDailyApi.closeDaily('branch-1', '2026-06-18')

    expect(mockApi.post).toHaveBeenCalledWith('/hrk/close-daily', undefined, {
      headers: { 'X-Branch-Id': 'branch-1' },
      params: { date: '2026-06-18' },
    })
    expect(result[0]?.type).toBe('RECEIVE')
  })

  it('cancel calls DELETE /hrk/{id}', async () => {
    mockApi.delete.mockResolvedValue({})

    await hrkDailyApi.cancel('hrk-tx-1')

    expect(mockApi.delete).toHaveBeenCalledWith('/hrk/hrk-tx-1')
  })
})
