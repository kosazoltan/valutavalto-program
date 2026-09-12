import { describe, it, expect } from 'vitest'
import { currencyDecimals, displayedAmount, formatCurrencyAmount } from './currencyAmountFormat'

/**
 * FKH-065 FR-5 + NFR-3: per-currency decimal formatting for the closing wizard's
 * "Expected / difference" panel. HUF is a 5 Ft rounded, 0-decimal currency; JPY has
 * no minor unit; every other currency keeps 2 decimals (the DenominationEntryPage
 * convention).
 */
describe('currencyDecimals', () => {
  it('HUF has no decimals', () => {
    expect(currencyDecimals('HUF')).toBe(0)
  })

  it('JPY has no decimals', () => {
    expect(currencyDecimals('JPY')).toBe(0)
  })

  it('is case insensitive', () => {
    expect(currencyDecimals('jpy')).toBe(0)
    expect(currencyDecimals('huf')).toBe(0)
  })

  it('defaults to 2 decimals for other currencies', () => {
    expect(currencyDecimals('EUR')).toBe(2)
    expect(currencyDecimals('USD')).toBe(2)
    expect(currencyDecimals('CHF')).toBe(2)
  })
})

describe('formatCurrencyAmount', () => {
  it('HUF is rounded to 5 Ft (repo invariant, not plain Math.round)', () => {
    // 1233 -> 1235 per HungarianRounding.roundToFive; plain Math.round would give 1233.
    expect(formatCurrencyAmount(1233, 'HUF')).toBe('1235')
    expect(formatCurrencyAmount(1001, 'HUF')).toBe('1000')
    expect(formatCurrencyAmount(1008, 'HUF')).toBe('1010')
  })

  it('HUF keeps the sign of a negative difference after 5 Ft rounding', () => {
    expect(formatCurrencyAmount(-1233, 'HUF')).toBe('-1235')
  })

  it('EUR keeps two decimals', () => {
    expect(formatCurrencyAmount(2460.5, 'EUR')).toBe('2460,50')
  })

  it('JPY is shown without decimals and is NOT 5-rounded', () => {
    // Only HUF carries the 5 Ft rule — a JPY amount must stay exact.
    expect(formatCurrencyAmount(1233, 'JPY')).toBe('1233')
  })

  it('returns an em dash for a missing value', () => {
    expect(formatCurrencyAmount(null, 'HUF')).toBe('—')
    expect(formatCurrencyAmount(undefined, 'EUR')).toBe('—')
  })
})

describe('displayedAmount', () => {
  it('HUF carries the 5 Ft rounding', () => {
    expect(displayedAmount(1233, 'HUF')).toBe(1235)
  })

  it('rounds to the DISPLAYED precision so a shown zero never compares as non-zero', () => {
    // Reviewer P2: a JPY residue renders as "0" (0 decimals) but must also COMPARE as 0,
    // otherwise the match colouring paints a displayed zero red. The backend keeps two
    // decimals, so this input is reachable.
    expect(displayedAmount(0.4, 'JPY')).toBe(0)
    expect(formatCurrencyAmount(0.4, 'JPY')).toBe('0')
  })

  it('keeps EUR at its own two-decimal precision', () => {
    expect(displayedAmount(0.4, 'EUR')).toBe(0.4)
    expect(displayedAmount(0.004, 'EUR')).toBe(0)
  })
})
