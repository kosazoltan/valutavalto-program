/**
 * FK-04/C — Munkacsoport árfolyamlap localStorage-perzisztencia + 0-s lap kontextus.
 *
 * A 0-s lap (`MainRateSheetPage`) Phase-1 mintáját követi: a csoport-lap KÉPLETEI és a
 * számított J–S ÉRTÉK-pillanatképei kliens-oldalon, localStorage-ban élnek (a publikálás
 * a meglévő `publishGroupRate` szerver-kontraktuson megy). Így:
 *  - a felhasználói képletek megmaradnak csoport- és újratöltés-váltáskor,
 *  - a `#NN` kereszt-csoport hivatkozások fel tudják oldani a már megnyitott csoportok értékeit,
 *  - az `A`–`I` és `!<oszlop><KÓD>` hivatkozások a 0-s lap localStorage-állományából oldódnak fel.
 *
 * Minden függvény defenzív: hibás/hiányzó localStorage esetén üres szerkezetet ad (nem dob).
 */

import { WORKGROUP_FORMULA_STORAGE_PREFIX, type Sheet0Values, type WgValues } from './workgroupSheetFormula'

/** A 0-s lap (MainRateSheetPage) localStorage kulcsa — A–I oszlop-források. */
const SHEET0_STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'
/** Csoportonkénti J–S érték-pillanatkép kulcs (a `#NN` kereszt-hivatkozásokhoz). */
const WORKGROUP_VALUES_STORAGE_KEY = 'arfolyamkeszito.workgroupSheet.values.v1'

/** A 0-s lap egy sorának nyers alakja (a MainRateSheetPage MainRateRow-ja, releváns mezők). */
interface RawSheet0Row {
  currency?: string
  settlement?: number // A
  otp?: number // B
  helper?: number // C
  weakMultiBuy?: number // E
  weakMultiSell?: number // F
  crossSettlement?: number // G
  crossRate?: number // H
  wholesale?: number // I
}

/** Egy 0-s lap sor → A–I oszlop-értékek (a `D` ISO-címke kizárva, mint a motorban). */
export function sheet0RowToValues(row: RawSheet0Row): Sheet0Values {
  const v: Sheet0Values = {}
  if (typeof row.settlement === 'number') v.A = row.settlement
  if (typeof row.otp === 'number') v.B = row.otp
  if (typeof row.helper === 'number') v.C = row.helper
  if (typeof row.weakMultiBuy === 'number') v.E = row.weakMultiBuy
  if (typeof row.weakMultiSell === 'number') v.F = row.weakMultiSell
  if (typeof row.crossSettlement === 'number') v.G = row.crossSettlement
  if (typeof row.crossRate === 'number') v.H = row.crossRate
  if (typeof row.wholesale === 'number') v.I = row.wholesale
  return v
}

/** A 0-s lap A–I oszlop-értékei valutakód szerint (a `A`–`I` és `!<oszlop><KÓD>` hivatkozásokhoz). */
export function loadSheet0ByCurrency(storage: Storage = localStorage): Map<string, Sheet0Values> {
  const map = new Map<string, Sheet0Values>()
  try {
    const raw = storage.getItem(SHEET0_STORAGE_KEY)
    if (!raw) return map
    const rows = JSON.parse(raw) as RawSheet0Row[]
    if (!Array.isArray(rows)) return map
    for (const r of rows) {
      if (r && typeof r.currency === 'string') map.set(r.currency.toUpperCase(), sheet0RowToValues(r))
    }
  } catch {
    /* defenzív: hibás JSON → üres map */
  }
  return map
}

const formulaKey = (groupId: string): string => `${WORKGROUP_FORMULA_STORAGE_PREFIX}.${groupId}`

/**
 * FK02-B / FR-11, FR-12: a csoport FIX (nem-formulás) beírt rátaértékeinek localStorage-kulcsa.
 * A képletek mellett a fix beírt értékek (vétel/eladás/sávok) eddig csak React state-ben éltek,
 * ezért lapváltáskor/újratöltéskor a szerver-bootstrap felülírta őket. Csoportonként, kulcs
 * `${currencyId}.${field}` → a beírt nyers string.
 */
const ratesKey = (groupId: string): string => `arfolyamkeszito.workgroupSheet.rates.v1.${groupId}`

