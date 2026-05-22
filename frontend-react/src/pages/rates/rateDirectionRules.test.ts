import { describe, it, expect } from 'vitest'
import { validateRateDirection, type RateDirectionRow } from './rateDirectionRules'

const row = (p: Partial<RateDirectionRow>): RateDirectionRow => ({
  currencyCode: 'EUR',
  settlement: 400,
  buyRate: 395,
  sellRate: 405,
  ...p,
})

describe('validateRateDirection (FR-RFM-25)', () => {
  it('helyes irány (vételi ≤ elszámoló ≤ eladási) → nincs sértés', () => {
    expect(validateRateDirection([row({})])).toEqual([])
  })

  it('eladási < elszámoló → SELL_BELOW_SETTLEMENT', () => {
    const v = validateRateDirection([row({ sellRate: 395 })]) // 395 < 400
    expect(v).toHaveLength(1)
    expect(v[0]!.type).toBe('SELL_BELOW_SETTLEMENT')
    expect(v[0]!.currencyCode).toBe('EUR')
  })

  it('vételi > elszámoló → BUY_ABOVE_SETTLEMENT', () => {
    const v = validateRateDirection([row({ buyRate: 405 })]) // 405 > 400
    expect(v).toHaveLength(1)
    expect(v[0]!.type).toBe('BUY_ABOVE_SETTLEMENT')
  })

  it('mindkét irány hibás → két sértés egy sorra', () => {
    const v = validateRateDirection([row({ buyRate: 410, sellRate: 390 })])
    expect(v).toHaveLength(2)
    expect(v.map((x) => x.type).sort()).toEqual(['BUY_ABOVE_SETTLEMENT', 'SELL_BELOW_SETTLEMENT'])
  })

  it('egyenlőség megengedett (eladási == vételi == elszámoló) → nincs sértés', () => {
    expect(validateRateDirection([row({ buyRate: 400, sellRate: 400 })])).toEqual([])
  })

  it('hiányzó/0 elszámoló → nem validál (nincs hamis riasztás)', () => {
    expect(validateRateDirection([row({ settlement: 0 })])).toEqual([])
  })

  it('0 vételi/eladási ráta → az adott irányt kihagyja', () => {
    expect(validateRateDirection([row({ buyRate: 0, sellRate: 0 })])).toEqual([])
  })

  it('több valuta — csak a hibásakat jelzi', () => {
    const v = validateRateDirection([
      row({ currencyCode: 'EUR' }), // ok
      row({ currencyCode: 'USD', settlement: 360, buyRate: 355, sellRate: 350 }), // sell < settlement
      row({ currencyCode: 'GBP' }), // ok
    ])
    expect(v).toHaveLength(1)
    expect(v[0]!.currencyCode).toBe('USD')
  })

  it('üres bemenet → üres eredmény', () => {
    expect(validateRateDirection([])).toEqual([])
  })

  it('apró float-zaj (epsilon alatt) → nincs hamis riasztás', () => {
    // sellRate épp csak elszámoló alatt, de epsilon-on belül
    expect(validateRateDirection([row({ sellRate: 400 - 1e-12, buyRate: 400 + 1e-12 })])).toEqual([])
  })
})
