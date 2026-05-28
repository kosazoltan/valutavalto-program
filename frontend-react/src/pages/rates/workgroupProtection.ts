/**
 * FK-04/E — Árfolyamvédelem (frontend, mentés-előtti azonnali visszajelzés).
 *
 * A backend `RatePublishService.validateRateProtection` (FK-04/E.2) AZONOS szabálya,
 * kliens-oldalon megismételve, hogy a felhasználó NE a 400-as szerverhibából, hanem
 * azonnal — a kiküldés gombnyomásakor — értesüljön a téves árfolyamról.
 *
 * Szabály (csempe jobb felső checkbox `protectionEnabled = true` esetén):
 *  - Vételi oszlopok (L, N, P, R) értéke nem lehet NAGYOBB a J (elszámoló) árfolyamnál.
 *  - Eladási oszlopok (M, O, Q, S) értéke nem lehet KISEBB a J árfolyamnál.
 *
 * A J=null (nincs elszámoló) sor kimarad — a referencia ismeretlen (a backend ugyanígy
 * skippeli; a kötelező-elszámoló szabály külön tárgya).
 *
 * Pure, izoláltan tesztelhető (workgroupProtection.test.ts). NEM dob — `violations` listát ad.
 */

/** Egy munkacsoport-lap egyetlen valuta-sorának J–S numerikus értékei (a védelem-ellenőrzéshez). */
export interface ProtectionRow {
  currencyCode: string
  /** J — elszámoló árfolyam. null/0 → a sort nem ellenőrizzük. */
  official: number | null
  /** L — alap vétel */
  buy: number
  /** M — alap eladás */
  sell: number
  /** N — 1. kedvezményes vétel */
  limit1Buy: number
  /** O — 1. kedvezményes eladás */
  limit1Sell: number
  /** P — 2. kedvezményes vétel */
  limit2Buy: number
  /** Q — 2. kedvezményes eladás */
  limit2Sell: number
  /** R — saját hatáskörű vétel */
  limit3Buy: number
  /** S — saját hatáskörű eladás */
  limit3Sell: number
}

export interface ProtectionViolation {
  currencyCode: string
  /** Oszlop-címke a backenddel egyezően, pl. "L vétel" / "M eladás". */
  column: string
  value: number
  official: number
  message: string
}

interface ColumnDef {
  label: string
  pick: (r: ProtectionRow) => number
  direction: 'buy' | 'sell'
}

// Az oszlop-címkék EGYEZNEK a backend RatePublishService.checkBuyRate/checkSellRate
// címkéivel ("L vétel", "M eladás", …), hogy a felhasználó ugyanazt a szöveget lássa.
const COLUMNS: ColumnDef[] = [
  { label: 'L vétel', pick: (r) => r.buy, direction: 'buy' },
  { label: 'N vétel', pick: (r) => r.limit1Buy, direction: 'buy' },
  { label: 'P vétel', pick: (r) => r.limit2Buy, direction: 'buy' },
  { label: 'R vétel', pick: (r) => r.limit3Buy, direction: 'buy' },
  { label: 'M eladás', pick: (r) => r.sell, direction: 'sell' },
  { label: 'O eladás', pick: (r) => r.limit1Sell, direction: 'sell' },
  { label: 'Q eladás', pick: (r) => r.limit2Sell, direction: 'sell' },
  { label: 'S eladás', pick: (r) => r.limit3Sell, direction: 'sell' },
]

/** Az érték „beállított"-e (üres/0 cella nem ellenőrzendő — a kötelező-ráta külön szabály). */
function isSet(v: number): boolean {
  return Number.isFinite(v) && v > 0
}

/**
 * FK-04/E árfolyamvédelem-ellenőrzés a teljes munkacsoport-lapra.
 *
 * @param rows         a munkacsoport valuta-sorai J–S numerikus értékekkel
 * @param protectionEnabled  a csoport `protectionEnabled` flag-je; ha false → üres lista
 * @param groupLabel   a hibaüzenet csoport-megnevezése, pl. "3-es csoport"
 * @returns a megsértett szabályok listája (üres = minden ráta szabályos)
 */
export function validateWorkgroupProtection(
  rows: ProtectionRow[],
  protectionEnabled: boolean,
  groupLabel: string,
): ProtectionViolation[] {
  if (!protectionEnabled) return []
  const violations: ProtectionViolation[] = []

  for (const r of rows) {
    const j = r.official
    if (j == null || j <= 0) continue // nincs elszámoló → nem ellenőrizzük (backend-azonos)

    for (const col of COLUMNS) {
      const v = col.pick(r)
      if (!isSet(v)) continue
      if (col.direction === 'buy' && v > j) {
        violations.push({
          currencyCode: r.currencyCode,
          column: col.label,
          value: v,
          official: j,
          message: `${groupLabel} ${r.currencyCode} ${col.label} nem lehet magasabb az elszámolónál (${v} > ${j}).`,
        })
      } else if (col.direction === 'sell' && v < j) {
        violations.push({
          currencyCode: r.currencyCode,
          column: col.label,
          value: v,
          official: j,
          message: `${groupLabel} ${r.currencyCode} ${col.label} nem lehet alacsonyabb az elszámolónál (${v} < ${j}).`,
        })
      }
    }
  }
  return violations
}

/** Csoport-címke képzése a backenddel egyezően: sorszám → "X-es csoport", egyébként "(KÓD) csoport". */
export function workgroupProtectionLabel(legacyGroupNumber: number | null | undefined, code: string): string {
  return legacyGroupNumber != null ? `${legacyGroupNumber}-es csoport` : `(${code}) csoport`
}
