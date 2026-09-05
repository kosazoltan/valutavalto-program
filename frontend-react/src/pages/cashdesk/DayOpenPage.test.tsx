import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DayOpenPage from './DayOpenPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  logout: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  dailySessionIsOpen: vi.fn(),
  dailySessionGetReversalCount: vi.fn(),
  cashBalanceList: vi.fn(),
  sessionValidateOpen: vi.fn(),
  sessionOpen: vi.fn(),
  sessionGetOpeningBalance: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

vi.mock('react-router-dom', () => ({
  useNavigate: () => mocks.navigate,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      worker: {
        id: 77,
        branchId: '11111111-1111-1111-1111-111111111111',
        fullName: 'Teszt Pénztáros',
      },
      logout: mocks.logout,
    }),
}))

vi.mock('../../services/api/index', () => ({
  dailySessionApi: {
    isOpen: mocks.dailySessionIsOpen,
    getReversalCount: mocks.dailySessionGetReversalCount,
  },
  cashBalanceApi: {
    list: mocks.cashBalanceList,
  },
  sessionOpenApi: {
    validateOpen: mocks.sessionValidateOpen,
    open: mocks.sessionOpen,
    getOpeningBalance: mocks.sessionGetOpeningBalance,
  },
  clearPersistedToken: mocks.clearPersistedToken,
}))

describe('DayOpenPage session open backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.dailySessionIsOpen.mockResolvedValue(false)
    mocks.dailySessionGetReversalCount.mockResolvedValue(3)
    mocks.sessionValidateOpen.mockResolvedValue(['Előző napi zárási eltérés nyitva van.'])
    mocks.cashBalanceList.mockResolvedValue([
      {
        id: 1,
        branchId: '11111111-1111-1111-1111-111111111111',
        currencyId: 1,
        currencyCode: 'HUF',
        currencyName: 'Forint',
        currentBalance: 125000,
        openingBalance: 125000,
        dailyChange: 0,
        midRate: 1,
        hufValue: 125000,
        openingHufValue: 125000,
        dailyChangeHuf: 0,
        isLowBalance: false,
        isHighBalance: false,
      },
      {
        id: 2,
        branchId: '11111111-1111-1111-1111-111111111111',
        currencyId: 2,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        currentBalance: 500,
        openingBalance: 500,
        dailyChange: 0,
        midRate: 390,
        hufValue: 195000,
        openingHufValue: 195000,
        dailyChangeHuf: 0,
        isLowBalance: false,
        isHighBalance: false,
      },
    ])
    mocks.sessionOpen.mockResolvedValue({
      sessionId: 42,
      branchId: '11111111-1111-1111-1111-111111111111',
      workerId: 77,
      workerName: 'Teszt Pénztáros',
      sessionDate: '2026-06-19',
      status: 'OPEN',
      warnings: ['Nyitás után ellenőrizd a címletezést.'],
    })
    mocks.sessionGetOpeningBalance.mockResolvedValue({ HUF: 125000, EUR: 500 })
  })

  it('betöltéskor lekéri a session-open validációt és megjeleníti a figyelmeztetést', async () => {
    render(<DayOpenPage />)

    await screen.findByText(/Előző napi zárási eltérés nyitva van\./)

    expect(mocks.dailySessionIsOpen).toHaveBeenCalled()
    expect(mocks.dailySessionGetReversalCount).toHaveBeenCalled()
    expect(mocks.sessionValidateOpen).toHaveBeenCalledWith('11111111-1111-1111-1111-111111111111')
    expect(mocks.cashBalanceList).toHaveBeenCalled()
    expect(screen.getByTestId('daily-reversal-count')).toHaveTextContent('Mai sztornók')
    expect(screen.getByTestId('daily-reversal-count')).toHaveTextContent('3')
  })

  it('napnyitáskor a /sessions/open után lekéri a backend nyitó készletet', async () => {
    const user = userEvent.setup()
    render(<DayOpenPage />)

    await user.click(await screen.findByRole('button', { name: 'Nap megnyitása' }))

    await waitFor(() => {
      expect(mocks.sessionOpen).toHaveBeenCalledWith({
        workerId: 77,
        branchId: '11111111-1111-1111-1111-111111111111',
      })
      expect(mocks.sessionGetOpeningBalance).toHaveBeenCalledWith(42)
      expect(mocks.navigate).toHaveBeenCalledWith('/cashier')
    })
    expect(await screen.findByTestId('session-opening-balances')).toHaveTextContent('HUF')
    expect(screen.getByText(/Nyitás után ellenőrizd a címletezést\./)).toBeInTheDocument()
  })

  // === FKH-051 (Test plan 17): FR-2 link from the past-open-day warning to /closing/retroactive ===

  it('FKH-051 T17: a past-open-day warning renders the retroactive link and clicking it navigates', async () => {
    mocks.sessionValidateOpen.mockResolvedValue([
      '⚠️ Az előző nap nincs lezárva! (Dátum: 2026-09-04)',
    ])
    const user = userEvent.setup()
    render(<DayOpenPage />)

    const link = await screen.findByTestId('session-open-retroactive-link')
    await user.click(link)

    expect(mocks.navigate).toHaveBeenCalledWith('/closing/retroactive')
  })

  it('FKH-051 T17b: with an empty warning list the retroactive link is absent', async () => {
    mocks.sessionValidateOpen.mockResolvedValue([])
    render(<DayOpenPage />)

    await screen.findByTestId('daily-reversal-count')
    expect(screen.queryByTestId('session-open-retroactive-link')).toBeNull()
  })
})
