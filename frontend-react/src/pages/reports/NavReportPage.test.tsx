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
  validateNavAmount: vi.fn(),
  approveDiscrepancy: vi.fn(),
  exportMonthlyPtgszlah: vi.fn(),
  exportCustomPtgszlah: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  navReportApi: {
    getDaily: mocks.getDaily,
    getReportable: mocks.getReportable,
    exportCsv: mocks.exportCsv,
    listClosings: mocks.listClosings,
    getClosingSummary: mocks.getClosingSummary,
    validateNavAmount: mocks.validateNavAmount,
    approveDiscrepancy: mocks.approveDiscrepancy,
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
        branchId: 'branch-1',
        totalRevenue: 1_250_000,
        status: 'CLOSED',
      },
    ])
    mocks.getClosingSummary.mockResolvedValue({
      totalRevenue: 1_250_000,
      handlingFeeTotal: 50_000,
      vatAmount: 13_500,
      transactionCount: 3,
    })
    mocks.validateNavAmount.mockResolvedValue({
      closingId: 'closing-1',
      branchCode: 'BUD01',
      branchName: 'Budapest 01',
      closingDate: '2026-06-18',
      navAmount: 1_200_000,
      systemAmount: 1_250_000,
      discrepancy: -50_000,
      isMatch: false,
    })
    mocks.approveDiscrepancy.mockResolvedValue(undefined)
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
      expect(mocks.listClosings).toHaveBeenCalledWith({
        dateFrom: '2026-06-18',
        dateTo: '2026-06-18',
        page: 0,
        size: 10,
      })
    })
    expect(await screen.findByText('NAV-001')).toBeInTheDocument()
    expect(screen.getByText('Teszt Ügyfél')).toBeInTheDocument()
    expect(screen.getByTestId('nav-closing-panel')).toBeInTheDocument()
    expect(screen.getByText('CLOSED')).toBeInTheDocument()
  })

  it('lekéri a NAV zárás összesítőt és indítja a PTGSZLAH XML exportokat', async () => {
    const user = userEvent.setup()
    render(<NavReportPage />)

    await user.click(screen.getByRole('button', { name: /reports.navReport.submit/i }))
    await user.click(
      await screen.findByRole('button', { name: /reports.navReport.closings.summaryButton/i }),
    )

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

  it('hibás NAV összegre nem hív validációs backendet', async () => {
    const user = userEvent.setup()
    render(<NavReportPage />)

    await user.click(screen.getByRole('button', { name: /reports.navReport.submit/i }))
    await user.type(await screen.findByLabelText('reports.navReport.discrepancy.navAmount'), '-1')
    await user.click(
      screen.getByRole('button', { name: /reports.navReport.discrepancy.validate/i }),
    )

    expect(mocks.validateNavAmount).not.toHaveBeenCalled()
    expect(
      await screen.findByText('reports.navReport.discrepancy.errors.invalidAmount'),
    ).toBeInTheDocument()
  })

  it('validálja a NAV összeget pontos branch/date params értékekkel és megjeleníti az eltérést', async () => {
    const user = userEvent.setup()
    render(<NavReportPage />)

    await user.click(screen.getByRole('button', { name: /reports.navReport.submit/i }))
    await user.type(
      await screen.findByLabelText('reports.navReport.discrepancy.navAmount'),
      '1200000',
    )
    await user.click(
      screen.getByRole('button', { name: /reports.navReport.discrepancy.validate/i }),
    )

    await waitFor(() => {
      expect(mocks.validateNavAmount).toHaveBeenCalledWith('branch-1', '2026-06-18', 1_200_000)
    })
    expect(await screen.findByText('reports.navReport.discrepancy.mismatch')).toBeInTheDocument()
    expect(screen.getByText(/-50 000 Ft/)).toBeInTheDocument()
  })

  it('approve-discrepancy csak 20+ karakteres indoklással hívódik', async () => {
    const user = userEvent.setup()
    render(<NavReportPage />)

    await user.click(screen.getByRole('button', { name: /reports.navReport.submit/i }))
    await user.type(
      await screen.findByLabelText('reports.navReport.discrepancy.navAmount'),
      '1200000',
    )
    await user.click(
      screen.getByRole('button', { name: /reports.navReport.discrepancy.validate/i }),
    )
    const approveButton = await screen.findByRole('button', {
      name: /reports.navReport.discrepancy.approve/i,
    })
    expect(approveButton).toBeDisabled()

    await user.type(screen.getByLabelText('reports.navReport.discrepancy.justification'), 'Rövid')
    expect(approveButton).toBeDisabled()
    expect(mocks.approveDiscrepancy).not.toHaveBeenCalled()

    await user.clear(screen.getByLabelText('reports.navReport.discrepancy.justification'))
    await user.type(
      screen.getByLabelText('reports.navReport.discrepancy.justification'),
      'Pénztárgép kerekítési eltérés igazolva',
    )
    await user.click(approveButton)

    await waitFor(() => {
      expect(mocks.approveDiscrepancy).toHaveBeenCalledWith(
        'closing-1',
        1_200_000,
        'Pénztárgép kerekítési eltérés igazolva',
      )
    })
    expect(mocks.getClosingSummary).toHaveBeenCalledWith('closing-1')
    expect(mocks.listClosings).toHaveBeenCalledTimes(2)
  })
})
