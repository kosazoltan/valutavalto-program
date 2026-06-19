import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('./client', () => ({
  api: {
    get: vi.fn(),
    patch: vi.fn(),
  },
}))

import { api } from './client'
import { ertektarApi, treasuryApi } from './index'

const mockApi = vi.mocked(api)

describe('treasuryApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a dedikált treasury dashboard végpontot hívja', async () => {
    const dashboard = { totalTransactionCount: 17, branchCount: 2 }
    mockApi.get.mockResolvedValueOnce({ data: dashboard })

    await expect(treasuryApi.dashboard()).resolves.toBe(dashboard)
    expect(mockApi.get).toHaveBeenCalledWith('/treasury/dashboard')
  })

  it('a fiók-összehasonlítást a dedikált backend végpontról kéri', async () => {
    const rows = [{ branchId: 'branch-1', branchCode: 'SZEGED', branchName: 'Szeged' }]
    mockApi.get.mockResolvedValueOnce({ data: rows })

    await expect(treasuryApi.branchComparison()).resolves.toBe(rows)
    expect(mockApi.get).toHaveBeenCalledWith('/treasury/branch-comparison')
  })

  it('a beküldési státuszt a dedikált backend végpontról kéri', async () => {
    const rows = [{ branchId: 'branch-1', branchCode: 'SZEGED', submitted: true }]
    mockApi.get.mockResolvedValueOnce({ data: rows })

    await expect(treasuryApi.submissionStatus()).resolves.toBe(rows)
    expect(mockApi.get).toHaveBeenCalledWith('/treasury/submission-status')
  })

  it('a bankflow összesítőt a dedikált backend végpontról kéri', async () => {
    const rows = [{ currencyCode: 'EUR', netFlow: 1500 }]
    mockApi.get.mockResolvedValueOnce({ data: rows })

    await expect(treasuryApi.bankFlow()).resolves.toBe(rows)
    expect(mockApi.get).toHaveBeenCalledWith('/treasury/bank-flow', { params: {} })
  })

  it('a fiókcsoport összesítőt a dedikált backend végpontról kéri', async () => {
    const rows = [{ id: 'group-1', name: 'Dél', totalProfit: 25000 }]
    mockApi.get.mockResolvedValueOnce({ data: rows })

    await expect(treasuryApi.branchGroupSummary()).resolves.toBe(rows)
    expect(mockApi.get).toHaveBeenCalledWith('/treasury/branch-group-summary', { params: {} })
  })

  it('a cégösszesítőt a dedikált backend végpontról kéri', async () => {
    const rows = [{ id: 'company-1', name: 'EBC', totalProfit: 50000 }]
    mockApi.get.mockResolvedValueOnce({ data: rows })

    await expect(treasuryApi.companySummary()).resolves.toBe(rows)
    expect(mockApi.get).toHaveBeenCalledWith('/treasury/company-summary', { params: {} })
  })

  it('az értéktári alárendelt pénztár monitoringot az ErtektarController végpontról kéri', async () => {
    const rows = { 'branch-1': { branchId: 'branch-1', isOnline: true } }
    mockApi.get.mockResolvedValueOnce({ data: rows })

    await expect(treasuryApi.ertektarBranches()).resolves.toBe(rows)
    expect(mockApi.get).toHaveBeenCalledWith('/ertektar/branches')
  })

  it('az értéktári konszolidált riportot az ErtektarController végpontról kéri', async () => {
    const report = { totals: { totalTransactions: 17, totalHufTurnover: 1700000 } }
    mockApi.get.mockResolvedValueOnce({ data: report })

    await expect(treasuryApi.ertektarConsolidatedReport('2026-06-01', '2026-06-18')).resolves.toBe(report)
    expect(mockApi.get).toHaveBeenCalledWith('/ertektar/reports/consolidated', {
      params: { from: '2026-06-01', to: '2026-06-18' },
    })
  })

  it('a begyűjtés státuszváltást az ErtektarController PATCH szerződésére köti', async () => {
    const row = { id: 11, status: 'COMPLETED' }
    mockApi.patch.mockResolvedValueOnce({ data: row })

    await expect(ertektarApi.updateCollectionStatus(11, 'COMPLETED')).resolves.toBe(row)
    expect(mockApi.patch).toHaveBeenCalledWith('/ertektar/collections/11/status', null, {
      params: { status: 'COMPLETED' },
    })
  })

  it('a szétosztás státuszváltást az ErtektarController PATCH szerződésére köti', async () => {
    const row = { id: 12, status: 'REJECTED' }
    mockApi.patch.mockResolvedValueOnce({ data: row })

    await expect(ertektarApi.updateDistributionStatus(12, 'REJECTED')).resolves.toBe(row)
    expect(mockApi.patch).toHaveBeenCalledWith('/ertektar/distribution/12/status', null, {
      params: { status: 'REJECTED' },
    })
  })

  it('a banki tranzakció státuszváltást az ErtektarController PATCH szerződésére köti', async () => {
    const row = { id: 13, status: 'IN_PROGRESS' }
    mockApi.patch.mockResolvedValueOnce({ data: row })

    await expect(ertektarApi.updateBankTransactionStatus(13, 'IN_PROGRESS')).resolves.toBe(row)
    expect(mockApi.patch).toHaveBeenCalledWith('/ertektar/bank-transactions/13/status', null, {
      params: { status: 'IN_PROGRESS' },
    })
  })
})
