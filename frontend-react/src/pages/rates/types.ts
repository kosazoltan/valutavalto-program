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
 * Codex PR #1767 LOW: a `parseNum` a nem-numerikus/sérült stringet csendben 0-vá alakítja, ami
 * engedélyezett-nulla irányon „legitim 0"-ként mehetne tovább. Ez a szigorú változat üres,
 * nem-numerikus vagy nem-véges bemenetre `null`-t ad — a hívó explicit hibát jelezhet.
 */
/**
 * Teljes-sztring decimális minta: opcionális előjel, számjegyek, legfeljebb egy tizedespont
 * (a magyar vessző normalizálás UTÁN), számjegyek. NEM elejéről-értelmező: a `parseFloat`
 * a „0abc” / „0,00oops” / „0x10” bemenetet 0-nak olvasná (Codex PR #1767 fix-kör LOW).
 */
const STRICT_DECIMAL_PATTERN = /^[+-]?(\d+(\.\d+)?|\.\d+)$/

export function parseNumStrict(val: string | null | undefined): number | null {
  if (val == null) return null
  const t = val.trim()
  if (t === '') return null
  const normalized = t.replace(',', '.')
  if (!STRICT_DECIMAL_PATTERN.test(normalized)) return null
  const n = Number(normalized)
  return Number.isFinite(n) ? n : null
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
