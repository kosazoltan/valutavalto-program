// FK02-B / FR-2..5: a csoport-árfolyamlap cella-mentésének „nagy eltérés" védelme.
// Tiszta (mellékhatás-mentes) segédfüggvény, hogy egységtesztelhető legyen a page-komponens
// nehéz függőségei nélkül.

/** Az az arányos küszöb, amely felett megerősítést kérünk a mentés előtt (10%). */
export const SIGNIFICANT_DEVIATION_THRESHOLD = 0.1

/**
 * Lebegőpontos tűrés: a pontosan a küszöbön lévő eltérés (pl. 1.10 → 1.21 = 0.11/1.10) a JS
 * tört-aritmetikájában 0.0999…988-ra kerekülhet, ami a sima `>=` mellett kimaradna. Az epsilon
 * (a küszöbnél több nagyságrenddel kisebb) garantálja, hogy a pontosan 10%-os eltérés is triggerel.
 */
const DEVIATION_EPSILON = 1e-9

/**
 * Igaz, ha az új érték az előző (perzisztált) értékhez képest legalább a küszöböt eléri.
 * Null/üres előző vagy új érték, illetve 0 alap esetén nincs korlátozás (nem értelmezhető arány).
 */
export function isSignificantDeviation(oldVal: number | null, newVal: number | null): boolean {
  if (oldVal === null || newVal === null || oldVal === 0) return false
  return (
    Math.abs(newVal - oldVal) / Math.abs(oldVal) >=
    SIGNIFICANT_DEVIATION_THRESHOLD - DEVIATION_EPSILON
  )
}
