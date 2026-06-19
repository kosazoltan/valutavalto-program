import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import NavReportPage from './NavReportPage'

const mocks = vi.hoisted(() => ({
  getDaily: vi.fn(),
  getReportable: vi.fn(),
  exportCsv: vi.fn(),
  listClosings: vi.fn(),
  getClosingSummary: vi.fn(),
  exportMonthlyPtgszlah: vi.fn(),
  exportCustomPtgszlah: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  navReportApi: {
    getDaily: mocks.getDaily,
    getReportable: mocks.getReportable,
    exportCsv: mocks.exportCsv,
    listClosings: mocks.listClosings,
    getClosingSummary: mocks.getClosingSummary,
    exportMonthlyPtgszlah: mocks.exportMonthlyPtgszlah,
    exportCustomPtgszlah: mocks.exportCustomPtgszlah,
  },
}))

vi.mock('../../utils/dateFormat', () => ({
  localIsoDate: () => '2026-06-18',
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('NavReportPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.clearAllMocks()
    mocks.getDaily.mockResolvedValue({
      date: '2026-06-18',
      reportableTransactionCount: 1,
      totalAmountHuf: 2_500_000,
      transactions: [],
    })
    mocks.getReportable.mockResolvedValue([
      {
        transactionId: 101,
        receiptNumber: 'NAV-001',
        transactionType: 'BUY',
        transactionDate: '2026-06-18',
        transactionTime: '10:15:00',
        currencyCode: 'EUR',
        currencyAmount: 6000,
        exchangeRate: 410,
        hufAmount: 2_460_000,
        customerId: 'customer-1',
        customerName: 'Teszt Ügyfél',
        customerAddress: 'Szeged',
        customerDocumentNumber: 'AB123456',
      },
    ])
    mocks.listClosings.mockResolvedValue([
      {
        id: 'closing-1',
        closingDate: '2026-06-18',
        totalRevenue: 1_250_000,
        status: 'OPEN',
      },
    ])
    mocks.getClosingSummary.mockResolvedValue({
      totalRevenue: 1_250_000,
      handlingFeeTotal: 50_000,
      vatAmount: 13_500,
      transactionCount: 3,
    })
    mocks.exportMonthlyPtgszlah.mockResolvedValue(new Blob(['<xml/>'], { type: 'application/xml' }))
    mocks.exportCustomPtgszlah.mockResolvedValue(new Blob(['<xml/>'], { type: 'application/xml' }))
    Object.defineProperty(URL, 'createObjectURL', {
      value: vi.fn(() => 'blob:nav-report'),
      configurable: true,
    })
    Object.defineProperty(URL, 'revokeObjectURL', {
      value: vi.fn(),
      configurable: true,
    })
  })

  it('a napi összesítő mellett a reportable listavégpontot is lekéri és abból renderel sort', async () => {
    const user = userEvent.setup()
    render(<NavReportPage />)

    await user.click(screen.getByRole('button', { name: /reports.navReport.submit/i }))

    await waitFor(() => {
      expect(mocks.getDaily).toHaveBeenCalledWith('2026-06-18')
      expect(mocks.getReportable).toHaveBeenCalledWith('2026-06-18')
      expect(mocks.listClosings).toHaveBeenCalledWith({ dateFrom: '2026-06-18', dateTo: '2026-06-18', page: 0, size: 10 })
    })
    expect(await screen.findByText('NAV-001')).toBeInTheDocument()
    expect(screen.getByText('Teszt Ügyfél')).toBeInTheDocument()
    expect(screen.getByTestId('nav-closing-panel')).toBeInTheDocument()
    expect(screen.getByText('OPEN')).toBeInTheDocument()
  })

  it('lekéri a NAV zárás összesítőt és indítja a PTGSZLAH XML exportokat', async () => {
    const user = userEvent.setup()
    render(<NavReportPage />)

    await user.click(screen.getByRole('button', { name: /reports.navReport.submit/i }))
    await user.click(await screen.findByRole('button', { name: /reports.navReport.closings.summaryButton/i }))

    const createElement = document.createElement.bind(document)
    vi.spyOn(document, 'createElement').mockImplementation((tagName, options) => {
      const element = createElement(tagName, options)
      if (tagName.toLowerCase() === 'a') {
        Object.defineProperty(element, 'click', {
          value: vi.fn(),
          configurable: true,
        })
      }
      return element
    })

    await user.click(screen.getByRole('button', { name: /reports.navReport.ptgszlahMonthly/i }))
    await user.click(screen.getByRole('button', { name: /reports.navReport.ptgszlahDaily/i }))

    await waitFor(() => {
      expect(mocks.getClosingSummary).toHaveBeenCalledWith('closing-1')
      expect(mocks.exportMonthlyPtgszlah).toHaveBeenCalledWith(2026, 6)
      expect(mocks.exportCustomPtgszlah).toHaveBeenCalledWith('2026-06-18', '2026-06-18')
    })
    expect(screen.getByText('reports.navReport.closings.summary.totalRevenue')).toBeInTheDocument()
  })
})