/** Egy csoport fix (nem-formulás) rátaértékei (kulcs = `${currencyId}.${field}`). */
export function loadGroupRateValues(groupId: string, storage: Storage = localStorage): Record<string, string> {
  try {
    const raw = storage.getItem(ratesKey(groupId))
    if (!raw) return {}
    const parsed = JSON.parse(raw) as Record<string, string>
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch {
    return {}
  }
}

export function saveGroupRateValues(groupId: string, values: Record<string, string>, storage: Storage = localStorage): void {
  try {
    // Üres store → a kulcs ELTÁVOLÍTÁSA (Copilot): nem hagyunk „{}" entryt, és a publikálás-utáni
    // „overlay-törlés" szemantikailag is helyes (a betöltés ezután {}-t ad, a szerver lesz az authority).
    if (Object.keys(values).length === 0) {
      storage.removeItem(ratesKey(groupId))
      return
    }
    storage.setItem(ratesKey(groupId), JSON.stringify(values))
  } catch {
    /* quota / privát mód → kihagyjuk (a memóriabeli state tovább működik) */
  }
}

/**
 * FK02-B / FR-11, FR-12 — TARTÓS offline (Electron SQLite) perzisztencia a localStorage MELLÉ.
 *
 * A LOCAL-FIRST mandate szerint az árfolyamkészítő tartós lokál tárolója az SQLite (`rate-maker.db`),
 * nem a böngésző localStorage-a. A localStorage a gyors SZINKRON út + web/dev fallback; az SQLite a
 * tartós, „kamu-mock nélküli" tároló (FK02-B findings QA-garancia #1). Dual-write: a hívó MINDKETTŐBE
 * ír (localStorage azonnal, SQLite best-effort), betöltéskor SQLite-first (Electron) → localStorage.
 * Electronon kívül (böngésző/dev) ezek no-op / üres értéket adnak — nincs regresszió.
 */
interface RateMakerLocalFirstApi {
  saveGroupRateValues?: (payload: { groupId: string; values: Record<string, string> }) => Promise<{ ok: boolean }>
  getGroupRateValues?: (groupId: string) => Promise<Record<string, string>>
}

function getLocalFirstApi(): RateMakerLocalFirstApi | null {
  const api = (globalThis as { electronAPI?: { localFirst?: RateMakerLocalFirstApi } }).electronAPI
  return api?.localFirst ?? null
}

/** Fire-and-forget: a csoport fix rátaértékeit az Electron SQLite-ba is elmenti (best-effort, nem dob). */
export function saveGroupRateValuesToOfflineDb(groupId: string, values: Record<string, string>): void {
  const lf = getLocalFirstApi()
  if (!lf?.saveGroupRateValues) return
  try {
    void lf.saveGroupRateValues({ groupId, values }).catch(() => { /* best-effort: a localStorage út él */ })
  } catch {
    /* nem-Electron / IPC-hiba → a szinkron localStorage út tovább működik */
  }
}

/** Az Electron SQLite-ból tölti a csoport fix rátaértékeit (üres, ha nincs Electron vagy nincs adat). */
export async function loadGroupRateValuesFromOfflineDb(groupId: string): Promise<Record<string, string>> {
  const lf = getLocalFirstApi()
  if (!lf?.getGroupRateValues) return {}
  try {
    const res = await lf.getGroupRateValues(groupId)
    return res && typeof res === 'object' ? res : {}
  } catch {
    return {}
  }
}

/**
 * FK02-B / FR-11, FR-12 — EGYSÉGES dual-write: a csoport fix rátaértékeit a localStorage-ba (szinkron)
 * ÉS a tartós Electron SQLite-ba (best-effort) is elmenti. MINDEN író call-site ezt hívja (onBlur, undo,
 * redo, bulk-paste, publikálás-utáni törlés), hogy a két tároló SOHA ne divergáljon — különben a
 * betöltéskori SQLite-first overlay elavult/visszavont értéket támaszthatna fel (review P0/P1).
 */
export function persistGroupRateValues(groupId: string, values: Record<string, string>): void {
  saveGroupRateValues(groupId, values)
  saveGroupRateValuesToOfflineDb(groupId, values)
}

/** Egy csoport képletei (kulcs = `${currencyId}.${field}`). */
export function loadGroupFormulas(groupId: string, storage: Storage = localStorage): Record<string, string> {
  try {
    const raw = storage.getItem(formulaKey(groupId))
    if (!raw) return {}
    const parsed = JSON.parse(raw) as Record<string, string>
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch {
    return {}
  }
}

export function saveGroupFormulas(groupId: string, formulas: Record<string, string>, storage: Storage = localStorage): void {
  try {
    storage.setItem(formulaKey(groupId), JSON.stringify(formulas))
  } catch {
    /* quota / privát mód → némán kihagyjuk (a memóriabeli state tovább működik) */
  }
}

/** Az összes csoport persistált J–S érték-pillanatképe: csoportsorszám → (valutakód → J–S). */
type ValuesStore = Record<string, Record<string, WgValues>>

export function loadAllGroupValueSnapshots(storage: Storage = localStorage): Map<number, Map<string, WgValues>> {
  const out = new Map<number, Map<string, WgValues>>()
  try {
    const raw = storage.getItem(WORKGROUP_VALUES_STORAGE_KEY)
    if (!raw) return out
    const store = JSON.parse(raw) as ValuesStore
    if (!store || typeof store !== 'object') return out
    for (const [groupNumStr, byCurrency] of Object.entries(store)) {
      const groupNum = Number(groupNumStr)
      if (!Number.isFinite(groupNum)) continue
      const inner = new Map<string, WgValues>()
      for (const [code, wgv] of Object.entries(byCurrency)) inner.set(code.toUpperCase(), wgv)
      out.set(groupNum, inner)
    }
  } catch {
    /* defenzív */
  }
  return out
}

/** Egy csoport (sorszám) számított J–S pillanatképének mentése a `#NN` hivatkozásokhoz. */
export function saveGroupValueSnapshot(
  groupNumber: number,
  byCurrency: Map<string, WgValues>,
  storage: Storage = localStorage,
): void {
  try {
    const raw = storage.getItem(WORKGROUP_VALUES_STORAGE_KEY)
    const store: ValuesStore = raw ? (JSON.parse(raw) as ValuesStore) : {}
    const inner: Record<string, WgValues> = {}
    for (const [code, wgv] of byCurrency) inner[code.toUpperCase()] = wgv
    store[String(groupNumber)] = inner
    storage.setItem(WORKGROUP_VALUES_STORAGE_KEY, JSON.stringify(store))
  } catch {
    /* quota / privát mód → kihagyjuk */
  }
}
