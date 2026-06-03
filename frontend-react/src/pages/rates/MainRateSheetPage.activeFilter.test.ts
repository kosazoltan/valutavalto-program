import { describe, it, expect, beforeEach } from 'vitest'
import { loadFromStorage, loadInactiveCurrencyCodes } from './MainRateSheetPage'

/**
 * FR-HL-04/05 (b3-arfolyam-karbantarto-hibalista): a 0-ás lap (MainRateSheetPage) KIZÁRÓLAG az aktív
 * valutákat mutathatja. Az inaktív kódokat localStorage-ból (INACTIVE_STORAGE_KEY) szűrjük — az
 * inaktivált valuta a hard-coded DEFAULT_CURRENCIES-ből is eltűnik, reaktiváláskor visszajön.
 */
const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'
const INACTIVE_KEY = 'arfolyamkeszito.mainSheet.inactiveCurrencies.v1'

describe('FR-HL-04/05 — 0-ás lap aktív-valuta szűrés', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('loadInactiveCurrencyCodes: üres/hibás → üres Set, érvényes tömb → Set', () => {
    expect(loadInactiveCurrencyCodes().size).toBe(0)
    localStorage.setItem(INACTIVE_KEY, '{nem json')
    expect(loadInactiveCurrencyCodes().size).toBe(0)
    localStorage.setItem(INACTIVE_KEY, JSON.stringify(['RUB', 'TRY']))
    expect(loadInactiveCurrencyCodes()).toEqual(new Set(['RUB', 'TRY']))
  })

  it('üres storage + nincs inaktív → a teljes default lista (EUR..NZD) megjelenik', () => {
    const rows = loadFromStorage()
    const codes = rows.map(r => r.currency)
    expect(codes).toContain('EUR')
    expect(codes).toContain('RUB')
    expect(codes.length).toBeGreaterThan(15)
  })

  it('inaktív valuta NEM jelenik meg (a hard-coded DEFAULT_CURRENCIES-ből sem)', () => {
    localStorage.setItem(INACTIVE_KEY, JSON.stringify(['RUB', 'TRY']))
    const codes = loadFromStorage().map(r => r.currency)
    expect(codes).not.toContain('RUB')
    expect(codes).not.toContain('TRY')
    expect(codes).toContain('EUR') // aktívak megmaradnak
  })

  it('tárolt sorból is kiszűri az inaktívat, és nem re-seedeli a defaultból', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([
      { currency: 'EUR', settlement: 400 },
      { currency: 'RUB', settlement: 3 },
    ]))
    localStorage.setItem(INACTIVE_KEY, JSON.stringify(['RUB']))
    const codes = loadFromStorage().map(r => r.currency)
    expect(codes).not.toContain('RUB')
    expect(codes).toContain('EUR')
  })

  it('reaktiválás (üres inaktív-halmaz) → a valuta visszakerül a default listából', () => {
    localStorage.setItem(INACTIVE_KEY, JSON.stringify([]))
    expect(loadFromStorage().map(r => r.currency)).toContain('RUB')
  })

  it('a véglegesen törölt valuták (DKK/NOK/...) továbbra is kiszűrve maradnak', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([
      { currency: 'EUR', settlement: 400 },
      { currency: 'DKK', settlement: 50 },
    ]))
    const codes = loadFromStorage().map(r => r.currency)
    expect(codes).not.toContain('DKK')
  })
})
