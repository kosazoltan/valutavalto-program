import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import LiveCashPositionPage from './LiveCashPositionPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  getDetailedPosition: vi.fn(),
}))

vi.mock('@/services/api/index', () => ({
  api: {
    get: mocks.apiGet,
  },
  cashBalanceApi: {
    getDetailedPosition: mocks.getDetailedPosition,
  },
}))

describe('LiveCashPositionPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockResolvedValue({
      data: {
        branchId: 'branch-1',
        date: '2026-06-18',
        lines: [
          {
            currencyCode: 'HUF',
            currencyName: 'Magyar forint',
            opening: 100000,
            income: 50000,
            expense: 25000,
            closing: 125000,
          },
        ],
        handlingFeeHuf: 2500,
      },
    })
    mocks.getDetailedPosition.mockResolvedValue({
      branchId: 'branch-1',
      timestamp: '2026-06-18T12:00:00',
      items: [],
      totalHufValue: 1234567,
      totalOpeningHufValue: 1200000,
      totalDailyChangeHuf: 34567,
      currencyCount: 4,
      lowBalanceAlerts: 1,
      highBalanceAlerts: 0,
    })
  })

  it('megjeleníti a cash-balances/position HUF-egyenértékes összesítőjét', async () => {
    render(
      <MemoryRouter>
        <LiveCashPositionPage />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/reports/live-cash-position')
      expect(mocks.getDetailedPosition).toHaveBeenCalled()
      expect(screen.getByText('Készlet HUF-egyenérték')).toBeInTheDocument()
    })

    expect(screen.getByText('1 234 567 Ft')).toBeInTheDocument()
    expect(screen.getByText('34 567 Ft')).toBeInTheDocument()
    expect(screen.getByText('Készlet riasztások')).toBeInTheDocument()
    expect(screen.getByText('1')).toBeInTheDocument()
  })
})
