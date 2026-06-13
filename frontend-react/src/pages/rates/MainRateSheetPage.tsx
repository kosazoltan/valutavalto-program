import { useState, useEffect, useCallback, useMemo, useRef, type KeyboardEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { Send, LogOut, Globe, Save, ArrowRight, Info, Wifi, WifiOff, Settings, CheckCircle2 } from 'lucide-react'
import { nextEditableCell, EDITABLE_ORDER, type EditableCol, type NavKey } from './sheetNavigation'
import {
  isFormula,
  evaluateFormula,
  FORMULA_STORAGE_KEY,
  type ColValues,
  type FormulaContext,
} from './mainSheetFormula'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAuthStore } from '../../stores/authStore'
import { exchangeRateMasterApi, type ExchangeRateMaster } from '../../services/api/exchangeRateMaster'
// FK05 (FR-1): a Főlap szétküldése is a munkacsoport-publish útvonalon megy.
import { publishAllWorkgroups, summarizePublishAll } from './publishAllWorkgroups'
import { exchangeRateApi } from '../../services/api/exchange-rates'
import { getCrossBase, useCurrencyCatalog } from '../../hooks/useCurrencyCatalog'
import CurrencyManagerModal from './components/CurrencyManagerModal'
import { arfolyamInternetLinkApi, type ArfolyamInternetLink } from '../../services/api/arfolyamInternetLinks'
import { computeCrossSettlement, resolveSettlement, crossSettlementStaysAuto } from './mainSheetRules'
import { validateRateDirection } from './rateDirectionRules'
import {
  euaDeviationExceeds, computeEuaRate, raiffeisenBandViolations,
  RAIFFEISEN_BAND_PERCENT, type BandSource,
} from './rfmRules'

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
  settlementManual?: boolean // 2026-05-20: kereszt-valutánál is kézzel felülírható az A (true=kézi, A=G auto ha false)
}

// FK04 (FR-2): a korábbi hard-coded DEFAULT_CURRENCIES konstans MEGSZŰNT — a sorlista
// tagsága és sorrendje a currency táblából jön (useCurrencyCatalog hook, V317 kanonikus
// display_order). A kereszt-alap térkép a hook mellől importált CROSS_BASE_MAP
// (getCrossBase) — az értékek a régi DEFAULT_CURRENCIES[].crossBase 1:1 átemelése.

// v2.5.61: a régi localStorage cache-eket szűrjük, hogy a 6 törölt valuta
// ne maradjon a UI-on (defenzív, ha a user már elindította a régi v2.5.60-at).
// TODO (FK04): eltávolítható, ha minden éles DB lefuttatta a V317+ migrációt és a
// kollégák kliensei már a katalógus-alapú Főlapot futtatják.
// + RUB (2026-06-12 user-direktíva, V319): nem forgalmazott valuta — a defenzív szűrő
// a localStorage-ben ragadt régi cache-sorokból is kiszedi.
const REMOVED_CURRENCIES = new Set(['DKK', 'NOK', 'SEK', 'HRK', 'BGN', 'RCH', 'RUB'])

const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'

// FR-HL-04/05 (b3-arfolyam-karbantarto-hibalista): a 0-ás lapon (és offline) KIZÁRÓLAG az aktív
// valuták jelenhetnek meg. A szerverről lekért INAKTÍV valuta-kódokat ide persistáljuk, hogy a
// Valutakezelőben inaktivált valuta offline (szerver nélküli) betöltéskor is szűrve maradjon.
// Online módban a szűrés inherens: a katalógus (useCurrencyCatalog) csak aktív ∪ EUA-t ad (FK04).
const INACTIVE_STORAGE_KEY = 'arfolyamkeszito.mainSheet.inactiveCurrencies.v1'

export function loadInactiveCurrencyCodes(): Set<string> {
  try {
    const raw = localStorage.getItem(INACTIVE_STORAGE_KEY)
    if (!raw) return new Set<string>()
    const arr = JSON.parse(raw) as string[]
    return Array.isArray(arr) ? new Set(arr) : new Set<string>()
  } catch {
    return new Set<string>()
  }
}

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

/**
 * FK04: offline/cache-betöltés — KIZÁRÓLAG a korábban perzisztált sorok (értékekkel),
 * a véglegesen törölt + (szerver szerint) inaktív valuták kiszűrésével. A sorlista
 * TAGSÁGÁT online módban a currency tábla adja (buildRowsFromCatalog); a cache itt
 * csak az utolsó ismert állapot offline megőrzésére szolgál.
 */
export function loadFromStorage(): MainRateRow[] {
  // FR-HL-04/05: a véglegesen törölt ÉS a (szerver szerint) INAKTÍV valutákat is kiszűrjük.
  const inactive = loadInactiveCurrencyCodes()
  const excluded = (code: string) => REMOVED_CURRENCIES.has(code) || inactive.has(code)
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw) as MainRateRow[]
    return parsed.filter(r => !excluded(r.currency))
  } catch (e) {
    logger.error('MainRateSheetPage', 'Storage load failed', e)
    return []
  }
}

/**
 * FK04 (FR-2, FR-3): a Főlap sorainak felépítése a currency-katalógusból.
 * - tagság + sorrend: a katalógus (displayOrder szerint rendezett, aktív ∪ EUA);
 * - cella-ÉRTÉKEK: a localStorage cache-ből, valutakód szerint párosítva;
 * - cache-ben lévő, de katalógusból hiányzó (inaktivált) valuta sora NEM jelenik meg;
 * - katalógusban új (cache-ben még nem látott) valuta üres sorral jelenik meg, a
 *   helyes displayOrder pozícióban;
 * - crossBase: mindig a CROSS_BASE_MAP-ből (a cache-elt érték helyett — igazságforrás).
 */
export function buildRowsFromCatalog(
  catalog: Array<{ code: string }>,
  cachedRows: MainRateRow[],
): MainRateRow[] {
  const cachedByCode = new Map(cachedRows.map(r => [r.currency, r]))
  return catalog
    .filter(c => !REMOVED_CURRENCIES.has(c.code))
    .map(c => {
      const crossBase = getCrossBase(c.code)
      const cached = cachedByCode.get(c.code)
      return cached ? { ...cached, crossBase } : emptyRow(c.code, crossBase)
    })
}

// Oszlop-mapping. A 9 oszlop: A=settlement, B=otp, C=helper, D=currency (CSAK label),
// E=weakMultiBuy, F=weakMultiSell, G=crossSettlement (computed), H=crossRate, I=wholesale.
// D oszlop VÉDETT — nem fogad képletet, csak text label.
// 2026-05-26 (legacy képlet-motor): a Főlapon képletezhető ÉRTÉK-oszlopok = A, B, C, E, F.
// (D=ISO-címke védett; G/H=kereszt-auto változatlan; I/Nagybani NEM képletezhető — spec.)
const FORMULA_COLUMNS = ['settlement', 'otp', 'helper', 'weakMultiBuy', 'weakMultiSell'] as const
type FormulaColumn = typeof FORMULA_COLUMNS[number]
// Humanreadable oszlop-nevek a user-facing hibajelzéshez.
const COL_NAMES: Record<FormulaColumn, string> = {
  settlement: 'A — Elszámoló',
  otp: 'B — OTP',
  helper: 'C — Segéd',
  weakMultiBuy: 'E — Gyenge multis vétel',
  weakMultiSell: 'F — Gyenge multis eladás',
}

/**
 * Képlet-kulcs = `${valutakód}.${col}` (pl. `EUR.settlement`). Csak felhasználói képletek
 * tárolódnak (a legacy képlet-string).
 *
 * FK04 self-review P0: a korábbi `${rowIdx}.${col}` kulcs a katalógus-vezérelt (változó
 * tagságú/sorrendű) sorlistában instabil — egy közbeszúrt új valuta minden alatta lévő
 * sor indexét eltolta volna, és a mentett képletek NÉMÁN rossz valutára kerülnek.
 * A valutakód stabil azonosító.
 */
