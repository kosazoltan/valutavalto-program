import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MonthlyClosingPage from './MonthlyClosingPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  monthlyGetAllClosedMonths: vi.fn(),
  monthlyGetReport: vi.fn(),
  monthlyPerformClosing: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
  },
  monthlyClosingApi: {
    getAllClosedMonths: mocks.monthlyGetAllClosedMonths,
    getReport: mocks.monthlyGetReport,
    performClosing: mocks.monthlyPerformClosing,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { branchId: 'branch-1' } }),
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('MonthlyClosingPage — havi zárás (értéktár)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockResolvedValue({ data: [] })
    mocks.monthlyGetAllClosedMonths.mockResolvedValue([
      {
        id: 'closing-1',
        yearMonth: '2026-06',
        branchName: 'Budapest 01',
        status: 'OPEN',
      },
    ])
    mocks.monthlyGetReport.mockResolvedValue({
      id: 1,
      branchId: 'branch-1',
      branchName: 'Backend Budapest 01',
      yearMonth: '2026-06',
      closedAt: '2026-06-30T18:00:00',
      closedByWorkerId: 77,
      closedByWorkerName: 'Backend Záró',
      totalBuyHuf: 1000000,
      totalSellHuf: 750000,
      totalHandlingFee: 12000,
      transactionCount: 42,
      currencyBreakdown: '{"EUR":{"buy":1000}}',
      createdAt: '2026-06-30T18:01:00',
    })
    mocks.monthlyPerformClosing.mockResolvedValue({
      id: 2,
      branchId: 'branch-1',
      branchName: 'Backend Budapest 01',
      yearMonth: '2026-07',
      closedAt: '2026-07-31T18:00:00',
      closedByWorkerId: 77,
      closedByWorkerName: 'Backend Záró',
      totalBuyHuf: 1200000,
      totalSellHuf: 800000,
      totalHandlingFee: 15000,
      transactionCount: 44,
      currencyBreakdown: '{"EUR":{"buy":1200}}',
      createdAt: '2026-07-31T18:01:00',
    })
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('betölti a havi zárás listát a saját iroda branchId-jával', async () => {
    render(<MonthlyClosingPage />)

    await waitFor(() => {
      expect(mocks.monthlyGetAllClosedMonths).toHaveBeenCalledWith('branch-1')
    })

    expect(await screen.findByTestId('monthly-closing-action-panel')).toBeInTheDocument()
    expect(await screen.findByText('Budapest 01')).toBeInTheDocument()
  })

  // FK-040 regressziós őr: a 2025-01-01 óta nem forgalmazott HRK pénztár-bank készletmozgás
  // elavult szekciói NEM jelenhetnek meg az aktív értéktári havi zárásban.
  it('NEM rendereli az elavult HRK szekciókat', async () => {
    render(<MonthlyClosingPage />)

    await screen.findByTestId('monthly-closing-action-panel')

    expect(screen.queryByText('HRK havi készletmozgás')).not.toBeInTheDocument()
    expect(screen.queryByText('HRK napi napló')).not.toBeInTheDocument()
    expect(screen.queryByTestId('hrk-monthly-panel')).not.toBeInTheDocument()
    expect(screen.queryByTestId('hrk-daily-movement-form')).not.toBeInTheDocument()
  })

  it('havi zárás részletezéskor a backend havi report reprezentációját jeleníti meg', async () => {
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByText('Budapest 01')
    await user.click(screen.getByRole('button', { name: /Részletek/i }))

    await waitFor(() => {
      expect(mocks.monthlyGetReport).toHaveBeenCalledWith('branch-1', '2026-06')
      expect(screen.getByTestId('monthly-closing-report-panel')).toBeInTheDocument()
      expect(screen.getByText(/Backend Budapest 01/)).toBeInTheDocument()
      expect(screen.getByText('Backend Záró')).toBeInTheDocument()
      expect(screen.getByText('42')).toBeInTheDocument()
      expect(screen.getByText('12 000 Ft')).toBeInTheDocument()
    })
  })

  it('havi zárás gomb megerősítés után a performClosing backend wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByTestId('monthly-closing-action-panel')
    const monthInput = screen.getByLabelText('Zárandó hónap')
    await user.clear(monthInput)
    await user.type(monthInput, '2026-07')
    await user.click(screen.getByRole('button', { name: /Havi zárás végrehajtása/i }))

    await waitFor(() => {
      expect(window.confirm).toHaveBeenCalledWith(
        'Biztosan végrehajtja a havi zárást erre a hónapra: 2026-07?',
      )
      expect(mocks.monthlyPerformClosing).toHaveBeenCalledWith('branch-1', '2026-07')
      expect(mocks.monthlyGetAllClosedMonths.mock.calls.length).toBeGreaterThanOrEqual(2)
      expect(screen.getByTestId('monthly-closing-report-panel')).toBeInTheDocument()
      expect(screen.getByText('44')).toBeInTheDocument()
      expect(screen.getByText('15 000 Ft')).toBeInTheDocument()
    })
  })

  it('havi zárás megerősítés elutasításakor nem hív backend POST-ot', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByTestId('monthly-closing-action-panel')
    await user.click(screen.getByRole('button', { name: /Havi zárás végrehajtása/i }))

    await waitFor(() => {
      expect(window.confirm).toHaveBeenCalled()
    })
    expect(mocks.monthlyPerformClosing).not.toHaveBeenCalled()
  })
})
