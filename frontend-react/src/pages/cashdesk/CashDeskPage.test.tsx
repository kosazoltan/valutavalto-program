import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CashDeskPage from './CashDeskPage'

const mocks = vi.hoisted(() => ({
  balanceList: vi.fn(),
  getSummary: vi.fn(),
  getByCurrencyId: vi.fn(),
  getByCurrencyCode: vi.fn(),
  adjust: vi.fn(),
  getCurrentSession: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../services/api/index', () => ({
  cashBalanceApi: {
    list: mocks.balanceList,
    getSummary: mocks.getSummary,
    getByCurrencyId: mocks.getByCurrencyId,
    getByCurrencyCode: mocks.getByCurrencyCode,
    adjust: mocks.adjust,
  },
  dailySessionApi: {
    getCurrent: mocks.getCurrentSession,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
    warning: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

function renderPage() {
  render(
    <MemoryRouter>
      <CashDeskPage />
    </MemoryRouter>,
  )
}

describe('CashDeskPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.balanceList.mockResolvedValue([
      {
        id: 1,
        branchId: 'branch-1',
        branchName: 'Szeged',
        currencyId: 1,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        currentBalance: 1200,
        openingBalance: 1000,
        dailyChange: 200,
        minBalance: 100,
        maxBalance: 5000,
        createdAt: '2026-06-19T08:00:00',
      },
      {
        id: 2,
        branchId: 'branch-1',
        branchName: 'Szeged',
        currencyId: 2,
        currencyCode: 'HUF',
        currencyName: 'Magyar forint',
        currentBalance: 250000,
        openingBalance: 200000,
        dailyChange: 50000,
        minBalance: 10000,
        maxBalance: 1000000,
        createdAt: '2026-06-19T08:00:00',
      },
    ])
    mocks.getSummary.mockResolvedValue({
      totalCurrencies: 2,
      hufBalance: 250000,
      lowBalanceAlerts: 1,
      highBalanceAlerts: 0,
      balances: [],
    })
    mocks.getCurrentSession.mockResolvedValue({
      status: 'OPEN',
      openedAt: '2026-06-19T08:00:00',
      openedByWorkerName: 'Teszt Elek',
      transactionCount: 3,
      buyTurnoverHuf: 100000,
      sellTurnoverHuf: 90000,
      handlingFeeTotal: 2500,
    })
    const detail = {
      id: 1,
      branchId: 'branch-1',
      branchName: 'Szeged',
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      currentBalance: 1200,
      openingBalance: 1000,
      dailyChange: 200,
      minBalance: 100,
      maxBalance: 5000,
      createdAt: '2026-06-19T08:00:00',
    }
    mocks.getByCurrencyId.mockResolvedValue(detail)
    mocks.getByCurrencyCode.mockResolvedValue(detail)
  })

  it('megjeleníti a branch summary választ és részletező hívást indít valuta ID/kód alapján', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitFor(() => expect(mocks.getSummary).toHaveBeenCalled())
    expect(await screen.findByText('250 000 common.ft')).toBeInTheDocument()
    expect(screen.getByText('Alacsony jelzés')).toBeInTheDocument()
    expect(screen.getByText('1')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'EUR részletek' }))

    await waitFor(() => {
      expect(mocks.getByCurrencyId).toHaveBeenCalledWith(1)
      expect(mocks.getByCurrencyCode).toHaveBeenCalledWith('EUR')
    })
    expect(await screen.findByText('EUR pénzkészlet részletek')).toBeInTheDocument()
    expect(screen.getByText('ID és kód egyezik')).toBeInTheDocument()
  })
})
