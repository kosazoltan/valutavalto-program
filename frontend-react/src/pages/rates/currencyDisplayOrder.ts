/**
 * FK04 (FR-4): a munkacsoport-lap valuta-rendezése a currency tábla `displayOrder`
 * mezőjéből (a backend overview item hordozza) — a korábbi hard-coded
 * MAIN_SHEET_CURRENCY_ORDER konstans kiváltása.
 *
 * A backend a getRateOverview()-ban az aktív valutákat displayOrder szerint adja,
 * de az EUA-t (inaktív törzsadat, V298) a lista VÉGÉRE fűzi — ezért a kliens-oldali
 * rendezés kötelező, hogy az EUA a kanonikus 15. helyre (RUB=14 és TRY=16 közé) kerüljön.
 *
 * Ismeretlen (displayOrder nélküli) kód a lista végére, ABC-rendben — az eddigi
 * sortByMainSheetOrder viselkedésével azonosan.
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
