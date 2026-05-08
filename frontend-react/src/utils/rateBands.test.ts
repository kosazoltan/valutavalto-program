import { describe, it, expect } from 'vitest'
import { getBandForAmount, isWithinBand, isWithinHardLimit, getHardLimitMessage } from './rateBands'
import type { ExchangeRate } from '../services/api/exchange-rates'

const mockRate = {
  id: 1,
  currencyId: 1,
  currencyCode: 'EUR',
  currencyName: 'Euro',
  baseBuyRate: 400,
  baseSellRate: 410,
  limit1Amount: 100000,
  limit1BuyRate: 402,
  limit1SellRate: 408,
  limit2Amount: 500000,
  limit2BuyRate: 404,
  limit2SellRate: 406,
  limit3Amount: 1000000,
  limit3BuyRate: 405,
  limit3SellRate: 405,
  officialRate: 405,
  active: true,
  validFrom: '2026-01-01',
  validTo: '2026-12-31',
  validDate: '2026-01-01',
  validTime: '00:00:00',
  createdAt: '2026-01-01T00:00:00Z',
} as unknown as ExchangeRate

describe('rateBands', () => {
  describe('getBandForAmount', () => {
    it('returns base rate for small amounts', () => {
      const band = getBandForAmount(mockRate, 'buy', 50000)
      expect(band.tierRate).toBe(400)
      expect(band.tierName).toBe('alap')
    })

    it('returns limit1 for amounts >= limit1Amount', () => {
      const band = getBandForAmount(mockRate, 'buy', 150000)
      expect(band.tierRate).toBe(402)
      expect(band.tierName).toBe('limit1')
    })

    it('returns limit2 for amounts >= limit2Amount', () => {
      const band = getBandForAmount(mockRate, 'buy', 600000)
      expect(band.tierRate).toBe(404)
      expect(band.tierName).toBe('limit2')
    })

    it('returns limit3 for amounts >= limit3Amount', () => {
      const band = getBandForAmount(mockRate, 'buy', 1500000)
      expect(band.tierRate).toBe(405)
      expect(band.tierName).toBe('limit3')
    })

    it('buy mode: minRate=base, maxRate=tierRate', () => {
      const band = getBandForAmount(mockRate, 'buy', 150000)
      expect(band.minRate).toBe(400)
      expect(band.maxRate).toBe(402)
    })

    it('sell mode: minRate=tierRate, maxRate=base', () => {
      const band = getBandForAmount(mockRate, 'sell', 150000)
      expect(band.tierRate).toBe(408)
      expect(band.minRate).toBe(408)
      expect(band.maxRate).toBe(410)
    })
  })

  describe('isWithinBand', () => {
    it('returns true for rate within band', () => {
      expect(isWithinBand(mockRate, 401, 'buy', 150000)).toBe(true)
    })

    it('returns true for rate at band boundary', () => {
      expect(isWithinBand(mockRate, 402, 'buy', 150000)).toBe(true)
      expect(isWithinBand(mockRate, 400, 'buy', 150000)).toBe(true)
    })

    it('returns false for rate above band', () => {
      expect(isWithinBand(mockRate, 403, 'buy', 150000)).toBe(false)
    })

    it('sell: returns false for rate below band', () => {
      expect(isWithinBand(mockRate, 407, 'sell', 150000)).toBe(false)
    })
  })

  describe('isWithinHardLimit', () => {
    it('buy: rate at officialRate is OK', () => {
      expect(isWithinHardLimit(405, 405, 'buy')).toBe(true)
    })

    it('buy: rate above officialRate is NOT OK', () => {
      expect(isWithinHardLimit(406, 405, 'buy')).toBe(false)
    })

    it('sell: rate at officialRate is OK', () => {
      expect(isWithinHardLimit(405, 405, 'sell')).toBe(true)
    })

    it('sell: rate below officialRate is NOT OK', () => {
      expect(isWithinHardLimit(404, 405, 'sell')).toBe(false)
    })

    it('null officialRate always passes', () => {
      expect(isWithinHardLimit(999, null, 'buy')).toBe(true)
      expect(isWithinHardLimit(1, undefined, 'sell')).toBe(true)
    })
  })

  describe('getHardLimitMessage', () => {
    it('buy message mentions ceiling', () => {
      const msg = getHardLimitMessage('buy', 405)
      expect(msg).toContain('405.00')
      expect(msg).toContain('magasabb')
    })

    it('sell message mentions floor', () => {
      const msg = getHardLimitMessage('sell', 405)
      expect(msg).toContain('405.00')
      expect(msg).toContain('alacsonyabb')
    })
  })
})
