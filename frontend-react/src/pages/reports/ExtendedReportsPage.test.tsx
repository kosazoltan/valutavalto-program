import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ExtendedReportsPage from './ExtendedReportsPage'

const mocks = vi.hoisted(() => ({
  getPeriod: vi.fn(),
  getMonthlyTurnoverReport: vi.fn(),
  getTransferReport: vi.fn(),
  getHandlingFeeReport: vi.fn(),
  getCashStatus: vi.fn(),
  getTodaySummary: vi.fn(),
  getCurrencyReport: vi.fn(),
  getDailyFullReport: vi.fn(),
  exportPeriodCsv: vi.fn(),
  exportMonthlyTurnoverCsv: vi.fn(),
  exportDailyClosingPdf: vi.fn(),
  getTransactionList: vi.fn(),
  getReceiptList: vi.fn(),
  getFeeSummary: vi.fn(),
  getMonthlyInventory: vi.fn(),
  getMonthlyTurnover: vi.fn(),
  getMonthlyTransfers: vi.fn(),
  getHandlingCost: vi.fn(),
  getDailyCashDesk: vi.fn(),
  getCurrentCashDeskStatus: vi.fn(),
  getSuspiciousTransactions: vi.fn(),
  getCardTransactionFees: vi.fn(),
  toast: {
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  reportApi: {
    getPeriod: mocks.getPeriod,
    getMonthlyTurnover: mocks.getMonthlyTurnoverReport,
    getTransferReport: mocks.getTransferReport,
    getHandlingFeeReport: mocks.getHandlingFeeReport,
    getCashStatus: mocks.getCashStatus,
    getTodaySummary: mocks.getTodaySummary,
    getCurrencyReport: mocks.getCurrencyReport,
    getDailyFullReport: mocks.getDailyFullReport,
    exportPeriodCsv: mocks.exportPeriodCsv,
    exportMonthlyTurnoverCsv: mocks.exportMonthlyTurnoverCsv,
    exportDailyClosingPdf: mocks.exportDailyClosingPdf,
  },
  reportExtendedApi: {
    getTransactionList: mocks.getTransactionList,
    getReceiptList: mocks.getReceiptList,
    getFeeSummary: mocks.getFeeSummary,
    getMonthlyInventory: mocks.getMonthlyInventory,
    getMonthlyTurnover: mocks.getMonthlyTurnover,
    getMonthlyTransfers: mocks.getMonthlyTransfers,
    getHandlingCost: mocks.getHandlingCost,
    getDailyCashDesk: mocks.getDailyCashDesk,
    getCurrentCashDeskStatus: mocks.getCurrentCashDeskStatus,
    getSuspiciousTransactions: mocks.getSuspiciousTransactions,
    getCardTransactionFees: mocks.getCardTransactionFees,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('ExtendedReportsPage CSV backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getPeriod.mockResolvedValue({ totalTransactionCount: 3 })
    mocks.getMonthlyTurnoverReport.mockResolvedValue({ totalTurnoverHuf: 100000 })
    mocks.getTransferReport.mockResolvedValue({ totalTransfers: 2 })
    mocks.getHandlingFeeReport.mockResolvedValue({ totalHandlingFees: 1500 })
    mocks.getCashStatus.mockResolvedValue({ branchName: 'Budapest 01', totalHufEquivalent: 250000 })
    mocks.getTodaySummary.mockResolvedValue({ reportDate: '2026-06-18', transactionCount: 7 })
    mocks.getCurrencyReport.mockResolvedValue({
      currencyId: 1,
      currencyCode: 'EUR',
      totalBuyHuf: 120000,
    })
    mocks.getDailyFullReport.mockResolvedValue({ branchName: 'Budapest 01', transactionCount: 4 })
    mocks.exportPeriodCsv.mockResolvedValue(new Blob(['period']))
    mocks.exportMonthlyTurnoverCsv.mockResolvedValue(new Blob(['monthly']))
    mocks.exportDailyClosingPdf.mockResolvedValue(new Blob(['pdf'], { type: 'application/pdf' }))
    mocks.getTransactionList.mockResolvedValue({})
    mocks.getReceiptList.mockResolvedValue({})
    mocks.getFeeSummary.mockResolvedValue({})
    mocks.getMonthlyInventory.mockResolvedValue({})
    mocks.getMonthlyTurnover.mockResolvedValue({})
    mocks.getMonthlyTransfers.mockResolvedValue({})
    mocks.getHandlingCost.mockResolvedValue({})
    mocks.getDailyCashDesk.mockResolvedValue({ cashDeskId: 'cashdesk-1', transactionCount: 5 })
    mocks.getCurrentCashDeskStatus.mockResolvedValue({ cashDeskId: 'cashdesk-1', status: 'OPEN' })
    mocks.getSuspiciousTransactions.mockResolvedValue({})
    mocks.getCardTransactionFees.mockResolvedValue({})
    vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:csv')
    vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => undefined)
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('időszaki forgalom kiválasztásakor a period riportot és CSV export endpointot használja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'period-turnover')
    const dateInputs = container.querySelectorAll('input[type="date"]')
    await user.type(dateInputs[0]!, '2026-06-01')
    await user.type(dateInputs[1]!, '2026-06-18')

    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))
    await waitFor(() => {
      expect(mocks.getPeriod).toHaveBeenCalledWith('2026-06-01', '2026-06-18')
    })

    await user.click(screen.getByRole('button', { name: /CSV export/i }))
    await waitFor(() => {
      expect(mocks.exportPeriodCsv).toHaveBeenCalledWith('2026-06-01', '2026-06-18')
      expect(URL.createObjectURL).toHaveBeenCalled()
    })
  })

  it('havi forgalom CSV exportja a monthly-turnover CSV backend endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'monthly-turnover')
    const numberInputs = container.querySelectorAll('input[type="number"]')
    await user.clear(numberInputs[0]!)
    await user.type(numberInputs[0]!, '2026')
    await user.clear(numberInputs[1]!)
    await user.type(numberInputs[1]!, '6')

    await user.click(screen.getByRole('button', { name: /CSV export/i }))
    await waitFor(() => {
      expect(mocks.exportMonthlyTurnoverCsv).toHaveBeenCalledWith(2026, 6)
      expect(URL.createObjectURL).toHaveBeenCalled()
    })
  })

  it('havi forgalom generálásakor a legacy monthly-turnover riport endpointot hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'monthly-turnover')
    const numberInputs = container.querySelectorAll('input[type="number"]')
    await user.clear(numberInputs[0]!)
    await user.type(numberInputs[0]!, '2026')
    await user.clear(numberInputs[1]!)
    await user.type(numberInputs[1]!, '6')

    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getMonthlyTurnoverReport).toHaveBeenCalledWith(2026, 6)
    })
  })

  it('átadás-átvétel összesítő generálásakor a legacy transfers riport endpointot hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'transfer-summary')
    const dateInputs = container.querySelectorAll('input[type="date"]')
    await user.type(dateInputs[0]!, '2026-06-01')
    await user.type(dateInputs[1]!, '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getTransferReport).toHaveBeenCalledWith('2026-06-01', '2026-06-18')
    })
  })

  it('kezelési díj összesítő generálásakor a legacy handling-fees riport endpointot hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'handling-cost')
    const dateInputs = container.querySelectorAll('input[type="date"]')
    await user.type(dateInputs[0]!, '2026-06-01')
    await user.type(dateInputs[1]!, '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getHandlingFeeReport).toHaveBeenCalledWith('2026-06-01', '2026-06-18')
    })
  })

  it('bővített havi forgalom generálásakor a reports-extended monthly-turnover endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'extended-monthly-turnover')
    const numberInputs = container.querySelectorAll('input[type="number"]')
    await user.clear(numberInputs[0]!)
    await user.type(numberInputs[0]!, '2026')
    await user.clear(numberInputs[1]!)
    await user.type(numberInputs[1]!, '6')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getMonthlyTurnover).toHaveBeenCalledWith(undefined, 2026, 6)
    })
  })

  it('bővített kezelési költség generálásakor a reports-extended handling-cost endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'extended-handling-cost')
    const dateInputs = container.querySelectorAll('input[type="date"]')
    await user.type(dateInputs[0]!, '2026-06-01')
    await user.type(dateInputs[1]!, '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getHandlingCost).toHaveBeenCalledWith(undefined, '2026-06-01', '2026-06-18')
    })
  })

  it('napi pénztár riport generálásakor a reports-extended daily-cash-desk endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'daily-cash-desk')
    await user.clear(screen.getByTestId('cash-desk-report-id'))
    await user.type(screen.getByTestId('cash-desk-report-id'), 'cashdesk-1')
    const dateInputs = container.querySelectorAll('input[type="date"]')
    await user.type(dateInputs[0]!, '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getDailyCashDesk).toHaveBeenCalledWith('cashdesk-1', '2026-06-18')
    })
    expect(screen.getByText(/transactionCount/)).toBeInTheDocument()
  })

  it('aktuális pénztár riport generálásakor a reports-extended current-cash-desk-status endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'current-cash-desk-status')
    await user.clear(screen.getByTestId('cash-desk-report-id'))
    await user.type(screen.getByTestId('cash-desk-report-id'), 'cashdesk-1')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getCurrentCashDeskStatus).toHaveBeenCalledWith('cashdesk-1')
    })
    expect(screen.getByText(/OPEN/)).toBeInTheDocument()
  })

  it('aktuális pénztár státusz generálásakor a cash-status backend endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'cash-status')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getCashStatus).toHaveBeenCalled()
    })
    expect(screen.getByText(/Budapest 01/)).toBeInTheDocument()
  })

  it('mai zárási összesítő generálásakor a today-summary backend endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'today-summary')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getTodaySummary).toHaveBeenCalled()
    })
    expect(screen.getByText(/transactionCount/)).toBeInTheDocument()
  })

  it('valuta forgalmi riport generálásakor a currency riport backend endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    const { container } = render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'currency-report')
    await user.clear(screen.getByTestId('currency-report-id'))
    await user.type(screen.getByTestId('currency-report-id'), '1')
    const dateInputs = container.querySelectorAll('input[type="date"]')
    await user.type(dateInputs[0]!, '2026-06-01')
    await user.type(dateInputs[1]!, '2026-06-18')
    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))

    await waitFor(() => {
      expect(mocks.getCurrencyReport).toHaveBeenCalledWith(1, '2026-06-01', '2026-06-18')
    })
    expect(screen.getByText(/EUR/)).toBeInTheDocument()
  })

  it('napi zárás teljes riportnál a full és PDF backend endpoint wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'daily-full')
    await user.type(screen.getByTestId('daily-report-branch-id'), 'branch-1')
    await user.type(screen.getByTestId('daily-report-date'), '2026-06-18')

    await user.click(screen.getByRole('button', { name: /Riport generálása/i }))
    await waitFor(() => {
      expect(mocks.getDailyFullReport).toHaveBeenCalledWith('branch-1', '2026-06-18')
    })
    expect(screen.getByText(/Budapest 01/)).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /PDF export/i }))
    await waitFor(() => {
      expect(mocks.exportDailyClosingPdf).toHaveBeenCalledWith('branch-1', '2026-06-18')
      expect(URL.createObjectURL).toHaveBeenCalled()
    })
  })

  it('PDF export hiba: Blob-hibatestből olvasott üzenetet mutat', async () => {
    const user = userEvent.setup()
    mocks.exportDailyClosingPdf.mockRejectedValue({
      response: {
        data: new window.Blob([JSON.stringify({ message: 'PDF export szerverhiba' })], {
          type: 'application/json',
        }),
      },
    })
    render(<ExtendedReportsPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'daily-full')
    await user.type(screen.getByTestId('daily-report-branch-id'), 'branch-1')
    await user.type(screen.getByTestId('daily-report-date'), '2026-06-18')
    await user.click(screen.getByRole('button', { name: /PDF export/i }))

    await waitFor(() => {
      expect(mocks.toast.error).toHaveBeenCalledWith('Export hiba', 'PDF export szerverhiba')
    })
  })
})
