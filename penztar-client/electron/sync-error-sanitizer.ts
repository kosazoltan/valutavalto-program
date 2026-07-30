/**
 * FK-071 MEDIUM-E (Codex security review) — PII-szűrés a sync-hibaüzeneteken
 * TÁROLÁS és NAPLÓZÁS előtt (Electron main process).
 *
 * A GREEN-fázisban a maszkolás csak megjelenítéskor futott
 * (frontend-react/src/utils/syncErrorSanitizer.ts) — a nyers szerver-üzenet
 * (PII-vel) bekerült a pending_transactions.sync_error mezőbe, a
 * pending_transaction_sync_attempts naplóba és a sync-engine logjába. Ez a
 * modul ugyanazt a maszkolást alkalmazza a perzisztencia-/log-határon.
 *
 * FONTOS SORREND-INVARIÁNS (PR #116): a business-validation detektor
 * (isBusinessValidationError) és az auth/hálózat-osztályozás a NYERS szövegen
 * fut, a maszkolt változat csak a tárolt/logolt/megjelenített VÉGSŐ érték.
 * A maszkolás bizonyítottan nem érinti a "HTTP {status}: {statusText}"
 * prefixet (az e-mail minta '@'-ot igényel, a telefon-minta számjegy-
 * lookaroundja kizárja a "HTTP 406"-féle álpozitívot), így a két változat
 * osztályozási szempontból ekvivalens — a nyers/maszkolt szétválasztás
 * defenzív garancia.
 *
 * TARTSD SZINKRONBAN a frontend párjával:
 * frontend-react/src/utils/syncErrorSanitizer.ts (megjelenítés-oldali,
 * defense-in-depth réteg + a javítás előtt tárolt legacy sorok szűrése).
 */

const EMAIL_PATTERN = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;

// +36 / 0036 / 06 előtag + 1-2 jegyű körzet + 6-8 jegy, szóköz/kötőjel/per
// tagolással vagy anélkül. A számjegy-lookaround kizárja, hogy összegek,
// dátumok vagy bizonylatszámok belsejében lévő "06" hamisan match-eljen.
const HU_PHONE_PATTERN = /(?<!\d)(?:\+36|0036|06)[ \-/]?\d{1,2}[ \-/]?\d{3}[ \-/]?\d{3,4}(?!\d)/g;

export const EMAIL_MASK = '[e-mail elrejtve]';
export const PHONE_MASK = '[telefonszám elrejtve]';

/**
 * A tárolásra/naplózásra szánt sync-hibaüzenet PII-mentesített változata.
 * A lényegi tartalom (hiba-ok, HTTP-prefix) változatlan marad.
 */
export function sanitizeSyncErrorMessage(message: string): string {
  return message.replace(EMAIL_PATTERN, EMAIL_MASK).replace(HU_PHONE_PATTERN, PHONE_MASK);
}
