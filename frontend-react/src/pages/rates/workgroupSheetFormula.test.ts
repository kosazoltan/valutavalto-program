import { describe, it, expect } from 'vitest'
import {
  evaluateWorkgroupFormula,
  extractWorkgroupDependencies,
  isFormula,
  parseNumber,
  type WorkgroupFormulaContext,
} from './workgroupSheetFormula'

function ctx(over: Partial<WorkgroupFormulaContext> = {}): WorkgroupFormulaContext {
  return {
    sheet0Self: { A: 400, F: 410, C: 0.97 },
    sheet0ByCurrency: new Map([
      ['EUR', { F: 415, E: 405 }],
      ['USD', { F: 380 }],
    ]),
    workgroupSelf: { J: 400, L: 388, M: 412 },
    workgroupsByNumber: new Map([
      [1, { L: 390, M: 410 }],
      [3, { L: 385 }],
    ]),
    ...over,
  }
}

describe('workgroupSheetFormula (FK-03)', () => {
  describe('isFormula / parseNumber', () => {
    it('tiszta szám NEM képlet (magyar vessző is)', () => {
      expect(isFormula('0,97')).toBe(false)
      expect(isFormula('-5')).toBe(false)
      expect(isFormula('100')).toBe(false)
      expect(isFormula('')).toBe(false)
    })
    it('hivatkozás/művelet KÉPLET', () => {
      expect(isFormula('J*0,97')).toBe(true)
      expect(isFormula('!FEUR')).toBe(true)
      expect(isFormula('#01L')).toBe(true)
    })
    it('parseNumber magyar vesszővel', () => {
      expect(parseNumber('0,97')).toBe(0.97)
      expect(parseNumber('abc')).toBeNull()
    })
  })

  describe('self hivatkozások', () => {
    it('A–I a 0-s lap aktuális valuta sora', () => {
      expect(evaluateWorkgroupFormula('A', ctx())).toEqual({ value: 400 })
      expect(evaluateWorkgroupFormula('F*C', ctx())).toEqual({ value: 410 * 0.97 })
    })
    it('J–S az aktuális munkacsoport', () => {
      expect(evaluateWorkgroupFormula('J', ctx())).toEqual({ value: 400 })
      expect(evaluateWorkgroupFormula('L', ctx())).toEqual({ value: 388 })
    })
    it('K (ISO kód) nem hivatkozható', () => {
      const r = evaluateWorkgroupFormula('K', ctx())
      expect('error' in r && r.error).toContain('K oszlop')
    })
    it('hiányzó self érték → hiba', () => {
      const r = evaluateWorkgroupFormula('B', ctx())
      expect('error' in r).toBe(true)
    })
  })

  describe('kereszt-valuta !<oszlop><KÓD>', () => {
    it('!FEUR = EUR F oszlopa a 0-s lapon', () => {
      expect(evaluateWorkgroupFormula('!FEUR', ctx())).toEqual({ value: 415 })
    })
    it('műveletben', () => {
      expect(evaluateWorkgroupFormula('!FEUR-!FUSD', ctx())).toEqual({ value: 415 - 380 })
    })
    it('ismeretlen valuta → hiba', () => {
      const r = evaluateWorkgroupFormula('!FGBP', ctx())
      expect('error' in r && r.error).toContain('GBP')
    })
  })

  describe('kereszt-munkacsoport #NN<oszlop>', () => {
    it('#01L = a 01-es csoport L oszlopa', () => {
      expect(evaluateWorkgroupFormula('#01L', ctx())).toEqual({ value: 390 })
    })
    it('#03L + saját J', () => {
      expect(evaluateWorkgroupFormula('#03L+J', ctx())).toEqual({ value: 385 + 400 })
    })
    it('ismeretlen csoport → hiba', () => {
      const r = evaluateWorkgroupFormula('#09L', ctx())
      expect('error' in r && r.error).toContain('#09')
    })
    it('egyjegyű csoportszám → hiba (kétjegyű kell)', () => {
      const r = evaluateWorkgroupFormula('#1L', ctx())
      expect('error' in r).toBe(true)
    })
    it('háromjegyű csoportszám → érthető "kétjegyű" hiba', () => {
      const r = evaluateWorkgroupFormula('#012L', ctx())
      expect('error' in r && r.error).toContain('kétjegyű')
    })
    it('kereszt-munkacsoport műveletben (záró-token nélkül helyes)', () => {
      expect(evaluateWorkgroupFormula('#01L*2', ctx())).toEqual({ value: 390 * 2 })
    })
    it('K oszlopra hivatkozás → hiba', () => {
      const r = evaluateWorkgroupFormula('#01K', ctx())
      expect('error' in r && r.error).toContain('K oszlop')
    })
  })

  describe('műveletek és zárójel', () => {
    it('precedencia + zárójel', () => {
      expect(evaluateWorkgroupFormula('(J+L)*2', ctx())).toEqual({ value: (400 + 388) * 2 })
      expect(evaluateWorkgroupFormula('J+L*2', ctx())).toEqual({ value: 400 + 388 * 2 })
    })
    it('nullával osztás → hiba', () => {
      const r = evaluateWorkgroupFormula('J/0', ctx())
      expect('error' in r && r.error).toContain('Nullával')
    })
    it('unáris mínusz', () => {
      expect(evaluateWorkgroupFormula('-J', ctx())).toEqual({ value: -400 })
    })
    it('vezető-tizedes operandus (magyar `,97`)', () => {
      expect(evaluateWorkgroupFormula('J*,97', ctx())).toEqual({ value: 400 * 0.97 })
      expect(evaluateWorkgroupFormula('F*.5', ctx())).toEqual({ value: 410 * 0.5 })
    })
    it('hiányzó záró zárójel → hiba', () => {
      expect('error' in evaluateWorkgroupFormula('(J+L', ctx())).toBe(true)
    })
    it('többjegyű azonosító (valuta ! nélkül) → hiba', () => {
      expect('error' in evaluateWorkgroupFormula('EUR', ctx())).toBe(true)
    })
    it('D oszlop (ISO-kód címke) self-hivatkozása → elutasítva, nem numerikus (Codex P2)', () => {
      const r = evaluateWorkgroupFormula('D', ctx())
      expect('error' in r).toBe(true)
      if ('error' in r) expect(r.error).toContain('Érvénytelen oszlop-hivatkozás')
    })
    it('D oszlop kereszt-hivatkozása (!DEUR) → elutasítva (Codex P2)', () => {
      const r = evaluateWorkgroupFormula('!DEUR', ctx())
      expect('error' in r).toBe(true)
      if ('error' in r) expect(r.error).toContain('Érvénytelen kereszt-hivatkozás')
    })
  })

  describe('extractWorkgroupDependencies', () => {
    it('mind a 4 hivatkozás-típust kigyűjti', () => {
      const refs = extractWorkgroupDependencies('A + J + !FEUR + #01L')
      expect(refs).toEqual([
        { kind: 'sheet0Self', col: 'A' },
        { kind: 'wgSelf', col: 'J' },
        { kind: 'sheet0Cross', currency: 'EUR', col: 'F' },
        { kind: 'wgCross', group: 1, col: 'L' },
      ])
    })
    it('hibás képletre üres tömb', () => {
      expect(extractWorkgroupDependencies('@@@')).toEqual([])
    })
    it('a D oszlop nem kerül a függőségek közé (érvénytelen → üres)', () => {
      expect(extractWorkgroupDependencies('D')).toEqual([])
    })
  })
})
