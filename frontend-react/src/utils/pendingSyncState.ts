/**
 * FKH-031 NFR-1 — renderer-oldali párja az Electron `business-retry.ts` policy-nek.
 *
 * A sync-engine 7 nap után véglegesen visszatartja az üzleti (4xx) hibával
 * elutasított tételt (`isBusinessRetryWithheld` → mindig `true`), vagyis
 * automatikusan MÁR NEM próbálkozik. Eddig a UI ezt nem különböztette meg egy
 * öt perce hibázott tételtől: mindkettő "Szinkronizálás sikertelen" feliratot
 * kapott, így egy pénzügyi tétel 7 nap után némán elveszhetett.
 *
 * Ez a modul csak OSZTÁLYOZ (tiszta függvény, nincs I/O), hogy ugyanaz a döntés
 * a bizonylat-vázlat listán és a tranzakciólistán is azonosan jelenjen meg.
 *
 * Az ablak hossza szándékosan tükrözi az Electron `BUSINESS_RETRY_WINDOW_MS`
 * konstansát. A két csomag között nincs futásidejű import (a renderer nem lát rá
 * az electron/ könyvtárra), ezért az érték itt is ki van mondva — ha az egyik
 * változik, a másikat is módosítani kell.
 */

/** FKH-031 NFR-1: az automatikus üzleti retry-ablak hossza — 7 nap. */
export const BUSINESS_RETRY_WINDOW_MS = 7 * 24 * 60 * 60 * 1000

export type PendingSyncKind =
  /** Nincs hiba: a normál, csendes "szinkronra vár" állapot. */
  | 'PENDING'
  /** Hibázott, de az automatikus újrapróbálkozás még hátra van. */
  | 'RETRYING'
  /** A 7 napos ablak lejárt: a rendszer már NEM próbálkozik magától. */
  | 'MANUAL_REQUIRED'

export interface PendingSyncInput {
  /** A tárolt (már PII-maszkolt) szinkron-hibaüzenet, ha van. */
  syncError?: string | null
  /** A tétel helyi rögzítésének időpontja (ISO). */
  createdAt?: string | null
}

export interface PendingSyncState {
  kind: PendingSyncKind
  /** `true`, ha a tételt már csak kézi újraküldés viheti fel. */
  needsManualIntervention: boolean
  /** A listákon megjelenő állapotfelirat. */
  label: string
}

const LABELS: Record<PendingSyncKind, string> = {
  PENDING: 'Helyben mentve, szinkronra vár',
  RETRYING: 'Szinkronizálás sikertelen — automatikus újrapróbálkozás',
  MANUAL_REQUIRED: 'Kézi beavatkozás szükséges — nem próbálkozik újra',
}

function parseIso(value: string | null | undefined): number | null {
  if (!value) return null
  const ms = Date.parse(value)
  return Number.isNaN(ms) ? null : ms
}

/**
 * Egy függő tétel szinkron-állapotának osztályozása.
 *
 * Fail-open: hiányzó vagy értelmezhetetlen `createdAt` esetén NEM jelölünk kézi
 * állapotot — egy sérült időbélyeg miatt pénzügyi tétel nem tűnhet fel
 * "feladottként". Ugyanez a döntés az Electron oldalon is (`isBusinessRetryExpired`).
 */
export function classifyPendingSyncState(
  input: PendingSyncInput,
  nowMs: number = Date.now(),
): PendingSyncState {
  const hasError = Boolean(input.syncError && input.syncError.trim())
  if (!hasError) {
    return { kind: 'PENDING', needsManualIntervention: false, label: LABELS.PENDING }
  }

  const createdAt = parseIso(input.createdAt)
  const expired = createdAt !== null && nowMs - createdAt >= BUSINESS_RETRY_WINDOW_MS
  const kind: PendingSyncKind = expired ? 'MANUAL_REQUIRED' : 'RETRYING'
  return { kind, needsManualIntervention: expired, label: LABELS[kind] }
}
