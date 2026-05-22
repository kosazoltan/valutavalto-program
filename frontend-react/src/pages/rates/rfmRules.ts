/**
 * RFM számítási szabályok (Árfolyamkészítő — alaplap ÁR001 + csoportlap ÁR002).
 *
 * Pure, izoláltan tesztelhető (rfmRules.test.ts). A spec unit-AC-jét fedi
 * (EXCMD b1-arfolyamkeszito): "EUA 20% szabály, R/S képlet (P+0,25), 10%
 * Raiffeisen sáv mindkét forrásmódra (elszámoló vs OTP), kereszt-árfolyam".
 */

/** EUA tűrés-küszöb: az euró-érme árfolyama max 20%-kal térhet el (FR-RFM-09). */
export const EUA_MARKUP = 1.2
export const EUA_MAX_DEVIATION = 0.2

/** Raiffeisen sáv alap-százaléka (±10%, szabadon állítható) — FR-RFM-12/13. */
export const RAIFFEISEN_BAND_PERCENT = 10

/**
 * EUA (euró-érme) képzett árfolyama: a gyenge árfolyamos euró eladás × 1.2
 * (FR-RFM-09). 0 vagy nem véges bemenetre 0.
 */
export function computeEuaRate(eurWeakSell: number): number {
  if (!Number.isFinite(eurWeakSell) || eurWeakSell <= 0) return 0
  return eurWeakSell * EUA_MARKUP
}

/**
 * Igaz, ha a megadott EUA-árfolyam a képzett (×1.2) értékhez képest 20%-nál
 * jobban eltér — ekkor ki kell írni az ügyfeleknek (FR-RFM-09).
 */
export function euaDeviationExceeds(euaRate: number, eurWeakSell: number): boolean {
  const expected = computeEuaRate(eurWeakSell)
  if (expected <= 0 || !Number.isFinite(euaRate) || euaRate <= 0) return false
  return Math.abs(euaRate - expected) / expected > EUA_MAX_DEVIATION
}

export interface RateBand {
  min: number
  max: number
}

/**
 * Raiffeisen ±N% sáv egy bázisárfolyam köré (FR-RFM-12/13). A bázis lehet az
 * elszámoló VAGY az OTP árfolyam — a hívó dönti el a forrásmódot. A százalék
 * szabadon állítható (alap 10%).
 */
export function raiffeisenBand(base: number, percent: number = RAIFFEISEN_BAND_PERCENT): RateBand {
  if (!Number.isFinite(base) || base <= 0) return { min: 0, max: 0 }
  // Copilot #792: érvénytelen (NaN/Infinity/negatív) százalék → alapérték,
  // különben {NaN, NaN} mérgezné a későbbi számításokat/UI-t.
  const pct = Number.isFinite(percent) && percent >= 0 ? percent : RAIFFEISEN_BAND_PERCENT
  const delta = base * (pct / 100)
  return { min: base - delta, max: base + delta }
}

/**
 * Saját hatáskörű Vét.max / Elad.min képlet (FR-RFM-19): az előző (P/Q) értékhez
 * hozzáadva a kedvezmény mértéke (pl. EUR: P + 0,25).
 */
export function computeRsRate(pRate: number, discount: number): number {
  if (!Number.isFinite(pRate)) return 0
  const d = Number.isFinite(discount) ? discount : 0
  return pRate + d
}

/**
 * Kereszt-árfolyam (FR-RFM-04/05): EUR/USD bázis elszámoló osztva a kereszt-rátával.
 * Hiányzó/0 bemenetre 0.
 */
export function computeCrossRate(baseSettlement: number, crossRate: number): number {
  if (!Number.isFinite(baseSettlement) || !Number.isFinite(crossRate) || crossRate <= 0) return 0
  return baseSettlement / crossRate
}
