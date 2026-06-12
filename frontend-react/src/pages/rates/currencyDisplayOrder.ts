/**
 * FK04 (FR-4): a munkacsoport-lap valuta-rendezése a currency tábla `displayOrder`
 * mezőjéből (a backend overview item hordozza) — a korábbi hard-coded
 * MAIN_SHEET_CURRENCY_ORDER konstans kiváltása.
 *
 * A backend a getRateOverview()-ban az aktív valutákat displayOrder szerint adja,
 * de az EUA-t (inaktív törzsadat, V298) a lista VÉGÉRE fűzi — ezért a kliens-oldali
 * rendezés kötelező, hogy az EUA a kanonikus 15. helyre (RUB=14 és TRY=16 közé) kerüljön.
 *
 * Ismeretlen (displayOrder NÉLKÜLI) kód a lista végére, ABC-rendben — defenzív ág:
 * a V317 után minden DB-sornak van display_order-e (a nem-kanonikusak 100+, id-sorrendben),
 * így ez az ág csak hiányos API-válasznál él. A régi sortByMainSheetOrder a konstanson
 * kívüli kódokat ABC-ben rendezte; a V317-es 100+ tartomány id-sorrendje ettől elvileg
 * eltérhet, de a nem-kanonikus valuták (BGN, DKK, HRK, NOK, SEK) mind inaktívak, az
 * overview pedig csak aktívakat ad — gyakorlati eltérés nincs (verifikáció-jegyzet).
 */
export function sortByDisplayOrder<T extends { currencyCode: string; displayOrder?: number | null }>(
  rows: T[],
): T[] {
  return [...rows].sort((a, b) => {
    const ia = a.displayOrder ?? Number.MAX_SAFE_INTEGER
    const ib = b.displayOrder ?? Number.MAX_SAFE_INTEGER
    if (ia === ib) return a.currencyCode.localeCompare(b.currencyCode)
    return ia - ib
  })
}
