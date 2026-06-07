import { describe, it, expect } from 'vitest'
import { recomputeWorkgroupSheet, type WgComputeRow, type WorkgroupComputeInput } from './workgroupSheetCompute'
import type { Sheet0Values, WgValues } from './workgroupSheetFormula'

function emptyVals(): WgComputeRow['values'] {
  return {
    officialRate: null,
    buyRate: null,
    sellRate: null,
    limit1BuyRate: null,
    limit1SellRate: null,
    limit2BuyRate: null,
    limit2SellRate: null,
    limit3BuyRate: null,
    limit3SellRate: null,
  }
}

function input(over: Partial<WorkgroupComputeInput> & { rows: WgComputeRow[] }): WorkgroupComputeInput {
  return {
    formulas: {},
    sheet0ByCurrency: new Map<string, Sheet0Values>(),
    otherGroupsByCurrency: new Map<number, Map<string, WgValues>>(),
    ...over,
  }
}

describe('recomputeWorkgroupSheet (FK-04/C)', () => {
  it('képlet nélkül a fix értékek változatlanok', () => {
    const rows: WgComputeRow[] = [
      { currencyId: 1, currencyCode: 'EUR', values: { ...emptyVals(), officialRate: 400, buyRate: 395, sellRate: 405 } },
    ]
    const res = recomputeWorkgroupSheet(input({ rows }))
    expect(res.diverged).toBe(false)
    expect(res.rows[0]!.values.buyRate).toBe(395)
    expect(res.rows[0]!.values.officialRate).toBe(400)
  })

  it('self J–S hivatkozás: L = J - 5', () => {
    const rows: WgComputeRow[] = [
      { currencyId: 1, currencyCode: 'EUR', values: { ...emptyVals(), officialRate: 400, sellRate: 410 } },
    ]
    const res = recomputeWorkgroupSheet(input({ rows, formulas: { '1.buyRate': 'J - 5' } }))
    expect(res.rows[0]!.values.buyRate).toBe(395)
    expect(res.errors).toEqual({})
  })

  it('0-s lap A–I self hivatkozás: J = A (elszámoló a 0-s lapról)', () => {
    const rows: WgComputeRow[] = [{ currencyId: 1, currencyCode: 'EUR', values: emptyVals() }]
    const sheet0 = new Map<string, Sheet0Values>([['EUR', { A: 402 }]])
    const res = recomputeWorkgroupSheet(input({ rows, sheet0ByCurrency: sheet0, formulas: { '1.officialRate': 'A' } }))
    expect(res.rows[0]!.values.officialRate).toBe(402)
  })

  it('FR-8: F shorthand csak L/M-ben — buyRate (L) kiértékelődik, limit1BuyRate (N) hibázik', () => {
    const sheet0 = new Map<string, Sheet0Values>([['EUR', { F: 390 }]])
    const rows = (): WgComputeRow[] => [{ currencyId: 1, currencyCode: 'EUR', values: { ...emptyVals(), officialRate: 400 } }]
    // F a buyRate (L) mezőben → engedélyezett shorthand → a Főlap EUR F értéke (390)
    const resL = recomputeWorkgroupSheet(input({ rows: rows(), sheet0ByCurrency: sheet0, formulas: { '1.buyRate': 'F' } }))
    expect(resL.rows[0]!.values.buyRate).toBe(390)
    expect(resL.errors['1.buyRate']).toBeUndefined()
    // F a limit1BuyRate (N) mezőben → tiltott → VV-VALID-004 hiba, az érték marad null
    const resN = recomputeWorkgroupSheet(input({ rows: rows(), sheet0ByCurrency: sheet0, formulas: { '1.limit1BuyRate': 'F' } }))
    expect(resN.errors['1.limit1BuyRate']).toContain('VV-VALID-004')
    expect(resN.rows[0]!.values.limit1BuyRate).toBeNull()
  })

  it('!<oszlop><KÓD> kereszt-valuta: EUA eladása = EUR F oszlopa a 0-s lapon', () => {
    const rows: WgComputeRow[] = [{ currencyId: 9, currencyCode: 'EUA', values: { ...emptyVals(), officialRate: 400 } }]
    const sheet0 = new Map<string, Sheet0Values>([['EUR', { F: 415 }]])
    const res = recomputeWorkgroupSheet(input({ rows, sheet0ByCurrency: sheet0, formulas: { '9.sellRate': '!FEUR' } }))
    expect(res.rows[0]!.values.sellRate).toBe(415)
  })

  it('#NN kereszt-csoport: L = #01L + 0,5', () => {
    const rows: WgComputeRow[] = [{ currencyId: 1, currencyCode: 'EUR', values: { ...emptyVals(), officialRate: 400 } }]
    const otherGroups = new Map<number, Map<string, WgValues>>([
      [1, new Map<string, WgValues>([['EUR', { L: 390 }]])],
    ])
    const res = recomputeWorkgroupSheet(
      input({ rows, otherGroupsByCurrency: otherGroups, formulas: { '1.buyRate': '#01L + 0,5' } }),
    )
    expect(res.rows[0]!.values.buyRate).toBe(390.5)
  })

  it('láncolt self képlet több passzban konvergál: M = L + 10, L = J - 5', () => {
    const rows: WgComputeRow[] = [{ currencyId: 1, currencyCode: 'EUR', values: { ...emptyVals(), officialRate: 400 } }]
    const res = recomputeWorkgroupSheet(
      input({ rows, formulas: { '1.buyRate': 'J - 5', '1.sellRate': 'L + 10' } }),
    )
    expect(res.rows[0]!.values.buyRate).toBe(395)
    expect(res.rows[0]!.values.sellRate).toBe(405)
    expect(res.diverged).toBe(false)
  })

  it('körhivatkozás → diverged=true, fix értékek megmaradnak', () => {
    const rows: WgComputeRow[] = [
      { currencyId: 1, currencyCode: 'EUR', values: { ...emptyVals(), officialRate: 400, buyRate: 100 } },
    ]
    // L = M + 1, M = L + 1 → soha nem stabilizálódik
    const res = recomputeWorkgroupSheet(
      input({ rows, formulas: { '1.buyRate': 'M + 1', '1.sellRate': 'L + 1' } }),
    )
    expect(res.diverged).toBe(true)
    expect(res.rows[0]!.values.buyRate).toBe(100) // eredeti fix érték
  })

  it('JPY → 4 tizedes kerekítés (FK02-E FR-10 / NFR-3)', () => {
    const rows: WgComputeRow[] = [{ currencyId: 5, currencyCode: 'JPY', values: { ...emptyVals(), officialRate: 2 } }]
    const res = recomputeWorkgroupSheet(input({ rows, formulas: { '5.buyRate': 'J / 3' } }))
    expect(res.rows[0]!.values.buyRate).toBe(0.6667) // 0.66666… → JPY 4 tizedes → 0.6667
  })

  it('hibás képlet (ismeretlen valuta) → errors-ban, érték marad', () => {
    const rows: WgComputeRow[] = [{ currencyId: 1, currencyCode: 'EUR', values: { ...emptyVals(), buyRate: 395 } }]
    const res = recomputeWorkgroupSheet(input({ rows, formulas: { '1.buyRate': '!FXXX' } }))
    expect(res.errors['1.buyRate']).toBeTruthy()
    expect(res.rows[0]!.values.buyRate).toBe(395) // változatlan
  })
})
