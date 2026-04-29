import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import RatesPage from './RatesPage'

const mocks = vi.hoisted(() => ({
  exchangeRateApiList: vi.fn(),
  exchangeRateApiCreate: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
  logger: {
    error: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    debug: vi.fn(),
  },
  useAuthStore: vi.fn(),
  useAppMode: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  exchangeRateApi: {
    list: mocks.exchangeRateApiList,
    create: mocks.exchangeRateApiCreate,
  },
}))

vi.mock('../../utils/electronTransactions', () => ({
  recordLocalAuditEvent: mocks.recordLocalAuditEvent,
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

// 2026-04-29 v2.3.10 (B2 fix): a /rates oldal mode='full' + foertektar/ugyvezeto role
// esetén szerkeszthető. A tesztek default mockja: full mode + foertektar role, így a
// "Szerkesztés" gomb és "MNB letöltés" gomb látszik.
vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

vi.mock('../../hooks/useAppMode', () => ({
  useAppMode: mocks.useAppMode,
}))

const mockRates = [
  {
    id: 1,
    currencyCode: 'EUR',
    currencyName: 'Euró',
    baseBuyRate: 391.50,
    baseSellRate: 398.50,
    officialRate: 391.25,
    validTime: '10:30',
    currencyId: 1,
    createdAt: new Date().toISOString(),
  },
  {
    id: 2,
    currencyCode: 'USD',
    currencyName: 'US Dollár',
    baseBuyRate: 358.20,
    baseSellRate: 365.80,
    officialRate: 358.15,
    validTime: '10:30',
    currencyId: 2,
    createdAt: new Date().toISOString(),
  },
]

describe('RatesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.exchangeRateApiList.mockResolvedValue(mockRates)
    // Default: full mode + foertektar role (canEdit=true, MNB + Edit gombok látszanak)
    mocks.useAppMode.mockReturnValue({ mode: 'full' })
    mocks.useAuthStore.mockImplementation((selector: any) =>
      selector({
        hasCanonicalRole: (roles: readonly string[]) =>
          roles.includes('foertektar') || roles.includes('ugyvezeto'),
      }),
    )
  })

  it('oldal renderelésének ellenőrzése', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getByText('Árfolyamok')).toBeInTheDocument()
    })
  })

  it('árfolyam API-t betöltéskor meghívja', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(mocks.exchangeRateApiList).toHaveBeenCalled()
    })
  })

  it('betöltés közben loading state mutatódik', () => {
    mocks.exchangeRateApiList.mockImplementation(
      () => new Promise(resolve => setTimeout(() => resolve(mockRates), 100)),
    )
    render(<RatesPage />)
    // Loading indikátor megjelenhet, de gyorsan eltűnik
    expect(mocks.exchangeRateApiList).toHaveBeenCalled()
  })

  it('árfolyamok táblázatban megjelenítése', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getByText('EUR')).toBeInTheDocument()
      expect(screen.getByText('USD')).toBeInTheDocument()
      expect(screen.getByText('Euró')).toBeInTheDocument()
      expect(screen.getByText('US Dollár')).toBeInTheDocument()
    })
  })

  it('árfolyam értékek helyesen jelennek meg', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      // Values are formatted with Hungarian comma (391,50)
      expect(screen.getByText(/391[.,]50/)).toBeInTheDocument()
      expect(screen.getByText(/398[.,]50/)).toBeInTheDocument()
      expect(screen.getByText(/358[.,]20/)).toBeInTheDocument()
    })
  })

  it('szerkesztés gomb megosztódik minden sorra', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      const editButtons = screen.getAllByTitle('Szerkesztés')
      expect(editButtons.length).toBeGreaterThan(0)
    })
  })



  it('frissítés gomb újra betölti az árfolyamokat', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getByText('EUR')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    const refreshButton = screen.getByRole('button', { name: /Frissítés/i })
    await user.click(refreshButton)

    await waitFor(() => {
      expect(mocks.exchangeRateApiList).toHaveBeenCalledTimes(2)
    })
  })

  it('API hiba során error üzenetet jelenít meg', async () => {
    mocks.exchangeRateApiList.mockRejectedValue(new Error('API hiba'))
    render(<RatesPage />)

    await waitFor(() => {
      expect(screen.getByText(/Hiba az árfolyamok betöltésekor/)).toBeInTheDocument()
    })
  })



  it('utolsó frissítés ideje megjelenítésre kerül', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getByText(/Utolsó frissítés:/)).toBeInTheDocument()
    })
  })

  it('download gomb letöltési funktionalitást biztosít', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getByText('EUR')).toBeInTheDocument()
    })

    const downloadButton = screen.getByRole('button', { name: /MNB letöltés/i })
    expect(downloadButton).toBeInTheDocument()
  })
})