type FormulaMap = Record<string, string>

/**
 * FK04 legacy-migráció: a régi `${rowIdx}.${col}` kulcsú képleteket az AKKORI sorlista
 * (localStorage row-cache) alapján valutakód-kulcsra fordítjuk — a képletek a felhasználó
 * által utoljára LÁTOTT sorokhoz tartoznak, ezt a cache őrzi. Feloldhatatlan index →
 * a képletet eldobjuk (rossz sorra kerülő képlet rosszabb, mint a hiányzó).
 */
export function migrateLegacyFormulaKeys(
  parsed: Record<string, string>,
  cachedRows: Array<{ currency: string }>,
): FormulaMap {
  const migrated: FormulaMap = {}
  for (const [key, formula] of Object.entries(parsed)) {
    const dot = key.indexOf('.')
    if (dot <= 0) continue
    const head = key.slice(0, dot)
    const col = key.slice(dot + 1)
    if (/^\d+$/.test(head)) {
      const currency = cachedRows[Number(head)]?.currency
      if (currency) migrated[`${currency}.${col}`] = formula
    } else {
      migrated[key] = formula
    }
  }
  return migrated
}

export function loadFormulasFromStorage(cachedRows: Array<{ currency: string }>): FormulaMap {
  try {
    const raw = localStorage.getItem(FORMULA_STORAGE_KEY)
    if (!raw) return {}
    const parsed = JSON.parse(raw) as Record<string, string>
    const hasLegacyKeys = Object.keys(parsed).some(k => /^\d+\./.test(k))
    if (!hasLegacyKeys) return parsed
    const migrated = migrateLegacyFormulaKeys(parsed, cachedRows)
    try {
      localStorage.setItem(FORMULA_STORAGE_KEY, JSON.stringify(migrated))
    } catch { /* quota / privát mód — a migrált map a memóriában él tovább */ }
    return migrated
  } catch {
    return {}
  }
}

// G oszlop kereszt-számítás + A oszlop feloldás → ./mainSheetRules (pure, tesztelt).

