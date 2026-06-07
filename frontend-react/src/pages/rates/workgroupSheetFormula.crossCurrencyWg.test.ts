import { describe, it, expect } from 'vitest'
import {
  evaluateWorkgroupFormula,
  extractWorkgroupDependencies,
  isFormula,
  replaceFormulaCurrency,
  type WorkgroupFormulaContext,
} from './workgroupSheetFormula'

/**
 * FK02-E (FR-4): a `!<oszlop><KÓD>` kereszt-valuta hivatkozás kiterjesztése a munkacsoport
 * oszlopaira (J–S). Pl. `!MEUR` = az AKTUÁLIS csoport EUR sorának M (eladás) oszlopa.
 * Ezt használja az EUA-sor alapértelmezett eladási képlete (EUA M = EUR M).
 */
function ctx(over: Partial<WorkgroupFormulaContext> = {}): WorkgroupFormulaContext {
  return {
    sheet0Self: { A: 400 },
    sheet0ByCurrency: new Map([['EUR', { F: 415 }]]),
    workgroupSelf: { J: 400, L: 388, M: 412 },
    workgroupsByNumber: new Map(),
    workgroupByCurrency: new Map([
      ['EUR', { J: 405, L: 400, M: 410 }],
      ['USD', { L: 360, M: 372 }],
    ]),
    ...over,
  }
}

describe('FK02-E !<J–S oszlop><KÓD> kereszt-valuta (azonos csoport)', () => {
  it('!MEUR = az aktuális csoport EUR sorának M oszlopa', () => {
    expect(evaluateWorkgroupFormula('!MEUR', ctx())).toEqual({ value: 410 })
  })

  it('!LUSD = USD L oszlopa (vétel), művelettel is', () => {
    expect(evaluateWorkgroupFormula('!LUSD', ctx())).toEqual({ value: 360 })
    expect(evaluateWorkgroupFormula('!MEUR-1', ctx())).toEqual({ value: 409 })
  })

  it('a 0-s lap (A–I) kereszt-hivatkozás VÁLTOZATLANUL működik', () => {
    expect(evaluateWorkgroupFormula('!FEUR', ctx())).toEqual({ value: 415 })
  })

  it('ismeretlen valuta a csoportban → hiba', () => {
    const r = evaluateWorkgroupFormula('!MGBP', ctx())
    expect('error' in r && r.error).toContain('Ismeretlen valuta')
  })

  it('hiányzó workgroupByCurrency kontextus → hiba (nem összeomlás)', () => {
    const r = evaluateWorkgroupFormula('!MEUR', ctx({ workgroupByCurrency: undefined }))
    expect('error' in r).toBe(true)
  })

  it('!KEUR (ISO kód oszlop) érvénytelen', () => {
    const r = evaluateWorkgroupFormula('!KEUR', ctx())
    expect('error' in r).toBe(true)
  })

  it('isFormula felismeri', () => {
    expect(isFormula('!MEUR')).toBe(true)
  })

  it('extractWorkgroupDependencies wgCrossCurrency ref-et ad', () => {
    expect(extractWorkgroupDependencies('!MEUR')).toEqual([
      { kind: 'wgCrossCurrency', currency: 'EUR', col: 'M' },
    ])
  })

  describe('replaceFormulaCurrency (lehúzás) — FR-4 TBD-4 fix hivatkozás', () => {
    it('EUA-sor !MEUR-je NEM cserélődik más sorra húzva (EUR ≠ EUA)', () => {
      // Az EUA sorból BAM-ra lehúzva a kód EUR marad (a forrás-valuta EUA ≠ EUR).
      expect(replaceFormulaCurrency('!MEUR', 'EUA', 'BAM')).toBe('!MEUR')
    })
    it('!MEUR az EUR-sorból USD-re húzva relatívan cserélődik', () => {
      expect(replaceFormulaCurrency('!MEUR', 'EUR', 'USD')).toBe('!MUSD')
    })
  })
})
