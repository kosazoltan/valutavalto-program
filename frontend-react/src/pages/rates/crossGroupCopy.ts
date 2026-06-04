/**
 * FK02-D (FR-9..13): cross-csoport másolás — a kijelölt cellák tartalmának (érték VAGY képlet)
 * átvitele más munkacsoport(ok) AZONOS sor–oszlop pozícióiba.
 *
 * A munkacsoport-lap cella-tartalma KÉT tárolóban él (kulcs mindkettőnél `${currencyId}.${field}`):
 *  - képlet → a per-csoport formula-tároló (loadGroupFormulas/saveGroupFormulas),
 *  - fix érték → a per-csoport group_rate_values (loadGroupRateValues/persistGroupRateValues).
 * Egy adott cellára a kettő KIZÁRJA egymást: ha képlet van, a fix érték törlendő és fordítva.
 *
 * Ez a tiszta helper a forrás-cellák alapján kiszámolja a CÉL-csoport ÚJ formula- és érték-térképét;
 * az IO-t (load/persist) a hívó (RateCreationPage) végzi a két tárolóba.
 */

/** Egy átmásolandó forrás-cella: a (currencyId.field) kulcs + a tartalma (képlet VAGY fix érték). */
export interface CrossGroupCopyCell {
  /** `${currencyId}.${field}` — a cél azonos pozíciója. */
  key: string
  /** Ha a forrás-cella képlet (nem üres) → ez kerül a cél formula-tárolójába. */
  formula?: string | null
  /** Ha a forrás-cella fix érték (nincs képlet) → ez kerül a cél group_rate_values-be. */
  value?: string | null
}

export interface CrossGroupCopyResult {
  formulas: Record<string, string>
  values: Record<string, string>
}

/**
 * A cél-csoport meglévő formula- és érték-térképére alkalmazza a forrás-cellákat.
 * @param targetFormulas a cél-csoport jelenlegi képletei (másolat készül, az eredeti nem mutálódik)
 * @param targetValues   a cél-csoport jelenlegi fix értékei (másolat készül)
 * @param cells          a kijelölt forrás-cellák tartalma
 */
export function applyCrossGroupCopy(
  targetFormulas: Record<string, string>,
  targetValues: Record<string, string>,
  cells: CrossGroupCopyCell[],
): CrossGroupCopyResult {
  const formulas = { ...targetFormulas }
  const values = { ...targetValues }
  for (const cell of cells) {
    const f = cell.formula?.trim()
    if (f) {
      // Képlet-cella: a célban a képlet él, a fix érték törlődik (a képlet számolja).
      formulas[cell.key] = f
      delete values[cell.key]
    } else if (cell.value != null && cell.value.trim() !== '') {
      // Fix érték-cella: a célban az érték él, a képlet törlődik.
      values[cell.key] = cell.value.trim()
      delete formulas[cell.key]
    } else {
      // Üres forrás → a cél cella kiürül (mindkét tárolóból törlés).
      delete formulas[cell.key]
      delete values[cell.key]
    }
  }
  return { formulas, values }
}
