import { describe, it, expect } from 'vitest'
import {
  isFormula,
  parseNumber,
  evaluateFormula,
  extractDependencies,
  type FormulaContext,
} from './mainSheetFormula'

function ctx(self: Record<string, number>, byCurrency: Record<string, Record<string, number>> = {}): FormulaContext {
  return {
    self: self as FormulaContext['self'],
    byCurrency: new Map(Object.entries(byCurrency).map(([k, v]) => [k, v as FormulaContext['self']])),
  }
}

describe('isFormula', () => {
  it('tiszta szám (vessző/pont/előjel) → NEM képlet', () => {
    expect(isFormula('100')).toBe(false)
    expect(isFormula('0,97')).toBe(false)
    expect(isFormula('0.97')).toBe(false)
    expect(isFormula('-5')).toBe(false)
    expect(isFormula('  42  ')).toBe(false)
  })
  it('üres → NEM képlet (auto)', () => {
    expect(isFormula('')).toBe(false)
    expect(isFormula('   ')).toBe(false)
  })
  it('vezető-tizedes (,97 / .97) → NEM képlet, hanem érték (Codex P2 #863)', () => {
    expect(isFormula(',97')).toBe(false)
    expect(isFormula('.97')).toBe(false)
    expect(isFormula('-,5')).toBe(false)
    expect(parseNumber(',97')).toBe(0.97)
    expect(parseNumber('.5')).toBe(0.5)
  })
  it('oszlop-ref / kereszt-ref / művelet → képlet', () => {
    expect(isFormula('C*0,97')).toBe(true)
    expect(isFormula('!FEUR')).toBe(true)
    expect(isFormula('A+B')).toBe(true)
    expect(isFormula('C')).toBe(true)
  })
})

describe('parseNumber', () => {
  it('magyar vessző és pont', () => {
    expect(parseNumber('0,97')).toBe(0.97)
    expect(parseNumber('1.5')).toBe(1.5)
    expect(parseNumber('-3,25')).toBe(-3.25)
  })
  it('érvénytelen → null', () => {
    expect(parseNumber('abc')).toBeNull()
  })
})

describe('evaluateFormula — saját sor oszlop-hivatkozás', () => {
  it('C*0,97 (a spec fő példája)', () => {
    const r = evaluateFormula('C*0,97', ctx({ C: 400 }))
    expect(r).toEqual({ value: 388 })
  })
  it('A+B', () => {
    expect(evaluateFormula('A+B', ctx({ A: 100, B: 25 }))).toEqual({ value: 125 })
  })
  it('hiányzó oszlop-érték → error', () => {
    const r = evaluateFormula('C*2', ctx({ A: 1 }))
    expect('error' in r).toBe(true)
  })
})

describe('evaluateFormula — kereszt-valuta (!FEUR)', () => {
  it('!FEUR → az EUR sor F oszlopa (EUA eladás = EUR eladás)', () => {
    const r = evaluateFormula('!FEUR', ctx({ A: 1 }, { EUR: { F: 415.5 } }))
    expect(r).toEqual({ value: 415.5 })
  })
  it('kereszt-ref műveletben', () => {
    const r = evaluateFormula('!FEUR-1,5', ctx({}, { EUR: { F: 415.5 } }))
    expect(r).toEqual({ value: 414 })
  })
  it('ismeretlen valuta → error', () => {
    const r = evaluateFormula('!FGBP', ctx({}, { EUR: { F: 415 } }))
    expect('error' in r).toBe(true)
  })
})

describe('evaluateFormula — műveletek és zárójel', () => {
  it('prioritás: A+B*C', () => {
    expect(evaluateFormula('A+B*C', ctx({ A: 10, B: 2, C: 3 }))).toEqual({ value: 16 })
  })
  it('zárójel: (A+B)*C', () => {
    expect(evaluateFormula('(A+B)*C', ctx({ A: 10, B: 2, C: 3 }))).toEqual({ value: 36 })
  })
  it('osztás', () => {
    expect(evaluateFormula('A/B', ctx({ A: 100, B: 4 }))).toEqual({ value: 25 })
  })
  it('unáris mínusz', () => {
    expect(evaluateFormula('-C+5', ctx({ C: 3 }))).toEqual({ value: 2 })
  })
  it('nullával osztás → error', () => {
    const r = evaluateFormula('A/B', ctx({ A: 1, B: 0 }))
    expect('error' in r).toBe(true)
  })
})

describe('evaluateFormula — szintaxis-hibák (nem dob)', () => {
  it('hiányzó záró zárójel', () => {
    expect('error' in evaluateFormula('(A+B', ctx({ A: 1, B: 2 }))).toBe(true)
  })
  it('bare multi-betűs azonosító (valuta ! nélkül)', () => {
    expect('error' in evaluateFormula('EUR*2', ctx({}, { EUR: { F: 1 } }))).toBe(true)
  })
  it('nem-érték oszlopbetű (D/G)', () => {
    expect('error' in evaluateFormula('D', ctx({ A: 1 }))).toBe(true)
    expect('error' in evaluateFormula('G*2', ctx({ A: 1 }))).toBe(true)
  })
})

describe('extractDependencies', () => {
  it('saját sor + kereszt-ref', () => {
    const deps = extractDependencies('C*0,97+!FEUR')
    expect(deps).toEqual([
      { col: 'C' },
      { currency: 'EUR', col: 'F' },
    ])
  })
  it('érvénytelen képlet → []', () => {
    expect(extractDependencies('@@@')).toEqual([])
  })
})
