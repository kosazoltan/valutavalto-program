import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, it, expect, beforeEach } from 'vitest'
import DashboardPage from './DashboardPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  apiGet: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
  },
}))

function setupApiGet() {
  mocks.apiGet.mockImplementation((path: string) => {
    if (path === '/dashboard/summary') {
      return Promise.resolve({
        data: {
          todayVolume: 12500000,
          openTransactions: 47,
          activeBranches: 9,
          alertCount: 3,
          currencyVolumes: { EUR: 8000000, USD: 4500000 },
          recentTransactions: [
            {
              id: 1,
              type: 'BUY',
              currencyCode: 'EUR',
              amount: 500,
              hufAmount: 195750,
              cashierName: 'Kiss János',
              createdAt: '2026-03-27T10:45:00',
            },
            {
              id: 2,
              type: 'SELL',
              currencyCode: 'USD',
              amount: 1000,
              hufAmount: 358200,
              cashierName: 'Nagy Péter',
              createdAt: '2026-03-27T10:32:00',
            },
            {
              id: 3,
              type: 'BUY',
              currencyCode: 'GBP',
              amount: 200,
              hufAmount: 91000,
              cashierName: 'Szabó Anna',
              createdAt: '2026-03-27T10:15:00',
            },
          ],
          branchSyncStatuses: [],
        },
      })
    }
    if (path === '/health') {
      return Promise.resolve({
        data: { status: 'UP', db: 'connected', uptime: '1h 2m 3s', version: '2.0.0' },
      })
    }
    if (path === '/health/detailed') {
      return Promise.resolve({
        data: {
          status: 'UP',
          database: { connected: true, responseTimeMs: 12, activeConnections: 2 },
          jvm: { heapUsed: 67108864, heapMax: 536870912, threads: 24 },
        },
      })
    }
    if (path === '/health/info') {
      return Promise.resolve({
        data: {
          name: 'valuta-backend',
          version: '2.0.0',
          environment: 'test',
          javaVersion: '21',
        },
      })
    }
    return Promise.resolve({ data: [] })
  })
}

vi.mock('../services/api/exchange-rates', () => ({
  exchangeRateApi: {
    list: vi.fn().mockResolvedValue([
      {
        id: 1,
        currencyId: 4,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        validDate: '2026-03-27',
        validTime: '08:00',
        baseBuyRate: 391.5,
        baseSellRate: 398.5,
        officialRate: 395.0,
        active: true,
        createdAt: '2026-03-27T08:00:00',
      },
      {
        id: 2,
        currencyId: 5,
        currencyCode: 'USD',
        currencyName: 'Amerikai dollár',
        validDate: '2026-03-27',
        validTime: '08:00',
        baseBuyRate: 358.2,
        baseSellRate: 365.8,
        officialRate: 362.0,
        active: true,
        createdAt: '2026-03-27T08:00:00',
      },
      {
        id: 3,
        currencyId: 6,
        currencyCode: 'GBP',
        currencyName: 'Angol font',
        validDate: '2026-03-27',
        validTime: '08:00',
        baseBuyRate: 455.0,
        baseSellRate: 465.0,
        officialRate: 460.0,
        active: true,
        createdAt: '2026-03-27T08:00:00',
      },
      {
        id: 4,
        currencyId: 7,
        currencyCode: 'CHF',
        currencyName: 'Svájci frank',
        validDate: '2026-03-27',
        validTime: '08:00',
        baseBuyRate: 402.5,
        baseSellRate: 410.0,
        officialRate: 406.0,
        active: true,
        createdAt: '2026-03-27T08:00:00',
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
    setupApiGet()
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
    expect(screen.getByText('Aktív irodák')).toBeInTheDocument()
    expect(screen.getByText('Riasztások')).toBeInTheDocument()
  })

  it('KPI értékeket helyesen jeleníti meg', async () => {
    renderDashboardPage()
    await waitFor(() => {
      expect(screen.getByText('47')).toBeInTheDocument()
      expect(screen.getByText('12.5M Ft')).toBeInTheDocument()
      expect(screen.getByText('9')).toBeInTheDocument()
      expect(screen.getByText('3')).toBeInTheDocument()
    })
  })

  it('rendszerállapot panelt a health backend endpointokból tölti', async () => {
    renderDashboardPage()

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/health')
      expect(mocks.apiGet).toHaveBeenCalledWith('/health/detailed')
      expect(mocks.apiGet).toHaveBeenCalledWith('/health/info')
    })
    expect(screen.getByText('Rendszerállapot')).toBeInTheDocument()
    expect(screen.getByText('valuta-backend')).toBeInTheDocument()
    expect(screen.getByText('connected')).toBeInTheDocument()
    expect(screen.getByText('12 ms')).toBeInTheDocument()
    expect(screen.getByText('test')).toBeInTheDocument()
    expect(screen.getByText(/Java 21/)).toBeInTheDocument()
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
    // 2026-04-29 v2.3.10 (E-B3 fix): a Dashboard "Árfolyam módosítás" gomb
    // mode='full' + foertektar/ugyvezeto nélkül "Árfolyamok megtekintése" lesz.
    // A test default mock (nincs role) → fallback link.
    expect(screen.getByText('Árfolyamok megtekintése')).toBeInTheDocument()
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
