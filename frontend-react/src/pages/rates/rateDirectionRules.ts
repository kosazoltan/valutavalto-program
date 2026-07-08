/**
 * RFM árfolyam-irány validáció (Árfolyamkészítő 0-s lap, kiküldés előtt).
 *
 * Pure, izoláltan tesztelhető (rateDirectionRules.test.ts).
 *
 * Üzleti invariáns (EXCMD b1-arfolyamkeszito FR-RFM-25, docx ÁR002-10):
 * kiküldés előtt az ELADÁSI árfolyam NEM lehet kisebb az elszámolónál, és a
 * VÉTELI árfolyam NEM lehet magasabb az elszámolónál. Ha nem megfelelő, a
 * rendszer figyelmeztetést küld, amikor ki akarja küldeni az árfolyamot.
 *
 * (A főlapon: settlement = A/Elszámoló, weakMultiBuy = vételi, weakMultiSell = eladási.)
 */

/** Float-összehasonlítási tolerancia (a kerekítési zaj ne adjon hamis riasztást). */
const EPSILON = 1e-9

export interface RateDirectionRow {
  currencyCode: string
  /** Elszámoló árfolyam (A oszlop). */
  settlement: number
  /** Vételi árfolyam (a pénztár ennyiért VESZI a valutát az ügyféltől). */
  buyRate: number
  /** Eladási árfolyam (a pénztár ennyiért ADJA a valutát az ügyfélnek). */
  sellRate: number
}

export type RateDirectionViolationType = 'SELL_BELOW_SETTLEMENT' | 'BUY_ABOVE_SETTLEMENT'

export interface RateDirectionViolation {
  currencyCode: string
  type: RateDirectionViolationType
  settlement: number
  rate: number
  message: string
}

/**
 * Egy sor irány-ellenőrzése. Üres/0 elszámolóra vagy hiányzó rátára nem validál
 * (nem tudjuk eldönteni, ne adjunk hamis riasztást). Az egyenlőség megengedett
 * (eladási ≥ elszámoló, vételi ≤ elszámoló), csak a szigorú sértés riaszt.
 */
function checkRow(row: RateDirectionRow): RateDirectionViolation[] {
  const violations: RateDirectionViolation[] = []
  // Sourcery #787: defenzív — csak véges, pozitív elszámolóra validálunk
  // (a hívó számokat ad át, de NaN/Infinity/0 ne adjon hamis vagy hibás riasztást).
  if (!Number.isFinite(row.settlement) || row.settlement <= 0) return violations

  if (
    Number.isFinite(row.sellRate) &&
    row.sellRate > 0 &&
    row.sellRate < row.settlement - EPSILON
  ) {
    violations.push({
      currencyCode: row.currencyCode,
      type: 'SELL_BELOW_SETTLEMENT',
      settlement: row.settlement,
      rate: row.sellRate,
      message: `${row.currencyCode}: az eladási árfolyam (${row.sellRate}) kisebb az elszámolónál (${row.settlement})`,
    })
  }
  if (Number.isFinite(row.buyRate) && row.buyRate > 0 && row.buyRate > row.settlement + EPSILON) {
    violations.push({
      currencyCode: row.currencyCode,
      type: 'BUY_ABOVE_SETTLEMENT',
      settlement: row.settlement,
      rate: row.buyRate,
      message: `${row.currencyCode}: a vételi árfolyam (${row.buyRate}) magasabb az elszámolónál (${row.settlement})`,
    })
  }
  return violations
}

/**
 * Az összes sor irány-validációja kiküldés előtt.
 * @returns a szabálysértések listája (üres = minden rendben)
 */
export function validateRateDirection(rows: RateDirectionRow[]): RateDirectionViolation[] {
  if (!rows || rows.length === 0) return []
  return rows.flatMap(checkRow)
}
