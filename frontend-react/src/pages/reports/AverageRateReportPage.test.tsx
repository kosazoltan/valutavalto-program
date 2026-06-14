/**
 * FK-027 — Átlag árfolyam pivot oldal tesztjei.
 * Lefedi: pivot tábla render oszlopcsoportokkal + valuta-sorokkal (FR-5/6),
 * "Típus"/"Valuta" szűrő hiánya (FR-7), Excel export gomb (FR-8).
 */
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import AverageRateReportPage from './AverageRateReportPage'

const mockGetPivot = vi.fn()
const mockExportExcel = vi.fn()
const mockListActive = vi.fn()

vi.mock('../../services/api/index', () => ({
  averageRateApi: {
    getPivot: (...args: unknown[]) => mockGetPivot(...args),
    exportExcel: (...args: unknown[]) => mockExportExcel(...args),
  },
  branchApi: {
    listActive: (...args: unknown[]) => mockListActive(...args),
  },
}))

const PIVOT = {
  periodStart: '2026-06-01',
  periodEnd: '2026-06-30',
  columnGroups: [
    { groupCode: 'SZEGED', groupName: 'SZEGED', groupType: 'REGION' as const },
    { groupCode: 'total', groupName: 'EXCLUSIVE BEST CHANGE ZRT', groupType: 'TOTAL' as const },
  ],
  currencyRows: [
    {
      currencyCode: 'EUR',
      values: {
        SZEGED: { buyAvgRate: 400, buySumAmount: 1000, sellAvgRate: 420, sellSumAmount: 500 },
        total: { buyAvgRate: 401, buySumAmount: 2000, sellAvgRate: 421, sellSumAmount: 800 },
      },
    },
    {
      currencyCode: 'USD',
      values: {
        SZEGED: { buyAvgRate: 360, buySumAmount: 0, sellAvgRate: 0, sellSumAmount: 0 },
        total: { buyAvgRate: 360, buySumAmount: 0, sellAvgRate: 0, sellSumAmount: 0 },
      },
    },
  ],
}

function renderPage() {
  return render(<AverageRateReportPage />)
}

describe('AverageRateReportPage — FK-027 pivot', () => {
  beforeEach(() => {
    mockGetPivot.mockReset()
    mockExportExcel.mockReset()
    mockListActive.mockReset()
    mockListActive.mockResolvedValue([])
    global.URL.createObjectURL = vi.fn(() => 'blob:mock')
    global.URL.revokeObjectURL = vi.fn()
  })

  it('FR-5/6: lekérdezés után pivot tábla — oszlopcsoportok + valuta-sorok', async () => {
    mockGetPivot.mockResolvedValue(PIVOT)
    renderPage()
    fireEvent.click(screen.getByText('Lekérdezés'))
    await waitFor(() => expect(screen.getByTestId('pivot-table')).toBeInTheDocument())
    expect(screen.getByText('EXCLUSIVE BEST CHANGE ZRT')).toBeInTheDocument()
    expect(screen.getByText('EUR')).toBeInTheDocument()
    expect(screen.getByText('USD')).toBeInTheDocument()
    // Vétel/Eladás alfejlécek (4 oszlop / csoport)
    expect(screen.getAllByText('Vétel Árfolyam').length).toBe(2) // 2 oszlopcsoport
    expect(screen.getAllByText('Eladás Összeg').length).toBe(2)
  })

  it('FR-7: nincs "Típus" és "Valuta" szűrő, csak Iroda', () => {
    renderPage()
    expect(screen.getByLabelText('Iroda szűrő')).toBeInTheDocument()
    expect(screen.queryByText('Típus')).not.toBeInTheDocument()
    expect(screen.queryByText('Valuta')).not.toBeInTheDocument()
  })

  it('FR-8: az "Excel export" gomb meghívja az export API-t', async () => {
    mockExportExcel.mockResolvedValue(new Blob(['xlsx']))
    renderPage()
    fireEvent.click(screen.getByText('Excel export'))
    await waitFor(() => expect(mockExportExcel).toHaveBeenCalled())
  })
})
