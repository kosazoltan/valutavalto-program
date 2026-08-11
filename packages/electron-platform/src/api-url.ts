/**
 * API-URL feloldas es hiba-uzenet ertelmezes — PLATFORM-RETEG (pure).
 *
 * === MIERT VAN ITT (platform-refaktor 3. kor, 2026-08-11, U1 szelet) ===
 * A `.hermes/tmp/clone-detect.py` 2026-08-11-i merese szerint a maradek 15
 * cross-layer klon MIND a `kozponti` <-> `rate-maker` paros. Ebbol harom
 * fuggveny normalizalt (`;` + behuzas strippelt) diffje BAJTRA AZONOS volt:
 *
 *   normalizeApiUrl        penztar:190-193  kozponti:193-196  arfolyam:89-92   -> mind a 3 azonos
 *   parseErrorMessage      kozponti:327-334 arfolyam:222-229                   -> azonos
 *   resolveConfiguredApiUrl kozponti:224-237 arfolyam:120-133                  -> azonos
 *
 * === EZ A MODUL SZANDEKOSAN PURE (nincs `electron` import) ===
 * Igy unit-tesztelheto Electron futtatokornyezet nelkul, es a
 * `penztar-client` vitest node-kornyezetebol kozvetlenul behivhato.
 *
 * ============================================================================
 * !!! MIERT DONTES-OBJEKTUM ES NEM KESZ URL (viselkedes-megorzes) !!!
 * ============================================================================
 * A harom kliens `resolveConfiguredApiUrl`-je a DONTESI LOGIKABAN azonos, de a
 * MELLEKHATASAIBAN NEM:
 *
 *   - `penztar-client` a fallbacket EAGER modon szamolja ki (main.ts:196), meg
 *     akkor is, ha a konfiguralt URL ervenyes. Ez megfigyelheto: a
 *     `loadProductionUrls()` hibas csomag eseten `log.error` CRITICAL-t ir.
 *     Ha ezt lusta thunk-ra cserelnenk, az a log CSENDBEN ELTUNNE.
 *   - `penztar-client` ket agban `log.warn`-ol (invalid protocol / parse error);
 *     a masik ket kliens NEM logol.
 *
 * Ezert a platform csak a DONTEST adja vissza, a mellekhatas (fallback-szamitas
 * idozitese + logolas) a kliensben marad. Ez az AGENTS/skill szabalya:
 * "a kliens-specifikus kulonbseg legyen explicit, ne rejtett default".
 */

/** A konfiguralt `server_url` normalizalasa `.../api/v1` alakra. */
export function normalizeApiUrl(value: string): string {
  const trimmed = value.trim().replace(/\/+$/, '')
  return trimmed.endsWith('/api/v1') ? trimmed : `${trimmed}/api/v1`
}

/** Miert nem hasznalhato a konfiguralt `server_url`. */
export type ApiUrlFallbackReason =
  /** Nincs beallitva vagy csak whitespace. A kliensek ezt NEM logoljak. */
  | 'empty'
  /** Nem http/https sema (pl. `file:`, `javascript:`) — biztonsagi elutasitas. */
  | 'invalid-protocol'
  /** A `new URL(...)` dobott (szintaktikailag ervenytelen ertek). */
  | 'parse-error'

/** A `server_url` ertekelesenek eredmenye. */
export type ApiUrlDecision =
  | { readonly kind: 'configured'; readonly url: string }
  | {
      readonly kind: 'fallback'
      readonly reason: ApiUrlFallbackReason
      /** `invalid-protocol`: a nyers ertek. `parse-error`: a hibauzenet. */
      readonly detail: string
    }

/**
 * Eldonti, hasznalhato-e a konfiguralt `server_url`.
 *
 * NEM szamol fallback URL-t es NEM logol — lasd a fajl elejen a
 * viselkedes-megorzesi indoklast.
 */
export function decideApiUrl(configured: string | null | undefined): ApiUrlDecision {
  const trimmed = (configured ?? '').trim()
  if (!trimmed) {
    return { kind: 'fallback', reason: 'empty', detail: '' }
  }
  let parsed: URL
  try {
    parsed = new URL(trimmed)
  } catch (err) {
    return {
      kind: 'fallback',
      reason: 'parse-error',
      detail: err instanceof Error ? err.message : String(err),
    }
  }
  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    return { kind: 'fallback', reason: 'invalid-protocol', detail: trimmed }
  }
  return { kind: 'configured', url: normalizeApiUrl(trimmed) }
}

/**
 * Backend hibavalasz torzsebol ember-olvashato uzenet.
 * Nem-JSON vagy hianyzo mezo eseten a `fallback` szoveget adja vissza.
 */
export function parseErrorMessage(responseBody: string, fallback: string): string {
  try {
    const parsed = JSON.parse(responseBody) as { message?: unknown; error?: unknown }
    return String(parsed.message ?? parsed.error ?? fallback)
  } catch {
    return fallback
  }
}
