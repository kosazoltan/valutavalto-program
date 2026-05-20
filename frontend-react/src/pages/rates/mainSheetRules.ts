/**
 * Főlap (Árfolyamkészítő 0-s lap) cella-feloldási szabályok.
 *
 * Pure, izoláltan tesztelhető (mainSheetRules.test.ts).
 *
 * Üzleti döntés (Kósa Zoltán 2026-05-20): a G/H oszlopok kereszt-logikája marad
 * (kézzel NEM felülírható), az A oszlop (Elszámoló) viszont kézzel felülírható —
 * kereszt-valutáknál is. Ha az A nincs kézzel felülírva, a G (kereszt-számolt)
 * értékét veszi fel automatikusan.
 */
export interface SettlementRow {
  settlement: number
  crossRate: number
  crossBase: 'EUR' | 'USD' | null
  /** true, ha az A oszlopot a felhasználó kézzel felülírta (csak kereszt-valutákra értelmezett). */
  settlementManual?: boolean
}

/**
 * G oszlop — kereszt árfolyam alapú elszámoló: base (EUR/USD elszámoló) / crossRate.
 * Nem kereszt-valutára vagy hiányzó crossRate-re 0.
 */
export function computeCrossSettlement(
  row: { crossBase: 'EUR' | 'USD' | null; crossRate: number },
  eurSettlement: number,
  usdSettlement: number,
): number {
  if (!row.crossBase || !row.crossRate) return 0
  const base = row.crossBase === 'EUR' ? eurSettlement : usdSettlement
  if (!base) return 0
  return base / row.crossRate
}

/**
 * A oszlop (Elszámoló) tényleges értéke:
 *  - nem kereszt-valuta → a beírt settlement (mindig kézi),
 *  - kereszt-valuta + kézi felülírás → a beírt settlement,
 *  - kereszt-valuta felülírás nélkül → a G (kereszt-számolt) érték (auto).
 */
export function resolveSettlement(
  row: SettlementRow,
  eurSettlement: number,
  usdSettlement: number,
): number {
  if (!row.crossBase) return row.settlement
  if (row.settlementManual) return row.settlement
  return computeCrossSettlement(row, eurSettlement, usdSettlement)
}

/**
 * Kereszt-valuta A oszlop: a beírt érték MARAD auto módban (nem billen kézire), ha a cella
 * jelenleg auto (nem kézi) ÉS a beírt érték a G auto-értékkel egyezik a megadott tizedesre.
 * Így a puszta fókusz/blur (változatlan érték) nem zárja le a kereszt-követést (P1 #722).
 */
export function crossSettlementStaysAuto(
  enteredValue: number,
  autoG: number,
  decimals: number,
  wasManual: boolean,
): boolean {
  if (wasManual) return false
  return Number(enteredValue.toFixed(decimals)) === Number(autoG.toFixed(decimals))
}
