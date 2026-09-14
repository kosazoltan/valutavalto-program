export interface EditableRate {
  currencyId: number
  currencyCode: string
  currencyName: string
  /** FK04 (FR-4): a currency tábla megjelenítési sorrendje — a sorok ez alapján rendeződnek. */
  displayOrder?: number | null
  officialRate: number | null
  buyRate: string
  sellRate: string
  limit1BuyRate: string
  limit1SellRate: string
  limit2BuyRate: string
  limit2SellRate: string
  limit3BuyRate: string
  limit3SellRate: string
  hasRate: boolean
  modified: boolean
}

export function parseNum(val: string): number {
  return parseFloat(val.replace(',', '.')) || 0
}

/**
 * FK13 (FR-5): a 0 megjelenítési szerződése. `allowZero: true` = a currency-irányra engedélyezett,
 * ténylegesen beírt/számított 0, amit NEM szabad üres cellává (`''`) veszíteni visszaíráskor.
 * A valódi „üres cella" (null/undefined) ábrázolása mindkét módban `''` marad.
 */
export interface FmtRateOptions {
  allowZero?: boolean
}

/**
 * FK13 (FR-5) — RED-fázis scaffolding (2026-09-14): az `opts` paraméter a tesztek fordításához
 * létezik, de MÉG NINCS BEKÖTVE — a 0 `allowZero` mellett is `''`-t ad. GREEN: `allowZero`
 * és `val === 0` → formázott nulla (`0,0000` 4 tizedesnél).
 */
export function fmtRate(
  val: number | null | undefined,
  decimals = 4,
  opts?: FmtRateOptions,
): string {
  void opts
  if (val == null || val === 0) return ''
  return val.toFixed(decimals).replace('.', ',')
}

export function fmtAmount(val: number | null | undefined): string {
  if (val == null || val === 0) return ''
  return Math.round(val).toLocaleString('hu-HU')
}
