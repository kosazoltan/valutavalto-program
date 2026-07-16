import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import huJson from '../../i18n/hu.json'
import HandlingFeeDecadePage from './HandlingFeeDecadePage'

const translations: Record<string, string> = vi.hoisted(() => ({
  'reports.handlingFeeDecade.title': 'Kezelési díj — dekád riport',
  'reports.handlingFeeDecade.from': 'Tól',
  'reports.handlingFeeDecade.to': 'Ig',
  'reports.handlingFeeDecade.branch': 'Iroda',
  'reports.handlingFeeDecade.branchPlaceholder': '— Válasszon irodát —',
  'reports.handlingFeeDecade.loading': 'Betöltés...',
  'reports.handlingFeeDecade.submit': 'Lekérdezés',
  'reports.handlingFeeDecade.csvTitle': 'CSV export (kiválasztott iroda)',
  'reports.handlingFeeDecade.summary.period': 'Időszak',
  'reports.handlingFeeDecade.summary.buyTotal': 'Vétel összesen',
  'reports.handlingFeeDecade.summary.sellTotal': 'Eladás összesen',
  'reports.handlingFeeDecade.summary.grandTotal': 'Mindösszesen',
  'reports.handlingFeeDecade.dailyBreakdown': 'Naponkénti bontás',
  'reports.handlingFeeDecade.table.date': 'Dátum',
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
    { date: '2026-07-01', buyFee: 1000, sellFee: 0 },
    { date: '2026-07-02', buyFee: 500, sellFee: 700 },
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
})
