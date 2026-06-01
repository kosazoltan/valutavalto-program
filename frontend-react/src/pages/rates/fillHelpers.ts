/**
 * RFM csoportlap "Aktuális függvény" (FR-RFM-22) tiszta segédfüggvénye
 * (EXCMD b1-arfolyamkeszito, FR-RFMUI-15 / FR-RFMUI-17).
 *
 * FK02-B / FR-6..10 (2026-06-01): a korábbi GLOBÁLIS „Kitöltési segítség" helperek
 * (fillDownLimitBands / clearLimitBands) ELTÁVOLÍTVA — a teljes táblázatra ható, destruktív
 * lehúzás/sávtörlés megszűnt. Helyette a RateGrid Excel-szerű tartomány-kijelölése + lebegő
 * toolbarja (Lehúzás üres / Lehúzás mind / Sávok törlése) kizárólag a kijelölt cellákra hat.
 */

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
