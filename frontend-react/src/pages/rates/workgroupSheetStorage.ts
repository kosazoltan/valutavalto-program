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

import {
  WORKGROUP_FORMULA_STORAGE_PREFIX,
  type Sheet0Values,
  type WgValues,
} from './workgroupSheetFormula'
import { FORMULA_STORAGE_KEY } from './mainSheetFormula'

/** A 0-s lap (MainRateSheetPage) localStorage kulcsa — A–I oszlop-források. */
const SHEET0_STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'
const MAIN_SHEET_LOCAL_EDITS_KEY = 'arfolyamkeszito.mainSheet.localEdits.v1'
/** Csoportonkénti J–S érték-pillanatkép kulcs (a `#NN` kereszt-hivatkozásokhoz). */
const WORKGROUP_VALUES_STORAGE_KEY = 'arfolyamkeszito.workgroupSheet.values.v1'
const RATE_MAKER_STORAGE_PREFIXES = [
  'arfolyamkeszito.mainSheet.',
  'arfolyamkeszito.workgroupSheet.',
  'mainRateSheet.',
]

export interface RateMakerSheetSnapshot {
  version: 1
  savedAt: string
  entries: Record<string, string>
}

function isRateMakerStorageKey(key: string): boolean {
  return RATE_MAKER_STORAGE_PREFIXES.some((prefix) => key.startsWith(prefix))
}

