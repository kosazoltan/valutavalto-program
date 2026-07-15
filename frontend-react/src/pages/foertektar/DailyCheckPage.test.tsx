import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DailyCheckPage from './DailyCheckPage'

// FK-047/FK-052 — Napi ellenőrző lista frontend grid: valutánkénti mérleg a daily_balance
// adataiból, beleértve a vault napi záráskor rögzített BANK+/BANK− értékeket.

const mocks = vi.hoisted(() => ({
  getGrid: vi.fn(),
  listActive: vi.fn(),
  getActiveCurrencies: vi.fn(),
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))
vi.mock('../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn(), info: vi.fn() },
}))
vi.mock('../../services/api/index', () => ({
  dailyBalanceGridApi: { getGrid: mocks.getGrid },
  branchApi: { listActive: mocks.listActive },
  currencyApi: { getActive: mocks.getActiveCurrencies },
}))

// 21 aktív deviza + HUF (FR-2)
const CURRENCY_CODES = [
  'EUR',
  'USD',
  'GBP',
  'CHF',
  'JPY',
  'AUD',
  'CAD',
  'CZK',
  'PLN',
  'RON',
  'TRY',
  'CNY',
  'RSD',
  'UAH',
  'ILS',
  'AED',
  'THB',
  'KRW',
  'MXN',
  'ZAR',
  'EUA',
  'HUF',
]

function gridRow(code: string, overrides: Record<string, number | null> = {}) {
  return {
    currencyCode: code,
    openingBalance: 100,
    purchases: 10,
    sales: 5,
    transfersIn: 2,
    transfersOut: 1,
    closingBalance: 106,
    actualStock: 106,
    surplus: 0,
    shortage: 0,
    bankPlus: null,
    bankMinus: null,
    ...overrides,
  }
}

async function loadGrid() {
  await act(async () => {
    fireEvent.click(screen.getByText('Lekérdezés'))
  })
}

