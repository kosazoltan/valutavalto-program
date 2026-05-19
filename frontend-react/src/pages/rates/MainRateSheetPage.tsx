import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Send, LogOut, Globe, Save, ArrowRight, Info, Wifi, WifiOff, Settings } from 'lucide-react'
import { HyperFormula } from 'hyperformula'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'
import { exchangeRateMasterApi, type ExchangeRateMaster, type CreateMasterRateRequest } from '../../services/api/exchangeRateMaster'
import { currencyApi } from '../../services/api/exchange-rates'
import CurrencyManagerModal from './components/CurrencyManagerModal'

/**
 * Főlap (0-s lap) — Árfolyamkészítő program ALAP felülete.
 *
 * Spec forrás: "Áfolyamkészítő program működése" (Kósa Zoltán, 2026-05-13).
 *
 * <p>A 0-s lap az elszámoló árfolyamok beállítására, valamint az alap vételi/eladási
 * árfolyamok meghatározására szolgál. Ez a lap NEM tartozik pénztárhoz. A pénztárak,
 * árképzésüktől függően, külön munkacsoportokba vannak elhelyezve.</p>
 *
 * <p>Oszlopok (A-I):
 * <ul>
 *   <li>A — Elszámoló árfolyam (4 főváluta kézzel: EUR/USD/GBP/CHF, többi képlettel)</li>
 *   <li>B — OTP segéd (vételi)</li>
 *   <li>C — Segéd</li>
 *   <li>D — Valuta nem (ISO kód, VÉDETT)</li>
 *   <li>E — Gyenge multis vétel</li>
 *   <li>F — Gyenge multis eladás</li>
 *   <li>G — EUR/USD keresztárfolyam alapú elszámoló (számolt)</li>
 *   <li>H — Kereszt árfolyam (forrás, EUR-tartozó CZK,PLN,RON,RSD,BGN,BAM,TRY; USD-tartozó ILS,UAH,RUB,CNY,THB,BRL,MXN,NZD)</li>
 *   <li>I — Nagybani (jelenleg nem használt)</li>
 * </ul></p>
 *
 * <p>Adatfolyam:
 * <ul>
 *   <li>A oszlop érték → minden munkacsoport J oszlopába (Elszámoló) örökítve</li>
 *   <li>E/F oszlop → bizonyos munkacsoportok L/M oszlop képlet alapja</li>
 *   <li>G oszlop → automatikusan az A oszlopba kerülhet (kereszt-képletes valuták)</li>
 * </ul></p>
 *
 * <p><b>Phase 1 (MVP):</b> client-side state + localStorage perzisztencia.
 * Phase 2: backend persistence + reaktív data flow munkacsoportokhoz.</p>
 */

interface MainRateRow {
  currency: string         // D oszlop (VÉDETT)
  settlement: number       // A oszlop (Elszámoló)
  otp: number              // B oszlop (OTP segéd)
  helper: number           // C oszlop (Segéd)
  weakMultiBuy: number     // E oszlop (Gyenge multis vétel)
  weakMultiSell: number    // F oszlop (Gyenge multis eladás)
  crossSettlement: number  // G oszlop (EUR/USD kereszt alapú elszámoló — számolt)
  crossRate: number        // H oszlop (kereszt forrás, 6 tizedes)
  wholesale: number        // I oszlop (Nagybani)
  crossBase: 'EUR' | 'USD' | null  // melyik főváluta a kereszt alapja (NULL ha nem kereszt)
}

// v2.5.61 (2026-05-19 user-direktíva): 6 valuta törölve a Főlapról
// (DKK, NOK, SEK, HRK, BGN, RCH) — alacsony forgalmúak / már nem aktuálisak
// (HRK 2023-tól EUR; BGN belátható időn belül; skandináv koronák nem váltottak
// kollégánál; RCH custom volt). 22 valuta marad.
const DEFAULT_CURRENCIES: Array<Pick<MainRateRow, 'currency' | 'crossBase'>> = [
  { currency: 'EUR', crossBase: null }, // főváluta
  { currency: 'USD', crossBase: null }, // főváluta
  { currency: 'GBP', crossBase: null }, // főváluta
  { currency: 'CHF', crossBase: null }, // főváluta
  { currency: 'AUD', crossBase: null }, // OTP-ből (B oszlop)
  { currency: 'CAD', crossBase: null }, // OTP-ből (B oszlop)
  { currency: 'JPY', crossBase: null }, // 3 tizedes
  { currency: 'CZK', crossBase: 'EUR' },
  { currency: 'PLN', crossBase: 'EUR' },
  { currency: 'RON', crossBase: 'EUR' },
  { currency: 'RSD', crossBase: 'EUR' },
  { currency: 'ILS', crossBase: 'USD' },
  { currency: 'UAH', crossBase: 'USD' },
  { currency: 'RUB', crossBase: 'USD' },
  { currency: 'EUA', crossBase: null }, // Eurázsiai egyezmény (spec szerint)
  { currency: 'TRY', crossBase: 'EUR' },
  { currency: 'CNY', crossBase: 'USD' },
  { currency: 'BAM', crossBase: 'EUR' },
  { currency: 'THB', crossBase: 'USD' },
  { currency: 'BRL', crossBase: 'USD' },
  { currency: 'MXN', crossBase: 'USD' },
  { currency: 'NZD', crossBase: 'USD' },
]

// v2.5.61: a régi localStorage cache-eket szűrjük, hogy a 6 törölt valuta
// ne maradjon a UI-on (defenzív, ha a user már elindította a régi v2.5.60-at).
const REMOVED_CURRENCIES = new Set(['DKK', 'NOK', 'SEK', 'HRK', 'BGN', 'RCH'])

const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'

const emptyRow = (currency: string, crossBase: MainRateRow['crossBase']): MainRateRow => ({
  currency,
  settlement: 0,
  otp: 0,
  helper: 0,
  weakMultiBuy: 0,
  weakMultiSell: 0,
  crossSettlement: 0,
  crossRate: 0,
  wholesale: 0,
  crossBase,
})