export function exportRateMakerSheetSnapshot(
  storage: Storage = localStorage,
): RateMakerSheetSnapshot {
  const entries: Record<string, string> = {}
  for (let i = 0; i < storage.length; i += 1) {
    const key = storage.key(i)
    if (!key || !isRateMakerStorageKey(key)) continue
    const value = storage.getItem(key)
    if (value !== null) entries[key] = value
  }
  return { version: 1, savedAt: new Date().toISOString(), entries }
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

export function computeProtectedMainSheetCells(
  localEditsJson: string | null,
  savedAt: unknown,
): Set<string> {
  const protectedCells = new Set<string>()
  if (!localEditsJson) return protectedCells

  try {
    const markers: unknown = JSON.parse(localEditsJson)
    if (!isPlainObject(markers)) return protectedCells

    const savedAtTs = typeof savedAt === 'string' ? Date.parse(savedAt) : Number.NaN
    for (const [key, markerTs] of Object.entries(markers)) {
      if (typeof markerTs !== 'number' || !Number.isFinite(markerTs)) continue
      if (!Number.isFinite(savedAtTs) || markerTs > savedAtTs) protectedCells.add(key)
    }
  } catch {
    // Hibás marker-store nem véd cellát, de az import ettől még nem írhatja felül a store-t.
  }
  return protectedCells
}

export function mergeMainSheetRowsJson(
  serverJson: string,
  localJson: string | null,
  protectedCells: Set<string>,
): string | null {
  let serverRows: unknown
  try {
    serverRows = JSON.parse(serverJson)
  } catch {
    return null
  }
  if (!Array.isArray(serverRows)) return null
  if (protectedCells.size === 0) return serverJson

  let localRows: unknown
  try {
    localRows = localJson ? JSON.parse(localJson) : null
  } catch {
    return serverJson
  }
  if (!Array.isArray(localRows)) return serverJson

  const localByCode = new Map<string, Record<string, unknown>>()
  for (const row of localRows) {
    if (isPlainObject(row) && typeof row.currency === 'string') {
      localByCode.set(row.currency, row)
    }
  }

  const serverCurrencies = new Set<string>()
  const mergedRows = serverRows.map((serverRow) => {
    if (!isPlainObject(serverRow) || typeof serverRow.currency !== 'string') return serverRow
    const currency = serverRow.currency
    serverCurrencies.add(currency)
    const localRow = localByCode.get(currency)
    if (!localRow) return serverRow

    let mergedRow = serverRow
    const prefix = `${currency}.`
    for (const cellKey of protectedCells) {
      if (!cellKey.startsWith(prefix)) continue
      const field = cellKey.slice(prefix.length)
      if (!field || typeof localRow[field] !== 'number') continue
      if (mergedRow === serverRow) mergedRow = { ...serverRow }
      mergedRow[field] = localRow[field]
      if (field === 'settlement' && Object.hasOwn(localRow, 'settlementManual')) {
        mergedRow.settlementManual = localRow.settlementManual
      }
    }
    return mergedRow
  })

  for (const [currency, localRow] of localByCode) {
    if (serverCurrencies.has(currency)) continue
    const prefix = `${currency}.`
    const hasProtectedNumericCell = [...protectedCells].some((cellKey) => {
      if (!cellKey.startsWith(prefix)) return false
      const field = cellKey.slice(prefix.length)
      return field.length > 0 && typeof localRow[field] === 'number'
    })
    if (hasProtectedNumericCell) mergedRows.push(localRow)
  }

  return JSON.stringify(mergedRows)
}

export function mergeMainSheetFormulasJson(
  serverJson: string,
  localJson: string | null,
  protectedCells: Set<string>,
): string | null {
  let serverFormulas: unknown
  try {
    serverFormulas = JSON.parse(serverJson)
  } catch {
    return null
  }
  if (!isPlainObject(serverFormulas)) return null
  if (protectedCells.size === 0) return serverJson

  let localFormulas: Record<string, unknown> = {}
  try {
    const parsedLocal: unknown = localJson ? JSON.parse(localJson) : {}
    if (isPlainObject(parsedLocal)) localFormulas = parsedLocal
  } catch {
    // Hibás lokális formula-store esetén nincs megőrizhető lokális képlet.
  }

  const merged: Record<string, unknown> = { ...serverFormulas }
  for (const cellKey of protectedCells) {
    if (Object.hasOwn(localFormulas, cellKey) && typeof localFormulas[cellKey] === 'string') {
      merged[cellKey] = localFormulas[cellKey]
    } else {
      delete merged[cellKey]
    }
  }
  return JSON.stringify(merged)
}

export function importRateMakerSheetSnapshot(
  sheetJson: string,
  storage: Storage = localStorage,
  localBaseline?: RateMakerSheetSnapshot,
): number {
  let imported = 0
  try {
    const parsed = JSON.parse(sheetJson) as Partial<RateMakerSheetSnapshot>
    if (
      parsed.version !== 1 ||
      !parsed.entries ||
      typeof parsed.entries !== 'object' ||
      Array.isArray(parsed.entries)
    ) {
      return 0
    }
    const baseline = localBaseline ?? exportRateMakerSheetSnapshot(storage)
    const protectedCells = computeProtectedMainSheetCells(
      baseline.entries[MAIN_SHEET_LOCAL_EDITS_KEY] ?? null,
      parsed.savedAt,
    )
    for (const [key, value] of Object.entries(parsed.entries)) {
      if (!isRateMakerStorageKey(key) || typeof value !== 'string') continue
      if (key === MAIN_SHEET_LOCAL_EDITS_KEY) continue

      let toWrite: string | null = value
      if (key === SHEET0_STORAGE_KEY) {
        toWrite = mergeMainSheetRowsJson(value, baseline.entries[key] ?? null, protectedCells)
      } else if (key === FORMULA_STORAGE_KEY) {
        toWrite = mergeMainSheetFormulasJson(value, baseline.entries[key] ?? null, protectedCells)
      }
      if (toWrite === null) continue

      storage.setItem(key, toWrite)
      imported += 1
    }
    return imported
  } catch {
    return imported
  }
}

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

/**
 * FK10: 0 / nem-pozitív / nem-véges forrás = „nincs érték”. A kulcs kihagyásával a
 * képletmotor meglévő `Nincs érték…` hibaága fut le, a MainRateSheetPage baseline-mintájával
 * konzisztensen.
 */
const pos = (n: number | undefined): n is number =>
  typeof n === 'number' && Number.isFinite(n) && n > 0

/** Egy 0-s lap sor → A–I oszlop-értékek (a `D` ISO-címke kizárva, mint a motorban). */
export function sheet0RowToValues(row: RawSheet0Row): Sheet0Values {
  const v: Sheet0Values = {}
  if (pos(row.settlement)) v.A = row.settlement
  if (pos(row.otp)) v.B = row.otp
  if (pos(row.helper)) v.C = row.helper
  if (pos(row.weakMultiBuy)) v.E = row.weakMultiBuy
  if (pos(row.weakMultiSell)) v.F = row.weakMultiSell
  if (pos(row.crossSettlement)) v.G = row.crossSettlement
  if (pos(row.crossRate)) v.H = row.crossRate
  if (pos(row.wholesale)) v.I = row.wholesale
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
      if (r && typeof r.currency === 'string')
        map.set(r.currency.toUpperCase(), sheet0RowToValues(r))
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
export function loadGroupRateValues(
  groupId: string,
  storage: Storage = localStorage,
): Record<string, string> {
  try {
    const raw = storage.getItem(ratesKey(groupId))
    if (!raw) return {}
    const parsed = JSON.parse(raw) as Record<string, string>
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch {
    return {}
  }
}

export function dirtyCurrencyIdsFromOverlay(values: Record<string, string>): Set<number> {
  const currencyIds = new Set<number>()
  for (const key of Object.keys(values)) {
    const currencyIdPart = key.split('.')[0]
    if (!currencyIdPart) continue
    const currencyId = Number(currencyIdPart)
    if (Number.isFinite(currencyId)) currencyIds.add(currencyId)
  }
  return currencyIds
}

export function saveGroupRateValues(
  groupId: string,
  values: Record<string, string>,
  storage: Storage = localStorage,
): void {
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
  // A handler hiba esetén `{ ok: false, error }`-t is adhat (Copilot review) — a hívó best-effort, nem dob.
  saveGroupRateValues?: (payload: {
    groupId: string
    values: Record<string, string>
  }) => Promise<{ ok: boolean; error?: string }>
  getGroupRateValues?: (groupId: string) => Promise<unknown>
}

function getLocalFirstApi(): RateMakerLocalFirstApi | null {
  const api = (globalThis as { electronAPI?: { localFirst?: RateMakerLocalFirstApi } }).electronAPI
  return api?.localFirst ?? null
}

/**
 * FK02-D / Codex P1: a group-rate SQLite IPC TÉNYLEGES elérhetősége. NEM elég `isElectron()`-t
 * nézni: a group-rate IPC (`saveGroupRateValues`/`getGroupRateValues`) csak a `kozponti-client`
 * rate-maker módjában van bekötve. Ahol az IPC hiányzik (pl. böngésző), a localStorage az
 * autoritás — onnan kell tölteni (különben `{}` → adatvesztés).
 * (2026-08-11: a korábbi standalone `arfolyam-keszito-client` megszűnt; az RFM mód
 * egyetlen Electron-hostja a kozponti-client rate-maker flavorja.)
 */
export function isGroupRateOfflineDbAvailable(): boolean {
  const lf = getLocalFirstApi()
  return lf?.getGroupRateValues != null && lf?.saveGroupRateValues != null
}

/** Fire-and-forget: a csoport fix rátaértékeit az Electron SQLite-ba is elmenti (best-effort, nem dob). */
export function saveGroupRateValuesToOfflineDb(
  groupId: string,
  values: Record<string, string>,
): void {
  const lf = getLocalFirstApi()
  if (!lf?.saveGroupRateValues) return
  try {
    void lf.saveGroupRateValues({ groupId, values }).catch(() => {
      /* best-effort: a localStorage út él */
    })
  } catch {
    /* nem-Electron / IPC-hiba → a szinkron localStorage út tovább működik */
  }
}

/**
 * Awaitable SQLite-mentés: a csoport fix rátaértékeit az Electron SQLite-ba menti és VISSZAADJA
 * a tényleges eredményt (a hívó a sikert ehhez kötheti — pl. a cross-csoport másolás csak akkor
 * jelez sikert, ha az AUTORITATÍV SQLite-írás is rendben volt). Electronon kívül `{ ok: true }`
 * (ott a localStorage az autoritás). FK02-D / Codex P2.
 */
export async function saveGroupRateValuesToOfflineDbAwait(
  groupId: string,
  values: Record<string, string>,
): Promise<{ ok: boolean }> {
  const lf = getLocalFirstApi()
  if (!lf?.saveGroupRateValues) return { ok: true }
  try {
    const res = await lf.saveGroupRateValues({ groupId, values })
    return { ok: !!res?.ok }
  } catch {
    return { ok: false }
  }
}

/** Az Electron SQLite-ból tölti a csoport fix rátaértékeit (üres, ha nincs Electron vagy nincs adat). */
export async function loadGroupRateValuesFromOfflineDb(
  groupId: string,
): Promise<Record<string, string>> {
  const lf = getLocalFirstApi()
  if (!lf?.getGroupRateValues) return {}
  try {
    const res = await lf.getGroupRateValues(groupId)
    // Defenzív szanálás (Copilot review): csak sima objektum + string értékek mehetnek tovább —
    // tömb / null / nem-string érték NEM (különben a cellákba nem-string kerülhetne).
    if (!res || typeof res !== 'object' || Array.isArray(res)) return {}
    const clean: Record<string, string> = {}
    for (const [k, v] of Object.entries(res as Record<string, unknown>)) {
      if (typeof v === 'string') clean[k] = v
    }
    return clean
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
export function loadGroupFormulas(
  groupId: string,
  storage: Storage = localStorage,
): Record<string, string> {
  try {
    const raw = storage.getItem(formulaKey(groupId))
    if (!raw) return {}
    const parsed = JSON.parse(raw) as Record<string, string>
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch {
    return {}
  }
}

export function saveGroupFormulas(
  groupId: string,
  formulas: Record<string, string>,
  storage: Storage = localStorage,
): void {
  try {
    storage.setItem(formulaKey(groupId), JSON.stringify(formulas))
  } catch {
    /* quota / privát mód → némán kihagyjuk (a memóriabeli state tovább működik) */
  }
}

/** Az összes csoport persistált J–S érték-pillanatképe: csoportsorszám → (valutakód → J–S). */
type ValuesStore = Record<string, Record<string, WgValues>>

export function loadAllGroupValueSnapshots(
  storage: Storage = localStorage,
): Map<number, Map<string, WgValues>> {
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
