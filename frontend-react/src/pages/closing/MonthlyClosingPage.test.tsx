import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MonthlyClosingPage from './MonthlyClosingPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  monthlyGetAllClosedMonths: vi.fn(),
  monthlyGetReport: vi.fn(),
  hrkGetSummary: vi.fn(),
  hrkClose: vi.fn(),
  hrkHandover: vi.fn(),
  hrkReceive: vi.fn(),
  hrkGetJournal: vi.fn(),
  hrkCloseDaily: vi.fn(),
  hrkCancel: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
  },
  monthlyClosingApi: {
    getAllClosedMonths: mocks.monthlyGetAllClosedMonths,
    getReport: mocks.monthlyGetReport,
  },
  hrkMonthlyApi: {
    getSummary: mocks.hrkGetSummary,
    close: mocks.hrkClose,
  },
  hrkDailyApi: {
    handover: mocks.hrkHandover,
    receive: mocks.hrkReceive,
    getJournal: mocks.hrkGetJournal,
    closeDaily: mocks.hrkCloseDaily,
    cancel: mocks.hrkCancel,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { branchId: 'branch-1' } }),
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

const hrkSummary = {
  branchId: 'branch-1',
  yearMonth: '2026-06',
  totalTransactions: 2,
  totalHandoverHuf: 100000,
  totalReceiveHuf: 250000,
  netHuf: 150000,
  currencyBreakdown: [
    {
      currencyCode: 'EUR',
      handoverCount: 1,
      handoverAmount: 250,
      handoverHuf: 100000,
      receiveCount: 1,
      receiveAmount: 500,
      receiveHuf: 250000,
      netAmount: 250,
      netHuf: 150000,
    },
  ],
}

const hrkJournal = [
  {
    id: 'hrk-tx-1',
    branchId: 'branch-1',
    type: 'HANDOVER',
    currencyCode: 'EUR',
    amount: 250,
    hufAmount: 100000,
    bankAccountNumber: '11700000-00000000',
    reference: 'HRK-2026-001',
    note: 'Teszt átadás',
    status: 'COMPLETED',
    workerId: 77,
    createdAt: '2026-06-18T10:00:00',
    completedAt: '2026-06-18T10:05:00',
  },
  {
    id: 'hrk-tx-2',
    branchId: 'branch-1',
    type: 'RECEIVE',
    currencyCode: 'USD',
    amount: 100,
    hufAmount: 35000,
    bankAccountNumber: null,
    reference: 'HRK-2026-002',
    note: 'Függő átvétel',
    status: 'PENDING',
    workerId: 77,
    createdAt: '2026-06-18T11:00:00',
    completedAt: null,
  },
]

describe('MonthlyClosingPage HRK backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockResolvedValue({
      data: [
        {
          id: 'closing-1',
          yearMonth: '2026-06',
          branchName: 'Budapest 01',
          status: 'OPEN',
        },
      ],
    })
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
    mocks.hrkGetSummary.mockResolvedValue(hrkSummary)
    mocks.hrkClose.mockResolvedValue({ ...hrkSummary, totalTransactions: 3 })
    mocks.hrkHandover.mockResolvedValue({ ...hrkJournal[0], id: 'hrk-tx-new', type: 'HANDOVER' })
    mocks.hrkReceive.mockResolvedValue({ ...hrkJournal[1], id: 'hrk-tx-new-receive', type: 'RECEIVE' })
    mocks.hrkGetJournal.mockResolvedValue(hrkJournal)
    mocks.hrkCloseDaily.mockResolvedValue(hrkJournal)
    mocks.hrkCancel.mockResolvedValue(undefined)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('betölti a havi zárás listát, a HRK havi összesítőt és a napi naplót', async () => {
    render(<MonthlyClosingPage />)

    await waitFor(() => {
      expect(mocks.monthlyGetAllClosedMonths).toHaveBeenCalledWith('branch-1')
      expect(mocks.hrkGetSummary).toHaveBeenCalledWith(expect.stringMatching(/^\d{4}-\d{2}$/))
      expect(mocks.hrkGetJournal).toHaveBeenCalledWith('branch-1')
    })

    expect(await screen.findByText('HRK havi készletmozgás')).toBeInTheDocument()
    expect(await screen.findByText('HRK napi napló')).toBeInTheDocument()
    expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    expect(screen.getByText('HRK-2026-001')).toBeInTheDocument()
    expect(screen.getByText('HRK-2026-002')).toBeInTheDocument()
    expect(screen.getAllByText('150 000 Ft').length).toBeGreaterThan(0)
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

  it('HRK pénztár-bank átadást a handover backend wrapperre köt', async () => {
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByTestId('hrk-daily-movement-form')
    await user.type(screen.getByLabelText('Valuta'), 'eur')
    await user.type(screen.getByLabelText('Összeg'), '250')
    await user.type(screen.getByLabelText('HUF összeg'), '100000')
    await user.type(screen.getByLabelText('Bankszámla'), '11700000-00000000')
    await user.type(screen.getByLabelText('Megjegyzés'), 'Teszt átadás')
    await user.click(screen.getByRole('button', { name: /HRK rögzítés/i }))

    await waitFor(() => {
      expect(mocks.hrkHandover).toHaveBeenCalledWith('branch-1', {
        currencyCode: 'EUR',
        amount: 250,
        hufAmount: 100000,
        bankAccountNumber: '11700000-00000000',
        note: 'Teszt átadás',
      })
    })
  })

  it('HRK bank-pénztár átvételt a receive backend wrapperre köt', async () => {
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByTestId('hrk-daily-movement-form')
    await user.selectOptions(screen.getByLabelText('Művelet'), 'RECEIVE')
    await user.type(screen.getByLabelText('Valuta'), 'usd')
    await user.type(screen.getByLabelText('Összeg'), '100')
    await user.type(screen.getByLabelText('HUF összeg'), '35000')
    await user.click(screen.getByRole('button', { name: /HRK rögzítés/i }))

    await waitFor(() => {
      expect(mocks.hrkReceive).toHaveBeenCalledWith('branch-1', {
        currencyCode: 'USD',
        amount: 100,
        hufAmount: 35000,
        bankAccountNumber: undefined,
        note: undefined,
      })
    })
  })

  it('HRK PENDING tétel törlését a cancel backend wrapperre köti', async () => {
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByText('HRK-2026-002')
    const deleteButton = screen.getAllByRole('button', { name: /Törlés/i })
      .find((button) => !(button as HTMLButtonElement).disabled)
    if (!deleteButton) throw new Error('Hiányzik az aktív HRK törlés gomb')
    await user.click(deleteButton)

    await waitFor(() => {
      expect(mocks.hrkCancel).toHaveBeenCalledWith('hrk-tx-2')
    })
  })

  it('HRK havi zárás gomb megerősítés után a close backend wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByText('HRK havi készletmozgás')
    await user.click(screen.getByRole('button', { name: /HRK havi zárás/i }))

    await waitFor(() => {
      expect(window.confirm).toHaveBeenCalled()
      expect(mocks.hrkClose).toHaveBeenCalledWith(expect.stringMatching(/^\d{4}-\d{2}$/))
    })
  })

  it('HRK napi zárás gomb megerősítés után a close-daily backend wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<MonthlyClosingPage />)

    await screen.findByText('HRK napi napló')
    await user.click(screen.getByRole('button', { name: /HRK napi zárás/i }))

    await waitFor(() => {
      expect(window.confirm).toHaveBeenCalled()
      expect(mocks.hrkCloseDaily).toHaveBeenCalledWith('branch-1', expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/))
    })
  })
})
