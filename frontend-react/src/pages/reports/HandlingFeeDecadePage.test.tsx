import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import huJson from '../../i18n/hu.json'
import HandlingFeeDecadePage from './HandlingFeeDecadePage'

const translations: Record<string, string> = vi.hoisted(() => ({
  'reports.handlingFeeDecade.title': 'Kezelési díj — készpénz riport',
  'reports.handlingFeeDecade.from': 'Tól',
  'reports.handlingFeeDecade.to': 'Ig',
  'reports.handlingFeeDecade.branch': 'Iroda',
  'reports.handlingFeeDecade.branchPlaceholder': '— Válasszon irodát —',
  'reports.handlingFeeDecade.allBranchesOption': '— Minden iroda —',
  'reports.handlingFeeDecade.loading': 'Betöltés...',
  'reports.handlingFeeDecade.submit': 'Lekérdezés',
  'reports.handlingFeeDecade.csvTitle': 'CSV export (kiválasztott iroda)',
  'reports.handlingFeeDecade.summary.period': 'Időszak',
  'reports.handlingFeeDecade.summary.buyTotal': 'Vétel összesen',
  'reports.handlingFeeDecade.summary.sellTotal': 'Eladás összesen',
  'reports.handlingFeeDecade.summary.grandTotal': 'Mindösszesen',
  'reports.handlingFeeDecade.dailyBreakdown': 'Naponkénti bontás',
  'reports.handlingFeeDecade.table.date': 'Dátum',
  'reports.handlingFeeDecade.table.bankCode': 'Banki kód',
  'reports.handlingFeeDecade.table.branchCode': 'Pénztárszám',
  'reports.handlingFeeDecade.table.buyFee': 'Vétel kezelési díj',
  'reports.handlingFeeDecade.table.sellFee': 'Eladás kezelési díj',
  'reports.handlingFeeDecade.table.totalRow': 'Összesen',
  'reports.handlingFeeDecade.table.noData': 'Nincs adat a kiválasztott időszakra.',
  'reports.handlingFeeDecade.emptyState':
    'Adja meg a szűrőfeltételeket és nyomja meg a Lekérdezés gombot.',
  'reports.handlingFeeDecade.errors.noBranch': 'Válasszon irodát!',
  'reports.handlingFeeDecade.errors.noDateRange': 'Add meg a dátum-tartományt!',
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
  endDate: '2026-07-16',
  totalBuyFee: 1500,
  totalSellFee: 700,
  rows: [
    { date: '2026-07-01', bankCode: 'K&H', code: '001', buyFee: 1000, sellFee: 0 },
    { date: '2026-07-02', bankCode: '', code: '002', buyFee: 500, sellFee: 700 },
  ],
}

function setFilters() {
  fireEvent.change(screen.getByLabelText('Tól'), { target: { value: '2026-07-01' } })
  fireEvent.change(screen.getByLabelText('Ig'), { target: { value: '2026-07-16' } })
}

async function querySummary() {
  await waitFor(() =>
    expect(screen.getByRole('option', { name: '001 – K&H – Fő utca' })).toBeInTheDocument(),
  )
  setFilters()
  fireEvent.click(screen.getByRole('button', { name: 'Lekérdezés' }))
  await waitFor(() => expect(mockGet).toHaveBeenCalled())
}

describe('HandlingFeeDecadePage — FK-053', () => {
  beforeEach(() => {
    mockGet.mockReset()
    mockListActive.mockReset()
    mockListActive.mockResolvedValue(BRANCHES)
    mockGet.mockResolvedValue({ data: SUMMARY })
  })

  it('FR-3: a daily-summary végpontot hívja branchId és dátumtartomány paraméterekkel', async () => {
    render(<HandlingFeeDecadePage />)

    await querySummary()

    expect(mockGet).toHaveBeenCalledWith('/handling-fees/daily-summary', {
      params: { branchId: 'b1', startDate: '2026-07-01', endDate: '2026-07-16' },
    })
    expect(mockGet).not.toHaveBeenCalledWith('/handling-fees/report', expect.anything())
  })

  it('naponkénti sorokat és a vétel/eladás összesítő sort formázva jeleníti meg', async () => {
    render(<HandlingFeeDecadePage />)

    await querySummary()

    expect(await screen.findByText('2026. 07. 01.')).toBeInTheDocument()
    expect(screen.getByText('2026. 07. 02.')).toBeInTheDocument()
    expect(screen.getAllByText('1 000 Ft')).toHaveLength(1)
    expect(screen.getAllByText('1 500 Ft').length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText('700 Ft').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText('Összesen')).toBeInTheDocument()
  })

  it('NFR-4: a napi táblázat a közös data-grid osztályt használja', async () => {
    render(<HandlingFeeDecadePage />)

    await querySummary()

    expect(await screen.findByRole('table')).toHaveClass('data-grid')
  })

  it('FR-4: a fiók opcióban code, bankCode és name látszik, üres bankCode nélkül', async () => {
    render(<HandlingFeeDecadePage />)

    expect(await screen.findByRole('option', { name: '001 – K&H – Fő utca' })).toBeInTheDocument()
    expect(screen.getByRole('option', { name: '002 – Mellék' })).toBeInTheDocument()
    expect(huJson.reports.handlingFeeDecade.table.date).toBe('Dátum')
    expect(huJson.reports.handlingFeeDecade.table.bankCode).toBe('Banki kód')
    expect(huJson.reports.handlingFeeDecade.table.branchCode).toBe('Pénztárszám')
  })

  it('FR-5: a CSV export a napi CSV végpontot és a kiválasztott branchId-t használja', async () => {
    mockGet
      .mockResolvedValueOnce({ data: SUMMARY })
      .mockResolvedValueOnce({ data: new Blob(['csv'], { type: 'text/csv' }) })
    render(<HandlingFeeDecadePage />)
    await querySummary()

    fireEvent.click(await screen.findByRole('button', { name: 'CSV' }))

    await waitFor(() =>
      expect(mockGet).toHaveBeenCalledWith('/handling-fees/daily-summary/csv', {
        params: { branchId: 'b1', startDate: '2026-07-01', endDate: '2026-07-16' },
        responseType: 'blob',
      }),
    )
  })

  it('üres napi eredménynél a nincs adat sort jeleníti meg', async () => {
    mockGet.mockResolvedValue({
      data: { ...SUMMARY, totalBuyFee: 0, totalSellFee: 0, rows: [] },
    })
    render(<HandlingFeeDecadePage />)

    await querySummary()

    expect(await screen.findByText('Nincs adat a kiválasztott időszakra.')).toBeInTheDocument()
  })

  it('FR-3: a Minden iroda opció a placeholder után és a fiókok előtt jelenik meg', async () => {
    render(<HandlingFeeDecadePage />)

    await waitFor(() =>
      expect(screen.getByRole('option', { name: '001 – K&H – Fő utca' })).toBeInTheDocument(),
    )

    const select = screen.getByLabelText('Iroda')
    const options = within(select).getAllByRole('option')
    expect(options[0]).toHaveTextContent('— Válasszon irodát —')
    expect(options[1]).toHaveTextContent('— Minden iroda —')
    expect(options[2]).toHaveTextContent('001 – K&H – Fő utca')
  })

  it('FR-1/FR-3: Minden iroda választásakor branchId nélkül kérdez le', async () => {
    render(<HandlingFeeDecadePage />)

    await waitFor(() =>
      expect(screen.getByRole('option', { name: '— Minden iroda —' })).toBeInTheDocument(),
    )
    setFilters()
    fireEvent.change(screen.getByLabelText('Iroda'), { target: { value: '__ALL__' } })
    fireEvent.click(screen.getByRole('button', { name: 'Lekérdezés' }))

    await waitFor(() =>
      expect(mockGet).toHaveBeenCalledWith('/handling-fees/daily-summary', expect.anything()),
    )
    const [, config] = mockGet.mock.calls[0]!
    expect(config.params).toEqual({ startDate: '2026-07-01', endDate: '2026-07-16' })
    expect(config.params).not.toHaveProperty('branchId')
  })

  it('FR-4: CSV export Minden iroda mellett branchId nélkül hívja a végpontot', async () => {
    mockGet
      .mockResolvedValueOnce({ data: SUMMARY })
      .mockResolvedValueOnce({ data: new Blob(['csv'], { type: 'text/csv' }) })
    render(<HandlingFeeDecadePage />)

    await waitFor(() =>
      expect(screen.getByRole('option', { name: '— Minden iroda —' })).toBeInTheDocument(),
    )
    setFilters()
    fireEvent.change(screen.getByLabelText('Iroda'), { target: { value: '__ALL__' } })
    fireEvent.click(screen.getByRole('button', { name: 'Lekérdezés' }))
    await waitFor(() =>
      expect(mockGet).toHaveBeenCalledWith('/handling-fees/daily-summary', expect.anything()),
    )

    fireEvent.click(await screen.findByRole('button', { name: 'CSV' }))

    await waitFor(() =>
      expect(mockGet).toHaveBeenCalledWith('/handling-fees/daily-summary/csv', expect.anything()),
    )
    const [, config] = mockGet.mock.calls[1]!
    expect(config.params).toEqual({ startDate: '2026-07-01', endDate: '2026-07-16' })
    expect(config.params).not.toHaveProperty('branchId')
    expect(config.responseType).toBe('blob')
  })

  it('FR-6: a készpénzes kezelési díj riportcímet jeleníti meg', async () => {
    render(<HandlingFeeDecadePage />)

    expect(
      screen.getByRole('heading', { name: 'Kezelési díj — készpénz riport' }),
    ).toBeInTheDocument()
    await waitFor(() =>
      expect(screen.getByRole('option', { name: '001 – K&H – Fő utca' })).toBeInTheDocument(),
    )
  })

  it('FK-095: azonos dátum két irodája két sort jelenít meg Banki kód és Pénztárszám oszlopokkal', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
    mockGet.mockResolvedValue({
      data: {
        ...SUMMARY,
        rows: [
          { date: '2026-07-01', bankCode: 'K&H', code: '001', buyFee: 1000, sellFee: 0 },
          { date: '2026-07-01', bankCode: 'OTP', code: '002', buyFee: 25, sellFee: 0 },
          { date: '2026-07-02', bankCode: '', code: '003', buyFee: 500, sellFee: 700 },
        ],
      },
    })
    render(<HandlingFeeDecadePage />)

    await querySummary()

    expect(screen.getByRole('columnheader', { name: 'Banki kód' })).toBeInTheDocument()
    expect(screen.getByRole('columnheader', { name: 'Pénztárszám' })).toBeInTheDocument()
    const table = screen.getByRole('table')
    expect(within(table).getAllByText('2026. 07. 01.')).toHaveLength(2)
    const blankBankRow = within(table).getByText('2026. 07. 02.').closest('tr')!
    const cells = within(blankBankRow).getAllByRole('cell')
    expect(cells[1]!.textContent).toBe('')
    expect(cells[2]).toHaveTextContent('003')
    expect(consoleError.mock.calls.flat().join(' ')).not.toContain('Encountered two children')
    consoleError.mockRestore()
  })
})
