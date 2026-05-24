/**
 * RFM csoportlap "Kitöltési segítség" (FR-RFM-23) + "Aktuális függvény" (FR-RFM-22)
 * tiszta segédfüggvényei (EXCMD b1-arfolyamkeszito, FR-RFMUI-15 / FR-RFMUI-17).
 *
 * Pure, izoláltan tesztelhető (fillHelpers.test.ts). A legacy "#01M"
 * függvénykód-katalógus pontos szemantikája a forrásban TBD
 * (b1-arfolyamkeszito-kepernyok nyitott kérdés #2) — a kód determinisztikus,
 * forrás-megjelenítéssel egyező UI-paritás (#NNM formátum).
 */
import type { EditableRate } from './types'

/** A csoportlap 3 kedvezménysávjának (vétel/eladás) string-mezői. */
type StringRateField =
  | 'limit1BuyRate' | 'limit1SellRate'
  | 'limit2BuyRate' | 'limit2SellRate'
  | 'limit3BuyRate' | 'limit3SellRate'

const BAND_FIELDS: ReadonlyArray<{ buy: StringRateField; sell: StringRateField }> = [
  { buy: 'limit1BuyRate', sell: 'limit1SellRate' },
  { buy: 'limit2BuyRate', sell: 'limit2SellRate' },
  { buy: 'limit3BuyRate', sell: 'limit3SellRate' },
]

/**
 * FR-RFM-22 "Aktuális függvény": a csoportlapon megjelenített aktív képletkód
 * (#NNM formátum, pl. #01M). A pontos legacy katalógus TBD — determinisztikus
 * paritás: # + 2 jegyű csoportszám (legalább 01) + 'M' (munkacsoport-lap).
 */
export function currentFunctionCode(legacyGroupNumber: number | null | undefined): string {
  const n = typeof legacyGroupNumber === 'number' && Number.isFinite(legacyGroupNumber) && legacyGroupNumber > 0
    ? Math.trunc(legacyGroupNumber)
    : 1
  return `#${String(n).padStart(2, '0')}M`
}

/**
 * FR-RFM-23 "Adat lehúzás": a 0-s lap vételi/eladási árfolyamát lehúzza a 3
 * kedvezménysávba. Alapból csak az ÜRES sávmezőket tölti (non-destruktív, a
 * kézzel megadott sáv-értékeket megőrzi); overwrite=true esetén minden sávot
 * felülír (Excel drag-fill paritás). Immutable: új objektumot ad vissza
 * modified=true-val, ha tényleg változott; egyébként az eredetit (referencia).
 */
export function fillDownLimitBands(
  rate: EditableRate,
  opts: { overwrite?: boolean } = {},
): EditableRate {
  const buy = (rate.buyRate ?? '').trim()
  const sell = (rate.sellRate ?? '').trim()
  if (!buy && !sell) return rate // nincs mit lehúzni

  const next: EditableRate = { ...rate }
  let changed = false

  for (const { buy: bf, sell: sf } of BAND_FIELDS) {
    if (buy) {
      const cur = (next[bf] ?? '').trim()
      if ((opts.overwrite || !cur) && next[bf] !== buy) {
        next[bf] = buy
        changed = true
      }
    }
    if (sell) {
      const cur = (next[sf] ?? '').trim()
      if ((opts.overwrite || !cur) && next[sf] !== sell) {
        next[sf] = sell
        changed = true
      }
    }
  }

  if (!changed) return rate
  next.modified = true
  return next
}

/**
 * FR-RFM-23 komplementer művelet: a 3 kedvezménysáv törlése (a sávok így a 0-s
 * alap-árfolyamra esnek vissza). Immutable; csak akkor jelöl modified-ot, ha volt
 * mit törölni.
 */
export function clearLimitBands(rate: EditableRate): EditableRate {
  const next: EditableRate = { ...rate }
  let changed = false
  for (const { buy: bf, sell: sf } of BAND_FIELDS) {
    if ((next[bf] ?? '') !== '') { next[bf] = ''; changed = true }
    if ((next[sf] ?? '') !== '') { next[sf] = ''; changed = true }
  }
  if (!changed) return rate
  next.modified = true
  return next
}
