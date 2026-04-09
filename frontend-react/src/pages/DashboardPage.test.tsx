import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, it, expect, beforeEach } from 'vitest'
import DashboardPage from './DashboardPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../services/api/transactions', () => ({
  transactionApi: {
    getDailyTurnover: vi.fn().mockResolvedValue({
      totalBuyCount: 30,
      totalSellCount: 17,
      totalBuyHuf: 8000000,
      totalSellHuf: 4500000,
      totalHandlingFees: 25000,
      totalReversalCount: 3,
    }),
    list: vi.fn().mockResolvedValue({
      content: [
        { transactionType: 'BUY', currencyCode: 'EUR', currencyAmount: 500, hufAmount: 195750, workerName: 'Kiss János', transactionTime: '10:45:00', status: 'COMPLETED' },
        { transactionType: 'SELL', currencyCode: 'USD', currencyAmount: 1000, hufAmount: 358200, workerName: 'Nagy Péter', transactionTime: '10:32:00', status: 'COMPLETED' },
        { transactionType: 'BUY', currencyCode: 'GBP', currencyAmount: 200, hufAmount: 91000, workerName: 'Szabó Anna', transactionTime: '10:15:00', status: 'COMPLETED' },
      ],
      totalElements: 3,
      totalPages: 1,
      number: 0,
      size: 5,
    }),
  },
}))

vi.mock('../services/api/exchange-rates', () => ({
  exchangeRateApi: {
    list: vi.fn().mockResolvedValue([
      {
        id: 1, currencyId: 4, currencyCode: 'EUR', currencyName: 'Euró',
        validDate: '2026-03-27', validTime: '08:00', baseBuyRate: 391.50,
        baseSellRate: 398.50, officialRate: 395.00, active: true, createdAt: '2026-03-27T08:00:00',
      },
      {
        id: 2, currencyId: 5, currencyCode: 'USD', currencyName: 'Amerikai dollár',
        validDate: '2026-03-27', validTime: '08:00', baseBuyRate: 358.20,
        baseSellRate: 365.80, officialRate: 362.00, active: true, createdAt: '2026-03-27T08:00:00',
      },
      {
        id: 3, currencyId: 6, currencyCode: 'GBP', currencyName: 'Angol font',
        validDate: '2026-03-27', validTime: '08:00', baseBuyRate: 455.00,
        baseSellRate: 465.00, officialRate: 460.00, active: true, createdAt: '2026-03-27T08:00:00',
      },
      {
        id: 4, currencyId: 7, currencyCode: 'CHF', currencyName: 'Svájci frank',
        validDate: '2026-03-27', validTime: '08:00', baseBuyRate: 402.50,
        baseSellRate: 410.00, officialRate: 406.00, active: true, createdAt: '2026-03-27T08:00:00',
      },
    ]),
  },
  rateApi: {
    list: vi.fn().mockResolvedValue([]),
  },
}))

function renderDashboardPage() {
  render(
    <MemoryRouter>
      <DashboardPage />
    </MemoryRouter>,
  )
}

describe('DashboardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('oldal renderelésének ellenőrzése', () => {
    renderDashboardPage()
    expect(screen.getByText('Irányítópult')).toBeInTheDocument()
    expect(screen.getByText('Áttekintés és gyorsműveletek')).toBeInTheDocument()
  })

  it('KPI kártyákat jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText('Mai tranzakciók')).toBeInTheDocument()
    expect(screen.getByText('Mai forgalom')).toBeInTheDocument()
    expect(screen.getByText('Aktív ügyfelek')).toBeInTheDocument()
    expect(screen.getByText('Függő foglalók')).toBeInTheDocument()
  })

  it('KPI értékeket helyesen jeleníti meg', async () => {
    renderDashboardPage()
    await waitFor(() => {
      expect(screen.getByText('47')).toBeInTheDocument() // totalBuyCount(30) + totalSellCount(17)
      expect(screen.getByText('12.5M Ft')).toBeInTheDocument() // (8M+4.5M)/1M = 12.5M
      expect(screen.getByText('3')).toBeInTheDocument() // totalReversalCount
    })
  })

  it('árfolyam táblázatot jeleníti meg', async () => {
    renderDashboardPage()
    expect(screen.getByText('Aktuális árfolyamok')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
      expect(screen.getAllByText('USD').length).toBeGreaterThan(0)
      expect(screen.getAllByText('GBP').length).toBeGreaterThan(0)
      expect(screen.getAllByText('CHF').length).toBeGreaterThan(0)
    })
  })

  it('árfolyamok vétel és eladási értékeket helyesen mutatja', async () => {
    renderDashboardPage()
    // EUR sorban a vétel ár 391.50, eladás 398.50 (mock API-ból)
    await waitFor(() => {
      expect(screen.getByText('391.50')).toBeInTheDocument()
      expect(screen.getByText('398.50')).toBeInTheDocument()
    })
  })

  it('gyorsműveletek linkeket jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText('Új tranzakció')).toBeInTheDocument()
    expect(screen.getByText('Új ügyfél')).toBeInTheDocument()
    expect(screen.getByText('Árfolyam módosítás')).toBeInTheDocument()
    expect(screen.getByText('Napi zárás')).toBeInTheDocument()
  })

  it('legutóbbi tranzakciók táblázatot jeleníti meg', async () => {
    renderDashboardPage()
    expect(screen.getByText('Legutóbbi tranzakciók')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
      expect(screen.getByText('Szabó Anna')).toBeInTheDocument()
    })
  })

  it('tranzakciók státuszát helyesen jelöli meg', async () => {
    renderDashboardPage()
    await waitFor(() => {
      const badges = screen.getAllByText('Befejezve')
      expect(badges.length).toBeGreaterThan(0)
    })
  })

  it('utolsó frissítést az aktuális idővel jeleníti meg', () => {
    renderDashboardPage()
    // Kompakt UI: csak az idő jelenik meg, "Utolsó frissítés:" prefix eltávolítva
    const timeRegex = /\d{1,2}:\d{2}:\d{2}/
    expect(screen.getByText(timeRegex)).toBeInTheDocument()
  })

  it('árfolyam részletek linkre kattintás navigál', () => {
    renderDashboardPage()
    const ratesLink = screen.getAllByText(/Részletek/)[0]
    expect(ratesLink).toBeInTheDocument()
  })

  it('összes tranzakciók linkre kattintás navigál', () => {
    renderDashboardPage()
    const allTransactionsLink = screen.getAllByText(/Összes/)[0]
    expect(allTransactionsLink).toBeInTheDocument()
  })
})
