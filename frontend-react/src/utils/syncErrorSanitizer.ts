/**
 * FK-071 FR-6 — a tárolt szerver-hibaüzenet PII-szűrése megjelenítés előtt.
 *
 * A pénztáros a Tranzakciólistán a szinkron-hiba érdemi okát látja, de a
 * szerver-üzenetbe ágyazott PII-mintázatokat (e-mail-cím, telefonszám) maszkolni
 * kell. A minták a Fázis 0/E felderítés alapján:
 *  - e-mail: VALÓS backend-minta (IncomeSourceDocController:
 *    "Érvénytelen címzett email: " + email),
 *  - telefonszám: konzervatív feltételezett magyar minta (+36/06 előtaggal) —
 *    valós telefonszámos hibaüzenet-minta nem került elő, a review ezt a
 *    feltételezést erősítette meg (FK-071 GREEN Döntés 1).
 *
 * Okmányszám-maszkolás TUDATOSAN nincs (FK-071 GREEN Döntés 1): nincs bizonyíték
 * rá, hogy szerver-hibaüzenetben előfordulna, és egy mohó minta a bizonylatszám-
 * formátumot (1 betű + 9 számjegy, pl. V035000001) tévesen elfedhetné.
 *
 * FK-071 MEDIUM-E óta ez a modul a MEGJELENÍTÉS-oldali (defense-in-depth) réteg:
 * a maszkolás elsődlegesen már a tárolás/naplózás ELŐTT lefut az Electron main
 * processben. TARTSD SZINKRONBAN a párjával:
 * penztar-client/electron/sync-error-sanitizer.ts.
 */

const EMAIL_PATTERN = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g

// +36 / 0036 / 06 előtag + 1-2 jegyű körzet + 6-8 jegy, szóköz/kötőjel/per
// tagolással vagy anélkül. A számjegy-lookaround kizárja, hogy összegek,
// dátumok vagy bizonylatszámok belsejében lévő "06" hamisan match-eljen.
const HU_PHONE_PATTERN = /(?<!\d)(?:\+36|0036|06)[ \-/]?\d{1,2}[ \-/]?\d{3}[ \-/]?\d{3,4}(?!\d)/g

export const EMAIL_MASK = '[e-mail elrejtve]'
export const PHONE_MASK = '[telefonszám elrejtve]'

/**
 * A megjelenítésre szánt sync-hibaüzenet PII-mentesített változata.
 * A lényegi tartalom (hiba-ok) változatlan marad, csak a PII-mintázatú
 * részek cserélődnek maszkra.
 */
export function sanitizeSyncErrorMessage(message: string): string {
  return message.replace(EMAIL_PATTERN, EMAIL_MASK).replace(HU_PHONE_PATTERN, PHONE_MASK)
}
