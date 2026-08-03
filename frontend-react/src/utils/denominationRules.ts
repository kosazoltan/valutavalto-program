/**
 * FK-072_v2: tört címletek megelőzése — közös szabály (NFR-2).
 *
 * Az üzleti gyakorlat szerint 1 egység alatti (tört) névértékű címlet fizikailag
 * nem fordulhat elő, ezért a felületeken sem jeleníthető meg és nem is vihető be.
 * Minden érintett helyszín (záró-varázsló, Címletezés menü, Transfer, Shipment,
 * Bankjegy-bontás) EZT a helpert használja, hogy a szabály egy helyen éljen.
 *
 * A `denomination` valutakatalógus tört törzssorai változatlanok maradnak (§2/OUT)
 * — kizárólag a megjelenítés/bevitel szűrt.
 */
export const MIN_DENOMINATION_FACE_VALUE = 1

/** Igaz, ha a névérték megjeleníthető/beküldhető címletsor (véges és >= 1). */
export function isAllowedFaceValue(faceValue: number): boolean {
  return Number.isFinite(faceValue) && faceValue >= MIN_DENOMINATION_FACE_VALUE
}

/**
 * A tört-címlet elutasítás közös magyar hibaszöveg-magja (Sourcery-javaslat,
 * PR #1547) — a backend párja a ValidationMessages.FRACTIONAL_FACE_VALUE_CORE.
 * A VV-VALID-005 (negatív darabszám) üzenete szándékosan KÜLÖN szöveg, nem ide való.
 */
export const FRACTIONAL_FACE_VALUE_MESSAGE_CORE =
  'nem lehet 1-nél kisebb (tört címlet nem rögzíthető)'

/** Transfer/Shipment címletsor-hiba (a „névleges értéke" megfogalmazással). */
export const FRACTIONAL_FACE_VALUE_ERROR = `A címlet névleges értéke ${FRACTIONAL_FACE_VALUE_MESSAGE_CORE}!`

/** Bankjegy-bontás warning-üzenet (a „névértéke" megfogalmazással). */
export const FRACTIONAL_FACE_VALUE_WARNING = `A címlet névértéke ${FRACTIONAL_FACE_VALUE_MESSAGE_CORE}!`
