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
 * FK13 (FR-5): `allowZero` mellett a 0 formázott nullaként jelenik meg (`0,0000` 4 tizedesnél) —
 * így a `parseNum` kör-stabilan 0-ként olvassa vissza, és a képletből számított 0 nem veszik el.
 * `allowZero` nélkül (FK10 alapviselkedés) a 0 üres cella marad.
 */
export function fmtRate(
  val: number | null | undefined,
  decimals = 4,
  opts?: FmtRateOptions,
): string {
  if (val == null) return ''
  if (val === 0 && !opts?.allowZero) return ''
  return val.toFixed(decimals).replace('.', ',')
}

export function fmtAmount(val: number | null | undefined): string {
  if (val == null || val === 0) return ''
  return Math.round(val).toLocaleString('hu-HU')
}
