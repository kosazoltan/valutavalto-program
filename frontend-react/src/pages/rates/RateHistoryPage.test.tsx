import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RateHistoryPage from './RateHistoryPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: (...args: unknown[]) => mocks.apiGet(...args),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: (...args: unknown[]) => mocks.loggerError(...args),
  },
}))

describe('RateHistoryPage backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockImplementation((url: string) => {
      if (url === '/rate-history') {
        return Promise.resolve({
          data: [
            {
              id: 1,
              currencyCode: 'EUR',
              buyRate: '391.50',
              sellRate: '398.50',
              effectiveFrom: '2026-06-18T08:00:00',
            },
          ],
        })
      }
      if (url === '/rate-history/at-date') {
        return Promise.resolve({
          data: {
            id: 2,
            currencyCode: 'USD',
            buyRate: '358.20',
            sellRate: '365.80',
            effectiveFrom: '2026-06-18T09:30:00',
          },
        })
      }
      return Promise.resolve({ data: [] })
    })
  })

  it('betölti a történeti listát és az adott időpont árfolyamát a backendből kéri', async () => {
    const user = userEvent.setup()
    render(<RateHistoryPage />)

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/rate-history', {
        params: expect.objectContaining({
          from: expect.any(String),
          to: expect.any(String),
        }),
      })
      expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    })

    fireEvent.change(screen.getByLabelText('Adott időpont valuta'), {
      target: { value: 'usd' },
    })
    fireEvent.change(screen.getByLabelText('Adott időpont'), {
      target: { value: '2026-06-18T09:30' },
    })

    await user.click(screen.getByRole('button', { name: 'Lekérdezés' }))

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/rate-history/at-date', {
        params: {
          currency: 'USD',
          date: '2026-06-18T09:30',
        },
      })
      expect(screen.getByText('358.20')).toBeInTheDocument()
      expect(screen.getByText('365.80')).toBeInTheDocument()
    })
  })
})
