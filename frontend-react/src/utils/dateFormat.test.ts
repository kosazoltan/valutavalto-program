import { describe, it, expect } from 'vitest'
import { localIsoDate } from './dateFormat'

describe('localIsoDate', () => {
  it('formats a local date as YYYY-MM-DD', () => {
    // Lokális konstruktor: 2026. május 20. (hónap 0-indexelt → 4)
    expect(localIsoDate(new Date(2026, 4, 20))).toBe('2026-05-20')
  })

  it('zero-pads month and day', () => {
    expect(localIsoDate(new Date(2026, 0, 5))).toBe('2026-01-05')
    expect(localIsoDate(new Date(2026, 8, 9))).toBe('2026-09-09')
  })

  it('uses LOCAL calendar day, not UTC (no off-by-one near midnight)', () => {
    // Késő este és kora reggel is ugyanazt a lokális naptári napot kell adja.
    // (A toISOString().slice(0,10) pozitív UTC-offsetű zónában éjfél közelében
    //  átcsúszhatna a szomszédos napra — a localIsoDate ezt elkerüli.)
    expect(localIsoDate(new Date(2026, 4, 20, 23, 30))).toBe('2026-05-20')
    expect(localIsoDate(new Date(2026, 4, 20, 0, 30))).toBe('2026-05-20')
  })

  it('defaults to now when no argument is given', () => {
    const expected = localIsoDate(new Date())
    expect(localIsoDate()).toBe(expected)
    expect(localIsoDate()).toMatch(/^\d{4}-\d{2}-\d{2}$/)
  })
})
