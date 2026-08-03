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
