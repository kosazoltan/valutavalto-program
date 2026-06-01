// FK02-B / FR-2..5: a csoport-árfolyamlap cella-mentésének „nagy eltérés" védelme.
// Tiszta (mellékhatás-mentes) segédfüggvény, hogy egységtesztelhető legyen a page-komponens
// nehéz függőségei nélkül.

/** Az az arányos küszöb, amely felett megerősítést kérünk a mentés előtt (10%). */
export const SIGNIFICANT_DEVIATION_THRESHOLD = 0.1

/**
 * Igaz, ha az új érték az előző (perzisztált) értékhez képest legalább a küszöböt eléri.
 * Null/üres előző vagy új érték, illetve 0 alap esetén nincs korlátozás (nem értelmezhető arány).
 */
export function isSignificantDeviation(oldVal: number | null, newVal: number | null): boolean {
  if (oldVal === null || newVal === null || oldVal === 0) return false
  return Math.abs(newVal - oldVal) / Math.abs(oldVal) >= SIGNIFICANT_DEVIATION_THRESHOLD
}
