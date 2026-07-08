import { describe, it, expect } from 'vitest'
import {
  nextEditableCell,
  isCellEditable,
  EDITABLE_ORDER,
  type CellPos,
  type SheetNavRow,
} from './sheetNavigation'

// Minimál sorok: EUR (nem crossBase), CHF (crossBase=EUR → crossRate szerkeszthető).
const row = (crossBase: string | null): SheetNavRow => ({ crossBase })

const rows: SheetNavRow[] = [
  row(null), // EUR
  row('EUR'), // CHF (cross)
  row(null), // USD
]

describe('sheetNavigation', () => {
  it('EDITABLE_ORDER: D és G nincs benne (védett), H benne van', () => {
    expect(EDITABLE_ORDER).not.toContain('currency')
    expect(EDITABLE_ORDER).not.toContain('crossSettlement')
    expect(EDITABLE_ORDER).toContain('crossRate')
  })

  it('crossRate csak crossBase sornál szerkeszthető', () => {
    expect(isCellEditable(rows, 0, 'crossRate')).toBe(false) // EUR
    expect(isCellEditable(rows, 1, 'crossRate')).toBe(true) // CHF
    expect(isCellEditable(rows, 0, 'settlement')).toBe(true)
  })

  it('ArrowRight: F → (nem-cross sor) átugorja a crossRate-et I-re', () => {
    const from: CellPos = { rowIdx: 0, col: 'weakMultiSell' } // F, EUR (nem cross)
    expect(nextEditableCell(from, 'ArrowRight', rows)).toEqual({ rowIdx: 0, col: 'wholesale' }) // I
  })

  it('ArrowRight: F → (cross sor) crossRate-re lép (H szerkeszthető)', () => {
    const from: CellPos = { rowIdx: 1, col: 'weakMultiSell' } // F, CHF (cross)
    expect(nextEditableCell(from, 'ArrowRight', rows)).toEqual({ rowIdx: 1, col: 'crossRate' }) // H
  })

  it('ArrowLeft a bal szélen: nincs mozgás (settlement marad)', () => {
    const from: CellPos = { rowIdx: 0, col: 'settlement' }
    expect(nextEditableCell(from, 'ArrowLeft', rows)).toEqual(from)
  })

  it('ArrowDown: ugyanaz az oszlop, következő sor', () => {
    const from: CellPos = { rowIdx: 0, col: 'otp' }
    expect(nextEditableCell(from, 'ArrowDown', rows)).toEqual({ rowIdx: 1, col: 'otp' })
  })

  it('ArrowDown crossRate oszlopon: átugorja a nem-cross USD sort (nincs lejjebb cross) → marad', () => {
    const from: CellPos = { rowIdx: 1, col: 'crossRate' } // CHF cross
    // lejjebb csak USD (nem cross) → nincs szerkeszthető crossRate → marad
    expect(nextEditableCell(from, 'ArrowDown', rows)).toEqual(from)
  })

  it('ArrowUp az alsó sorból a tetejéig ugyanazon oszlopon', () => {
    const from: CellPos = { rowIdx: 2, col: 'settlement' }
    expect(nextEditableCell(from, 'ArrowUp', rows)).toEqual({ rowIdx: 1, col: 'settlement' })
  })
})
