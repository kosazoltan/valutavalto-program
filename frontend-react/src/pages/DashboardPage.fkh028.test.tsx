import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DashboardPage from './DashboardPage'

/**
 * FKH-028 Fázis 6: a Dashboard "Legutóbbi tranzakciók" táblájában minden
 * tranzakció-típus a SAJÁT feliratával jelenik meg. A korábbi bináris ternary
 * (BUY → 'Vétel', minden más → 'Eladás') a Transfer-alapú tételeket tévesen
 * "Eladás"-ként mutatta.
 */

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  rateGetActive: vi.fn(),
}))

vi.mock('../services/api/index', () => ({
  api: { get: mocks.apiGet },
}))

vi.mock('../services/api/exchange-rates', () => ({
  exchangeRateApi: { getActive: mocks.rateGetActive, list: mocks.rateGetActive },
}))

vi.mock('../stores/authStore', () => ({
  useAuthStore: (selector: (s: unknown) => unknown) =>
    selector({
      worker: { id: 1, fullName: 'Teszt Felhasználó', role: 'ADMIN', branchId: 'b1' },
      activeRole: 'ADMIN',
      roles: ['ADMIN'],
      hasCanonicalRole: () => true,
    }),
}))

vi.mock('../hooks/useAppMode', () => ({
  useAppMode: () => ({ mode: 'full' }),
}))

function summaryWith(type: string) {
  return {
    data: {
      todayVolume: 1000000,
      activeBranches: 3,
      openTransactions: 5,
      alertCount: 0,
      currencyVolumes: {},
      recentTransactions: [
        {
          id: 1,
          time: '10:00',
          type,
          currency: 'USD',
          amount: 1000,
          huf: 340000,
          cashier: 'Teszt',
          status: 'COMPLETED',
        },
      ],
      yesterdayComparison: {},
    },
  }
}

describe('DashboardPage — FKH-028 tranzakció-típus feliratok (Fázis 6)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.rateGetActive.mockResolvedValue([])
  })

  it('FKH-028: TRANSFER_OUT tétel "Átadás" felirattal jelenik meg, NEM "Eladás"-ként', async () => {
    mocks.apiGet.mockResolvedValue(summaryWith('TRANSFER_OUT'))

    render(
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Átadás')).toBeInTheDocument()
    expect(screen.queryByText('Eladás')).toBeNull()
  })

  it('FKH-028: TRANSFER_IN tétel "Átvétel" felirattal jelenik meg', async () => {
    mocks.apiGet.mockResolvedValue(summaryWith('TRANSFER_IN'))

    render(
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Átvétel')).toBeInTheDocument()
    expect(screen.queryByText('Eladás')).toBeNull()
  })

  it('Regresszió: BUY → "Vétel", SELL → "Eladás" változatlanul', async () => {
    mocks.apiGet.mockResolvedValue(summaryWith('BUY'))

    render(
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Vétel')).toBeInTheDocument()
  })
})