function loadFromStorage(): MainRateRow[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return DEFAULT_CURRENCIES.map(c => emptyRow(c.currency, c.crossBase))
    const parsed = JSON.parse(raw) as MainRateRow[]
    // v2.5.61: szűrjük a törölt valutákat — a régi localStorage-ban még benne
    // lehetnek (DKK/NOK/SEK/HRK/BGN/RCH). Defensive cleanup mounton.
    const filtered = parsed.filter(r => !REMOVED_CURRENCIES.has(r.currency))
    // Defensive: ha új valuta jött a default listába, hozzáadjuk
    const existingCurrencies = new Set(filtered.map(r => r.currency))
    for (const def of DEFAULT_CURRENCIES) {
      if (!existingCurrencies.has(def.currency)) {
        filtered.push(emptyRow(def.currency, def.crossBase))
      }
    }
    return filtered
  } catch (e) {
    logger.error('MainRateSheetPage', 'Storage load failed', e)
    return DEFAULT_CURRENCIES.map(c => emptyRow(c.currency, c.crossBase))
  }
}

// v2.5.61: HyperFormula oszlop-mapping. A spreadsheet sheet 9 oszlop:
// A=settlement, B=otp, C=helper, D=currency (CSAK label), E=weakMultiBuy,
// F=weakMultiSell, G=crossSettlement (computed), H=crossRate, I=wholesale.
// D oszlop VÉDETT — nem accept formula, csak text label.
const FORMULA_COLUMNS = ['settlement', 'otp', 'helper', 'weakMultiBuy', 'weakMultiSell', 'wholesale'] as const
type FormulaColumn = typeof FORMULA_COLUMNS[number]

/** HyperFormula formula key = `${rowIdx}.${col}`. Csak felhasználói képletek tárolódnak. */
type FormulaMap = Record<string, string>
const FORMULA_STORAGE_KEY = 'arfolyamkeszito.mainSheet.formulas.v1'

function loadFormulasFromStorage(): FormulaMap {
  try {
    const raw = localStorage.getItem(FORMULA_STORAGE_KEY)
    if (!raw) return {}
    return JSON.parse(raw) as FormulaMap
  } catch {
    return {}
  }
}

/**
 * G oszlop számítás: kereszt árfolyam alapú elszámoló.
 *
 * <p>Példa CZK: H oszlop / EUR A oszlop értéke (ezzel ha az EUR elszámoló változik,
 * a CZK G oszlopa követi a változást, és onnan az A-ba kerül).</p>
 */
function computeCrossSettlement(row: MainRateRow, eurSettlement: number, usdSettlement: number): number {
  if (!row.crossBase || !row.crossRate) return 0
  const base = row.crossBase === 'EUR' ? eurSettlement : usdSettlement
  if (!base) return 0
  // Spec: A oszlop = H oszlop / A oszlop EUR (vagy USD) értéke
  // Pontosabban: a base elszámoló * 1 egység más-valuta = base / crossRate
  // Pl. EUR=400, EUR/CZK kereszt = 24.5 → CZK A = 400/24.5 = 16.32
  return base / row.crossRate
}

