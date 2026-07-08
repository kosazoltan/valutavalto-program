/**
 * FK02-D (FR-14): a munkacsoport-csempék MINDIG a sorszám (legacyGroupNumber) szerint
 * növekvő sorrendben jelennek meg, függetlenül az API-válasz sorrendjétől és a
 * szerkesztés/mentés/új-csoport műveletektől. A betöltéskor rendezünk (a forrásnál),
 * hogy a csempe-render és a kijelölés-index (selectedWgIndex) is stabil maradjon.
 *
 * A sorszám nélküli (legacyGroupNumber == null) csoportok a lista VÉGÉRE kerülnek,
 * stabil (eredeti) relatív sorrendben.
 */
export function sortWorkgroupsBySequence<T extends { legacyGroupNumber?: number | null }>(
  list: T[],
): T[] {
  return [...list].sort((a, b) => {
    const sa = a.legacyGroupNumber ?? Number.POSITIVE_INFINITY
    const sb = b.legacyGroupNumber ?? Number.POSITIVE_INFINITY
    return sa - sb
  })
}
