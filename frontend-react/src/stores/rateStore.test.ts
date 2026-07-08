import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { act } from '@testing-library/react'

// Mock the api from services/api/index
vi.mock('../services/api/index', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    defaults: { baseURL: '' },
    interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
  },
  persistToken: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

import { useRateStore } from './rateStore'
import { api } from '../services/api/index'
import type { ExchangeRate } from '../services/api/index'

const mockApi = api as unknown as { get: ReturnType<typeof vi.fn> }

const mockEurRate: ExchangeRate = {
  id: 1,
  currencyId: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  validDate: '2024-01-15',
  validTime: '08:00:00',
  baseBuyRate: 375,
  baseSellRate: 390,
  active: true,
  createdAt: '2024-01-15T08:00:00Z',
}

const mockUsdRate: ExchangeRate = {
  id: 2,
  currencyId: 2,
  currencyCode: 'USD',
  currencyName: 'Dollár',
  validDate: '2024-01-15',
  validTime: '08:00:00',
  baseBuyRate: 345,
  baseSellRate: 360,
  active: true,
  createdAt: '2024-01-15T08:00:00Z',
}

describe('rateStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Reset store
    act(() => {
      useRateStore.setState({
        rates: [],
        lastUpdate: null,
        isLoading: false,
        error: null,
        autoRefreshIntervalId: null,
      })
    })
  })

  afterEach(() => {
    // Stop any auto refresh
    useRateStore.getState().stopAutoRefresh()
  })

  describe('fetchRates', () => {
    it('loads rates and sets lastUpdate', async () => {
      mockApi.get.mockResolvedValue({ data: [mockEurRate, mockUsdRate] })

      await act(async () => {
        await useRateStore.getState().fetchRates()
      })

      const state = useRateStore.getState()
      expect(state.rates).toHaveLength(2)
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
      expect(state.lastUpdate).toBeTruthy()
    })

    it('sets isLoading=true during fetch', async () => {
      let resolveFn: (val: unknown) => void
      const promise = new Promise((resolve) => {
        resolveFn = resolve
      })
      mockApi.get.mockReturnValue(promise)

      // Start fetch without awaiting
      act(() => {
        void useRateStore.getState().fetchRates()
      })

      expect(useRateStore.getState().isLoading).toBe(true)

      // Resolve
      await act(async () => {
        resolveFn!({ data: [] })
        await promise
      })
    })

    it('sets error on failure', async () => {
      mockApi.get.mockRejectedValue(new Error('Network error'))

      await act(async () => {
        await useRateStore.getState().fetchRates()
      })

      const state = useRateStore.getState()
      expect(state.error).toBe('Network error')
      expect(state.isLoading).toBe(false)
    })
  })

  describe('getRate', () => {
    it('returns undefined for unknown currency', () => {
      expect(useRateStore.getState().getRate('XYZ')).toBeUndefined()
    })

    it('returns rate for known currency', () => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate] })
      })
      const rate = useRateStore.getState().getRate('EUR')
      expect(rate?.baseBuyRate).toBe(375)
    })
  })

  describe('getBuyRate / getSellRate', () => {
    beforeEach(() => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate] })
      })
    })

    it('getBuyRate returns baseBuyRate', () => {
      expect(useRateStore.getState().getBuyRate('EUR')).toBe(375)
    })

    it('getSellRate returns baseSellRate', () => {
      expect(useRateStore.getState().getSellRate('EUR')).toBe(390)
    })

    it('getBuyRate returns 0 for unknown', () => {
      expect(useRateStore.getState().getBuyRate('XYZ')).toBe(0)
    })

    it('getSellRate returns 0 for unknown', () => {
      expect(useRateStore.getState().getSellRate('XYZ')).toBe(0)
    })
  })

  describe('getEffectiveBuyRate / getEffectiveSellRate', () => {
    it('returns 0 for unknown currency', () => {
      expect(useRateStore.getState().getEffectiveBuyRate('XYZ', 1000)).toBe(0)
      expect(useRateStore.getState().getEffectiveSellRate('XYZ', 1000)).toBe(0)
    })

    it('returns baseBuyRate when no limits defined', () => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate] })
      })
      expect(useRateStore.getState().getEffectiveBuyRate('EUR', 100)).toBe(375)
    })

    it('returns limit1BuyRate when amount >= limit1Amount', () => {
      const rateWithLimits: ExchangeRate = {
        ...mockEurRate,
        limit1Amount: 1000,
        limit1BuyRate: 380,
        limit1SellRate: 395,
      }
      act(() => {
        useRateStore.setState({ rates: [rateWithLimits] })
      })
      expect(useRateStore.getState().getEffectiveBuyRate('EUR', 1000)).toBe(380)
      expect(useRateStore.getState().getEffectiveBuyRate('EUR', 999)).toBe(375)
    })

    it('returns highest applicable tier', () => {
      const rateWithLimits: ExchangeRate = {
        ...mockEurRate,
        limit1Amount: 1000,
        limit1BuyRate: 380,
        limit2Amount: 5000,
        limit2BuyRate: 385,
        limit3Amount: 10000,
        limit3BuyRate: 388,
      }
      act(() => {
        useRateStore.setState({ rates: [rateWithLimits] })
      })
      expect(useRateStore.getState().getEffectiveBuyRate('EUR', 10000)).toBe(388)
      expect(useRateStore.getState().getEffectiveBuyRate('EUR', 5000)).toBe(385)
      expect(useRateStore.getState().getEffectiveBuyRate('EUR', 1000)).toBe(380)
    })
  })

  describe('applyPublishedRates', () => {
    it('does nothing for empty updates', () => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate] })
      })
      act(() => {
        useRateStore.getState().applyPublishedRates([])
      })
      expect(useRateStore.getState().rates).toHaveLength(1)
    })

    it('updates existing rate', () => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate] })
      })
      act(() => {
        useRateStore
          .getState()
          .applyPublishedRates([{ currencyCode: 'EUR', buyRate: 380, sellRate: 395 }])
      })
      const state = useRateStore.getState()
      expect(state.rates[0]!.baseBuyRate).toBe(380)
      expect(state.rates[0]!.baseSellRate).toBe(395)
    })

    it('adds new currency not in current rates', () => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate] })
      })
      act(() => {
        useRateStore
          .getState()
          .applyPublishedRates([{ currencyCode: 'CHF', buyRate: 400, sellRate: 415 }])
      })
      const state = useRateStore.getState()
      expect(state.rates).toHaveLength(2)
      expect(state.rates.find((r) => r.currencyCode === 'CHF')?.baseBuyRate).toBe(400)
    })

    it('skips updates without currencyCode', () => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate] })
      })
      act(() => {
        useRateStore.getState().applyPublishedRates([{ buyRate: 999, sellRate: 999 } as any])
      })
      // EUR unchanged
      expect(useRateStore.getState().getBuyRate('EUR')).toBe(375)
    })

    it('preserves original order', () => {
      act(() => {
        useRateStore.setState({ rates: [mockEurRate, mockUsdRate] })
      })
      act(() => {
        useRateStore
          .getState()
          .applyPublishedRates([{ currencyCode: 'USD', buyRate: 350, sellRate: 365 }])
      })
      const { rates } = useRateStore.getState()
      expect(rates[0]!.currencyCode).toBe('EUR')
      expect(rates[1]!.currencyCode).toBe('USD')
      expect(rates[1]!.baseBuyRate).toBe(350)
    })
  })

  describe('startAutoRefresh / stopAutoRefresh', () => {
    it('stopAutoRefresh clears interval', () => {
      act(() => {
        useRateStore.setState({
          autoRefreshIntervalId: 999 as unknown as ReturnType<typeof setInterval>,
        })
      })
      act(() => {
        useRateStore.getState().stopAutoRefresh()
      })
      expect(useRateStore.getState().autoRefreshIntervalId).toBeNull()
    })
  })
})
