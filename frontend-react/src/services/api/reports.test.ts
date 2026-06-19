import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from './client'
import { navReportApi, reportApi } from './reports'

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
  get: ReturnType<typeof vi.fn>
}

describe('reportApi CSV export backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: new Blob(['ok']) })
  })

  it('exportMonthlyTurnoverCsv calls GET /reports/monthly-turnover/csv with year and month', async () => {
    await reportApi.exportMonthlyTurnoverCsv(2026, 6)

    expect(mockApi.get).toHaveBeenCalledWith('/reports/monthly-turnover/csv', {
      params: { year: 2026, month: 6 },
      responseType: 'blob',
    })
  })

  it('exportPeriodCsv calls GET /reports/period/csv with date range', async () => {
    await reportApi.exportPeriodCsv('2026-06-01', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/reports/period/csv', {
      params: { startDate: '2026-06-01', endDate: '2026-06-18' },
      responseType: 'blob',
    })
  })
})

describe('reportApi legacy ReportController backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { ok: true } })
  })

  it('getMonthlyTurnover calls GET /reports/monthly-turnover with year and month', async () => {
    await reportApi.getMonthlyTurnover(2026, 6)

    expect(mockApi.get).toHaveBeenCalledWith('/reports/monthly-turnover', {
      params: { year: 2026, month: 6 },
    })
  })

  it('getTransferReport calls GET /reports/transfers with date range', async () => {
    await reportApi.getTransferReport('2026-06-01', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/reports/transfers', {
      params: { startDate: '2026-06-01', endDate: '2026-06-18' },
    })
  })

  it('getHandlingFeeReport calls GET /reports/handling-fees with date range', async () => {
    await reportApi.getHandlingFeeReport('2026-06-01', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/reports/handling-fees', {
      params: { startDate: '2026-06-01', endDate: '2026-06-18' },
    })
  })

  it('getDailyFullReport calls GET /reports/daily/{branchId}/{date}/full', async () => {
    await reportApi.getDailyFullReport('branch-1', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/reports/daily/branch-1/2026-06-18/full')
  })

  it('exportDailyClosingPdf calls GET /reports/daily/{branchId}/{date}/pdf as blob', async () => {
    await reportApi.exportDailyClosingPdf('branch-1', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/reports/daily/branch-1/2026-06-18/pdf', {
      responseType: 'blob',
    })
  })
})

describe('navReportApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: [] })
  })

  it('getReportable calls GET /nav-reports/reportable with date', async () => {
    await navReportApi.getReportable('2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/nav-reports/reportable', {
      params: { date: '2026-06-18' },
    })
  })
})