export default function MainRateSheetPage() {
  const navigate = useNavigate()
  const isLocalRateMakerApp = import.meta.env.VITE_APP_FLAVOR === 'rate-maker'
  const canEdit = useAuthStore((state) =>
    isLocalRateMakerApp && (state.hasRole('ADMIN') || state.hasCanonicalRole(['foertektar', 'ugyvezeto', 'admin'])),
  )
  const [rows, setRows] = useState<MainRateRow[]>(() => loadFromStorage())
  const [dirty, setDirty] = useState(false)
  // FK04 verifikáció P1: a szerver-sync effekt async closure-je a futás-INDÍTÁSKORI dirty-t
  // látná (stale closure) — a ref-ből a VÁLASZ beérkezésekor érvényes értéket olvassuk,
  // különben a fetch közben commitolt user-szerkesztést a válasz némán felülírná.
  const dirtyRef = useRef(dirty)
  useEffect(() => { dirtyRef.current = dirty }, [dirty])
  // FK04 (FR-1, FR-2): a valutasorok tagsága + sorrendje a currency táblából
  // (useCurrencyCatalog). A Valutakezelő módosítása után catalog.reload() frissít
  // (a korábbi currencyReloadVersion bump helyett), app-újraindítás nélkül.
  const catalog = useCurrencyCatalog()
  const [activeCell, setActiveCell] = useState<{ rowIdx: number; col: keyof MainRateRow } | null>(null)
  // Képletek per cella, kulcs = `${valutakód}.${col}` (FK04). Csak a felhasználói képletek
  // vannak itt — fix számérték NEM kerül ide. Szintaxis: legacy (lásd mainSheetFormula).
  // A legacy rowIdx-kulcsú képleteket a betöltés a row-cache alapján migrálja.
  const [formulas, setFormulas] = useState<FormulaMap>(() => loadFormulasFromStorage(loadFromStorage()))
  // Codex P1 #581 fix: editBuffer őrzi a felhasználó RAW input-ját az aktív cella szerkesztésekor.
  const [editBuffer, setEditBuffer] = useState<string>('')
  // 2026-05-21 (Kósa Zoltán): Excel-szerű kétállapotú cella — kijelölt (editing=false,
  // nyíl-navigáció) vs. szerkesztés (editing=true, gépelés). Enter belép szerkesztésbe,
  // Enter jóváhagy + lefelé lép; Escape elvet. Lásd ./sheetNavigation.
  const [editing, setEditing] = useState(false)
  // Sourcery #762: a fókusz-effekt CSAK billentyűzetes navigáció/Enter-edit után
  // lopjon fókuszt a cellára — különben a rácson kívüli elemekre (gombok) nem
  // lehetne fókuszálni, mert a blurCell már nem nullázza az activeCell-t.
  const pendingFocusRef = useRef(false)
  const [showHelp, setShowHelp] = useState(false)
  const [publishing, setPublishing] = useState(false)
  // FK05 (FR-8): "X / Y munkacsoport elküldve" folyamat-visszajelzés a szétküldés alatt.
  const [publishProgress, setPublishProgress] = useState<{ done: number; total: number } | null>(null)
  // FR-RFM-12/13: Raiffeisen ±N% sáv. A bázis (elszámoló/OTP) és a százalék szabadon
  // állítható, szezonálisan kézzel döntött → localStorage-ban perzisztált.
  const [bandBase, setBandBase] = useState<BandSource>(() => {
    try {
      return localStorage.getItem('mainRateSheet.bandBase') === 'otp' ? 'otp' : 'settlement'
    } catch { return 'settlement' }
  })
  const [bandPercent, setBandPercent] = useState<number>(() => {
    try {
      const stored = localStorage.getItem('mainRateSheet.bandPercent')
      // null (még sosem mentve) → alapérték; tárolt "0" → 0 (megengedett, NEM esik vissza alapra).
      const raw = stored === null ? NaN : Number(stored)
      return Number.isFinite(raw) && raw >= 0 ? raw : RAIFFEISEN_BAND_PERCENT
    } catch { return RAIFFEISEN_BAND_PERCENT }
  })
  useEffect(() => {
    // Defenzív: privát mód / quota / tiltott storage esetén a setItem dobhat — ne döntse le a rendert.
    try {
      localStorage.setItem('mainRateSheet.bandBase', bandBase)
      localStorage.setItem('mainRateSheet.bandPercent', String(bandPercent))
    } catch { /* storage nem elérhető — a beállítás csak a munkamenetre érvényes */ }
  }, [bandBase, bandPercent])
  // V238 (2026-05-19): Valutakezelő modal — uj valuta hozzaadasa / aktivalas / deaktivalas
  const [showCurrencyManager, setShowCurrencyManager] = useState(false)
  // N1 (legacy ARFOLYAM / TINTERNETTMKFORM) — internet-link karbantartó
  const [internetOpen, setInternetOpen] = useState(false)
  const [internetLinks, setInternetLinks] = useState<ArfolyamInternetLink[]>([])
  const [linkForm, setLinkForm] = useState({ buttonNumber: '', label: '', url: '' })
  const lastSavedAt = useRef<string | null>(null)

  const loadInternetLinks = useCallback(async () => {
    try {
      setInternetLinks(await arfolyamInternetLinkApi.list())
    } catch (err) {
      logger.error('MainRateSheetPage', 'internet-link load', err)
    }
  }, [])

  useEffect(() => { void loadInternetLinks() }, [loadInternetLinks])

  const addInternetLink = async () => {
    const num = parseInt(linkForm.buttonNumber, 10)
    if (Number.isNaN(num)) { toast.error('Hiba', 'A gombszám szám legyen.'); return }
    if (!linkForm.label.trim() || !linkForm.url.trim()) { toast.error('Hiba', 'Felirat és URL kötelező.'); return }
    if (!/^https?:\/\/\S+$/i.test(linkForm.url.trim())) { toast.error('Hiba', 'Az URL csak http:// vagy https:// címmel kezdődhet.'); return }
    try {
      await arfolyamInternetLinkApi.create(num, linkForm.label.trim(), linkForm.url.trim())
      setLinkForm({ buttonNumber: '', label: '', url: '' })
      await loadInternetLinks()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const removeInternetLink = async (id: string) => {
    try {
      await arfolyamInternetLinkApi.remove(id)
      await loadInternetLinks()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }
  // Phase 2 wiring (Kosa Zoltan 2026-05-18 directive): a foertektaros által az
  // EXE-ben végzett árfolyam-szerkesztés a KÖZPONTI szerveren tárolt
  // ExchangeRateMaster állományt írja/olvassa. Az EXE thin client.
  const [serverSyncState, setServerSyncState] = useState<'loading' | 'online' | 'offline' | 'idle'>('idle')
  const [serverLastSyncAt, setServerLastSyncAt] = useState<string | null>(null)
  const currencyIdMapRef = useRef<Map<string, number>>(new Map())

  // Computed cross settlement for G column
  const eurRow = useMemo(() => rows.find(r => r.currency === 'EUR'), [rows])
  const usdRow = useMemo(() => rows.find(r => r.currency === 'USD'), [rows])
  const eurSettlement = eurRow?.settlement ?? 0
  const usdSettlement = usdRow?.settlement ?? 0

  // 2026-05-20 (Kósa Zoltán): a G (kereszt-számolt) MARAD auto (kézzel nem felülírható),
  // az A (settlement) viszont kézzel felülírható kereszt-valutánál is — resolveSettlement
  // dönti el: kézi felülírás → a beírt érték, egyébként → a G auto-érték.
  const enrichedRows = useMemo<MainRateRow[]>(() => {
    return rows.map((r) => {
      const computedG = r.crossBase ? computeCrossSettlement(r, eurSettlement, usdSettlement) : 0
      return {
        ...r,
        crossSettlement: computedG,
        settlement: resolveSettlement(r, eurSettlement, usdSettlement),
      }
    })
  }, [rows, eurSettlement, usdSettlement])

  // Codex P1 #581 fix: A column for crossBase rows is DERIVED, NOT user-editable.
  // Spec: "A többi valuta elszámoló árfolyama a 'G' oszlopban szereplő érték (képletes számítással)."
  // → Settlement column read-only ha crossBase != null. A renderelés `aIsAuto = !!row.crossBase`
  //   alapján dönt span vs. input között a render-loop-ban.

  // 2026-05-26 (legacy képlet-motor): reaktív újraszámítás. A `formulas` map a
  // felhasználói képlet-stringeket tárolja (kulcs `${valutakód}.${field}`); a kiszámolt
  // értékeket — a korábbi HyperFormula-architektúrával azonos módon — visszaírjuk a
  // `rows` mezőkbe, hogy a render/save/publish változatlanul olvashassa.
  //
  // Jacobi-iterációs fixpont: minden passzban a passz-eleji pillanatképből számoljuk
  // az összes képlet-cellát, majd alkalmazzuk. Aciklikus gráfra ≤ mélység lépésben
  // konvergál; körhivatkozásnál a `maxIter` cap megállít (nem fagy). A guard-ref
  // megakadályozza, hogy a saját setRows végtelen effekt-loopot indítson.
  const recomputeGuardRef = useRef(false)
  useEffect(() => {
    if (recomputeGuardRef.current) { recomputeGuardRef.current = false; return }
    const formulaKeys = Object.keys(formulas)
    if (formulaKeys.length === 0) return

    const rowColValues = (r: MainRateRow): ColValues => ({
      A: resolveSettlement(r, eurSettlement, usdSettlement),
      B: r.otp,
      C: r.helper,
      E: r.weakMultiBuy,
      F: r.weakMultiSell,
    })

    const maxIter = formulaKeys.length + 2
    let working = rows
    let changedOverall = false
    let converged = false
    for (let iter = 0; iter < maxIter; iter++) {
      const snapshot = working.map(rowColValues)
      const byCurrency = new Map<string, ColValues>()
      working.forEach((r, i) => byCurrency.set(r.currency.toUpperCase(), snapshot[i]!))
      let changedThisPass = false
      const nextWorking = working.map((row, idx) => {
        let nr = row
        const ctx: FormulaContext = { self: snapshot[idx]!, byCurrency }
        for (const field of FORMULA_COLUMNS) {
          const f = formulas[`${row.currency}.${field}`]
          if (!f) continue
          const res = evaluateFormula(f, ctx)
          if ('error' in res) continue // hibás képlet → érték marad (a hover/edit floating jelzi a képletet)
          const dec = row.currency === 'JPY' ? 3 : 2
          const val = Number(res.value.toFixed(dec))
          if (nr[field] !== val) { nr = { ...nr, [field]: val }; changedThisPass = true }
        }
        return nr
      })
      working = nextWorking
      if (changedThisPass) changedOverall = true
      else { converged = true; break }
    }
    // Copilot/Codex #863: ha NEM konvergált a maxIter alatt (körhivatkozás-gyanú, pl. `A` cella
    // képlete `A+1`), NEM commitoljuk a tetszőleges nem-konvergált részeredményt (az korrumpálná
    // a megjelenített/publikált rátát). A korábbi (stabil) értékek maradnak; csak figyelmeztetünk.
    if (!converged) {
      logger.warn('MainRateSheetPage', 'Képlet-újraszámítás nem konvergált (körhivatkozás-gyanú) — a részeredményt elvetjük, a korábbi értékek maradnak')
      return
    }
    if (changedOverall) {
      recomputeGuardRef.current = true
      setRows(working)
    }
  }, [rows, formulas, eurSettlement, usdSettlement])

  // Codex P1 #581 iter-4 (eredeti) + v2.5.61 (HyperFormula): sync visszaadja
  // a next rows snapshot-ot a save/dispatch caller-nek. NEM tisztán pure —
  // setFormulas() side-effect-et hív, ha "=" képletet/képlet-törlést detektál
  // (Copilot P2 #697). De a returned snapshot a save/dispatch szempontjából
  // VALÓDI tartalmat hordoz (HF synchronous evaluation, NEM placeholder 0).
  const computeCellCommit = useCallback((
    currentRows: MainRateRow[],
    rowIdx: number,
    col: keyof MainRateRow,
    raw: string,
  ): MainRateRow[] | null => {
    if (col === 'currency' || col === 'crossBase' || col === 'crossSettlement') return null
    // 2026-05-20: az A (settlement) kereszt-valutánál is szerkeszthető (settlementManual jelöléssel).
    const trimmed = raw.trim()
    const isCrossSettlement = col === 'settlement' && !!currentRows[rowIdx]?.crossBase

    // 2026-05-26 (legacy képlet-motor): ha az input KÉPLET (nem tiszta szám) → tároljuk
    // a képlet-stringet + szinkron kiértékelés a save/dispatch path-hoz (NEM placeholder 0,
    // hogy a publikálás valódi értéket lásson; az effekt később idempotensen újraszámol).
    // FK04: a kulcs valutakód-alapú — a rowIdx a katalógus-vezérelt listában instabil.
    const formulaKey = `${currentRows[rowIdx]?.currency ?? rowIdx}.${col}`
    const isFormulaCol = FORMULA_COLUMNS.includes(col as FormulaColumn)
    if (isFormulaCol && isFormula(trimmed)) {
      setFormulas(prev => ({ ...prev, [formulaKey]: trimmed }))
      const colVals = (r: MainRateRow): ColValues => ({
        A: resolveSettlement(r, eurSettlement, usdSettlement),
        B: r.otp,
        C: r.helper,
        E: r.weakMultiBuy,
        F: r.weakMultiSell,
      })
      const byCurrency = new Map<string, ColValues>()
      currentRows.forEach((r) => byCurrency.set(r.currency.toUpperCase(), colVals(r)))
      const res = evaluateFormula(trimmed, { self: colVals(currentRows[rowIdx]!), byCurrency })
      let evaluated: number
      if ('error' in res) {
        // Hibás képlet → NEM némán 0; warn + toast, az érték a régi marad (rollback).
        logger.warn('MainRateSheetPage', `Formula error in cell ${formulaKey}: ${res.error}`, trimmed)
        toast.warning('Képlet hiba', `${COL_NAMES[col as FormulaColumn] ?? col} cellában: ${res.error} (${trimmed})`)
        const currentValue = currentRows[rowIdx]?.[col]
        evaluated = typeof currentValue === 'number' ? currentValue : 0
      } else {
        const dec = currentRows[rowIdx]?.currency === 'JPY' ? 3 : 2
        evaluated = Number(res.value.toFixed(dec))
      }
      const next = [...currentRows]
      next[rowIdx] = { ...next[rowIdx]!, [col]: evaluated, ...(isCrossSettlement ? { settlementManual: true } : {}) }
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
    // Kereszt-valuta A oszlop: üres beírás → vissza auto módba (settlementManual=false, A=G).
    if (isCrossSettlement && trimmed === '') {
      const next = [...currentRows]
      next[rowIdx] = { ...next[rowIdx]!, settlementManual: false }
      return next
    }
    if (trimmed === '') {
      nextValue = 0
    } else {
      const parsed = Number.parseFloat(trimmed.replace(/\s/g, '').replace(',', '.'))
      if (Number.isNaN(parsed)) return null
      nextValue = parsed
    }
    // Kereszt-valuta A oszlop: csak akkor billentünk KÉZI módba, ha az érték TÉNYLEG eltér
    // a G auto-értéktől. Ha a felhasználó csak rákattint és kilép (változatlan érték), MARAD
    // auto — különben a puszta fókusz/blur lezárná a kereszt-követést (Codex/Copilot P1 #722).
    if (isCrossSettlement) {
      const cur = currentRows[rowIdx]!
      const autoG = computeCrossSettlement(cur, eurSettlement, usdSettlement)
      const dec = cur.currency === 'JPY' ? 3 : 2
      if (crossSettlementStaysAuto(nextValue, autoG, dec, !!cur.settlementManual)) return null // változatlan → marad auto
      const next = [...currentRows]
      next[rowIdx] = { ...cur, settlement: nextValue, settlementManual: true }
      return next
    }
    const currentValue = currentRows[rowIdx]?.[col]
    // Codex P2 #581 iter-3: no-op ha érték nem változott
    if (typeof currentValue === 'number' && currentValue === nextValue) return null
    const next = [...currentRows]
    next[rowIdx] = { ...next[rowIdx]!, [col]: nextValue }
    return next
  }, [formulas, eurSettlement, usdSettlement])

  // Side-effect wrapper: aszinkron állapotfrissítés (NEM használható azonnali serialization-höz).
  const commitCell = useCallback((rowIdx: number, col: keyof MainRateRow, raw: string) => {
    if (!canEdit) return
    const next = computeCellCommit(rows, rowIdx, col, raw)
    if (next) {
      setRows(next)
      setDirty(true)
    }
  }, [canEdit, rows, computeCellCommit])

  const blurCell = useCallback((rowIdx: number, col: keyof MainRateRow) => {
    // CSAK akkor commitolunk, ha tényleg szerkesztés volt — különben a kijelölt
    // (nem-szerkesztés) cellából kilépve üres editBuffer-rel adatvesztés lenne.
    // Az activeCell-t NEM nullázzuk itt: a nyíl-navigáció fókusz-mozgásakor a régi
    // cella blur-je nem törölheti az új aktív cellát (fókusz-race elkerülés).
    if (editing) {
      commitCell(rowIdx, col, editBuffer)
    }
    // Copilot #762: az edit-állapotot MINDIG visszaállítjuk (nincs stale editing/buffer
    // ugyanabban az event-timingban), de az activeCell-t a fókusz-race miatt nem bántjuk.
    setEditBuffer('')
    setEditing(false)
  }, [editing, commitCell, editBuffer])

  // ===== 2026-05-21: Excel-szerű billentyűzetes navigáció + Enter-edit =====
  const decimalsForCol = useCallback((rowIdx: number, col: keyof MainRateRow): number => {
    if (col === 'crossRate') return 6
    const r = enrichedRows[rowIdx]
    return r && isJpy(r.currency) ? 3 : 2
  }, [enrichedRows])

  const seedBuffer = useCallback((rowIdx: number, col: keyof MainRateRow): string => {
    const formula = formulas[`${enrichedRows[rowIdx]?.currency ?? rowIdx}.${String(col)}`]
    if (formula) return formula
    const v = enrichedRows[rowIdx]?.[col]
    return typeof v === 'number' && v ? v.toFixed(decimalsForCol(rowIdx, col)) : ''
  }, [formulas, enrichedRows, decimalsForCol])

  // Kijelölés (nyíl-navigáció után): aktív cella, DE nem szerkesztés.
  const selectCell = useCallback((rowIdx: number, col: EditableCol) => {
    setActiveCell({ rowIdx, col })
    setEditBuffer('')
    setEditing(false)
  }, [])

  // Szerkesztésbe lépés (Enter / dupla-katt / kattintás): buffer seed + editing=true.
  const startEdit = useCallback((rowIdx: number, col: keyof MainRateRow) => {
    if (!canEdit || !EDITABLE_ORDER.includes(col as EditableCol)) return
    pendingFocusRef.current = true // szöveg-kijelölés/fókusz az aktív input-ra
    setActiveCell({ rowIdx, col })
    setEditBuffer(seedBuffer(rowIdx, col))
    setEditing(true)
  }, [canEdit, seedBuffer])

  // Fókusz-kezelés: CSAK akkor fókuszálunk programatikusan, ha billentyűzetes
  // navigáció/Enter-edit kérte (pendingFocusRef) — így a rácson kívülre is lehet
  // fókuszálni (Sourcery #762). Egérkattintás esetén a böngésző maga fókuszál.
  useEffect(() => {
    if (!activeCell || !pendingFocusRef.current) return
    pendingFocusRef.current = false
    const el = document.getElementById(`cell-${activeCell.rowIdx}-${String(activeCell.col)}`) as HTMLInputElement | null
    if (!el) return
    if (document.activeElement !== el) el.focus()
    if (editing) el.select()
  }, [activeCell, editing])

  const handleCellKeyDown = useCallback((
    e: KeyboardEvent<HTMLInputElement>,
    rowIdx: number,
    col: keyof MainRateRow,
  ) => {
    if (!canEdit || !EDITABLE_ORDER.includes(col as EditableCol)) return
    const isEditingThis = activeCell?.rowIdx === rowIdx && activeCell.col === col && editing
    if (isEditingThis) {
      if (e.key === 'Enter') {
        e.preventDefault()
        commitCell(rowIdx, col, editBuffer)
        setEditBuffer('')
        setEditing(false)
        const nxt = nextEditableCell({ rowIdx, col: col as EditableCol }, 'ArrowDown', enrichedRows)
        pendingFocusRef.current = true
        setActiveCell({ rowIdx: nxt.rowIdx, col: nxt.col })
      } else if (e.key === 'Escape') {
        e.preventDefault()
        setEditBuffer('')
        setEditing(false)
      }
      // nyilak szerkesztés közben: alapértelmezett kurzor-mozgás
      return
    }
    // Kijelölt (nem-szerkesztés) mód:
    if (e.key === 'ArrowUp' || e.key === 'ArrowDown' || e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      e.preventDefault()
      const nxt = nextEditableCell({ rowIdx, col: col as EditableCol }, e.key as NavKey, enrichedRows)
      pendingFocusRef.current = true
      selectCell(nxt.rowIdx, nxt.col)
    } else if (e.key === 'Enter' || e.key === 'F2') {
      e.preventDefault()
      startEdit(rowIdx, col)
    }
  }, [canEdit, activeCell, editing, editBuffer, enrichedRows, commitCell, selectCell, startEdit])

  // Codex P1 #581 iter-4 fix: flushActiveCell SYNC visszaadja a "rows to save"-et.
  // Ha aktív cella van → computeCellCommit-tal kalkulálja a next-et, setRows-t hív
  // (state update aszinkron), és VISSZAADJA a next array-t azonnal.
  // Ha nincs aktív cella vagy no-op → a current rows-t adja vissza.
  // A caller (saveLocally, dispatchToServer) ezzel azonnal tud serializálni.
  // Visszaadja a SYNC commit utáni rows-t ÉS a képlet-snapshotot. A `formulas` state-update
  // aszinkron (setFormulas), ezért a saveLocally a closure-beli stale `formulas`-t mentené —
  // ezért a frissen beírt képlet-stringet itt szinkronban is kiszámoljuk és visszaadjuk
  // (Copilot #863: különben a képlet elveszhet mentés-szerkesztés-közben edge-case-ben).
  const flushActiveCell = useCallback((): { rows: MainRateRow[]; formulas: FormulaMap } => {
    if (!activeCell || !canEdit || !editing) {
      if (activeCell) {
        setActiveCell(null)
        setEditBuffer('')
      }
      return { rows, formulas }
    }
    const trimmed = editBuffer.trim()
    const key = `${rows[activeCell.rowIdx]?.currency ?? activeCell.rowIdx}.${String(activeCell.col)}`
    const isFormulaCol = (FORMULA_COLUMNS as readonly string[]).includes(activeCell.col as string)
    let nextFormulas = formulas
    if (isFormulaCol) {
      if (isFormula(trimmed)) nextFormulas = { ...formulas, [key]: trimmed }
      else if (formulas[key]) { nextFormulas = { ...formulas }; delete nextFormulas[key] }
    }
    const next = computeCellCommit(rows, activeCell.rowIdx, activeCell.col, editBuffer)
    setActiveCell(null)
    setEditBuffer('')
    setEditing(false)
    if (next) {
      setRows(next)
      setDirty(true)
      return { rows: next, formulas: nextFormulas } // SYNC — caller a frissen committed értéket + képletet serializálja
    }
    return { rows, formulas: nextFormulas }
  }, [activeCell, canEdit, editing, rows, formulas, computeCellCommit, editBuffer])

  // Codex P2 #581 iter-6 fix: saveLocally visszaadja boolean-t (true=success, false=fail).
  // Caller (CSOPORTOK navigate) csak success esetén navigáljon, hogy pending edit ne vesszen el
  // low-storage / private-browser környezetben.
  const saveLocally = useCallback((): boolean => {
    const { rows: rowsToSave, formulas: formulasToSave } = flushActiveCell()
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(rowsToSave))
      // A képletek külön kulccsal perzisztálódnak, hogy a következő mount-kor a focusCell
      // ugyanazt a képlet-kifejezést tudja megmutatni. A flushActiveCell SYNC visszaadta a
      // frissen committed képlet-snapshotot (a stale closure helyett) — Copilot #863.
      localStorage.setItem(FORMULA_STORAGE_KEY, JSON.stringify(formulasToSave))
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
    // FK04: megvárjuk a currency-katalógust (useCurrencyCatalog) — az adja a sorlista
    // tagságát és sorrendjét. Hiba esetén offline fallback a localStorage cache-re.
    if (catalog.loading) return
    if (catalog.error) {
      // Verif P2: in-flight (auto-save által még nem perzisztált) szerkesztést NEM dobunk el
      // a cache-fallback kedvéért — dirty alatt a memóriabeli rows marad.
      if (!dirtyRef.current) setRows(loadFromStorage())
      setServerSyncState('offline')
      toast.warning('Offline', 'Szerver nem elérhető — helyi cache betöltve')
      return
    }
    let cancelled = false
    setServerSyncState('loading')
    const loadServerData = async () => {
      try {
        // 1. A TELJES currencies törzs a katalógus-hookból (FR-HL-04/05: az `active` flag is
        //    kell, hogy az inaktív valutákat kiszűrhessük; a /currencies/all aktívat+inaktívat is ad).
        const currencies = catalog.all
        const codeToId = new Map<string, number>()
        for (const c of currencies) {
          codeToId.set(c.code, c.id)
        }
        currencyIdMapRef.current = codeToId

        // FR-HL-04/05: az INAKTÍV valuta-kódokat persistáljuk, hogy az offline fallback
        // (loadFromStorage) is kiszűrje őket — így a Valutakezelőben inaktivált valuta szerver
        // nélküli indításkor sem jelenik meg, és reaktiváláskor visszajön.
        // Copilot PR #1097: a katalógus-tag inaktívak (EUA — szándékosan inaktív törzs, V298)
        // NEM kerülhetnek a szűrőlistába, különben offline eltűnne az EUA sora.
        const catalogCodes = new Set(catalog.currencies.map(c => c.code))
        const inactiveCodes = currencies
          .filter(c => c.active === false && !catalogCodes.has(c.code))
          .map(c => c.code)
        try {
          localStorage.setItem(INACTIVE_STORAGE_KEY, JSON.stringify(inactiveCodes))
        } catch { /* quota / privát mód → a szerver-szűrés a memóriában akkor is érvényesül */ }

        // 2. Lehuzzuk az aktiv (publikalt) torzs arfolyamokat
        const serverRates = await exchangeRateMasterApi.listActivePublished()
        if (cancelled) return

        // 3. Merge: szerver-ratek a MainRateRow oszlopaiba (currencyCode alapjan).
        // FK04 (FR-2, FR-3): a sorlista a katalógusból épül — a cache csak az értékeket adja.
        const cachedRows = buildRowsFromCatalog(catalog.currencies, loadFromStorage())
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
        // mar editelt — a row-okat erintetlen hagyjuk (csak a tagsagot frissitjuk lent).
        // (FK05 #1118: a korabbi szerver-snapshot diff-tracking megszunt — a Folap
        // szetkuldese az osszes munkacsoportot publikalja, nem diff-alapon.)
        if (dirtyRef.current) {
          // User mar editelt (dirtyRef: a VALASZKORI allapot, nem a stale closure — verif P1).
          // Az ERTEKEIT nem irjuk felul szerver-rataval, de a sorlista TAGSAGAT a friss
          // katalogushoz igazitjuk (FR-3: uj/inaktivalt valuta dirty alatt is ervenyesul,
          // kulonben az onCurrencyChanged "a Folap frissult" toastja hamis lenne — verif P2).
          setRows(prev => buildRowsFromCatalog(catalog.currencies, prev))
          setServerSyncState('online')
          setServerLastSyncAt(new Date().toISOString())
          logger.info('MainRateSheetPage', `Server sync (user editing - ertekek megorzve, tagsag frissitve): ${serverRates.length} aktiv arfolyam`)
          return
        }

        // 2026-05-24 fix: a publikált master-ráták mellett az MNB HIVATALOS rátákat is
        // lehúzzuk, hogy a publikálatlan valuták NE maradjanak üresek a 0-s lapon — a
        // főértéktáros mind a 28 valutát lássa a központi MNB-alapértékkel. (Eddig csak
        // EUR/USD látszott, mert csak azoknak volt publikált master rátája.)
        const officialByCode = new Map<string, { officialRate: number; baseBuyRate: number; baseSellRate: number }>()
        try {
          const officialRates = await exchangeRateApi.list()
          if (cancelled) return
          for (const o of officialRates) {
            if (o.currencyCode) {
              officialByCode.set(o.currencyCode, {
                officialRate: Number(o.officialRate) || 0,
                baseBuyRate: Number(o.baseBuyRate) || 0,
                baseSellRate: Number(o.baseSellRate) || 0,
              })
            }
          }
        } catch (offErr) {
          logger.warn('MainRateSheetPage', 'MNB hivatalos ráták lehúzása sikertelen — seed kihagyva', offErr)
        }

        const mergedRows = cachedRows.map((row) => {
          const sr = codeToServerRate.get(row.currency)
          if (sr) {
            // Publikált master ráta. Backend mapping: officialRate -> A (settlement),
            // baseBuyRate -> E (weakMultiBuy), baseSellRate -> F (weakMultiSell).
            return {
              ...row,
              settlement: Number(sr.officialRate) || row.settlement,
              weakMultiBuy: Number(sr.baseBuyRate) || row.weakMultiBuy,
              weakMultiSell: Number(sr.baseSellRate) || row.weakMultiSell,
            }
          }
          // Nincs publikált master ráta → seed az MNB hivatalos rátából (ha van),
          // hogy a valuta ne maradjon üres. A főértéktáros innen állítja be + publikál.
          const off = officialByCode.get(row.currency)
          if (off && (off.officialRate > 0 || off.baseBuyRate > 0 || off.baseSellRate > 0)) {
            return {
              ...row,
              settlement: off.officialRate || off.baseBuyRate || row.settlement,
              weakMultiBuy: off.baseBuyRate || row.weakMultiBuy,
              weakMultiSell: off.baseSellRate || row.weakMultiSell,
            }
          }
          return row // se master, se hivatalos ráta — marad üres
        })
        // Verif P1 (2. ablak): a user az MNB-ráták fetch-e KÖZBEN is commitolhatott —
        // utolsó ellenőrzés a felülírás előtt; dirty alatt csak tagság-frissítés.
        if (dirtyRef.current) {
          setRows(prev => buildRowsFromCatalog(catalog.currencies, prev))
          setServerSyncState('online')
          setServerLastSyncAt(new Date().toISOString())
          logger.info('MainRateSheetPage', 'Server sync (user editing a 2. fetch alatt) - ertekek megorzve')
          return
        }
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
        // Sourcery PR #687: explicit reload localStorage cache, ne fugjunk a kezdeti hydratation-tol.
        // Verif P2: dirty alatt a memóriabeli (in-flight editet hordozó) rows marad.
        if (!dirtyRef.current) setRows(loadFromStorage())
        setServerSyncState('offline')
        toast.warning('Offline', 'Szerver nem elérhető — helyi cache betöltve')
      }
    }
    void loadServerData()
    return () => { cancelled = true }
    // dirty szándékosan NINCS a dep-listában — csak a katalógus betöltésekor ÉS valuta-
    // aktiválás/inaktiválás után (catalog.reload → catalog.all új referencia) syncolunk.
    // A dirty AKTUÁLIS (válaszkori) értékét a dirtyRef adja, NEM a closure (verif P1).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [catalog.loading, catalog.error, catalog.all, catalog.currencies])

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
    const { rows: rowsToDispatch } = flushActiveCell()
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

    // 2. FK05 (FR-1, FR-2): a Főlap szétküldése is a munkacsoport-publish útvonalon megy
    // (POST /rate-creation/publish-group-rate, MINDEN csoportra) — az exchange-rate-master
    // create→approve→publish út kivezetése külön technikai-adósság kör (FK05 OUT).
    // A kiküldés előtti adatminőség-figyelmeztetések (irány, EUA, Raiffeisen-sáv) a 0-s lap
    // TELJES (nem-nulla rátájú) állományán futnak — a csoportlapok képletei ebből táplálkoznak.
    const eurRowD = rowsToDispatch.find((r) => r.currency === 'EUR')
    const usdRowD = rowsToDispatch.find((r) => r.currency === 'USD')
    const eurS = eurRowD?.settlement ?? 0
    const usdS = usdRowD?.settlement ?? 0

    const ratedRows = rowsToDispatch.flatMap((r) => {
      if (r.weakMultiBuy <= 0 || r.weakMultiSell <= 0) return []
      // A oszlop tényleges értéke: kézi felülírás → beírt érték, egyébként a G auto-érték.
      return [{ row: r, effectiveSettlement: resolveSettlement(r, eurS, usdS) }]
    })

    // G7 (EXCMD b1-arfolyamkeszito FR-RFM-25): kiküldés előtti irány-validáció —
    // az eladási (weakMultiSell) nem lehet kisebb az elszámolónál, a vételi
    // (weakMultiBuy) nem lehet magasabb. Sértés esetén figyelmeztetés + megerősítés.
    const directionViolations = validateRateDirection(
      ratedRows.map(({ row, effectiveSettlement }) => ({
        currencyCode: row.currency,
        settlement: effectiveSettlement,
        buyRate: row.weakMultiBuy,
        sellRate: row.weakMultiSell,
      })),
    )
    const warnings: string[] = directionViolations.map((v) => `• ${v.message}`)

    // G22 (FR-RFM-09): EUA (euró-érme) árfolyam max 20% eltérés a gyenge euró
    // eladás × 1.2 képzett értéktől; ennél nagyobb eltérésnél ki kell írni.
    const eurSell = rowsToDispatch.find((r) => r.currency === 'EUR')?.weakMultiSell ?? 0
    const euaSell = rowsToDispatch.find((r) => r.currency === 'EUA')?.weakMultiSell ?? 0
    if (euaSell > 0 && eurSell > 0 && euaDeviationExceeds(euaSell, eurSell)) {
      warnings.push(
        `• EUA: az euró-érme árfolyam (${euaSell}) több mint 20%-kal eltér a képzett ` +
        `értéktől (${computeEuaRate(eurSell).toFixed(2)} = gyenge euró eladás × 1.2)`,
      )
    }

    // G23 (FR-RFM-12/13): Raiffeisen ±N% eltérési sáv — a vétel/eladás a kiválasztott bázistól
    // (elszámoló VAGY OTP) max bandPercent%-kal térhet el. A bázison kívüli értékek figyelmeztetést
    // adnak a kiküldés előtt (a megbízási szerződés szerinti 10%-os korlát, szabadon állítva).
    const bandViolations = raiffeisenBandViolations(
      ratedRows.map(({ row, effectiveSettlement }) => ({
        currency: row.currency,
        base: bandBase === 'otp' ? row.otp : effectiveSettlement,
        buy: row.weakMultiBuy,
        sell: row.weakMultiSell,
      })),
      bandPercent,
    )
    const bandBaseLabel = bandBase === 'otp' ? 'OTP' : 'elszámoló'
    for (const v of bandViolations) {
      warnings.push(
        `• Raiffeisen sáv: ${v.currency} ${v.kind === 'buy' ? 'vétel' : 'eladás'} (${v.rate}) a ` +
        `±${bandPercent}%-os sávon kívül [${v.min.toFixed(2)}–${v.max.toFixed(2)}], ` +
        `bázis: ${bandBaseLabel} (${v.base.toFixed(2)})`,
      )
    }

    if (warnings.length > 0) {
      // window.confirm: szándékos, függőség-mentes választás, konzisztens a meglévő
      // mintával (ReservationPage). Egyedi modal-dialógusra cserélése külön UX-kör,
      // a futó-app (Electron) verifikációval együtt (Sourcery #787).
      const proceed = window.confirm(
        'Árfolyam-figyelmeztetés (FR-RFM-25 / FR-RFM-09):\n\n' + warnings.join('\n') +
        '\n\nBiztosan kiküldi így az árfolyamot?',
      )
      if (!proceed) {
        setPublishing(false)
        return
      }
    }

    // 3. FK05 (FR-1, FR-2, FR-8): minden munkacsoport publikálása a munkacsoport-lap
    // útvonalán (publish-group-rate) — a csoport-adatok a tárolt overlay + képletek
    // headless kiértékeléséből jönnek (publishAllWorkgroups, TBD-4 tényfeltárás szerint).
    try {
      const result = await publishAllWorkgroups({
        onProgress: (done, total) => setPublishProgress({ done, total }),
      })

      setDirty(false)
      setServerSyncState('online')
      setServerLastSyncAt(new Date().toISOString())

      if (result.total === 0) {
        toast.warning(
          'Nincs munkacsoport',
          'Nincs aktív árfolyam-munkacsoport — előbb hozzon létre csoportot a munkacsoport-lapon.',
        )
      } else {
        const summary = summarizePublishAll(result)
        if (summary.ok) {
          toast.success(summary.title, summary.detail)
        } else if (result.published > 0) {
          toast.warning(summary.title, summary.detail)
        } else {
          toast.error('Sikertelen', summary.detail)
          setServerSyncState('offline')
        }
      }
    } catch (e) {
      // Csak szerver/network hiba - localStorage mar a kulon try-block-on tul vagyunk
      logger.error('MainRateSheetPage', 'Server dispatch failed', e)
      toast.error('Hálózati hiba', 'Szerver nem elérhető — kérlek próbáld újra.')
      setServerSyncState('offline')
    } finally {
      setPublishProgress(null)
      setPublishing(false)
    }
  }, [canEdit, flushActiveCell, serverSyncState, bandBase, bandPercent])

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
          {/* FR-RFM-12/13: Raiffeisen ±N% eltérési sáv — bázis (elszámoló/OTP) + százalék. A
              kiküldés/ellenőrzés ezen a sávon kívüli vétel/eladásra figyelmeztet. */}
          <div className="flex items-center gap-1 text-xs" title="Raiffeisen eltérési sáv (FR-RFM-12/13): a vétel/eladás max ennyivel térhet el a választott bázistól">
            <span className="text-slate-500">Sáv:</span>
            <select
              value={bandBase}
              onChange={(e) => setBandBase(e.target.value === 'otp' ? 'otp' : 'settlement')}
              disabled={!canEdit}
              className="px-1 py-0.5 border border-slate-300 rounded text-xs disabled:opacity-40"
              title="A sáv bázisa: elszámoló vagy OTP árfolyam (FR-RFM-13)"
            >
              <option value="settlement">Elszámoló</option>
              <option value="otp">OTP</option>
            </select>
            <input
              type="number"
              min={0}
              step={0.5}
              value={bandPercent}
              onChange={(e) => { const n = Number(e.target.value); if (Number.isFinite(n) && n >= 0) setBandPercent(n) }}
              disabled={!canEdit}
              className="w-12 px-1 py-0.5 border border-slate-300 rounded text-xs disabled:opacity-40"
              title="Megengedett eltérés százaléka (alap 10%) — FR-RFM-12"
            />
            <span className="text-slate-500">%</span>
          </div>
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
        {/* FR-HL-10 (hibalista): dedikált ELLENŐRZÉS gomb — a háromlépcsős flow (Ellenőrzés → Mentés →
            Szétküldés) explicit szétválasztása. Ugyanazt az irány- + EUA-validációt futtatja, mint a
            kiküldés, de MENTÉS/KIKÜLDÉS NÉLKÜL. A MENTETT táblázat-állapotot (rows) ellenőrzi — ha épp
            cellát szerkesztesz, előbb a Mentés rögzíti a beírást (Copilot review). A szerver a kiküldéskor
            ismét validál. */}
        <button
          onClick={() => {
            const violations = validateRateDirection(
              rows.map(r => ({
                currencyCode: r.currency, settlement: r.settlement,
                buyRate: r.weakMultiBuy, sellRate: r.weakMultiSell,
              })),
            )
            const warnings = violations.map(v => `• ${v.message}`)
            const eurSell = rows.find(r => r.currency === 'EUR')?.weakMultiSell ?? 0
            const euaSell = rows.find(r => r.currency === 'EUA')?.weakMultiSell ?? 0
            if (euaSell > 0 && eurSell > 0 && euaDeviationExceeds(euaSell, eurSell)) {
              warnings.push(`• EUA: az euró-érme árfolyam (${euaSell}) >20%-kal eltér a képzett értéktől (${computeEuaRate(eurSell).toFixed(2)})`)
            }
            // FR-RFM-12/13: Raiffeisen ±N% sáv-ellenőrzés (a kiküldéssel azonos szabály, mentés/kiküldés nélkül).
            // Kereszt-valutáknál a tényleges elszámoló a resolveSettlement-tel számolt (mint a dispatch-út),
            // különben az auto-módú soroknál a nyers settlement=0 hibásan kihagyná a sávellenőrzést.
            const eurSettle = rows.find(r => r.currency === 'EUR')?.settlement ?? 0
            const usdSettle = rows.find(r => r.currency === 'USD')?.settlement ?? 0
            for (const v of raiffeisenBandViolations(
              rows.map(r => ({
                currency: r.currency,
                base: bandBase === 'otp' ? r.otp : resolveSettlement(r, eurSettle, usdSettle),
                buy: r.weakMultiBuy, sell: r.weakMultiSell,
              })),
              bandPercent,
            )) {
              warnings.push(
                `• Raiffeisen sáv: ${v.currency} ${v.kind === 'buy' ? 'vétel' : 'eladás'} (${v.rate}) a ±${bandPercent}%-os ` +
                `sávon kívül [${v.min.toFixed(2)}–${v.max.toFixed(2)}], bázis: ${bandBase === 'otp' ? 'OTP' : 'elszámoló'}`,
              )
            }
            if (warnings.length === 0) {
              toast.success('Ellenőrzés', 'A mentett táblázat rendben — a kiküldés a szerver-oldali ellenőrzést is elvégzi.')
            } else {
              toast.warning('Ellenőrzés', `${warnings.length} eltérés:\n${warnings.slice(0, 6).join('\n')}`)
            }
          }}
          className="px-3 py-1 text-xs font-medium bg-blue-600 text-white border border-blue-700 rounded hover:bg-blue-700 flex items-center gap-1"
        >
          <CheckCircle2 size={12} /> ELLENŐRZÉS
        </button>
        <button
          onClick={() => void dispatchToServer()}
          disabled={publishing || !canEdit}
          data-testid="dispatch-rates-button"
          className="px-3 py-1 text-xs font-medium bg-green-600 text-white border border-green-700 rounded hover:bg-green-700 disabled:opacity-40 flex items-center gap-1"
        >
          <Send size={12} />
          {publishing && publishProgress
            ? `${publishProgress.done} / ${publishProgress.total} MUNKACSOPORT ELKÜLDVE`
            : 'ÁRFOLYAMOK SZÉTKÜLDÉSE'}
        </button>
        {/* N1 (legacy ARFOLYAM / TINTERNETTMKFORM) — internet-link gyors-megnyitók */}
        {internetLinks.map(link => (
          <button
            key={link.id}
            onClick={() => window.open(link.url, '_blank', 'noopener,noreferrer')}
            title={link.url}
            className="px-2 py-1 text-xs font-medium bg-sky-50 border border-sky-300 rounded text-sky-700 hover:bg-sky-100 flex items-center gap-1"
          >
            <Globe size={12} /> {link.buttonNumber}. {link.label}
          </button>
        ))}
        <button
          onClick={() => { setInternetOpen(true); void loadInternetLinks() }}
          title="Internet-címek karbantartása (legacy TINTERNETTMKFORM)"
          className="px-3 py-1 text-xs font-medium bg-white border border-slate-300 rounded hover:bg-slate-50 flex items-center gap-1"
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
              // 2026-05-20: kereszt-valuta A oszlopa AUTO (G-ből), amíg kézzel nem írják felül.
              // Az A MINDIG szerkeszthető; az auto-állapot csak vizuális jelzés.
              const aIsAutoCross = !!row.crossBase && !row.settlementManual
              const isActive = (col: keyof MainRateRow) => activeCell?.rowIdx === idx && activeCell.col === col
              const cellClass = (col: keyof MainRateRow, baseClass: string) =>
                `${baseClass} ${isActive(col) ? 'ring-2 ring-blue-500' : ''}`
              // EditableInput closure: while focused, show editBuffer (raw user input);
              // when blurred, parse + commit. Codex P1 #581 fix.
              const renderInput = (col: keyof MainRateRow, currentVal: number, decimalsFor: number, classes: string, placeholder?: string) => {
                const activeThis = isActive(col)
                const editingThis = activeThis && editing
                // Hover (lebegő) jelzés: a cella képlet eredménye-e, kézi- vagy auto-érték.
                const cellFormula = formulas[`${row.currency}.${String(col)}`]
                const isFormulaColHere = (FORMULA_COLUMNS as readonly string[]).includes(col as string)
                const hoverTitle = cellFormula
                  ? `Képlet: ${cellFormula} = ${currentVal ? currentVal.toFixed(decimalsFor) : '0'}`
                  : (col === 'settlement' && aIsAutoCross
                    ? 'Automatikus érték (G kereszt-számolt). Írj be értéket/képletet a kézi felülíráshoz; üres = vissza auto.'
                    : (isFormulaColHere ? 'Kézi bevitelű érték (képlet is írható, pl. C*0,97 vagy !FEUR)' : undefined))
                return (
                  <input
                    id={`cell-${idx}-${String(col)}`}
                    type="text"
                    // Szerkesztéskor a RAW buffer, egyébként a formázott érték (readOnly).
                    value={editingThis ? editBuffer : (currentVal ? currentVal.toFixed(decimalsFor) : '0')}
                    readOnly={!canEdit || !editingThis}
                    onChange={(e) => setEditBuffer(e.target.value)}
                    onClick={() => startEdit(idx, col)}
                    onFocus={() => { if (!editingThis) selectCell(idx, col as EditableCol) }}
                    onKeyDown={(e) => handleCellKeyDown(e, idx, col)}
                    onBlur={() => blurCell(idx, col)}
                    className={`${classes} ${activeThis && !editing ? 'cursor-pointer' : ''}`}
                    disabled={!canEdit}
                    placeholder={placeholder}
                    title={hoverTitle}
                  />
                )
              }
              return (
                <tr key={row.currency} className="hover:bg-slate-50">
                  {/* A — Elszámoló (MINDIG szerkeszthető; kereszt-valutánál auto=G amíg nem írják felül) */}
                  <td
                    className={cellClass('settlement', `border border-slate-300 px-2 py-1 text-right font-mono font-bold ${aIsAutoCross ? 'text-amber-700 bg-amber-50/40' : 'text-red-700 bg-orange-50/50'}`)}
                    title={aIsAutoCross ? 'Auto (G kereszt-számolt). Írj be értéket a kézi felülíráshoz; üres = vissza auto.' : undefined}
                  >
                    {renderInput('settlement', row.settlement, decimals, `w-full bg-transparent text-right font-mono font-bold focus:outline-none ${aIsAutoCross ? 'text-amber-700 italic' : 'text-red-700'}`)}
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

        {/* === LEBEGŐ SZERKESZTŐ ABLAK === szerkesztés közben mutatja, mit írunk (képlet/érték) */}
        {editing && activeCell && (
          <div className="fixed bottom-4 right-4 z-50 max-w-sm rounded-lg border border-blue-400 bg-white px-4 py-3 shadow-lg">
            <div className="text-xs font-semibold text-blue-700">
              {rows[activeCell.rowIdx]?.currency} · {COL_NAMES[activeCell.col as FormulaColumn] ?? String(activeCell.col)}
            </div>
            <div className="mt-1 break-all font-mono text-sm text-slate-900">
              {editBuffer || <span className="text-slate-400">(üres → auto/törlés)</span>}
            </div>
            {isFormula(editBuffer) && (
              <div className="mt-1 text-[11px] text-slate-500">Képlet — Enter: jóváhagy, Esc: elvet</div>
            )}
          </div>
        )}

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
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300 w-24">A, B, C, E, F</td><td className="py-1 px-2 italic">Az AKTUÁLIS valuta sorának adott oszlopa (saját sor). A 0-s lapon ez az 5 érték-oszlop képletezhető.</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">C*0,97</td><td className="py-1 px-2 italic">Példa: az aktuális valuta C oszlopa szorozva 0,97-tel. (Tizedeselválasztó: vessző.)</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">!Fxxx</td><td className="py-1 px-2 italic">Más valuta sorának oszlopa (F=oszlop, xxx=valutakód). Pl. <b>!FEUR</b> = az EUR sor F (eladás) oszlopa — pl. az EUA eladása mindig az EUR eladása.</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">Műveletek</td><td className="py-1 px-2 italic">+ - * / és zárójel (a zárójel kötelező eltérő prioritású műveletek esetén)</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">(üres)</td><td className="py-1 px-2 italic">Üres cella → automatikus érték. Fix szám → kézi felülírás. Képlet → a képlet eredménye, automatikus újraszámítással.</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">#NNL</td><td className="py-1 px-2 italic">Munkacsoportok közötti hivatkozás (<span className="font-mono">#</span> + kétjegyű csoportazonosító + oszlopbetű, pl. <span className="font-mono">#01L</span>). A 0-s lapon nem értelmezett — a <b>csoport árfolyamlapokon</b> használható, a <span className="font-mono">J–S</span> oszlop-hivatkozásokkal együtt (lásd a csoport-lap „Képlet-súgó" gombját).</td></tr>
                </tbody>
              </table>
              <div className="mt-2 text-[11px] text-slate-500">Megjegyzés: a képlet NEM kezdődik „=" jellel; egyszerűen írd be (pl. <span className="font-mono">C*0,97</span> vagy <span className="font-mono">!FEUR</span>). A G és H oszlop (kereszt-számolt / kereszt-forrás) automatikus, nem képletezhető.</div>
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
          // FK04 / FR-3 + FR-HL-04: a backend Currency tábla változott (új valuta / aktiválás /
          // inaktiválás) → a katalógus újratöltése, így a 0-ás lap sorlistája AZONNAL frissül
          // (új valuta a helyes displayOrder pozícióban jelenik meg), app-újraindítás nélkül.
          catalog.reload()
          toast.success('Valutakezelő', 'A valuta-módosítás érvénybe lépett — a Főlap frissült.')
        }}
      />

      {/* N1 (legacy ARFOLYAM / TINTERNETTMKFORM) — internet-link karbantartó modal */}
      {internetOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-lg bg-white p-5 shadow-xl">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold flex items-center gap-2">
                <Globe size={18} /> Internet-címek karbantartása
              </h2>
              <button onClick={() => setInternetOpen(false)} className="text-slate-500 hover:text-slate-700">✕</button>
            </div>

            {canEdit && (
              <div className="mt-3 grid grid-cols-12 gap-2">
                <input type="number" placeholder="Sorsz." value={linkForm.buttonNumber}
                  onChange={e => setLinkForm(f => ({ ...f, buttonNumber: e.target.value }))}
                  className="col-span-2 form-input" />
                <input type="text" placeholder="Felirat" value={linkForm.label}
                  onChange={e => setLinkForm(f => ({ ...f, label: e.target.value }))}
                  className="col-span-4 form-input" />
                <input type="text" placeholder="https://..." value={linkForm.url}
                  onChange={e => setLinkForm(f => ({ ...f, url: e.target.value }))}
                  className="col-span-4 form-input" />
                <button onClick={() => void addInternetLink()}
                  className="col-span-2 px-2 py-1 text-xs font-medium bg-green-600 text-white rounded hover:bg-green-700">
                  Hozzáad
                </button>
              </div>
            )}

            <ul className="mt-3 max-h-72 divide-y divide-slate-100 overflow-auto rounded border border-slate-200">
              {internetLinks.length === 0 && (
                <li className="px-3 py-2 text-sm text-slate-400">Nincs internet-cím rögzítve.</li>
              )}
              {internetLinks.map(link => (
                <li key={link.id} className="flex items-center justify-between px-3 py-2 text-sm">
                  <span className="flex items-center gap-2">
                    <span className="font-mono text-sky-700">{link.buttonNumber}.</span>
                    <span className="font-medium">{link.label}</span>
                    <a href={link.url} target="_blank" rel="noopener noreferrer" className="text-slate-500 underline">{link.url}</a>
                  </span>
                  {canEdit && (
                    <button onClick={() => void removeInternetLink(link.id)}
                      className="text-red-500 hover:text-red-700" title="Törlés">✕</button>
                  )}
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </div>
  )
}