export default function MainRateSheetPage() {
  const navigate = useNavigate()
  const isLocalRateMakerApp = import.meta.env.VITE_APP_FLAVOR === 'rate-maker'
  const canEdit = useAuthStore((state) =>
    isLocalRateMakerApp && (state.hasRole('ADMIN') || state.hasCanonicalRole(['foertektar', 'ugyvezeto', 'admin'])),
  )
  const [rows, setRows] = useState<MainRateRow[]>(() => loadFromStorage())
  const [dirty, setDirty] = useState(false)
  const [activeCell, setActiveCell] = useState<{ rowIdx: number; col: keyof MainRateRow } | null>(null)
  // v2.5.61 (HyperFormula): képletek per cella, kulcs = `${rowIdx}.${col}`. Csak
  // a felhasználói képletek vannak itt — fix számérték NEM kerül ide.
  const [formulas, setFormulas] = useState<FormulaMap>(() => loadFormulasFromStorage())
  // HyperFormula instance — Excel-szerű cell-formula motor 380+ függvénnyel +
  // dependency-graph + auto-recalc. License: GPL v3 (internal company use OK).
  const hfRef = useRef<HyperFormula | null>(null)
  // Codex P1 #581 fix: editBuffer őrzi a felhasználó RAW input-ját az aktív cella szerkesztésekor.
  const [editBuffer, setEditBuffer] = useState<string>('')
  const [showHelp, setShowHelp] = useState(false)
  const [publishing, setPublishing] = useState(false)
  // V238 (2026-05-19): Valutakezelő modal — uj valuta hozzaadasa / aktivalas / deaktivalas
  const [showCurrencyManager, setShowCurrencyManager] = useState(false)
  const lastSavedAt = useRef<string | null>(null)
  // Phase 2 wiring (Kosa Zoltan 2026-05-18 directive): a foertektaros által az
  // EXE-ben végzett árfolyam-szerkesztés a KÖZPONTI szerveren tárolt
  // ExchangeRateMaster állományt írja/olvassa. Az EXE thin client.
  const [serverSyncState, setServerSyncState] = useState<'loading' | 'online' | 'offline' | 'idle'>('idle')
  const [serverLastSyncAt, setServerLastSyncAt] = useState<string | null>(null)
  const currencyIdMapRef = useRef<Map<string, number>>(new Map())
  // Codex+Copilot PR #687: a szerver utolso szinkron snapshot-ja - csak ennek
  // alapján döntheti el a dispatch hogy egy row tényleg módosult-e a szinkron óta.
  // Map<currencyCode, { weakMultiBuy, weakMultiSell, settlement }>
  const serverSnapshotRef = useRef<Map<string, { weakMultiBuy: number; weakMultiSell: number; settlement: number }>>(new Map())

  // Computed cross settlement for G column
  const eurRow = useMemo(() => rows.find(r => r.currency === 'EUR'), [rows])
  const usdRow = useMemo(() => rows.find(r => r.currency === 'USD'), [rows])
  const eurSettlement = eurRow?.settlement ?? 0
  const usdSettlement = usdRow?.settlement ?? 0

  // Codex P1 #581 fix: A oszlop érték crossBase-row-okra automatikusan a G oszlopból
  // (computeCrossSettlement) — spec szerint "A többi valuta elszámoló árfolyama a 'G'
  // oszlopban szereplő érték (képletes számítással)". A user által beállított settlement
  // értéket figyelmen kívül hagyjuk crossBase row esetén.
  const enrichedRows = useMemo<MainRateRow[]>(() => {
    return rows.map((r) => {
      const computedG = r.crossBase ? computeCrossSettlement(r, eurSettlement, usdSettlement) : 0
      return {
        ...r,
        crossSettlement: computedG,
        // A column auto-derive cross-base row-okra (spec §3 "G oszlop értékei módosítás nélkül A-ba kerülnek")
        settlement: r.crossBase ? computedG : r.settlement,
      }
    })
  }, [rows, eurSettlement, usdSettlement])

  // Codex P1 #581 fix: A column for crossBase rows is DERIVED, NOT user-editable.
  // Spec: "A többi valuta elszámoló árfolyama a 'G' oszlopban szereplő érték (képletes számítással)."
  // → Settlement column read-only ha crossBase != null. A renderelés `aIsAuto = !!row.crossBase`
  //   alapján dönt span vs. input között a render-loop-ban.

  // v2.5.61 (2026-05-19 user-direktíva): HyperFormula instance létrehozása mount-kor.
  // A spreadsheet 9 oszlopa: A=settlement, B=otp, C=helper, D=currency (label,
  // VÉDETT), E=weakMultiBuy, F=weakMultiSell, G=crossSettlement (számolt JS-ben),
  // H=crossRate, I=wholesale. A user az E-F-I-A-B-C-be írhat képletet "=" prefix-szel.
  useEffect(() => {
    if (hfRef.current) return // Csak egyszer
    const hf = HyperFormula.buildEmpty({ licenseKey: 'gpl-v3' })
    hf.addSheet('main')
    hfRef.current = hf
    return () => {
      hf.destroy()
      hfRef.current = null
    }
  }, [])

  // Reaktív szinkronizáció: amikor a `rows` vagy `formulas` állapot változik,
  // frissítjük a HyperFormula sheet tartalmát, majd újra olvassuk a kalkulált
  // értékeket. A loop megakadályozására useRef compare-rel ellenőrizzük, hogy
  // tényleg változott-e a recomputed érték.
  const hfRecomputeRef = useRef<boolean>(false)
  useEffect(() => {
    const hf = hfRef.current
    if (!hf) return
    if (hfRecomputeRef.current) {
      hfRecomputeRef.current = false
      return
    }
    const sheetId = hf.getSheetId('main')
    if (sheetId === undefined) return
    // Build full sheet data (9 col × N row). Cells with formulas use the formula
    // string ("=A1+B1"); cells without formulas use the raw numeric value.
    const data: (string | number | null)[][] = rows.map((row, idx) => {
      const formulaCell = (col: FormulaColumn, fallback: number): string | number =>
        formulas[`${idx}.${col}`] ?? fallback
      return [
        formulaCell('settlement', row.settlement),       // A
        formulaCell('otp', row.otp),                      // B
        formulaCell('helper', row.helper),                // C
        row.currency,                                     // D (label)
        formulaCell('weakMultiBuy', row.weakMultiBuy),    // E
        formulaCell('weakMultiSell', row.weakMultiSell),  // F
        row.crossSettlement,                              // G (JS-számolt)
        row.crossRate,                                    // H
        formulaCell('wholesale', row.wholesale),          // I
      ]
    })
    try {
      hf.setSheetContent(sheetId, data)
    } catch (e) {
      logger.warn('MainRateSheetPage', 'HyperFormula setSheetContent failed', e)
      return
    }
    // Olvassuk vissza a számolt értékeket. Ha bármi képlet-cella eltér a rows
    // jelenlegi értékétől, frissítjük (egyszeri batch update).
    const numericOrZero = (v: unknown): number => {
      if (typeof v === 'number' && Number.isFinite(v)) return v
      return 0
    }
    let mutated = false
    const nextRows = rows.map((row, idx) => {
      const newRow = { ...row }
      const cols: Array<[FormulaColumn, keyof MainRateRow, number]> = [
        ['settlement', 'settlement', 0],
        ['otp', 'otp', 1],
        ['helper', 'helper', 2],
        ['weakMultiBuy', 'weakMultiBuy', 4],
        ['weakMultiSell', 'weakMultiSell', 5],
        ['wholesale', 'wholesale', 8],
      ]
      for (const [formulaCol, rowKey, hfCol] of cols) {
        if (!formulas[`${idx}.${formulaCol}`]) continue
        const cellVal = hf.getCellValue({ sheet: sheetId, row: idx, col: hfCol })
        const num = numericOrZero(cellVal)
        if (newRow[rowKey] !== num) {
          ;(newRow as Record<string, unknown>)[rowKey] = num
          mutated = true
        }
      }
      return newRow
    })
    if (mutated) {
      hfRecomputeRef.current = true
      setRows(nextRows)
    }
  }, [rows, formulas])

  // Codex P1 #581 iter-4 fix: PURE függvény ami sync visszaadja a next rows array-t
  // (vagy null ha no-op). Ezáltal a save/dispatch szinkronoun tud serializálni
  // anélkül, hogy React state batching race-elne (a setRows async, ezért a
  // következő JSON.stringify(rows) még a régi snapshot-ot látja).
  const computeCellCommit = useCallback((
    currentRows: MainRateRow[],
    rowIdx: number,
    col: keyof MainRateRow,
    raw: string,
  ): MainRateRow[] | null => {
    if (col === 'currency' || col === 'crossBase' || col === 'crossSettlement') return null
    if (col === 'settlement' && currentRows[rowIdx]?.crossBase) return null
    const trimmed = raw.trim()

    // v2.5.61 (HyperFormula): "=" prefix-szel kezdődő input → képlet. Tároljuk
    // a képletet a `formulas` map-be, és a `rows`[col] értéket egyelőre 0-ra
    // állítjuk — a HyperFormula re-evaluation effect majd kitölti.
    const formulaKey = `${rowIdx}.${col}`
    const isFormulaCol = FORMULA_COLUMNS.includes(col as FormulaColumn)
    if (isFormulaCol && trimmed.startsWith('=')) {
      // Képlet rögzítés — async setFormulas + setRows(0) ami triggereli a
      // HyperFormula useEffect-et, ami visszaolvassa a számolt értéket.
      setFormulas(prev => ({ ...prev, [formulaKey]: trimmed }))
      const next = [...currentRows]
      next[rowIdx] = { ...next[rowIdx]!, [col]: 0 } // placeholder, HF újraszámolja
      return next
    }
    // Ha korábban képlet volt itt, de most fix számot ad meg a user, töröljük
    // a képletet a map-ből.
    if (isFormulaCol && formulas[formulaKey]) {
      setFormulas(prev => {
        const copy = { ...prev }
        delete copy[formulaKey]
        return copy
      })
    }

    let nextValue: number
    if (trimmed === '') {
      nextValue = 0
    } else {
      const parsed = Number.parseFloat(trimmed.replace(/\s/g, '').replace(',', '.'))
      if (Number.isNaN(parsed)) return null
      nextValue = parsed
    }
    const currentValue = currentRows[rowIdx]?.[col]
    // Codex P2 #581 iter-3: no-op ha érték nem változott
    if (typeof currentValue === 'number' && currentValue === nextValue) return null
    const next = [...currentRows]
    next[rowIdx] = { ...next[rowIdx]!, [col]: nextValue }
    return next
  }, [formulas])

  // Side-effect wrapper: aszinkron állapotfrissítés (NEM használható azonnali serialization-höz).
  const commitCell = useCallback((rowIdx: number, col: keyof MainRateRow, raw: string) => {
    if (!canEdit) return
    const next = computeCellCommit(rows, rowIdx, col, raw)
    if (next) {
      setRows(next)
      setDirty(true)
    }
  }, [canEdit, rows, computeCellCommit])

  const focusCell = useCallback((rowIdx: number, col: keyof MainRateRow, currentValue: number, decimals: number) => {
    setActiveCell({ rowIdx, col })
    // v2.5.61: ha a cellához tartozik képlet, azt mutatjuk az input-ban (NEM
    // a számolt értéket), így a user szerkeszteni tudja. A blurCell után újra
    // kalkulálódik a HyperFormula-val.
    const formulaKey = `${rowIdx}.${col as string}`
    const formula = formulas[formulaKey]
    if (formula) {
      setEditBuffer(formula)
    } else {
      setEditBuffer(currentValue ? currentValue.toFixed(decimals) : '')
    }
  }, [formulas])

  const blurCell = useCallback((rowIdx: number, col: keyof MainRateRow) => {
    commitCell(rowIdx, col, editBuffer)
    setActiveCell(null)
    setEditBuffer('')
  }, [commitCell, editBuffer])

  // Codex P1 #581 iter-4 fix: flushActiveCell SYNC visszaadja a "rows to save"-et.
  // Ha aktív cella van → computeCellCommit-tal kalkulálja a next-et, setRows-t hív
  // (state update aszinkron), és VISSZAADJA a next array-t azonnal.
  // Ha nincs aktív cella vagy no-op → a current rows-t adja vissza.
  // A caller (saveLocally, dispatchToServer) ezzel azonnal tud serializálni.
  const flushActiveCell = useCallback((): MainRateRow[] => {
    if (!activeCell || !canEdit) return rows
    const next = computeCellCommit(rows, activeCell.rowIdx, activeCell.col, editBuffer)
    setActiveCell(null)
    setEditBuffer('')
    if (next) {
      setRows(next)
      setDirty(true)
      return next  // SYNC return — caller serializes the just-committed value
    }
    return rows
  }, [activeCell, canEdit, rows, computeCellCommit, editBuffer])

  // Codex P2 #581 iter-6 fix: saveLocally visszaadja boolean-t (true=success, false=fail).
  // Caller (CSOPORTOK navigate) csak success esetén navigáljon, hogy pending edit ne vesszen el
  // low-storage / private-browser környezetben.
  const saveLocally = useCallback((): boolean => {
    const rowsToSave = flushActiveCell()
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(rowsToSave))
      // v2.5.61: a képletek is perzisztálódnak külön kulccsal, hogy a következő
      // mount-kor a focusCell ugyanazt a képlet-kifejezést tudja megmutatni.
      localStorage.setItem(FORMULA_STORAGE_KEY, JSON.stringify(formulas))
      lastSavedAt.current = new Date().toISOString()
      setDirty(false)
      toast.success('Mentve', 'Főlap helyileg mentve (localStorage)')
      return true
    } catch (e) {
      logger.error('MainRateSheetPage', 'Storage save failed', e)
      toast.error('Hiba', 'Helyi mentés sikertelen (privát böngészés / quota?)')
      return false
    }
  }, [flushActiveCell])

  // Phase 2 wiring (Kosa Zoltan 2026-05-18): a komponens MOUNT-jakor letoltjuk a
  // legujabb publikalt arfolyamokat a szerverrol (Aktiv ExchangeRateMaster
  // rekordok) es feltoltjuk a localStorage cache-t. Igy a tabla NEM ures - a
  // foertektaros mindig a kozponti legutolso adatot latja, NEM csak localStorage
  // snapshot-ot. Ez teszi az EXE-bol thin client-et a kozponti rate-engine ele.
  useEffect(() => {
    let cancelled = false
    setServerSyncState('loading')
    const loadServerData = async () => {
      try {
        // 1. Lehúzzuk a currencies tablat (currencyCode -> currencyId mapping)
        const currencies = await currencyApi.list()
        if (cancelled) return
        const codeToId = new Map<string, number>()
        for (const c of currencies) {
          codeToId.set(c.code, c.id)
        }
        currencyIdMapRef.current = codeToId

        // 2. Lehuzzuk az aktiv (publikalt) torzs arfolyamokat
        const serverRates = await exchangeRateMasterApi.listActivePublished()
        if (cancelled) return

        // 3. Merge: szerver-ratek a MainRateRow oszlopaiba (currencyCode alapjan)
        const cachedRows = loadFromStorage()
        const codeToServerRate = new Map<string, ExchangeRateMaster>()
        for (const sr of serverRates) {
          // currencyCode lehet hianyzo a backendben - keressuk vissza a mapbol
          let code = sr.currencyCode
          if (!code) {
            const codeMatch = Array.from(codeToId.entries()).find(([_c, id]) => id === sr.currencyId)
            code = codeMatch?.[0]
          }
          if (code) codeToServerRate.set(code, sr)
        }

        // Codex+Copilot PR #687: ne irjuk felul a user altal in-flight szerkesztett
        // row-okat. Ha a `dirty` flag mar igaz mire a szerver-resp visszater, a user
        // mar editelt - csak a snapshot-ot rogzitjuk, a row-okat erintetlen hagyjuk.
        const snapshot = new Map<string, { weakMultiBuy: number; weakMultiSell: number; settlement: number }>()
        for (const [code, sr] of codeToServerRate.entries()) {
          snapshot.set(code, {
            weakMultiBuy: Number(sr.baseBuyRate) || 0,
            weakMultiSell: Number(sr.baseSellRate) || 0,
            settlement: Number(sr.officialRate) || 0,
          })
        }
        serverSnapshotRef.current = snapshot

        if (dirty) {
          // User mar editelt - csak a snapshot kerul, a rows erintetlen marad
          setServerSyncState('online')
          setServerLastSyncAt(new Date().toISOString())
          logger.info('MainRateSheetPage', `Server sync (user editing - rows preserved): ${serverRates.length} aktiv arfolyam`)
          return
        }

        const mergedRows = cachedRows.map((row) => {
          const sr = codeToServerRate.get(row.currency)
          if (!sr) return row // nincs szerver-rekord erre a valutara
          // Backend mapping: baseBuyRate -> E (weakMultiBuy), baseSellRate -> F,
          // officialRate -> A (settlement)
          return {
            ...row,
            settlement: Number(sr.officialRate) || row.settlement,
            weakMultiBuy: Number(sr.baseBuyRate) || row.weakMultiBuy,
            weakMultiSell: Number(sr.baseSellRate) || row.weakMultiSell,
          }
        })
        setRows(mergedRows)
        setServerSyncState('online')
        setServerLastSyncAt(new Date().toISOString())

        // Copilot PR #687: persist merged rows to localStorage for true offline fallback
        try {
          localStorage.setItem(STORAGE_KEY, JSON.stringify(mergedRows))
        } catch (storageErr) {
          logger.error('MainRateSheetPage', 'Failed to persist server-merged rows to localStorage', storageErr)
          // NEM doblunk - a memoriaban levo state-tel mukodunk tovabb
        }

        logger.info('MainRateSheetPage', `Server sync: ${serverRates.length} aktiv arfolyam betoltve + cached`)
      } catch (err) {
        if (cancelled) return
        logger.error('MainRateSheetPage', 'Server sync failed - fallback localStorage cache', err)
        // Sourcery PR #687: explicit reload localStorage cache, ne fugjunk a kezdeti hydratation-tol
        setRows(loadFromStorage())
        setServerSyncState('offline')
        toast.warning('Offline', 'Szerver nem elérhető — helyi cache betöltve')
      }
    }
    void loadServerData()
    return () => { cancelled = true }
    // dirty intentional kihagyva a dep-listabol - csak az elso mount-on syncolunk,
    // a dirty-t a runtime-ban olvasunk be a useEffect inside-ban
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Auto-save on dirty + 1 sec debounce
  useEffect(() => {
    if (!dirty) return
    const timer = setTimeout(() => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(rows))
        lastSavedAt.current = new Date().toISOString()
        setDirty(false)
      } catch (e) {
        logger.error('MainRateSheetPage', 'Auto-save failed', e)
      }
    }, 1000)
    return () => clearTimeout(timer)
  }, [dirty, rows])

  const dispatchToServer = useCallback(async () => {
    if (!canEdit) {
      toast.warning('Olvasás-csak', 'Csak főértéktáros / ügyvezető küldhet ki árfolyamot')
      return
    }

    // Sourcery PR #687: short-circuit ha nincs szerver-szinkron - kulonben az osszes
    // valutara "nincs ID" hibat generalna a publish loop.
    if (serverSyncState !== 'online' || currencyIdMapRef.current.size === 0) {
      toast.warning(
        'Szerver nem elérhető',
        'Ne küldje ki, amíg a kezdeti szerver-szinkron nem fejeződött be (Online indikátor).',
      )
      return
    }

    // Phase 2 (Kosa Zoltan 2026-05-18 directive): a thin client a szerveren levo
    // ExchangeRateMaster aktiv arfolyamokhoz kepest CSAK A MODOSITOTT valutakat
    // kuldi (diff-alapu). Ezzel elkeruljuk a "ujra-publish all" anti-pattern-t.
    const rowsToDispatch = flushActiveCell()
    setPublishing(true)

    // 1. Mentes localStorage cache-be - kulon try-block (Sourcery PR #687)
    // hogy a quota/private-browsing hiba NE legyen szerver-network hibanak jelolt
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(rowsToDispatch))
      lastSavedAt.current = new Date().toISOString()
    } catch (storageErr) {
      logger.error('MainRateSheetPage', 'localStorage cache write failed', storageErr)
      toast.error(
        'Tárolási hiba',
        'A helyi gyorsítótár mentése nem sikerült (böngésző tárhely / privát mód). A szerver-publikálás MÉG meg fog történni.',
      )
      // NEM dobunk, folytatjuk a szerver-publikalast
    }

    // 2. Codex+Copilot PR #687: csak az aktualisan MODOSITOTT row-okat kuldjuk
    // (a serverSnapshotRef diff-jevel), NEM az osszes nem-nulla rate-eu valutat.
    // Ezzel elkeruljuk a duplikalt szerver-publish-eket.
    // Plus: cross-rate (crossBase != null) sorokra a `settlement` szamitott ertek
    // a `crossSettlement` mezobol jon (enrichedRows logika replikalva itt).
    const snapshot = serverSnapshotRef.current
    const eurRowD = rowsToDispatch.find((r) => r.currency === 'EUR')
    const usdRowD = rowsToDispatch.find((r) => r.currency === 'USD')
    const eurS = eurRowD?.settlement ?? 0
    const usdS = usdRowD?.settlement ?? 0

    const modifiedRows = rowsToDispatch.flatMap((r) => {
      if (r.weakMultiBuy <= 0 || r.weakMultiSell <= 0) return []
      // Cross-rate row: settlement a G oszlop szamitott ertekebol jon
      const effectiveSettlement = r.crossBase
        ? computeCrossSettlement(r, eurS, usdS)
        : r.settlement
      const snap = snapshot.get(r.currency)
      // Ha nincs szerver-snapshot, MINDIG kuldjuk (uj valuta)
      // Ha van, csak akkor kuldjuk ha mod-detected (abs delta > 0.0001)
      if (snap) {
        const dB = Math.abs(r.weakMultiBuy - snap.weakMultiBuy)
        const dS = Math.abs(r.weakMultiSell - snap.weakMultiSell)
        const dE = Math.abs(effectiveSettlement - snap.settlement)
        if (dB < 0.0001 && dS < 0.0001 && dE < 0.0001) return []
      }
      return [{ row: r, effectiveSettlement }]
    })

    if (modifiedRows.length === 0) {
      toast.warning(
        'Nincs változás',
        'A táblázat azonos a központi szerver utolsó publikált állapotával — nincs mit szétküldeni.',
      )
      setPublishing(false)
      return
    }

    // 3. Szerver-publikalas - kulon try-block (Sourcery PR #687)
    try {
      const codeToId = currencyIdMapRef.current
      const errors: string[] = []
      let publishedCount = 0

      for (const { row, effectiveSettlement } of modifiedRows) {
        const currencyId = codeToId.get(row.currency)
        if (!currencyId) {
          errors.push(`${row.currency}: nincs ID a currencies táblában`)
          continue
        }
        const payload: CreateMasterRateRequest = {
          currencyId,
          baseBuyRate: row.weakMultiBuy,
          baseSellRate: row.weakMultiSell,
          officialRate: effectiveSettlement || undefined,
          notes: `Főlap szétküldés (${new Date().toISOString()})`,
        }
        try {
          // Create DRAFT -> Approve -> Publish + automatikus elosztas
          const draft = await exchangeRateMasterApi.create(payload)
          await exchangeRateMasterApi.approve(draft.id)
          await exchangeRateMasterApi.publish(draft.id)
          publishedCount += 1
          // Snapshot frissites: a sikeres publikalas utan a snap === aktualis
          snapshot.set(row.currency, {
            weakMultiBuy: row.weakMultiBuy,
            weakMultiSell: row.weakMultiSell,
            settlement: effectiveSettlement,
          })
        } catch (e) {
          const msg = e instanceof Error ? e.message : String(e)
          errors.push(`${row.currency}: ${msg}`)
          logger.error('MainRateSheetPage', `Publish failed for ${row.currency}`, e)
        }
      }

      setDirty(false)
      setServerSyncState('online')
      setServerLastSyncAt(new Date().toISOString())

      if (errors.length === 0) {
        toast.success(
          'Szétküldve',
          `${publishedCount}/${modifiedRows.length} módosított valuta publikálva és szétküldve a pénztáraknak.`,
        )
      } else if (publishedCount > 0) {
        toast.warning(
          'Részben sikeres',
          `${publishedCount}/${modifiedRows.length} publikálva. Hibák: ${errors.slice(0, 3).join('; ')}`,
        )
      } else {
        toast.error(
          'Sikertelen',
          `Egyetlen valuta sem ment ki. Első hiba: ${errors[0] ?? 'ismeretlen'}`,
        )
        setServerSyncState('offline')
      }
    } catch (e) {
      // Csak szerver/network hiba - localStorage mar a kulon try-block-on tul vagyunk
      logger.error('MainRateSheetPage', 'Server dispatch failed', e)
      toast.error('Hálózati hiba', 'Szerver nem elérhető — kérlek próbáld újra.')
      setServerSyncState('offline')
    } finally {
      setPublishing(false)
    }
  }, [canEdit, flushActiveCell, serverSyncState])

  const formatCell = (val: number, decimals = 2): string => {
    if (!val || val === 0) return '0'
    return val.toFixed(decimals)
  }

  const isJpy = (currency: string) => currency === 'JPY'

  return (
    <div className="h-[calc(100vh-8rem)] flex flex-col bg-slate-50">
      {/* === HEADER === */}
      <div className="flex items-center justify-between bg-white px-4 py-2 border-b border-slate-200 shadow-sm">
        <div className="flex items-center gap-3">
          <h1 className="text-base font-bold text-slate-900">Főlap — Elszámoló árfolyamok</h1>
          <span className="text-xs text-slate-500 px-2 py-0.5 bg-slate-100 rounded">0-s lap (Alap)</span>
          {dirty && <span className="text-xs text-orange-600 font-medium">● módosítva</span>}
          {/* Phase 2: kozponti szerver szinkron-allapot indikator */}
          {serverSyncState === 'loading' && (
            <span className="text-xs text-blue-600 flex items-center gap-1">
              <Wifi size={12} className="animate-pulse" /> Szerver szinkron…
            </span>
          )}
          {serverSyncState === 'online' && (
            <span className="text-xs text-green-700 flex items-center gap-1" title={serverLastSyncAt ?? ''}>
              <Wifi size={12} /> Online (kp. szerver)
            </span>
          )}
          {serverSyncState === 'offline' && (
            <span className="text-xs text-red-600 flex items-center gap-1">
              <WifiOff size={12} /> Offline — helyi cache
            </span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowHelp(true)}
            className="flex items-center gap-1 px-2 py-1 text-xs border border-slate-300 rounded hover:bg-slate-100"
            title="Kitöltési segítség"
          >
            <Info size={13} /> Segítség
          </button>
          <button
            onClick={saveLocally}
            disabled={!dirty || !canEdit}
            className="flex items-center gap-1 px-2 py-1 text-xs border border-slate-300 rounded hover:bg-slate-100 disabled:opacity-40"
          >
            <Save size={13} /> Mentés
          </button>
        </div>
      </div>

      {/* === MENU BAR (felső sor menüpontok) === */}
      <div className="flex items-center gap-1 bg-slate-200 border-b border-slate-300 px-2 py-1">
        <button
          onClick={() => {
            // Codex P1 #581 iter-5: navigate előtt flush + persist aktív cella editBuffer-ét.
            // Codex P2 #581 iter-6: csak sikeres save után navigate-eljünk, hogy a pending
            // edit ne vesszen el low-storage / private-browser környezetben.
            if (saveLocally()) {
              navigate('/rates/creation')
            }
            // Ha save fail → user a Mentés Hiba toast-ot látja, marad a főlapon, megoldhatja.
          }}
          className="px-3 py-1 text-xs font-medium bg-white border border-slate-400 rounded hover:bg-slate-50 flex items-center gap-1"
        >
          <ArrowRight size={12} /> CSOPORTOK KARBANTARTÁSA
        </button>
        <button
          onClick={() => void dispatchToServer()}
          disabled={publishing || !canEdit}
          className="px-3 py-1 text-xs font-medium bg-green-600 text-white border border-green-700 rounded hover:bg-green-700 disabled:opacity-40 flex items-center gap-1"
        >
          <Send size={12} /> ÁRFOLYAMOK SZÉTKÜLDÉSE
        </button>
        <button
          onClick={() => toast.info('Internet címek', 'Hamarosan elérhető funkció.')}
          disabled
          title="Hamarosan elérhető funkció"
          className="px-3 py-1 text-xs font-medium bg-white border border-slate-300 rounded text-slate-400 cursor-not-allowed flex items-center gap-1"
        >
          <Globe size={12} /> INTERNET CÍMEK KARBANTARTÁSA
        </button>
        {/* V238 (2026-05-19) Valutakezelő — admin only (foertekitaros / ugyvezeto) */}
        {canEdit && (
          <button
            onClick={() => setShowCurrencyManager(true)}
            className="px-3 py-1 text-xs font-medium bg-white border border-slate-400 rounded hover:bg-slate-50 flex items-center gap-1"
            data-testid="open-currency-manager"
            title="Valutakezelő — új valuta hozzáadása / inaktiválás (audit log)"
          >
            <Settings size={12} /> VALUTAKEZELŐ
          </button>
        )}
        <div className="flex-1" />
        <button
          onClick={() => {
            // Codex P2 #581 iter-5: window.close() modern browser-ekben ignored.
            // Codex P2 #581 iter-7 fix: dirty-check ELŐTT flush+detect, mert egy focused cell
            // még NEM commitált (blur sem futott) → dirty=false félrevezetne, confirm dialog
            // NEM jönne elő, user veszít pending edit-et.
            const hadPendingBuffer = activeCell !== null
            flushActiveCell()
            const hasUnsavedChanges = dirty || hadPendingBuffer
            if (hasUnsavedChanges && !confirm('Vannak nem mentett módosítások. Biztosan kilépsz mentés nélkül?')) return
            useAuthStore.getState().logout()
            navigate('/login')
          }}
          className="px-3 py-1 text-xs font-medium bg-white border border-slate-400 rounded hover:bg-red-50 hover:border-red-300 flex items-center gap-1"
        >
          <LogOut size={12} /> KILÉPÉS
        </button>
      </div>

      {/* === RATE TABLE === */}
      <div className="flex-1 overflow-auto px-2 py-2">
        <table className="w-full text-xs border-collapse bg-white shadow-sm rounded overflow-hidden">
          <thead className="sticky top-0 bg-slate-200 border-b-2 border-slate-400">
            <tr className="text-[10px] uppercase font-bold text-slate-700">
              <th className="border border-slate-300 px-2 py-1 bg-orange-100" colSpan={1}>A — Elszámoló</th>
              <th className="border border-slate-300 px-2 py-1 bg-blue-50">B — OTP</th>
              <th className="border border-slate-300 px-2 py-1 bg-blue-50">C — Segéd</th>
              <th className="border border-slate-300 px-2 py-1 bg-slate-300">D — Valuta</th>
              <th className="border border-slate-300 px-2 py-1 bg-yellow-100" colSpan={2}>E-F — Gyenge multis (vét/elad)</th>
              <th className="border border-slate-300 px-2 py-1 bg-amber-50">G — Kereszt számolt</th>
              <th className="border border-slate-300 px-2 py-1 bg-pink-50">H — Kereszt forrás</th>
              <th className="border border-slate-300 px-2 py-1 bg-slate-100">I — Nagybani</th>
            </tr>
          </thead>
          <tbody>
            {enrichedRows.map((row, idx) => {
              const decimals = isJpy(row.currency) ? 3 : 2
              const aIsAuto = !!row.crossBase
              const isActive = (col: keyof MainRateRow) => activeCell?.rowIdx === idx && activeCell.col === col
              const cellClass = (col: keyof MainRateRow, baseClass: string) =>
                `${baseClass} ${isActive(col) ? 'ring-2 ring-blue-500' : ''}`
              // EditableInput closure: while focused, show editBuffer (raw user input);
              // when blurred, parse + commit. Codex P1 #581 fix.
              const renderInput = (col: keyof MainRateRow, currentVal: number, decimalsFor: number, classes: string, placeholder?: string) => (
                <input
                  type="text"
                  value={isActive(col) ? editBuffer : (currentVal ? currentVal.toFixed(decimalsFor) : '0')}
                  onChange={(e) => setEditBuffer(e.target.value)}
                  onFocus={() => focusCell(idx, col, currentVal, decimalsFor)}
                  onBlur={() => blurCell(idx, col)}
                  className={classes}
                  disabled={!canEdit}
                  placeholder={placeholder}
                />
              )
              return (
                <tr key={row.currency} className="hover:bg-slate-50">
                  {/* A — Elszámoló (piros, módosítható HA NEM cross-base) */}
                  <td className={cellClass('settlement', `border border-slate-300 px-2 py-1 text-right font-mono font-bold ${aIsAuto ? 'text-amber-700 bg-amber-50/40 italic' : 'text-red-700 bg-orange-50/50'}`)}>
                    {aIsAuto ? (
                      <span title="Auto-derived from G column (cross calculation)">
                        {formatCell(row.settlement, decimals)}
                      </span>
                    ) : renderInput('settlement', row.settlement, decimals, 'w-full bg-transparent text-right font-mono font-bold text-red-700 focus:outline-none')}
                  </td>
                  {/* B — OTP (kék segéd) */}
                  <td className={cellClass('otp', 'border border-slate-300 px-2 py-1 text-right font-mono text-blue-800 bg-blue-50/30')}>
                    {renderInput('otp', row.otp, decimals, 'w-full bg-transparent text-right font-mono text-blue-800 focus:outline-none')}
                  </td>
                  {/* C — Segéd (kék) */}
                  <td className={cellClass('helper', 'border border-slate-300 px-2 py-1 text-right font-mono text-blue-700 bg-blue-50/20')}>
                    {renderInput('helper', row.helper, decimals, 'w-full bg-transparent text-right font-mono text-blue-700 focus:outline-none')}
                  </td>
                  {/* D — Valuta (VÉDETT, fekete bold) */}
                  <td className="border border-slate-300 px-2 py-1 text-center font-mono font-bold text-slate-900 bg-slate-100">
                    {row.currency}
                  </td>
                  {/* E — Gyenge multis vétel (sárga) */}
                  <td className={cellClass('weakMultiBuy', 'border border-slate-300 px-2 py-1 text-right font-mono text-amber-900 bg-yellow-50')}>
                    {renderInput('weakMultiBuy', row.weakMultiBuy, decimals, 'w-full bg-transparent text-right font-mono text-amber-900 focus:outline-none')}
                  </td>
                  {/* F — Gyenge multis eladás (sárga) */}
                  <td className={cellClass('weakMultiSell', 'border border-slate-300 px-2 py-1 text-right font-mono text-amber-900 bg-yellow-50')}>
                    {renderInput('weakMultiSell', row.weakMultiSell, decimals, 'w-full bg-transparent text-right font-mono text-amber-900 focus:outline-none')}
                  </td>
                  {/* G — Kereszt számolt (read-only, barna) */}
                  <td className="border border-slate-300 px-2 py-1 text-right font-mono text-amber-700 bg-amber-50/40 italic">
                    {row.crossBase ? formatCell(row.crossSettlement, decimals) : '—'}
                  </td>
                  {/* H — Kereszt forrás (rózsa, 6 tizedes) — csak crossBase row */}
                  <td className={cellClass('crossRate', 'border border-slate-300 px-2 py-1 text-right font-mono text-pink-800 bg-pink-50/40')}>
                    {row.crossBase
                      ? renderInput('crossRate', row.crossRate, 6, 'w-full bg-transparent text-right font-mono text-pink-800 focus:outline-none', `${row.crossBase}/${row.currency}`)
                      : <span className="text-slate-400">—</span>}
                  </td>
                  {/* I — Nagybani (szürke, opcionális) */}
                  <td className={cellClass('wholesale', 'border border-slate-300 px-2 py-1 text-right font-mono text-slate-600 bg-slate-50')}>
                    {renderInput('wholesale', row.wholesale, decimals, 'w-full bg-transparent text-right font-mono text-slate-600 focus:outline-none')}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>

        {/* === LEGEND / INFO === */}
        <div className="mt-4 p-3 bg-white border border-slate-300 rounded text-xs text-slate-700 space-y-1">
          <div className="font-bold text-slate-900 mb-1">Oszlop magyarázatok:</div>
          <div><b>A — Elszámoló:</b> Itt állítjuk az elszámoló árfolyamokat. Minden munkalapon ugyanazok az értékek a J oszlopban. EUR/USD/GBP/CHF (4 főváluta) napközben kézzel állítva, többi képlettel.</div>
          <div><b>B — OTP:</b> OTP közzétett vételi árfolyamok (segédérték az alap vételi/eladási árfolyamok megállapítására). Forrás: <a href="https://www.otpbank.hu/portal/hu/Arfolyamok/OTP" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">otpbank.hu</a></div>
          <div><b>D — Valuta nem:</b> ISO kód (VÉDETT, nem módosítható).</div>
          <div><b>E-F — Gyenge multis árfolyamok:</b> Pár munkacsoportban módosítás nélkül áthívva, pár helyen képlet alapja.</div>
          <div><b>G — Kereszt számolt:</b> Az EUR/USD keresztárfolyam alapú elszámoló (számolt: A oszlop EUR vagy USD értéke / H oszlop érték). Pl. CZK A = EUR settlement / EUR/CZK kereszt. Read-only, automatikusan követi az A oszlop EUR/USD változását.</div>
          <div><b>H — Kereszt forrás:</b> Reggel/napközben beírt EUR vagy USD kereszt árfolyam (forrás: <a href="https://www.xe.com/currencyconverter/" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">xe.com</a>). Min. 6 tizedes pontosság. EUR-tartozó: CZK, PLN, RON, RSD, BGN, BAM, TRY. USD-tartozó: ILS, UAH, RUB, CNY, THB, BRL, MXN, NZD.</div>
          <div><b>I — Nagybani:</b> Jelenleg nem használt (Phase 2).</div>
          <div className="mt-2 text-slate-500"><b>Phase 1 (MVP):</b> Lokális mentés (localStorage). <b>Phase 2:</b> Backend persistence + reaktív adatfolyam munkacsoportokhoz (A → minden mcs J oszlopa).</div>
        </div>
      </div>

      {/* === HELP MODAL === */}
      {showHelp && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" onClick={() => setShowHelp(false)}>
          <div className="bg-emerald-50 border-2 border-emerald-700 rounded-lg p-6 max-w-2xl w-full" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-bold text-emerald-900 text-center mb-4">SEGÍTSÉG AZ ÁRFOLYAM SZERKESZTŐ PROGRAMHOZ</h2>
            <div className="bg-white border border-emerald-300 rounded p-3 mb-4">
              <div className="font-bold text-sm mb-2 text-center">FÜGGVÉNYEK KEZELÉSE</div>
              <table className="w-full text-xs">
                <tbody>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300 w-24">A — I</td><td className="py-1 px-2 italic">Azonos valutanem oszlopa az alap-árfolyam táblázatban (0-s lap)</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">J — Q</td><td className="py-1 px-2 italic">Azonos valutanem oszlopa az aktuális munkacsoportban</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">!Axxx</td><td className="py-1 px-2 italic">Más valutanem bármely oszlopa (A=oszlop, xxx=valutanem). Pl. !AEUR = A oszlop EUR sora</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">#CCA</td><td className="py-1 px-2 italic">Azonos valutanem egy másik csoportból (A=oszlop, xxx=valutanem)</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">Műveletek</td><td className="py-1 px-2 italic">+ - * / és zárójel (a zárójel kötelező eltérő prioritású műveletek esetén)</td></tr>
                </tbody>
              </table>
            </div>
            <div className="bg-white border border-emerald-300 rounded p-3 mb-4 text-xs space-y-2">
              <div><b>Adatmásolás:</b> CTRL + bal egér gomb a másolandó terület első adatának kijelöléséhez (LILA KERET) → kijelölés befejezése bal egér gomb lenyomásával (ZÖLD KERET)</div>
              <div><b>Adatlehúzás:</b> Az alap-árfolyam táblán egy, a munkacsoportoknál több oszlop adata húzható le. (Phase 2)</div>
              <div><b>Felbukkanó menük:</b> jobb egér gomb (Phase 2)</div>
            </div>
            <div className="text-center">
              <button
                onClick={() => setShowHelp(false)}
                className="px-4 py-2 bg-emerald-700 text-white rounded hover:bg-emerald-800 font-medium"
              >
                Vissza a munkához
              </button>
            </div>
          </div>
        </div>
      )}

      {/* V238 (2026-05-19) — Valutakezelő modal: új valuta hozzáadása, aktiválás/deaktiválás. */}
      <CurrencyManagerModal
        isOpen={showCurrencyManager}
        onClose={() => setShowCurrencyManager(false)}
        onCurrencyChanged={() => {
          // A backend Currency tabla változott → értesítjük a felhasználót hogy
          // a Főlap új-betöltést igényel (page reload vagy app restart). MVP:
          // simán toast, dinamikus row-frissítés v2.5.62-be jön.
          toast.info(
            'Valutakezelő',
            'Egy valuta módosult. A változás a Főlapon a következő app-indítás után jelenik meg.',
          )
        }}
      />
    </div>
  )
}
