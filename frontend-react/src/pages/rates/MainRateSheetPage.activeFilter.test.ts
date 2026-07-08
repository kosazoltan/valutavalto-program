import { describe, it, expect, beforeEach } from 'vitest'
import {
  loadFromStorage,
  loadInactiveCurrencyCodes,
  buildRowsFromCatalog,
} from './MainRateSheetPage'

/**
 * FK04 (FR-2, FR-3) + FR-HL-04/05: a 0-ás lap (MainRateSheetPage) sorlistájának tagsága és
 * sorrendje a currency-katalógusból (useCurrencyCatalog) jön; a localStorage cache csak a
 * cella-ÉRTÉKEKET adja. Offline (katalógus nélkül) a cache-elt sorok jelennek meg, a törölt +
 * inaktív kódok kiszűrésével.
 */
const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'
const INACTIVE_KEY = 'arfolyamkeszito.mainSheet.inactiveCurrencies.v1'

const cat = (...codes: string[]) => codes.map((code) => ({ code }))

describe('FK04 — buildRowsFromCatalog (katalógus-vezérelt sorlista)', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('loads_currencies_from_hook_not_constant: a tagság + sorrend a katalógusból jön', () => {
    // A fixture USD-keresztalapú példája a CNY (a RUB szintén USD-alapú, lásd
    // a rub_visible_when_active tesztet).
    const rows = buildRowsFromCatalog(cat('EUR', 'CNY', 'EUA', 'TRY'), [])
    expect(rows.map((r) => r.currency)).toEqual(['EUR', 'CNY', 'EUA', 'TRY'])
    // crossBase a CROSS_BASE_MAP-ből (TBD-1): CNY→USD, TRY→EUR, EUA→null
    expect(rows.find((r) => r.currency === 'CNY')?.crossBase).toBe('USD')
    expect(rows.find((r) => r.currency === 'TRY')?.crossBase).toBe('EUR')
    expect(rows.find((r) => r.currency === 'EUA')?.crossBase).toBeNull()
  })

  it('rub_visible_when_active: a RUB (V327 óta ismét forgalmazott) megjelenik, ha a katalógusban van', () => {
    // 2026-06-15: a RUB kikerült a REMOVED_CURRENCIES-ből — aktív katalógus-találat
    // esetén a sor megjelenik, USD-keresztalappal (display_order=14, UAH és EUA közé).
    const rows = buildRowsFromCatalog(cat('EUR', 'RUB'), [])
    expect(rows.map((r) => r.currency)).toEqual(['EUR', 'RUB'])
    expect(rows.find((r) => r.currency === 'RUB')?.crossBase).toBe('USD')
  })

  it('inactive_currency_not_shown: cache-ben lévő, de katalógusból hiányzó valuta sora eltűnik', () => {
    const cached = [
      { currency: 'EUR', settlement: 400 },
      { currency: 'HRK', settlement: 3 }, // véglegesen megszűnt → nincs az aktív katalógusban
    ] as Parameters<typeof buildRowsFromCatalog>[1]
    const rows = buildRowsFromCatalog(cat('EUR', 'TRY'), cached)
    const codes = rows.map((r) => r.currency)
    expect(codes).not.toContain('HRK')
    expect(codes).toEqual(['EUR', 'TRY'])
    // a cache-elt érték megmarad a megmaradó soron
    expect(rows.find((r) => r.currency === 'EUR')?.settlement).toBe(400)
  })

  it('new_currency_shown_in_correct_position: új katalógus-valuta üres sorral, a helyes pozícióban', () => {
    const cached = [
      { currency: 'EUR', settlement: 400 },
      { currency: 'TRY', settlement: 11 },
    ] as Parameters<typeof buildRowsFromCatalog>[1]
    // Az AED a katalógus 2. helyén jön (displayOrder szerint rendezve a hook adja így)
    const rows = buildRowsFromCatalog(cat('EUR', 'AED', 'TRY'), cached)
    expect(rows.map((r) => r.currency)).toEqual(['EUR', 'AED', 'TRY'])
    const aed = rows.find((r) => r.currency === 'AED')
    expect(aed?.settlement).toBe(0) // üres (új) sor
    expect(aed?.crossBase).toBeNull() // térképen kívüli kód → közvetlen árfolyam
  })

  it('a véglegesen törölt valutákat (DKK/NOK/…) a katalógusból is kiszűri (defenzív)', () => {
    const rows = buildRowsFromCatalog(cat('EUR', 'DKK'), [])
    expect(rows.map((r) => r.currency)).toEqual(['EUR'])
  })
})

describe('FR-HL-04/05 — offline cache-betöltés (loadFromStorage)', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('loadInactiveCurrencyCodes: üres/hibás → üres Set, érvényes tömb → Set', () => {
    expect(loadInactiveCurrencyCodes().size).toBe(0)
    localStorage.setItem(INACTIVE_KEY, '{nem json')
    expect(loadInactiveCurrencyCodes().size).toBe(0)
    localStorage.setItem(INACTIVE_KEY, JSON.stringify(['NOK', 'TRY']))
    expect(loadInactiveCurrencyCodes()).toEqual(new Set(['NOK', 'TRY']))
  })

  it('üres storage → üres lista (a tagságot online a katalógus adja, nem konstans)', () => {
    expect(loadFromStorage()).toEqual([])
  })

  it('tárolt sorból kiszűri az inaktívat (offline is érvényesül a Valutakezelő-szűrés)', () => {
    // Tetszőleges, a szerver által INAKTÍVnak jelölt valuta (itt a TRY a példa) offline
    // is kiszűrve marad — a mechanizmus független a véglegesen törölt halmaztól.
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify([
        { currency: 'EUR', settlement: 400 },
        { currency: 'TRY', settlement: 3 },
      ]),
    )
    localStorage.setItem(INACTIVE_KEY, JSON.stringify(['TRY']))
    const codes = loadFromStorage().map((r) => r.currency)
    expect(codes).not.toContain('TRY')
    expect(codes).toContain('EUR')
  })

  it('a véglegesen törölt valuták (DKK/NOK/…) továbbra is kiszűrve maradnak', () => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify([
        { currency: 'EUR', settlement: 400 },
        { currency: 'DKK', settlement: 50 },
      ]),
    )
    const codes = loadFromStorage().map((r) => r.currency)
    expect(codes).not.toContain('DKK')
    expect(codes).toContain('EUR')
  })
})
