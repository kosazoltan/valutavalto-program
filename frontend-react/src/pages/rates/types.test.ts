import { describe, it, expect } from 'vitest'
import { fmtRate, parseNum, parseNumStrict } from './types'

/**
 * Codex PR #1767 LOW: a `parseNum` NaN→0 konverziója engedélyezett-nulla irányon „legitim 0"-vá
 * tenné a sérült stringet; a szigorú változat ilyenkor `null`-t ad (explicit hiba a hívónál).
 */
describe('parseNumStrict — sérült / nem-numerikus bemenet', () => {
  it('nem-numerikus string → null (nem 0)', () => {
    expect(parseNumStrict('abc')).toBeNull()
    expect(parseNumStrict('NaN')).toBeNull()
    expect(parseNumStrict('Infinity')).toBeNull()
    // a laza parseNum ugyanezt csendben 0-nak veszi — ezt a szerződést a szigorú változat zárja ki
    expect(parseNum('abc')).toBe(0)
  })

  it('Codex fix-kör LOW: elejéről-értelmezhető, de nem tiszta decimális sztringek → null („0abc”, „0,00oops”, „0x10”)', () => {
    expect(parseNumStrict('0abc')).toBeNull()
    expect(parseNumStrict('0,00oops')).toBeNull()
    expect(parseNumStrict('0x10')).toBeNull()
    // a laza parseNum ezeket 0-nak / 0-nak / 0-nak olvassa — pont ezt zárja ki a szigorú változat
    expect(parseNum('0abc')).toBe(0)
    expect(parseNum('0,00oops')).toBe(0)
    expect(parseNum('0x10')).toBe(0)
  })

  it('Codex fix-kör LOW: több tizedesjel, előjel rossz helyen, tudományos alak, csupasz pont → null', () => {
    expect(parseNumStrict('1,000,5')).toBeNull()
    expect(parseNumStrict('1.2.3')).toBeNull()
    expect(parseNumStrict('5-')).toBeNull()
    expect(parseNumStrict('--5')).toBeNull()
    expect(parseNumStrict('1e3')).toBeNull()
    expect(parseNumStrict('.')).toBeNull()
    expect(parseNumStrict('5.')).toBeNull()
  })

  it('érvényes alakok: előjel, vezető/követő whitespace (trim), tizedespont és -vessző, .5 alak', () => {
    expect(parseNumStrict(' 395 ')).toBe(395)
    expect(parseNumStrict('-0,5')).toBe(-0.5)
    expect(parseNumStrict('+7.87')).toBe(7.87)
    expect(parseNumStrict(',5')).toBe(0.5)
    expect(parseNumStrict('0')).toBe(0)
  })

  it('üres / null / undefined → null', () => {
    expect(parseNumStrict('')).toBeNull()
    expect(parseNumStrict('   ')).toBeNull()
    expect(parseNumStrict(null)).toBeNull()
    expect(parseNumStrict(undefined)).toBeNull()
  })

  it('valódi 0 és magyar tizedesvessző értékek változatlanul számok', () => {
    expect(parseNumStrict('0')).toBe(0)
    expect(parseNumStrict('0,0000')).toBe(0)
    expect(parseNumStrict('7,87')).toBe(7.87)
    expect(parseNumStrict('395')).toBe(395)
  })
})

/**
 * FK13 (FR-5) — `fmtRate` 0-szerződése. Alapesetben (FK10) a 0 üres cellaként jelenik meg;
 * engedélyezett currency-irány kontextusában (`allowZero`) a ténylegesen beírt/számított 0
 * NEM veszhet el visszaíráskor, különben az `L = E` képlet 0-s eredménye egy körrel később
 * „Nincs érték a(z) L oszlopban” hibává válik.
 */
describe('fmtRate — FK13 explicit 0', () => {
  it('FR-5: allowZero kontextusban a 0 formázott nullaként jelenik meg (nem üres string)', () => {
    expect(fmtRate(0, 4, { allowZero: true })).toBe('0,0000')
  })

  it('FR-5: allowZero + tizedes-paraméter: a formázás a decimals szerint történik', () => {
    expect(fmtRate(0, 2, { allowZero: true })).toBe('0,00')
  })

  it('FR-5: az allowZero-val visszaírt 0 parseNum-mal 0-ként olvasható vissza (kör-stabil)', () => {
    expect(parseNum(fmtRate(0, 4, { allowZero: true }))).toBe(0)
  })

  it('FR-5: a valódi üres cella (null / undefined) allowZero mellett is üres marad', () => {
    expect(fmtRate(null, 4, { allowZero: true })).toBe('')
    expect(fmtRate(undefined, 4, { allowZero: true })).toBe('')
  })

  it('FR-12 guard: allowZero nélkül a 0 továbbra is üres cella (FK10 alapviselkedés)', () => {
    expect(fmtRate(0)).toBe('')
    expect(fmtRate(0, 4)).toBe('')
    expect(fmtRate(0, 4, {})).toBe('')
    expect(fmtRate(0, 4, { allowZero: false })).toBe('')
  })

  it('FR-12 guard: pozitív érték formázása változatlan mindkét módban', () => {
    expect(fmtRate(7.87)).toBe('7,8700')
    expect(fmtRate(7.87, 4, { allowZero: true })).toBe('7,8700')
  })
})
