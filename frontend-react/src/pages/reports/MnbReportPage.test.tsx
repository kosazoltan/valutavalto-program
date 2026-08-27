import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MnbReportPage from './MnbReportPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  get: vi.fn(),
  getDaily: vi.fn(),
  getMonthly: vi.fn(),
  validate: vi.fn(),
  downloadDailyXml: vi.fn(),
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/mnbReports', () => ({
  mnbReportsApi: {
    list: mocks.list,
    get: mocks.get,
    getDaily: mocks.getDaily,
    getMonthly: mocks.getMonthly,
    validate: mocks.validate,
    downloadDailyXml: mocks.downloadDailyXml,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

describe('MnbReportPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:mnb-daily')
    vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => undefined)
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined)
    mocks.list.mockResolvedValue([
      {
        id: 'report-1',
        reportType: 'DAILY',
        reportDate: '2026-06-18',
        status: 'DRAFT',
        totalTransactions: 7,
        submittedAt: null,
      },
    ])
    mocks.get.mockResolvedValue({
      id: 'report-1',
      reportType: 'DAILY',
      reportDate: '2026-06-18',
      status: 'DRAFT',
      totalBuyHuf: 120000,
      totalSellHuf: 80000,
      totalTransactions: 7,
      rejectionReason: 'Backend detail reason',
      lines: [{ id: 'line-1', currencyCode: 'EUR', buyAmount: 100, sellAmount: 50 }],
    })
    mocks.getDaily.mockResolvedValue({
      date: '2026-06-18',
      totalBuyHuf: 120000,
      totalSellHuf: 80000,
      totalTransactions: 7,
      currencyLines: [],
    })
    mocks.getMonthly.mockResolvedValue({
      month: '2026-06',
      totalBuyHuf: 620000,
      totalSellHuf: 480000,
      totalTransactions: 37,
      workingDays: 20,
      currencyLines: [],
    })
    mocks.validate.mockResolvedValue(['Nincs hiányzó árfolyam'])
    mocks.downloadDailyXml.mockResolvedValue(new Blob(['<mnb/>'], { type: 'application/xml' }))
  })

  it('részlet megnyitáskor a backend detail reprezentációt tölti be', async () => {
    const user = userEvent.setup()
    render(<MnbReportPage />)

    await screen.findByText('2026-06-18')
    await user.click(screen.getByRole('button', { name: /Részletek/i }))

    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith('report-1')
      expect(screen.getByText('Backend detail reason')).toBeInTheDocument()
    })
  })

  it('read-only ellenőrzéskor napi, havi és validációs endpointokat hív', async () => {
    const user = userEvent.setup()
    render(<MnbReportPage />)

    await screen.findByText('2026-06-18')
    await user.clear(screen.getByLabelText('MNB ellenőrzési nap'))
    await user.type(screen.getByLabelText('MNB ellenőrzési nap'), '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Read-only ellenőrzés/i }))

    await waitFor(() => {
      expect(mocks.getDaily).toHaveBeenCalledWith('2026-06-18')
      expect(mocks.getMonthly).toHaveBeenCalledWith('2026-06')
      expect(mocks.validate).toHaveBeenCalledWith('2026-06-18')
      expect(screen.getByText('37')).toBeInTheDocument()
      expect(screen.getByText('Nincs hiányzó árfolyam')).toBeInTheDocument()
    })
  })

  it('napi XML letöltéskor a date szerinti backend export endpointot hívja', async () => {
    const user = userEvent.setup()
    render(<MnbReportPage />)

    await screen.findByText('2026-06-18')
    await user.clear(screen.getByLabelText('MNB ellenőrzési nap'))
    await user.type(screen.getByLabelText('MNB ellenőrzési nap'), '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Napi XML/i }))

    await waitFor(() => {
      expect(mocks.downloadDailyXml).toHaveBeenCalledWith('2026-06-18')
      expect(URL.createObjectURL).toHaveBeenCalled()
    })
  })

  it('napi XML letöltési hiba: Blob-hibatestből olvasott üzenetet mutat', async () => {
    const user = userEvent.setup()
    mocks.downloadDailyXml.mockRejectedValue({
      response: {
        data: new window.Blob([JSON.stringify({ message: 'MNB XML szerverhiba' })], {
          type: 'application/json',
        }),
      },
    })
    render(<MnbReportPage />)

    await screen.findByText('2026-06-18')
    await user.clear(screen.getByLabelText('MNB ellenőrzési nap'))
    await user.type(screen.getByLabelText('MNB ellenőrzési nap'), '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Napi XML/i }))

    expect(await screen.findByText('MNB XML szerverhiba')).toBeInTheDocument()
  })
})
