import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RateHistoryPage from './RateHistoryPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  getByCurrencyCode: vi.fn(),
  getBuyRateForAmount: vi.fn(),
  getSellRateForAmount: vi.fn(),
  getHistoryByCode: vi.fn(),
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

vi.mock('../../services/api/exchange-rates', () => ({
  exchangeRateApi: {
    getByCurrencyCode: mocks.getByCurrencyCode,
    getBuyRateForAmount: mocks.getBuyRateForAmount,
    getSellRateForAmount: mocks.getSellRateForAmount,
    getHistoryByCode: mocks.getHistoryByCode,
  },
}))

describe('RateHistoryPage backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getByCurrencyCode.mockResolvedValue({
      id: 10,
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      validDate: '2026-06-18',
      validTime: '09:00:00',
      baseBuyRate: 391.5,
      baseSellRate: 398.5,
      active: true,
      createdAt: '2026-06-18T09:00:00',
    })
    mocks.getBuyRateForAmount.mockResolvedValue(392.1)
    mocks.getSellRateForAmount.mockResolvedValue(399.2)
    mocks.getHistoryByCode.mockResolvedValue([
      {
        id: 11,
        currencyId: 1,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        validDate: '2026-06-17',
        validTime: '09:00:00',
        baseBuyRate: 390.5,
        baseSellRate: 397.5,
        active: true,
        createdAt: '2026-06-17T09:00:00',
      },
    ])
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

  it('canonical exchange-rates read endpointokat használ kód, összegárfolyam és history lekérdezéshez', async () => {
    const user = userEvent.setup()
    render(<RateHistoryPage />)

    await screen.findAllByText('EUR')
    fireEvent.change(screen.getByLabelText('Árfolyam ellenőrzés valuta'), {
      target: { value: 'eur' },
    })
    fireEvent.change(screen.getByLabelText('Árfolyam ellenőrzés HUF összeg'), {
      target: { value: '100000' },
    })

    await user.click(screen.getByRole('button', { name: 'Árfolyam ellenőrzés' }))

    await waitFor(() => {
      expect(mocks.getByCurrencyCode).toHaveBeenCalledWith('EUR')
      expect(mocks.getBuyRateForAmount).toHaveBeenCalledWith(1, 100000)
      expect(mocks.getSellRateForAmount).toHaveBeenCalledWith(1, 100000)
      expect(mocks.getHistoryByCode).toHaveBeenCalledWith(
        'EUR',
        expect.any(String),
        expect.any(String),
      )
    })
    expect(screen.getByText('392.1')).toBeInTheDocument()
    expect(screen.getByText('399.2')).toBeInTheDocument()
    expect(screen.getByText(/Előzmény találatok/)).toHaveTextContent('Előzmény találatok: 1')
  })
})
