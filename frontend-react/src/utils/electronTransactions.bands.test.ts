import { describe, it, expect } from 'vitest'
import { mapCachedRatesToExchangeRates, type ElectronCachedRate } from './electronTransactions'

/**
 * FK-SÁVOS (2026-06-02): regresszió-védelem — az Electron cache → ExchangeRate mapper adja át a
 * sávos (limit) árfolyam-mezőket, hogy a pénztári képernyő getBandForAmount()-ja Electron offline
 * útvonalon is a valós sávokat lássa (eddig eldobta őket).
 */
describe('mapCachedRatesToExchangeRates — sávos árfolyam mezők', () => {
  it('átadja az official_rate + limit1/2/3 mezőket az ExchangeRate-be', () => {
    const cached: ElectronCachedRate[] = [{
      currency_code: 'EUR',
      buy_rate: 405,
      sell_rate: 411,
      unit: 1,
      updated_at: '2026-06-02T10:00:00',
      official_rate: 408,
      limit1_amount: 100000,
      limit1_buy_rate: 406,
      limit1_sell_rate: 410,
      limit2_amount: 300000,
      limit2_buy_rate: 407,
      limit2_sell_rate: 409,
      limit3_amount: 1000000,
      limit3_buy_rate: 408,
      limit3_sell_rate: 408,
    }]

    const [rate] = mapCachedRatesToExchangeRates(cached, [])

    expect(rate.officialRate).toBe(408)
    expect(rate.limit1Amount).toBe(100000)
    expect(rate.limit1BuyRate).toBe(406)
    expect(rate.limit1SellRate).toBe(410)
    expect(rate.limit2Amount).toBe(300000)
    expect(rate.limit2BuyRate).toBe(407)
    expect(rate.limit2SellRate).toBe(409)
    expect(rate.limit3Amount).toBe(1000000)
    expect(rate.limit3BuyRate).toBe(408)
    expect(rate.limit3SellRate).toBe(408)
  })

  it('null sávmezőket undefined-ra konvertál (nincs sávos árfolyam esetén)', () => {
    const cached: ElectronCachedRate[] = [{
      currency_code: 'USD',
      buy_rate: 360,
      sell_rate: 366,
      unit: 1,
      updated_at: '2026-06-02T10:00:00',
      official_rate: null,
      limit1_amount: null,
      limit1_buy_rate: null,
      limit1_sell_rate: null,
    }]

    const [rate] = mapCachedRatesToExchangeRates(cached, [])

    expect(rate.officialRate).toBeUndefined()
    expect(rate.limit1Amount).toBeUndefined()
    expect(rate.baseBuyRate).toBe(360)
    expect(rate.baseSellRate).toBe(366)
  })
})
