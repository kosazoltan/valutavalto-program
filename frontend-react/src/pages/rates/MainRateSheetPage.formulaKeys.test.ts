import { describe, it, expect, beforeEach } from 'vitest'
import { migrateLegacyFormulaKeys, loadFormulasFromStorage } from './MainRateSheetPage'
import { FORMULA_STORAGE_KEY } from './mainSheetFormula'

/**
 * FK04 self-review P0: a Főlap képlet-kulcsai rowIdx-ről valutakódra váltottak — a
 * katalógus-vezérelt (változó tagságú/sorrendű) sorlistában a sorindex instabil, és a
 * mentett képletek némán rossz valutára kerülhettek volna. A legacy kulcsokat a
 * row-cache (a felhasználó által utoljára látott sorrend) alapján migráljuk.
 */
const cachedRows = [
  { currency: 'EUR' },
  { currency: 'USD' },
  { currency: 'GBP' },
]

describe('FK04 — migrateLegacyFormulaKeys', () => {
  it('legacy rowIdx-kulcsot a cache-sorrend szerinti valutakódra fordít', () => {
    const migrated = migrateLegacyFormulaKeys(
      { '0.settlement': 'B+C', '2.otp': 'A*0,97' },
      cachedRows,
    )
    expect(migrated).toEqual({
      'EUR.settlement': 'B+C',
      'GBP.otp': 'A*0,97',
    })
  })

  it('feloldhatatlan indexű képletet eldob (nem találgat)', () => {
    const migrated = migrateLegacyFormulaKeys({ '7.settlement': 'B+C' }, cachedRows)
    expect(migrated).toEqual({})
  })

  it('már valutakód-kulcsú bejegyzést változatlanul átenged (vegyes map)', () => {
    const migrated = migrateLegacyFormulaKeys(
      { 'EUR.settlement': 'B+C', '1.helper': 'A-1' },
      cachedRows,
    )
    expect(migrated).toEqual({
      'EUR.settlement': 'B+C',
      'USD.helper': 'A-1',
    })
  })
})

describe('FK04 — loadFormulasFromStorage (migrációval)', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('üres / hibás storage → üres map', () => {
    expect(loadFormulasFromStorage(cachedRows)).toEqual({})
    localStorage.setItem(FORMULA_STORAGE_KEY, '{törött')
    expect(loadFormulasFromStorage(cachedRows)).toEqual({})
  })

  it('legacy kulcsokat migrálja ÉS visszaírja a storage-ba (tartós migráció)', () => {
    localStorage.setItem(FORMULA_STORAGE_KEY, JSON.stringify({ '1.settlement': 'C*2' }))
    const loaded = loadFormulasFromStorage(cachedRows)
    expect(loaded).toEqual({ 'USD.settlement': 'C*2' })
    expect(JSON.parse(localStorage.getItem(FORMULA_STORAGE_KEY)!)).toEqual({ 'USD.settlement': 'C*2' })
  })

  it('már migrált (valutakód-kulcsú) map változatlanul jön vissza', () => {
    const modern = { 'EUR.settlement': 'B+C' }
    localStorage.setItem(FORMULA_STORAGE_KEY, JSON.stringify(modern))
    expect(loadFormulasFromStorage(cachedRows)).toEqual(modern)
  })
})
