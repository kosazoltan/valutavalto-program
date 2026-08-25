import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { downloadBlob } from '../../utils/downloadBlob'
import PosHandlingFeePage from './PosHandlingFeePage'

const translations: Record<string, string> = vi.hoisted(() => ({
  'reports.posHandlingFee.title': 'Kezelési díj — POS riport',
  'reports.posHandlingFee.from': 'Tól',
  'reports.posHandlingFee.to': 'Ig',
  'reports.posHandlingFee.branch': 'Iroda',
  'reports.posHandlingFee.branchPlaceholder': '— Válasszon irodát —',
  'reports.posHandlingFee.allBranchesOption': '— Minden iroda —',
  'reports.posHandlingFee.loading': 'Betöltés...',
  'reports.posHandlingFee.submit': 'Lekérdezés',
  'reports.posHandlingFee.csvTitle': 'CSV export',
  'reports.posHandlingFee.summary.period': 'Időszak',
  'reports.posHandlingFee.summary.netTotal': 'POS nettó összesen',
  'reports.posHandlingFee.summary.feeTotal': 'POS KK összesen',
  'reports.posHandlingFee.dailyBreakdown': 'Naponkénti bontás',
  'reports.posHandlingFee.table.date': 'Dátum',
  'reports.posHandlingFee.table.bankCode': 'Banki kód',
  'reports.posHandlingFee.table.branchCode': 'Pénztárszám',
  'reports.posHandlingFee.table.netAmount': 'POS nettó (Ft)',
  'reports.posHandlingFee.table.feeAmount': 'POS KK (Ft)',
  'reports.posHandlingFee.table.totalRow': 'Összesen',
  'reports.posHandlingFee.table.noData': 'Nincs adat a kiválasztott időszakra.',
  'reports.posHandlingFee.emptyState':
    'Adja meg a szűrőfeltételeket és nyomja meg a Lekérdezés gombot.',
  'reports.posHandlingFee.errors.noBranch': 'Válasszon irodát!',
  'reports.posHandlingFee.errors.noDateRange': 'Add meg a dátum-tartományt!',
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => translations[key] ?? key,
  }),
}))

const mockGet = vi.fn()
const mockListActive = vi.fn()

vi.mock('../../services/api/index', () => ({
  api: { get: (...args: unknown[]) => mockGet(...args) },
  branchApi: { listActive: (...args: unknown[]) => mockListActive(...args) },
}))

vi.mock('../../utils/downloadBlob', () => ({
  downloadBlob: vi.fn(),
}))

const BRANCHES = [
  { id: 'b1', code: '001', bankCode: 'K&H', name: 'Fő utca' },
  { id: 'b2', code: '002', bankCode: '', name: 'Mellék' },
]

const SUMMARY = {
  startDate: '2026-07-01',
  endDate: '2026-07-02',
  totalNetAmount: 93000,
  totalFeeAmount: 3800,
  rows: [
    { date: '2026-07-01', bankCode: 'K&H', code: '001', netAmount: 73000, feeAmount: 3000 },
    { date: '2026-07-02', bankCode: '', code: '002', netAmount: 20000, feeAmount: 800 },
  ],
}

function setDateRange() {
  fireEvent.change(screen.getByLabelText('Tól'), { target: { value: '2026-07-01' } })
  fireEvent.change(screen.getByLabelText('Ig'), { target: { value: '2026-07-02' } })
}

async function waitForBranches() {
  await waitFor(() =>
    expect(screen.getByRole('option', { name: '001 – K&H – Fő utca' })).toBeInTheDocument(),
  )
}

async function queryBranch() {
  await waitForBranches()
  setDateRange()
  fireEvent.click(screen.getByRole('button', { name: 'Lekérdezés' }))
  await waitFor(() =>
    expect(mockGet).toHaveBeenCalledWith('/handling-fees/pos-daily-summary', expect.anything()),
  )
}

async function queryAllBranches() {
  await waitForBranches()
  setDateRange()
  fireEvent.change(screen.getByLabelText('Iroda'), { target: { value: '__ALL__' } })
  fireEvent.click(screen.getByRole('button', { name: 'Lekérdezés' }))
  await waitFor(() =>
    expect(mockGet).toHaveBeenCalledWith('/handling-fees/pos-daily-summary', expect.anything()),
  )
}

