// FK-003 – Zárás beérkezés felügyelet: tiszta (pure) nézet-logika.
// Kiszervezve a komponensből, hogy unit-tesztelhető legyen.

import type { ClosingControlStatus } from '../../services/api'

export type ClosingViewFilter = 'all' | 'done' | 'notArrived'

/**
 * Egy iroda zárása "beérkezett"-e: a teljesített zárások száma eléri az elvártat.
 * (completedCount/requiredCount, fallback a 3 zárástípus boolean összege / 3.)
 */
export function isClosingDone(row: ClosingControlStatus): boolean {
  const required = row.requiredCount ?? 3
  const completed = row.completedCount
    ?? (Number(row.dailyClosingDone) + Number(row.eveningClosingDone) + Number(row.navClosingDone))
  return completed >= required
}

export interface ClosingSummary {
  /** Összes aktív iroda (a lista hossza). */
  total: number
  /** Beérkezett zárású irodák. */
  done: number
  /** Még be nem érkezett zárású irodák (= total - done). */
  notArrived: number
}

/**
 * FK-003 1. pont: 3-kockás összesítő. Rendben + Hiányzó rekord = Iroda összesen,
 * tehát notArrived = total - done (NEM a missingRecord flag).
 */
export function computeClosingSummary(rows: ClosingControlStatus[]): ClosingSummary {
  const total = rows.length
  const done = rows.filter(isClosingDone).length
  return { total, done, notArrived: total - done }
}

/** Pénztárszám (branchCode) szerinti, numerikusan tudatos rendezés (BR009 < BR010 < BR105). */
export function sortByBranchCode(rows: ClosingControlStatus[]): ClosingControlStatus[] {
  return [...rows].sort((a, b) =>
    (a.branchCode ?? a.branchId).localeCompare(b.branchCode ?? b.branchId, 'hu', { numeric: true, sensitivity: 'base' }),
  )
}

/** Keresés (kód/név/város/megjegyzés) + állapot-szűrő (Összes / Rendben / Hiányzó rekord). */
export function matchesClosingFilter(
  row: ClosingControlStatus,
  filter: ClosingViewFilter,
  query: string,
): boolean {
  const normalized = query.trim().toLowerCase()
  const matchesQuery = !normalized || [row.branchCode, row.branchName, row.branchCity, row.notes]
    .some((value) => value?.toLowerCase().includes(normalized))
  if (!matchesQuery) return false
  if (filter === 'done') return isClosingDone(row)
  if (filter === 'notArrived') return !isClosingDone(row)
  return true
}