describe('FK-047 — Napi ellenőrző lista grid', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.listActive.mockResolvedValue([])
    mocks.getActiveCurrencies.mockResolvedValue(
      CURRENCY_CODES.map((code, i) => ({ code, displayOrder: i })),
    )
  })

  it('grid megjelenik pénztári adatokkal (FR-1, FR-3): mind a 12 oszlop + adat-sorok', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR', { purchases: 250.5 })])
    render(<DailyCheckPage />)
    await loadGrid()

    const grid = await screen.findByTestId('daily-check-grid')
    expect(grid).toBeInTheDocument()
    // FR-3: a 12 oszlopfejléc
    for (const h of [
      'DEVIZA',
      'NYITÓ',
      'VÉTEL',
      'ELADÁS',
      'PTÁR+',
      'PTÁR-',
      'ZÁRÓ',
      'SZÁMZÁR',
      'TÖBB',
      'HIÁNY',
      'BANK+',
      'BANK-',
    ]) {
      expect(screen.getByText(h)).toBeInTheDocument()
    }
    expect(screen.getByText('EUR')).toBeInTheDocument()
    expect(screen.getByText('250,50')).toBeInTheDocument()
    // FR-7/NFR-1: a váltakozó sorokat adó közös .data-grid osztály
    expect(grid.className).toContain('data-grid')
  })

  it('22 sor jelenik meg (21 deviza + HUF) — az adat nélküli valuták is (FR-2, FR-8)', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR')]) // csak 1 valutának van adata
    render(<DailyCheckPage />)
    // megvárjuk a valuta-katalógus betöltését
    await waitFor(() => expect(mocks.getActiveCurrencies).toHaveBeenCalled())
    await loadGrid()

    const grid = await screen.findByTestId('daily-check-grid')
    const bodyRows = grid.querySelectorAll('tbody tr')
    expect(bodyRows.length).toBe(22)
    // az adat nélküli HUF sor is látszik, „–" cellákkal, nem hibával
    expect(screen.getByText('HUF')).toBeInTheDocument()
  })

  it('FK-052: BANK+ valós összeget formáz, BANK− null esetén „–" (FR-9, FR-10)', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR', { bankPlus: 1500, bankMinus: null })])
    render(<DailyCheckPage />)
    await loadGrid()

    const grid = await screen.findByTestId('daily-check-grid')
    const eurRow = Array.from(grid.querySelectorAll('tbody tr')).find(
      (tr) => tr.querySelector('td')?.textContent === 'EUR',
    )!
    const cells = Array.from(eurRow.querySelectorAll('td'))
    expect(cells[10]!.textContent).toBe('1 500,00')
    expect(cells[11]!.textContent).toBe('–')
  })

  it('FK-052: BANK+/BANK− fejlécek és adatcellák nem placeholder-szürkék, nincs tooltip', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR', { bankPlus: 10, bankMinus: 5 })])
    render(<DailyCheckPage />)
    await loadGrid()

    const grid = await screen.findByTestId('daily-check-grid')
    const bankPlusHeader = screen.getByText('BANK+')
    const bankMinusHeader = screen.getByText('BANK-')
    expect(bankPlusHeader.className).not.toContain('text-gray-400')
    expect(bankMinusHeader.className).not.toContain('text-gray-400')
    expect(bankPlusHeader).not.toHaveAttribute('title')
    expect(bankMinusHeader).not.toHaveAttribute('title')

    const eurRow = Array.from(grid.querySelectorAll('tbody tr')).find(
      (tr) => tr.querySelector('td')?.textContent === 'EUR',
    )!
    const cells = Array.from(eurRow.querySelectorAll('td'))
    expect(cells[10]!.className).not.toContain('text-gray-400')
    expect(cells[11]!.className).not.toContain('text-gray-400')
  })

  it('FK-052: BANK+ valós nulla „0,00", nem „–"', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR', { bankPlus: 0, bankMinus: null })])
    render(<DailyCheckPage />)
    await loadGrid()

    const grid = await screen.findByTestId('daily-check-grid')
    const eurRow = Array.from(grid.querySelectorAll('tbody tr')).find(
      (tr) => tr.querySelector('td')?.textContent === 'EUR',
    )!
    const cells = Array.from(eurRow.querySelectorAll('td'))
    expect(cells[10]!.textContent).toBe('0,00')
    expect(cells[11]!.textContent).toBe('–')
  })

  it('üres adat esetén nincs összeomlás: minden cella „–" (FR-8, NFR-5)', async () => {
    mocks.getGrid.mockResolvedValue([]) // nincs zárás azon a napon
    render(<DailyCheckPage />)
    await waitFor(() => expect(mocks.getActiveCurrencies).toHaveBeenCalled())
    await loadGrid()

    // a grid megjelenik (a valuta-katalógus adja a sorokat), az EUR sor cellái „–"-t mutatnak
    const grid = await screen.findByTestId('daily-check-grid')
    const firstRow = grid.querySelector('tbody tr')!
    const cells = Array.from(firstRow.querySelectorAll('td'))
    // az 1. cella a valutakód, a többi mind „–"
    for (const td of cells.slice(1)) {
      expect(td.textContent).toBe('–')
    }
  })

  it('TÖBB és HIÁNY a TH-tranzakcióból számolt surplus/shortage mezőt mutatja (FR-6)', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR', { surplus: 15, shortage: 3 })])
    render(<DailyCheckPage />)
    await loadGrid()

    await screen.findByTestId('daily-check-grid')
    expect(screen.getByText('15,00')).toBeInTheDocument()
    expect(screen.getByText('3,00')).toBeInTheDocument()
  })

  it('TÖBB és HIÁNY egyszerre 0 → mindkét cella 0-t mutat (edge case)', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR', { surplus: 0, shortage: 0 })])
    render(<DailyCheckPage />)
    await loadGrid()

    const grid = await screen.findByTestId('daily-check-grid')
    const eurRow = Array.from(grid.querySelectorAll('tbody tr')).find(
      (tr) => tr.querySelector('td')?.textContent === 'EUR',
    )!
    const cells = Array.from(eurRow.querySelectorAll('td')).map((td) => td.textContent)
    // TÖBB (index 8) és HIÁNY (index 9) egyaránt 0,00 — nem „–"
    expect(cells[8]).toBe('0,00')
    expect(cells[9]).toBe('0,00')
  })

  it('SZÁMZÁR nélküli nap: actualStock=null → „–" (FR-8)', async () => {
    mocks.getGrid.mockResolvedValue([gridRow('EUR', { actualStock: null })])
    render(<DailyCheckPage />)
    await loadGrid()

    const grid = await screen.findByTestId('daily-check-grid')
    const eurRow = Array.from(grid.querySelectorAll('tbody tr')).find(
      (tr) => tr.querySelector('td')?.textContent === 'EUR',
    )!
    const cells = Array.from(eurRow.querySelectorAll('td')).map((td) => td.textContent)
    expect(cells[7]).toBe('–') // SZÁMZÁR oszlop
  })

  it('teljes cég nézet: a lekérdezés szűrő nélkül (branchId/vaultTerritoryId nélkül) hívódik (FR-5)', async () => {
    mocks.getGrid.mockResolvedValue([])
    render(<DailyCheckPage />)
    await loadGrid()

    expect(mocks.getGrid).toHaveBeenCalledWith(expect.any(String), undefined, undefined)
  })

  it('API-hiba: hibaüzenet jelenik meg, nincs összeomlás', async () => {
    mocks.getGrid.mockRejectedValue(new Error('Szerver nem elérhető'))
    render(<DailyCheckPage />)
    await loadGrid()

    await waitFor(() => {
      expect(screen.queryByTestId('daily-check-grid')).not.toBeInTheDocument()
    })
  })
})
