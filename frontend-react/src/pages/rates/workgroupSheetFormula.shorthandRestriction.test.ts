import { describe, it, expect } from 'vitest'
import { evaluateWorkgroupFormula, type WorkgroupFormulaContext } from './workgroupSheetFormula'

/**
 * FK02-D — FR-8: a 0-s lap rövidített hivatkozása (E/F/C) csak a vételi (L) és eladási (M)
 * oszlopban értelmezett. A többi 0-s lap self-ref (A,B,G,H,I) és a !/# hivatkozások mindenhol
 * érvényesek (a meglévő FK-04/C „J=A" funkció nem törhet).
 */
const ctx: WorkgroupFormulaContext = {
  sheet0Self: { A: 100, C: 5, E: 380, F: 390, G: 7 },
  sheet0ByCurrency: new Map([['EUR', { F: 400 }]]),
  workgroupSelf: { L: 381, M: 391 },
  workgroupsByNumber: new Map([[1, { L: 382 }]]),
}

describe('evaluateWorkgroupFormula — FR-8 shorthand L/M-megszorítás', () => {
  it('E/F/C engedélyezve (L/M oszlop) → kiértékelődik', () => {
    expect(evaluateWorkgroupFormula('F', ctx, { allowSheet0Shorthand: true })).toEqual({ value: 390 })
    expect(evaluateWorkgroupFormula('F+1', ctx, { allowSheet0Shorthand: true })).toEqual({ value: 391 })
    expect(evaluateWorkgroupFormula('E*0.97', ctx, { allowSheet0Shorthand: true })).toEqual({ value: 380 * 0.97 })
  })

  it('E/F/C NEM engedélyezve (pl. N sáv-oszlop) → VV-VALID-004 hiba', () => {
    const r = evaluateWorkgroupFormula('F', ctx, { allowSheet0Shorthand: false })
    expect('error' in r && r.error).toContain('VV-VALID-004')
    expect('error' in r && r.error).toContain('E/F/C')
    expect(evaluateWorkgroupFormula('F+1', ctx, { allowSheet0Shorthand: false })).toHaveProperty('error')
    expect(evaluateWorkgroupFormula('C', ctx, { allowSheet0Shorthand: false })).toHaveProperty('error')
    expect(evaluateWorkgroupFormula('E', ctx, { allowSheet0Shorthand: false })).toHaveProperty('error')
  })

  it('A/B/G/H/I 0-s lap self-ref NEM korlátozott (J=A funkció nem törhet)', () => {
    // allowSheet0Shorthand:false mellett is érvényes — pl. az elszámoló (J) = A
    expect(evaluateWorkgroupFormula('A', ctx, { allowSheet0Shorthand: false })).toEqual({ value: 100 })
    expect(evaluateWorkgroupFormula('G', ctx, { allowSheet0Shorthand: false })).toEqual({ value: 7 })
  })

  it('!<oszlop><KÓD> (sheet0Cross) és #NN (wgCross) mindenhol érvényesek', () => {
    expect(evaluateWorkgroupFormula('!FEUR', ctx, { allowSheet0Shorthand: false })).toEqual({ value: 400 })
    expect(evaluateWorkgroupFormula('#01L', ctx, { allowSheet0Shorthand: false })).toEqual({ value: 382 })
  })

  it('csoport self-ref (J–S, wgSelf) mindenhol érvényes', () => {
    expect(evaluateWorkgroupFormula('L', ctx, { allowSheet0Shorthand: false })).toEqual({ value: 381 })
  })

  it('default (opts nélkül) backward-compat: E/F/C engedélyezve', () => {
    expect(evaluateWorkgroupFormula('F', ctx)).toEqual({ value: 390 })
  })
})
