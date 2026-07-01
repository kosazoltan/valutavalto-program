// FK06: a Főlap E (vétel) / F (eladás) oszlop 10%-os eltérés-figyelmeztetésének tiszta,
// mellékhatás-mentes döntési logikája — hogy a page-komponens nehéz függőségei nélkül is
// egységtesztelhető legyen (a deviationCheck.ts / mainSheetRules.ts bevált mintája szerint).

import { isSignificantDeviation } from './deviationCheck'
import { isFormula } from './mainSheetFormula'

/** Az E/F oszlop-kulcsok, amelyekre a 10%-os eltérés-figyelmeztetés vonatkozik. */
export const DEVIATION_GUARDED_COLUMNS = ['weakMultiBuy', 'weakMultiSell'] as const
export type DeviationGuardedColumn = (typeof DEVIATION_GUARDED_COLUMNS)[number]

export interface DeviationDecision {
  /** Kell-e megerősítést kérni a commit előtt. */
  warn: boolean
  /** A számszerű előző (baseline) érték — csak ha warn=true. */
  previous: number | null
  /** Az új (parse-olt) érték — csak ha warn=true. */
  next: number | null
  /** Az eltérés kerekített százaléka — csak ha warn=true (a megerősítő szöveghez). */
  percent: number | null
}

const NO_WARN: DeviationDecision = { warn: false, previous: null, next: null, percent: null }

/** A Főlap magyar tizedesjeles / szóközös inputját számmá alakítja (null, ha nem szám). */
export function parseCellNumber(raw: string): number | null {
  const trimmed = raw.trim()
  if (trimmed === '') return null
  const parsed = Number.parseFloat(trimmed.replace(/\s/g, '').replace(',', '.'))
  return Number.isNaN(parsed) ? null : parsed
}

/**
 * Eldönti, hogy egy E/F cella-commit 10%-os eltérés-figyelmeztetést igényel-e.
 * - Csak E/F oszlopra (a többi oszlop soha nem riaszt).
 * - Képletet NEM korlátozunk (csak fix szám).
 * - Üres / nem-szám input → nincs riasztás.
 * - Üres / 0 / null baseline → nincs riasztás (FR-5: nincs hamis riasztás).
 * - A küszöb a közös deviationCheck.ts (10%), nincs duplikált küszöb-definíció (FR-4).
 */
export function evaluateDeviationWarning(
  col: string,
  raw: string,
  baseline: number | null,
): DeviationDecision {
  if (col !== 'weakMultiBuy' && col !== 'weakMultiSell') return NO_WARN
  const trimmed = raw.trim()
  if (trimmed === '' || isFormula(trimmed)) return NO_WARN
  const next = parseCellNumber(trimmed)
  if (next === null) return NO_WARN
  if (!isSignificantDeviation(baseline, next)) return NO_WARN
  const prev = baseline as number
  const percent = Math.round((Math.abs(next - prev) / Math.abs(prev)) * 100)
  return { warn: true, previous: prev, next, percent }
}