describe('PosHandlingFeePage — FK-059', () => {
  beforeEach(() => {
    mockGet.mockReset()
    mockListActive.mockReset()
    vi.mocked(downloadBlob).mockReset()
    mockListActive.mockResolvedValue(BRANCHES)
    mockGet.mockResolvedValue({ data: SUMMARY })
  })

  it('queries the POS summary endpoint with branch and date parameters', async () => {
    render(<PosHandlingFeePage />)

    await queryBranch()

    expect(mockGet).toHaveBeenCalledWith('/handling-fees/pos-daily-summary', {
      params: { branchId: 'b1', startDate: '2026-07-01', endDate: '2026-07-02' },
    })
  })

  it('omits branchId when Minden iroda is selected', async () => {
    render(<PosHandlingFeePage />)

    await queryAllBranches()

    const [, config] = mockGet.mock.calls[0]!
    expect(config.params).toEqual({ startDate: '2026-07-01', endDate: '2026-07-02' })
    expect(config.params).not.toHaveProperty('branchId')
  })

  it('renders localized daily POS columns and totals without a Vétel column', async () => {
    render(<PosHandlingFeePage />)

    await queryBranch()

    expect(await screen.findByText('2026. 07. 01.')).toBeInTheDocument()
    expect(screen.getByText('2026. 07. 02.')).toBeInTheDocument()
    expect(screen.getByRole('columnheader', { name: 'Dátum' })).toBeInTheDocument()
    expect(screen.getByRole('columnheader', { name: 'POS nettó (Ft)' })).toBeInTheDocument()
    expect(screen.getByRole('columnheader', { name: 'POS KK (Ft)' })).toBeInTheDocument()
    expect(screen.queryByText(/Vétel/)).not.toBeInTheDocument()
    expect(screen.getByText('Összesen')).toBeInTheDocument()
    expect(screen.getAllByText('93 000 Ft').length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText('3 800 Ft').length).toBeGreaterThanOrEqual(1)
  })

  it('exports branch CSV with the exact last query parameters and filename', async () => {
    mockGet
      .mockResolvedValueOnce({ data: SUMMARY })
      .mockResolvedValueOnce({ data: new Blob(['csv'], { type: 'text/csv' }) })
    render(<PosHandlingFeePage />)
    await queryBranch()

    fireEvent.click(await screen.findByRole('button', { name: 'CSV' }))

    await waitFor(() =>
      expect(mockGet).toHaveBeenCalledWith('/handling-fees/pos-daily-summary/csv', {
        params: { branchId: 'b1', startDate: '2026-07-01', endDate: '2026-07-02' },
        responseType: 'blob',
      }),
    )
    expect(downloadBlob).toHaveBeenCalledWith(
      expect.anything(),
      'kezelesi-dij-pos-napi-2026-07-01-2026-07-02.csv',
      'text/csv; charset=UTF-8',
    )
  })

  it('exports all-office CSV without branchId, matching the last query', async () => {
    mockGet
      .mockResolvedValueOnce({ data: SUMMARY })
      .mockResolvedValueOnce({ data: new Blob(['csv'], { type: 'text/csv' }) })
    render(<PosHandlingFeePage />)
    await queryAllBranches()

    fireEvent.click(await screen.findByRole('button', { name: 'CSV' }))

    await waitFor(() =>
      expect(mockGet).toHaveBeenCalledWith('/handling-fees/pos-daily-summary/csv', {
        params: { startDate: '2026-07-01', endDate: '2026-07-02' },
        responseType: 'blob',
      }),
    )
  })

  it('uses the shared data-grid class for the daily table', async () => {
    render(<PosHandlingFeePage />)

    await queryBranch()

    expect(await screen.findByRole('table')).toHaveClass('data-grid')
  })

  it('FK-095: azonos dátum két irodája két sort jelenít meg Banki kód és Pénztárszám oszlopokkal', async () => {
    mockGet.mockResolvedValue({
      data: {
        ...SUMMARY,
        rows: [
          { date: '2026-07-01', bankCode: 'K&H', code: '001', netAmount: 73000, feeAmount: 3000 },
          { date: '2026-07-01', bankCode: 'OTP', code: '002', netAmount: 20000, feeAmount: 800 },
          { date: '2026-07-02', bankCode: '', code: '003', netAmount: 0, feeAmount: 0 },
        ],
      },
    })
    render(<PosHandlingFeePage />)

    await queryBranch()

    expect(screen.getByRole('columnheader', { name: 'Banki kód' })).toBeInTheDocument()
    expect(screen.getByRole('columnheader', { name: 'Pénztárszám' })).toBeInTheDocument()
    expect(screen.getAllByText('2026. 07. 01.')).toHaveLength(2)
    const blankBankRow = screen.getByText('2026. 07. 02.').closest('tr')!
    const cells = within(blankBankRow).getAllByRole('cell')
    expect(cells[1].textContent).toBe('')
    expect(cells[2]).toHaveTextContent('003')
  })
})
