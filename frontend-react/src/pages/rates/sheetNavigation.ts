// Főlap (rate-maker) Excel-szerű billentyűzetes navigáció — tiszta, tesztelhető logika.
// Kósa Zoltán user-direktíva (2026-05-21): nyíl-navigáció a szerkeszthető cellák között,
// Enter belépés szerkesztésbe + Enter jóváhagyás. A D és G oszlop VÉDETT (nem navigálható
// szerkesztésre), a H (crossRate) csak kereszt-valuta (crossBase) soroknál szerkeszthető.

// Minimális strukturális sor-típus — csak a crossBase kell a navigációhoz (a
// crossRate/H csak kereszt-valutánál szerkeszthető). A MainRateSheetPage MainRateRow-ja
// strukturálisan hozzárendelhető (elkerüli a komponens↔helper körkörös importot).
export interface SheetNavRow {
  crossBase: string | null
}

export type EditableCol =
  | 'settlement'   // A
  | 'otp'          // B
  | 'helper'       // C
  | 'weakMultiBuy' // E
  | 'weakMultiSell'// F
  | 'crossRate'    // H (csak crossBase sor)
  | 'wholesale'    // I

/** Vizuális oszlop-sorrend (balról jobbra). D és G kimarad (védett). */
export const EDITABLE_ORDER: EditableCol[] = [
  'settlement', 'otp', 'helper', 'weakMultiBuy', 'weakMultiSell', 'crossRate', 'wholesale',
]

export interface CellPos {
  rowIdx: number
  col: EditableCol
}

export type NavKey = 'ArrowUp' | 'ArrowDown' | 'ArrowLeft' | 'ArrowRight'

/** Az adott (sor, oszlop) szerkeszthető-e. A crossRate csak crossBase soroknál. */
export function isCellEditable(rows: SheetNavRow[], rowIdx: number, col: EditableCol): boolean {
  const row = rows[rowIdx]
  if (!row) return false
  if (col === 'crossRate') return !!row.crossBase
  return true
}

/**
 * A következő szerkeszthető cella a megadott nyíl-irányba, a nem-szerkeszthető
 * cellákat átugorva. Ha nincs (a rács szélén túl), a jelenlegi pozíciót adja vissza
 * (nincs mozgás). Determinisztikus, mellékhatás-mentes.
 */
export function nextEditableCell(current: CellPos, key: NavKey, rows: SheetNavRow[]): CellPos {
  const rowCount = rows.length
  if (rowCount === 0) return current
  const colIdx = EDITABLE_ORDER.indexOf(current.col)
  if (colIdx < 0) return current

  if (key === 'ArrowLeft' || key === 'ArrowRight') {
    const step = key === 'ArrowRight' ? 1 : -1
    for (let c = colIdx + step; c >= 0 && c < EDITABLE_ORDER.length; c += step) {
      const col = EDITABLE_ORDER[c]!
      if (isCellEditable(rows, current.rowIdx, col)) return { rowIdx: current.rowIdx, col }
    }
    return current
  }

  // ArrowUp / ArrowDown: ugyanaz az oszlop, a legközelebbi sor ahol szerkeszthető.
  const step = key === 'ArrowDown' ? 1 : -1
  for (let r = current.rowIdx + step; r >= 0 && r < rowCount; r += step) {
    if (isCellEditable(rows, r, current.col)) return { rowIdx: r, col: current.col }
  }
  return current
}
