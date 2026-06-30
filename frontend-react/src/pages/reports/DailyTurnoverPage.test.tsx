/**
 * FK-045 — Napi forgalom oldal tesztjei.
 * Lefedi: FR-1 (nem omlik össze a backend TurnoverReportDto struktúrával), FR-6 (valutánkénti
 * táblázat + officialRate „–"), FR-8 (VETT/ELADOTT összesítők), üres állapot (NFR-4).
 */
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import DailyTurnoverPage from './DailyTurnoverPage'

const mockCompany = vi.fn()
const mockTerritory = vi.fn()
const mockByPeriod = vi.fn()
const mockListActive = vi.fn()

vi.mock('../../services/api/index', () => ({
  turnoverApi: {
    company: (...args: unknown[]) => mockCompany(...args),
    territory: (...args: unknown[]) => mockTerritory(...args),
    byPeriod: (...args: unknown[]) => mockByPeriod(...args),
  },
  branchApi: {
    listActive: (...args: unknown[]) => mockListActive(...args),
  },
}))

// A backend TurnoverReportDto TÉNYLEGES alakja (FR-11): totalBuy/totalSell/byCurrency.
const REPORT = {
  period: '2026-06-01 - 2026-06-30',
  totalBuy: 1002345,
  totalSell: 2008925,
  byCurrency: [
    { currencyCode: 'EUR', officialRate: 405.12, buyVolume: 2000, buyHuf: 800000, sellVolume: 1500, sellHuf: 600000 },
    { currencyCode: 'USD', officialRate: null, buyVolume: 500, buyHuf: 200000, sellVolume: 0, sellHuf: 0 },
  ],
}

describe('DailyTurnoverPage — FK-045', () => {
  beforeEach(() => {
    mockCompany.mockReset()
    mockTerritory.mockReset()
    mockByPeriod.mockReset()
    mockListActive.mockReset()
    mockListActive.mockResolvedValue([])
  })

  it('FR-1: az oldal hibamentesen betöltődik (nem omlik össze a régi struktúra hiányától)', () => {
    render(<DailyTurnoverPage />)
    // A korábbi hiba: Cannot read properties of undefined (reading 'totalBuyHuf'). Most data=null →
    // a táblázat/összesítő nem renderelődik, de a szűrő-panel és a fejléc igen.
    expect(screen.getByText('Időszak rendben')).toBeInTheDocument()
    expect(screen.getByText('Teljes cég')).toBeInTheDocument()
  })

  it('FR-6/FR-8: lekérdezés után valutánkénti táblázat + VETT/ELADOTT összesítők', async () => {
    mockCompany.mockResolvedValue(REPORT)
    render(<DailyTurnoverPage />)
    fireEvent.click(screen.getByText('Időszak rendben'))

    await waitFor(() => expect(screen.getByText('EUR')).toBeInTheDocument())
    expect(screen.getByText('USD')).toBeInTheDocument()
    // FR-7: az USD-hez nincs MNB-árfolyam → „–"
    expect(screen.getByText('–')).toBeInTheDocument()
    // FR-8: összesítők
    expect(screen.getByText('VETT összesen')).toBeInTheDocument()
    expect(screen.getByText('ELADOTT összesen')).toBeInTheDocument()
    expect(screen.getByText('1 002 345 Ft')).toBeInTheDocument()
    expect(screen.getByText('2 008 925 Ft')).toBeInTheDocument()
  })

  it('NFR-4: üres byCurrency → „Nincs forgalmi adat" üzenet, nem összeomlás', async () => {
    mockCompany.mockResolvedValue({ period: '2026-06-01 - 2026-06-30', totalBuy: 0, totalSell: 0, byCurrency: [] })
    render(<DailyTurnoverPage />)
    fireEvent.click(screen.getByText('Időszak rendben'))

    await waitFor(() =>
      expect(screen.getByText('Nincs forgalmi adat a megadott időszakra')).toBeInTheDocument(),
    )
  })
})
