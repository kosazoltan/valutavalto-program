import { describe, it, expect, vi, afterEach } from 'vitest'
import { localIsoDate, formatHuDate } from './dateFormat'

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

  it('defaults to now when no argument is given (determinisztikus, fake timer)', () => {
    // Fix rendszeridő → nincs éjfél-átlépés-flakeyness a két hívás közt.
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 4, 20, 12, 0, 0))
    expect(localIsoDate()).toBe('2026-05-20')
    expect(localIsoDate()).toBe(localIsoDate(new Date()))
  })
})

afterEach(() => {
  vi.useRealTimers()
})

describe('formatHuDate', () => {
  it('ISO dátumot pontozott magyar formába alakít', () => {
    expect(formatHuDate('2026-05-22')).toBe('2026.05.22.')
  })

  // A-6 (pótlás d5753273): üres/rossz bemenet → '' (sosem undefined-es szöveg)
  it('üres stringre üres stringet ad', () => {
    expect(formatHuDate('')).toBe('')
  })

  it('csak whitespace-re üres stringet ad', () => {
    expect(formatHuDate('   ')).toBe('')
  })

  it('nem-ISO bemenetre üres stringet ad', () => {
    expect(formatHuDate('nem-datum')).toBe('')
  })

  it('nem nulla-padded rövid formát nem fogad el', () => {
    expect(formatHuDate('2026-5-2')).toBe('')
  })
})
