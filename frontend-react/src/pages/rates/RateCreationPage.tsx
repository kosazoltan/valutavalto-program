import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { AxiosError } from 'axios'
import { RefreshCw, AlertTriangle, Send, Plus, X, Building2, Clock, Undo2, Redo2, Home, ArrowLeft, ShieldCheck, Shield, Pencil, Trash2 } from 'lucide-react'
import {
  rateCreationApi,
  rateWorkgroupApi,
  RateOverviewDTO,
  RateOverviewItem,
  WorkgroupDetailDTO,
  BranchListItem,
  type RateWorkgroupSaveDTO,
} from '../../services/api/index'
import {
  tileClasses,
  DEFAULT_TILE,
  WorkgroupEditor,
  ConfirmDialog,
  type ConfirmState,
} from './workgroupMaintenance'
import { FormulaSyntaxHelp, FormulaSyntaxHelpButton } from './FormulaSyntaxHelp'
import { toast } from '../../components/ui/toaster'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import RateGrid from './components/RateGrid'
import BranchPickerModal from './components/BranchPickerModal'
import { fmtRate, parseNum, type EditableRate } from './types'
import { currentFunctionCode, fillDownLimitBands, clearLimitBands } from './fillHelpers'
import { validateWorkgroupProtection, workgroupProtectionLabel, type ProtectionRow } from './workgroupProtection'
import { isFormula, type WgValues } from './workgroupSheetFormula'
import { isSignificantDeviation } from './deviationCheck'
import {
  recomputeWorkgroupSheet,
  FIELD_TO_WGCOL,
  type WgField,
  type WgComputeRow,
} from './workgroupSheetCompute'
import {
  loadSheet0ByCurrency,
  loadAllGroupValueSnapshots,
  loadGroupFormulas,
  saveGroupFormulas,
  saveGroupValueSnapshot,
  loadGroupRateValues,
  saveGroupRateValues,
} from './workgroupSheetStorage'
import { useTranslation } from 'react-i18next'

/** FK-04/C: a 8 képletezhető string-mező (J=officialRate read-only auto, K=ISO kód kihagyva). */
const WG_STRING_FIELDS: Exclude<WgField, 'officialRate'>[] = [
  'buyRate', 'sellRate',
  'limit1BuyRate', 'limit1SellRate',
  'limit2BuyRate', 'limit2SellRate',
  'limit3BuyRate', 'limit3SellRate',
]

// FK02-B / FR-1 (2026-06-01): a csoport-árfolyamlap valuta-sorrendje EGYEZZEN a Főlapéval
// (MainRateSheetPage DEFAULT_CURRENCIES), hogy a felhasználó ugyanazt a sorrendet lássa
// mindkét nézetben. A szerver `overview.currencies` sorrendje nem garantált. Ez a lista a
// MainRateSheetPage.DEFAULT_CURRENCIES kódjainak tükre (forrás-igazság ott).
const MAIN_SHEET_CURRENCY_ORDER: readonly string[] = [
  'EUR', 'USD', 'GBP', 'CHF', 'AUD', 'CAD', 'JPY', 'CZK', 'PLN', 'RON',
  'RSD', 'ILS', 'UAH', 'RUB', 'EUA', 'TRY', 'CNY', 'BAM', 'THB', 'BRL',
  'MXN', 'NZD',
]

/** A főlapi sorrend szerinti rendezés; az ismeretlen kódok a végére, ABC-rendben. */
function sortByMainSheetOrder<T extends { currencyCode: string }>(rows: T[]): T[] {
  return [...rows].sort((a, b) => {
    const ia = MAIN_SHEET_CURRENCY_ORDER.indexOf(a.currencyCode)
    const ib = MAIN_SHEET_CURRENCY_ORDER.indexOf(b.currencyCode)
    if (ia === -1 && ib === -1) return a.currencyCode.localeCompare(b.currencyCode)
    if (ia === -1) return 1
    if (ib === -1) return -1
    return ia - ib
  })
}

// FK02-B / FR-2..5 (2026-06-01): jelentős (≥10%) eltérés az ELŐZŐ MENTETT értékhez képest →
// megerősítő modal (elgépelés-védelem). Az arány-számítás a ./deviationCheck modulban.
/** WgField → ember-olvasható oszlopnév a megerősítő üzenethez. */
const WG_FIELD_LABEL: Record<string, string> = {
  buyRate: 'alap vétel', sellRate: 'alap eladás',
  limit1BuyRate: '1. sáv vétel', limit1SellRate: '1. sáv eladás',
  limit2BuyRate: '2. sáv vétel', limit2SellRate: '2. sáv eladás',
  limit3BuyRate: '3. sáv vétel', limit3SellRate: '3. sáv eladás',
  officialRate: 'elszámoló (J)',
}

/** EditableRate string-mező → szám (üres → null), a képlet-motor numerikus inputjához. */
function numOrNull(s: string): number | null {
  const t = s.trim()
  if (t === '') return null
  const n = parseFloat(t.replace(',', '.'))
  return Number.isFinite(n) ? n : null
}

// ===================== Main Component =====================

export default function RateCreationPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const isLocalRateMakerApp = import.meta.env.VITE_APP_FLAVOR === 'rate-maker'
  const canWriteRateCreation = useAuthStore((state) =>
    isLocalRateMakerApp && (state.hasRole('ADMIN') || state.hasCanonicalRole(['foertektar', 'ugyvezeto', 'admin'])),
  )
  const [overview, setOverview] = useState<RateOverviewDTO | null>(null)
  const [workgroups, setWorkgroups] = useState<WorkgroupDetailDTO[]>([])
  const [rates, setRates] = useState<EditableRate[]>([])
  // FK02-B / FR-2..5: a 10%-eltérés megerősítő modal állapota (a cella-commit interception-höz).
  const [rateConfirm, setRateConfirm] = useState<ConfirmState | null>(null)
  // FK02-B / FR-2..5: revert-jelzés a RateGrid felé — "Mégse" után a cella visszaáll a perzisztáltra.
  const [rateRevertSignal, setRateRevertSignal] = useState(0)
  // FK02-B / FR-11, FR-12: minden loadData növeli → a fix-érték overlay azonos csoportos reload után
  // is lefut (Codex P1: nem csak csoportváltáskor).
  const [reloadVersion, setReloadVersion] = useState(0)
  // FK-04/C (Codex #906): az undo/redo a `rates` MELLETT a `formulas`-t is rögzíti — különben
  // egy képlet beírása után a Ctrl+Z csak a megjelenített értéket állítaná vissza, a képlet a
  // state/localStorage-ban maradna, és a recompute újra alkalmazná (képlet-szerkesztés nem volt visszavonható).
  // FK02-B / FR-11, FR-12 (Codex P2): a snapshot a localStorage-ba mentett fix-érték állapotot is
  // rögzíti, hogy az undo/redo a perzisztált mentést is visszaállítsa (különben reload után a
  // visszavont érték jönne vissza).
  type UndoSnapshot = { rates: EditableRate[]; formulas: Record<string, string>; savedRateValues: Record<string, string> }
  const undoStack = useRef<UndoSnapshot[]>([])
  const redoStack = useRef<UndoSnapshot[]>([])
  // FK02-B / FR-2..5: a PERZISZTÁLT (loadData-kor betöltött, utoljára publikált/mentett) árfolyamok
  // numerikus pillanatképe, kulcs `${currencyId}.${field}`. A 10%-eltérés ehhez mér — NEM a session
  // közbeni, még nem publikált értékhez —, így a lépésenkénti elcsúszás (400→430→470) is kiszúrható.
  const baselineRatesRef = useRef<Record<string, number>>({})
  const [selectedWgIndex, setSelectedWgIndex] = useState<number>(0)
  /**
   * FK-02/03/04 (Kasza Helga / Bali Henriett 2026-05-28): a régi „bal oldali sávos"
   * 54-csempés választó helyett egységes csempés listanézet az induló képernyő.
   * - 'tile-list' (default): csempés grid az összes csoport árfolyamlappal
   * - 'editor': egy csoport árfolyamlap szerkesztése (rate-tábla + iroda-panel)
   * A csempére klikk azonnal megnyitja a szerkesztőt (megerősítés nélkül, docx-spec).
   */
  const [viewMode, setViewMode] = useState<'tile-list' | 'editor'>('tile-list')
  const [loading, setLoading] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  // T9.F: képletszintaxis-súgó (A–I / J–S / !Fxxx / #NNL) a csoport-lap szerkesztőhöz.
  const [showFormulaHelp, setShowFormulaHelp] = useState(false)

  // FK-04/C képletezés: felhasználói képletek (kulcs `${currencyId}.${field}`) csoportonként,
  // a kiszámolt cellánkénti hibák, és a 0-s lap / kereszt-csoport hivatkozás-kontextus.
  const [formulas, setFormulas] = useState<Record<string, string>>({})
  const [cellErrors, setCellErrors] = useState<Record<string, string>>({})
  // A 0-s lap (A–I) + más csoportok J–S pillanatképei localStorage-ból; ref, hogy a recompute
  // effekt függőség-listája stabil maradjon (a Map-eket csoport-nyitáskor frissítjük).
  const sheetCtxRef = useRef<{
    sheet0ByCurrency: Map<string, ReturnType<typeof loadSheet0ByCurrency> extends Map<string, infer V> ? V : never>
    otherGroupsByCurrency: Map<number, Map<string, WgValues>>
  }>({ sheet0ByCurrency: new Map(), otherGroupsByCurrency: new Map() })
  // Védi a recompute setRates-ét a végtelen effekt-loop ellen (0-s lap minta).
  const recomputeGuardRef = useRef(false)

  // Limit editing state
  const [editLimits, setEditLimits] = useState<{ l1: string; l2: string; l3: string }>({ l1: '', l2: '', l3: '' })
  const [limitsModified, setLimitsModified] = useState(false)
  const [savingLimits, setSavingLimits] = useState(false)

  // Branch picker modal
  const [branchModalOpen, setBranchModalOpen] = useState(false)
  const [allBranches, setAllBranches] = useState<BranchListItem[]>([])
  const [branchFilter, setBranchFilter] = useState('')
  const [selectedBranchIds, setSelectedBranchIds] = useState<Set<string>>(new Set())
  const [savingBranches, setSavingBranches] = useState(false)

  const selectedWg = workgroups[selectedWgIndex] ?? null

  // Sync limit inputs when workgroup changes
  useEffect(() => {
    if (selectedWg) {
      setEditLimits({
        l1: selectedWg.limit1Boundary ? String(selectedWg.limit1Boundary) : '0',
        l2: selectedWg.limit2Boundary ? String(selectedWg.limit2Boundary) : '0',
        l3: selectedWg.limit3Boundary ? String(selectedWg.limit3Boundary) : '0',
      })
      setLimitsModified(false)
    }
  // Only re-sync limit inputs when the selected workgroup identity changes
  // eslint-disable-next-line react-hooks/exhaustive-deps -- intentional: sync only on WG id change, not on every selectedWg reference
  }, [selectedWg?.id])

  // FK-04/C: csoport-nyitáskor betöltjük a csoport képleteit + a hivatkozás-kontextust
  // (0-s lap A–I a localStorage-ból, más csoportok J–S pillanatképei a `#NN`-hez).
  useEffect(() => {
    if (!selectedWg) {
      setFormulas({})
      setCellErrors({})
      return
    }
    sheetCtxRef.current = {
      sheet0ByCurrency: loadSheet0ByCurrency(),
      otherGroupsByCurrency: loadAllGroupValueSnapshots(),
    }
    setFormulas(loadGroupFormulas(selectedWg.id))
    setCellErrors({})
    // Codex #910 P1: az undo/redo stack csoportonként ÉRVÉNYTELEN — csoportváltáskor ürítjük,
    // különben egy másik csoportban beírt képletet a Ctrl+Z az AKTUÁLIS csoportba állítaná vissza,
    // és a perzisztáló effekt annak localStorage-kulcsa alá mentené (kereszt-csoport korrupció).
    undoStack.current = []
    redoStack.current = []
  // eslint-disable-next-line react-hooks/exhaustive-deps -- csak a csoport-id váltáskor töltünk újra
  }, [selectedWg?.id])

  // FK02-B / FR-11, FR-12: a csoport perzisztált FIX (nem-formulás) rátaértékeit visszaírjuk a
  // `rates`-be (a képlet-cellákat a recompute úgyis felülírja). Külön effekt, hogy NE csak a
  // csoportváltáskor, hanem a `loadData()` UTÁNI (azonos csoportos) reloadkor is lefusson
  // (Codex P1: `reloadVersion` növekszik minden loadData-nál). Csak OLVAS a localStorage-ból és a
  // `rates`-re tesz overlay-t — a localStorage-t NEM írja, ezért nem törli a mentett értékeket.
  useEffect(() => {
    if (!selectedWg) return
    const savedRateValues = loadGroupRateValues(selectedWg.id)
    if (Object.keys(savedRateValues).length === 0) return
    setRates(prev => prev.map(r => {
      let nr = r
      for (const field of WG_STRING_FIELDS) {
        const v = savedRateValues[`${r.currencyId}.${field}`]
        if (v != null && nr[field] !== v) {
          if (nr === r) nr = { ...r }
          nr[field] = v
        }
      }
      return nr
    }))
  // eslint-disable-next-line react-hooks/exhaustive-deps -- csoportváltáskor ÉS minden reloadnál
  }, [selectedWg?.id, reloadVersion])

  // FK-04/C: a csoport képleteinek perzisztálása minden változáskor (localStorage, csoportonként).
  useEffect(() => {
    if (selectedWg) saveGroupFormulas(selectedWg.id, formulas)
  }, [formulas, selectedWg])

  // FK-04/C reaktív újraszámítás: a képlet-cellákat feloldja és visszaírja a `rates`
  // string-mezőkbe (a fix cellák változatlanok). Jacobi-fixpont + ciklus-védelem a
  // workgroupSheetCompute-ban; a guard-ref akadályozza a saját setRates-loopot.
  useEffect(() => {
    if (recomputeGuardRef.current) { recomputeGuardRef.current = false; return }

    const computeRows: WgComputeRow[] = rates.map((r) => ({
      currencyId: r.currencyId,
      currencyCode: r.currencyCode,
      values: {
        officialRate: r.officialRate,
        buyRate: numOrNull(r.buyRate),
        sellRate: numOrNull(r.sellRate),
        limit1BuyRate: numOrNull(r.limit1BuyRate),
        limit1SellRate: numOrNull(r.limit1SellRate),
        limit2BuyRate: numOrNull(r.limit2BuyRate),
        limit2SellRate: numOrNull(r.limit2SellRate),
        limit3BuyRate: numOrNull(r.limit3BuyRate),
        limit3SellRate: numOrNull(r.limit3SellRate),
      },
    }))

    // Codex #906: a J–S pillanatképet a `#NN` kereszt-hivatkozásokhoz AKKOR is mentjük, ha a
    // csoportnak nincs képlete (fix-rátás csoport is érvényes hivatkozási cél). Külön helper.
    const saveSnapshot = (rows: WgComputeRow[]) => {
      if (selectedWg?.legacyGroupNumber == null) return
      const byCurrency = new Map<string, WgValues>()
      rows.forEach((row) => {
        const wgv: WgValues = {}
        for (const field of Object.keys(FIELD_TO_WGCOL) as WgField[]) {
          const v = row.values[field]
          if (v != null) wgv[FIELD_TO_WGCOL[field]] = v
        }
        byCurrency.set(row.currencyCode.toUpperCase(), wgv)
      })
      saveGroupValueSnapshot(selectedWg.legacyGroupNumber, byCurrency)
    }

    if (Object.keys(formulas).length === 0) {
      if (Object.keys(cellErrors).length > 0) setCellErrors({})
      // Codex #910 P1: NEM mentünk itt snapshotot — a `rates` tile-váltáskor NEM töltődik újra,
      // így egy korábbi (képletes) csoport számított rátáit mentené a fix-csoport #NN-kulcsa alá
      // (rossz kereszt-hivatkozási célértékek). A fix-rátás csoport #NN-célként-kezelése (#906 P2)
      // tudatosan elhalasztva — a kereszt-csoport korrupció elkerülése a fontosabb.
      return
    }
    const result = recomputeWorkgroupSheet({
      rows: computeRows,
      formulas,
      sheet0ByCurrency: sheetCtxRef.current.sheet0ByCurrency,
      otherGroupsByCurrency: sheetCtxRef.current.otherGroupsByCurrency,
    })
    setCellErrors(result.errors)
    if (result.diverged) {
      logger.warn('RateCreationPage', 'Munkacsoport-lap képlet-újraszámítás nem konvergált (körhivatkozás-gyanú) — a részeredményt elvetjük')
      return
    }

    // A számított értékeket VISSZAÍRJUK a string-mezőkbe (csak a képlet-cellákat).
    let changedOverall = false
    const next = rates.map((r, i) => {
      let nr = r
      for (const field of WG_STRING_FIELDS) {
        if (!formulas[`${r.currencyId}.${field}`]) continue
        const val = result.rows[i]!.values[field]
        const str = val == null ? '' : fmtRate(val)
        if (nr[field] !== str) {
          if (nr === r) nr = { ...r }
          nr[field] = str
          changedOverall = true
        }
      }
      // J (officialRate) NUMBER mező — ha képlete van, a SZÁMÍTOTT J-t írjuk vissza (number).
      if (formulas[`${r.currencyId}.officialRate`]) {
        const ofVal = result.rows[i]!.values.officialRate
        if (ofVal != null && nr.officialRate !== ofVal) {
          if (nr === r) nr = { ...r }
          nr.officialRate = ofVal
          changedOverall = true
        }
      }
      return nr
    })

    // #NN kereszt-hivatkozáshoz: a csoport SZÁMÍTOTT J–S pillanatképét perzisztáljuk.
    saveSnapshot(result.rows)

    if (changedOverall) {
      recomputeGuardRef.current = true
      setRates(next)
    }
  // cellErrors szándékosan kihagyva: csak rates/formulas változásra számolunk újra
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rates, formulas, selectedWg?.legacyGroupNumber])

  const loadData = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      let overviewData: RateOverviewDTO
      let wgData: WorkgroupDetailDTO[]

      if (isLocalRateMakerApp) {
        const bootstrap = await rateCreationApi.getLocalRateMakerBootstrap()
        overviewData = bootstrap.overview
        wgData = bootstrap.workgroups
      } else {
        const [overviewResponse, workgroupResponse] = await Promise.all([
          rateCreationApi.getOverview(),
          rateCreationApi.getWorkgroupDetails(),
        ])
        overviewData = overviewResponse
        wgData = workgroupResponse
      }

      setOverview(overviewData)
      setWorkgroups(wgData)
      setSelectedWgIndex((current) => (wgData[current] ? current : 0))

      const editableRates: EditableRate[] = overviewData.currencies.map((c: RateOverviewItem) => ({
        currencyId: c.currencyId,
        currencyCode: c.currencyCode,
        currencyName: c.currencyName,
        officialRate: c.officialRate,
        buyRate: fmtRate(c.currentBuyRate),
        sellRate: fmtRate(c.currentSellRate),
        limit1BuyRate: fmtRate(c.limit1BuyRate),
        limit1SellRate: fmtRate(c.limit1SellRate),
        limit2BuyRate: fmtRate(c.limit2BuyRate),
        limit2SellRate: fmtRate(c.limit2SellRate),
        limit3BuyRate: fmtRate(c.limit3BuyRate),
        limit3SellRate: fmtRate(c.limit3SellRate),
        hasRate: c.hasRate,
        modified: false,
      }))
      // FR-1: a Főlap (DEFAULT_CURRENCIES) sorrendjébe rendezzük — konzisztens nézet.
      setRates(sortByMainSheetOrder(editableRates))
      // FK02-B / FR-2..5: a perzisztált baseline rögzítése (a 10%-eltérés ehhez mér; publish/save
      // utáni újratöltéskor frissül). Csak a numerikusan értelmezhető mezőket tároljuk.
      const baseline: Record<string, number> = {}
      for (const er of editableRates) {
        for (const field of WG_STRING_FIELDS) {
          const n = numOrNull(String(er[field] ?? ''))
          if (n !== null) baseline[`${er.currencyId}.${field}`] = n
        }
      }
      baselineRatesRef.current = baseline
      // FK02-B / FR-11, FR-12: a fix-érték overlay effekt újrafuttatása (azonos csoportos reload is).
      setReloadVersion(v => v + 1)
    } catch (err) {
      logger.error('RateCreationPage', 'Betöltési hiba:', err)
      setError('Hiba az árfolyam adatok betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [isLocalRateMakerApp])

  useEffect(() => { void loadData() }, [loadData])

  // FK02-B / FR-11, FR-12: a pillanatnyi (perzisztált) fix-érték store a snapshothoz/visszaállításhoz.
  const currentSavedRateValues = useCallback((): Record<string, string> => {
    const id = selectedWg?.id
    return id ? loadGroupRateValues(id) : {}
  }, [selectedWg?.id])

  // FK02-B / FR-11, FR-12: a sávmezők (Lehúzás / Sávok törlése) fix értékeinek perzisztálása.
  // Cél-mezőnként frissít (üres → törlés), a buy/sell mezőket nem érinti — sparse store marad.
  const persistBandFields = useCallback((ratesArr: EditableRate[]) => {
    const id = selectedWg?.id
    if (!id) return
    const BANDS: Exclude<WgField, 'officialRate'>[] = [
      'limit1BuyRate', 'limit1SellRate', 'limit2BuyRate', 'limit2SellRate', 'limit3BuyRate', 'limit3SellRate',
    ]
    const saved = loadGroupRateValues(id)
    for (const r of ratesArr) {
      for (const field of BANDS) {
        const key = `${r.currencyId}.${field}`
        if (formulas[key]) continue
        const v = r[field]
        if (typeof v === 'string' && v !== '') saved[key] = v
        else delete saved[key]
      }
    }
    saveGroupRateValues(id, saved)
  }, [selectedWg?.id, formulas])

  const pushUndo = useCallback(() => {
    undoStack.current.push({ rates: rates.map(r => ({ ...r })), formulas: { ...formulas }, savedRateValues: currentSavedRateValues() })
    if (undoStack.current.length > 50) undoStack.current.shift()
    redoStack.current = []
  }, [rates, formulas, currentSavedRateValues])

  const undo = useCallback(() => {
    const prev = undoStack.current.pop()
    if (!prev) return
    const id = selectedWg?.id
    redoStack.current.push({ rates: rates.map(r => ({ ...r })), formulas: { ...formulas }, savedRateValues: currentSavedRateValues() })
    setRates(prev.rates)
    setFormulas(prev.formulas)
    if (id) saveGroupRateValues(id, prev.savedRateValues)
  }, [rates, formulas, currentSavedRateValues, selectedWg?.id])

  const redo = useCallback(() => {
    const nextState = redoStack.current.pop()
    if (!nextState) return
    const id = selectedWg?.id
    undoStack.current.push({ rates: rates.map(r => ({ ...r })), formulas: { ...formulas }, savedRateValues: currentSavedRateValues() })
    setRates(nextState.rates)
    setFormulas(nextState.formulas)
    if (id) saveGroupRateValues(id, nextState.savedRateValues)
  }, [rates, formulas, currentSavedRateValues, selectedWg?.id])

  // Ctrl+Z / Ctrl+Y global handler
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
        e.preventDefault()
        undo()
      } else if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) {
        e.preventDefault()
        redo()
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [undo, redo])

  const updateRate = (index: number, field: keyof EditableRate, value: string) => {
    pushUndo()
    setRates(prev => {
      const updated = [...prev]
      const existing = updated[index]
      if (!existing) return prev
      updated[index] = { ...existing, [field]: value, modified: true }
      return updated
    })
  }

  /**
   * FK-04/C cella-commit (a RateGrid blur/Enter-kor hívja). Ha az input KÉPLET
   * (nem tiszta szám), a képlet-stringet tároljuk (a számított érték a recompute-ból
   * jön); ha fix szám/üres, töröljük az esetleges képletet és a nyers értéket írjuk be.
   */
  const commitWorkgroupCell = useCallback((index: number, field: WgField, raw: string) => {
    if (!canWriteRateCreation) return
    const r = rates[index]
    if (!r) return
    const key = `${r.currencyId}.${field}`
    const trimmed = raw.trim()
    const wgId = selectedWg?.id

    const applyCommit = () => {
      pushUndo()
      if (isFormula(trimmed)) {
        setFormulas(prev => (prev[key] === trimmed ? prev : { ...prev, [key]: trimmed }))
        setRates(prev => prev.map((x, i) => (i === index ? { ...x, modified: true } : x)))
      } else {
        setFormulas(prev => {
          if (!prev[key]) return prev
          const copy = { ...prev }
          delete copy[key]
          return copy
        })
        if (field === 'officialRate') {
          // J (Elszámoló) NUMBER mező (a többi string). Fix override → parse; üres → undefined (auto = 0-s lap A).
          const n = numOrNull(trimmed)
          setRates(prev => prev.map((x, i) => (i === index ? { ...x, officialRate: n, modified: true } : x)))
        } else {
          setRates(prev => prev.map((x, i) => (i === index ? { ...x, [field]: trimmed, modified: true } : x)))
        }
      }

      // FK02-B / FR-11, FR-12: a fix (nem-formulás) érték localStorage-perzisztálása csoportonként,
      // hogy lapváltás/újratöltés után is megmaradjon. Formula vagy üres beírás → töröljük a kulcsot
      // (a recompute, ill. a szerver-bootstrap veszi át). A J (officialRate) itt nincs perzisztálva.
      if (wgId && field !== 'officialRate') {
        const saved = loadGroupRateValues(wgId)
        if (isFormula(trimmed) || trimmed === '') {
          if (key in saved) { delete saved[key]; saveGroupRateValues(wgId, saved) }
        } else if (saved[key] !== trimmed) {
          saved[key] = trimmed
          saveGroupRateValues(wgId, saved)
        }
      }
    }

    // FK02-B / FR-2..5: fix számra cserélt vétel/eladás/sáv mező esetén, ha az új érték a
    // PERZISZTÁLT (loadData-kor betöltött) értékhez képest ≥10%-ot tér el, megerősítést kérünk a
    // mentés ELŐTT. A baseline a perzisztált snapshot (NEM a session közbeni r[field]), így a
    // lépésenkénti elcsúszás (400→430→470 = 17.5%) is kiszúrható. 'Nem' → a cella visszaáll, a
    // mentés abortál. A formula- és a J (officialRate) mezőt nem korlátozzuk.
    if (!isFormula(trimmed) && field !== 'officialRate') {
      const prevVal = baselineRatesRef.current[key] ?? numOrNull(String(r[field] ?? ''))
      const nextVal = numOrNull(trimmed)
      if (isSignificantDeviation(prevVal, nextVal)) {
        const pct = Math.round((Math.abs((nextVal as number) - (prevVal as number)) / Math.abs(prevVal as number)) * 100)
        setRateConfirm({
          title: 'Nagy árfolyam-eltérés',
          message: `${r.currencyCode} – ${WG_FIELD_LABEL[field] ?? field}: ${prevVal} → ${nextVal} (${pct}% eltérés a korábbi értékhez képest). Biztosan elmenti?`,
          confirmLabel: 'Igen, mentem',
          danger: true,
          onConfirm: () => { applyCommit(); setRateConfirm(null) },
        })
        return
      }
    }
    applyCommit()
  }, [canWriteRateCreation, rates, pushUndo, selectedWg?.id])

  // ===================== Limit save =====================

  const handleSaveLimits = async () => {
    if (!selectedWg) return
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'A határok mentéséhez főértéktáros vagy ügyvezető szerepkör kell')
      return
    }
    setSavingLimits(true)
    try {
      await rateCreationApi.updateWorkgroupLimits(selectedWg.id, {
        limit1Boundary: parseInt(editLimits.l1) || 0,
        limit2Boundary: parseInt(editLimits.l2) || 0,
        limit3Boundary: parseInt(editLimits.l3) || 0,
      })
      toast.success('Mentve', 'Kedvezmény határok frissítve')
      setLimitsModified(false)
      void loadData()
    } catch (err) {
      if (err instanceof AxiosError && err.response?.status === 403) {
        toast.error('Nincs jogosultság', 'A határok mentéséhez főértéktáros vagy ügyvezető szerepkör kell')
      } else {
        toast.error('Hiba', 'Nem sikerült a határok mentése')
      }
    } finally {
      setSavingLimits(false)
    }
  }

  const handleLimitChange = (key: 'l1' | 'l2' | 'l3', val: string) => {
    setEditLimits(prev => ({ ...prev, [key]: val }))
    setLimitsModified(true)
  }

  // ===================== Branch management =====================

  const openBranchPicker = async () => {
    if (!selectedWg) return
    try {
      const branches = await rateCreationApi.getBranches(selectedWg.id)
      setAllBranches(branches)
      setSelectedBranchIds(new Set(branches.filter(b => b.assignedToCurrentWorkgroup).map(b => b.id)))
      setBranchFilter('')
      setBranchModalOpen(true)
    } catch {
      toast.error('Hiba', 'Nem sikerült az irodák betöltése')
    }
  }

  const handleSaveBranches = async () => {
    if (!selectedWg) return
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'Irodák mentéséhez főértéktáros vagy ügyvezető szerepkör kell')
      return
    }
    setSavingBranches(true)
    try {
      await rateCreationApi.updateWorkgroupBranches(selectedWg.id, Array.from(selectedBranchIds))
      toast.success('Mentve', 'Irodák frissítve')
      setBranchModalOpen(false)
      void loadData()
    } catch (err) {
      if (err instanceof AxiosError && err.response?.status === 403) {
        toast.error('Nincs jogosultság', 'Irodák mentéséhez főértéktáros vagy ügyvezető szerepkör kell')
      } else {
        toast.error('Hiba', 'Nem sikerült az irodák mentése')
      }
    } finally {
      setSavingBranches(false)
    }
  }

  const removeBranch = async (branchId: string) => {
    if (!selectedWg) return
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'Iroda eltávolításához főértéktáros vagy ügyvezető szerepkör kell')
      return
    }
    const newIds = selectedWg.branches.filter(b => b.id !== branchId).map(b => b.id)
    try {
      await rateCreationApi.updateWorkgroupBranches(selectedWg.id, newIds)
      toast.success('Eltávolítva', 'Iroda eltávolítva a csoportból')
      void loadData()
    } catch (err) {
      if (err instanceof AxiosError && err.response?.status === 403) {
        toast.error('Nincs jogosultság', 'Iroda eltávolításához főértéktáros vagy ügyvezető szerepkör kell')
      } else {
        toast.error('Hiba', 'Nem sikerült az iroda eltávolítása')
      }
    }
  }

  const toggleBranch = (id: string) => {
    setSelectedBranchIds(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  // ===================== Kitöltési segítség (FR-RFM-23) =====================

  /** Adat lehúzás: a 0-s vételi/eladási árfolyamot a 3 kedvezménysávba tölti. */
  const applyFillDown = (overwrite: boolean) => {
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'A kitöltési segítséghez főértéktáros vagy ügyvezető szerepkör kell')
      return
    }
    // Copilot #829: a számlálót a handlerben, a jelenlegi `rates` alapján képezzük
    // (a setRates updater StrictMode-ban duplán is lefuthat → megbízhatatlan).
    let touched = 0
    const nextRates = rates.map(r => {
      const next = fillDownLimitBands(r, { overwrite })
      if (next !== r) touched++
      return next
    })
    if (touched === 0) {
      toast.info('Nincs változás', 'Nincs lehúzható 0-s árfolyam')
      return
    }
    pushUndo()
    setRates(nextRates)
    persistBandFields(nextRates)
    toast.success('Lehúzva', overwrite
      ? `${touched} valuta sávjai felülírva a 0-s árfolyammal`
      : `${touched} valuta üres sávja feltöltve a 0-s árfolyammal`)
  }

  /** Sávok törlése: a 3 kedvezménysáv kiürítése (visszaesik a 0-s alapra). */
  const applyClearBands = () => {
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'A kitöltési segítséghez főértéktáros vagy ügyvezető szerepkör kell')
      return
    }
    let touched = 0
    const nextRates = rates.map(r => {
      const next = clearLimitBands(r)
      if (next !== r) touched++
      return next
    })
    if (touched === 0) {
      toast.info('Nincs változás', 'Nincs törölhető kedvezménysáv')
      return
    }
    pushUndo()
    setRates(nextRates)
    persistBandFields(nextRates)
    toast.success('Törölve', `${touched} valuta kedvezménysávja kiürítve`)
  }

  // ===================== Publish =====================

  const handlePublish = async () => {
    if (!selectedWg) {
      toast.warning('Munkacsoport szükséges', 'Válasszon munkacsoportot!')
      return
    }
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'Publikáláshoz főértéktáros vagy ügyvezető szerepkör kell')
      return
    }

    const validRates = rates.filter(r => {
      const buy = parseNum(r.buyRate)
      const sell = parseNum(r.sellRate)
      return buy > 0 && sell > 0
    })

    if (validRates.length === 0) {
      toast.warning('Nincs árfolyam', 'Nincs érvényes árfolyam a publikáláshoz!')
      return
    }

    for (const r of validRates) {
      const buy = parseNum(r.buyRate)
      const sell = parseNum(r.sellRate)
      if (buy >= sell) {
        toast.error('Hibás árfolyam', `${r.currencyCode}: Vétel (${r.buyRate}) >= Eladás (${r.sellRate})`)
        return
      }
    }

    // FK-04/E árfolyamvédelem (Kasza Helga spec): ha a csoport védelme BE van kapcsolva,
    // a publikálás előtt — azonnal, a szerver-kör nélkül — ellenőrizzük, hogy egyetlen vételi
    // (L,N,P,R) sem magasabb, és egyetlen eladási (M,O,Q,S) sem alacsonyabb a J elszámolónál.
    // A backend (RatePublishService.validateRateProtection) AZONOS szabállyal véd a kiküldéskor.
    if (selectedWg.protectionEnabled ?? true) {
      const protectionRows: ProtectionRow[] = validRates.map((r) => ({
        currencyCode: r.currencyCode,
        official: r.officialRate,
        buy: parseNum(r.buyRate),
        sell: parseNum(r.sellRate),
        limit1Buy: parseNum(r.limit1BuyRate),
        limit1Sell: parseNum(r.limit1SellRate),
        limit2Buy: parseNum(r.limit2BuyRate),
        limit2Sell: parseNum(r.limit2SellRate),
        limit3Buy: parseNum(r.limit3BuyRate),
        limit3Sell: parseNum(r.limit3SellRate),
      }))
      const violations = validateWorkgroupProtection(
        protectionRows,
        true,
        workgroupProtectionLabel(selectedWg.legacyGroupNumber, selectedWg.code),
      )
      if (violations.length > 0) {
        toast.error(
          'Árfolyamvédelem',
          `${violations.length} szabálysértő ráta — javítsd a publikálás előtt. ${violations[0]!.message}`,
        )
        return
      }
    }

    // BACKLOG-004 fix: Block publish if any validation error exists (limit/MNB checks)
    const errorCurrencyIds = Object.keys(validationErrors)
    if (errorCurrencyIds.length > 0) {
      const affectedCodes = validRates
        .filter(r => validationErrors[r.currencyId])
        .map(r => r.currencyCode)
      toast.error(
        'Validációs hiba',
        `${affectedCodes.join(', ')}: Javítsd a hibákat a publikálás előtt!`
      )
      return
    }

    setPublishing(true)
    try {
      const publishResult = await rateCreationApi.publishGroupRate({
        groupId: selectedWg.id,
        rates: validRates.map(r => ({
          currencyId: r.currencyId,
          buyRate: parseNum(r.buyRate),
          sellRate: parseNum(r.sellRate),
          officialRate: r.officialRate,
          limit1Amount: selectedWg.limit1Boundary || null,
          limit1BuyRate: parseNum(r.limit1BuyRate) || null,
          limit1SellRate: parseNum(r.limit1SellRate) || null,
          limit2Amount: selectedWg.limit2Boundary || null,
          limit2BuyRate: parseNum(r.limit2BuyRate) || null,
          limit2SellRate: parseNum(r.limit2SellRate) || null,
          limit3Amount: selectedWg.limit3Boundary || null,
          limit3BuyRate: parseNum(r.limit3BuyRate) || null,
          limit3SellRate: parseNum(r.limit3SellRate) || null,
        }))
      })
      if (publishResult && 'publicationId' in publishResult) {
        toast.success(
          'Publikálva!',
          `${publishResult.acceptedRates} árfolyam kiküldve: ${selectedWg.name} (${publishResult.affectedBranches} iroda)`
        )
      } else {
        toast.success('Publikálva!', `${validRates.length} árfolyam kiküldve: ${selectedWg.name} (${selectedWg.branches.length} iroda)`)
      }
      // FK02-B / FR-11, FR-12: publikálás után a szerver az authority (vö. published_rate
      // server_authority policy) — a csoport helyi fix-érték overlay-ét töröljük, hogy ne árnyékolja
      // a friss szerver-értékeket. A loadData() ezután a publikált értékeket tölti vissza.
      saveGroupRateValues(selectedWg.id, {})
      void loadData()
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Hiba a publikálás során'
      toast.error('Publikálási hiba', msg)
    } finally {
      setPublishing(false)
    }
  }

  // Grouped branches for modal
  const groupedBranches = useMemo(() => {
    const filtered = branchFilter
      ? allBranches.filter(b =>
          b.name.toLowerCase().includes(branchFilter.toLowerCase()) ||
          b.code.toLowerCase().includes(branchFilter.toLowerCase()) ||
          b.city.toLowerCase().includes(branchFilter.toLowerCase())
        )
      : allBranches
    const groups: Record<string, BranchListItem[]> = {}
    for (const b of filtered) {
      const city = b.city || 'Egyeb'
      if (!groups[city]) groups[city] = []
      groups[city].push(b)
    }
    return Object.entries(groups).sort(([a], [b]) => a.localeCompare(b, 'hu'))
  }, [allBranches, branchFilter])

  // ===================== Render =====================

  // BACKLOG-004: Validation error list per rate row (must be before early returns for hooks)
  const validationErrors = useMemo(() => {
    const errors: Record<number, string[]> = {}
    for (const r of rates) {
      const errs: string[] = []
      const buy = parseNum(r.buyRate)
      const sell = parseNum(r.sellRate)
      if (buy > 0 && sell > 0 && buy >= sell) {
        errs.push('Vétel ≥ Eladás')
      }
      // Limit consistency checks
      const l1b = parseNum(r.limit1BuyRate), l1s = parseNum(r.limit1SellRate)
      if (l1b > 0 && l1s > 0 && l1b >= l1s) errs.push('L1: Vétel ≥ Eladás')
      const l2b = parseNum(r.limit2BuyRate), l2s = parseNum(r.limit2SellRate)
      if (l2b > 0 && l2s > 0 && l2b >= l2s) errs.push('L2: Vétel ≥ Eladás')
      const l3b = parseNum(r.limit3BuyRate), l3s = parseNum(r.limit3SellRate)
      if (l3b > 0 && l3s > 0 && l3b >= l3s) errs.push('L3: Vétel ≥ Eladás')
      // Buy rate should be ≤ official rate (if both present)
      if (r.officialRate && buy > 0 && buy > r.officialRate * 1.1) {
        errs.push('Vétel > MNB +10%')
      }
      if (errs.length > 0) errors[r.currencyId] = errs
    }
    return errors
  }, [rates])

  // ===================== FK-02/03/04: Tile-list view =====================
  // Csempés listanézet az induló képernyő — a régi „bal oldali sávos" 54-csempés
  // jobboldali választó HELYETT a UI teljes szélességében.
  //
  // FONTOS: a tile-list ág a `loading && !overview` ÚTÁN visszatérő `<Loader/>`-nél
  // ELŐBB futtatandó, hogy az első bootstrap-load alatt is a csempés UI látsszon
  // (a WorkgroupTileListView saját maga rendel loading-state placeholder-t a
  // `workgroups` üres és `loading=true` esetére — single source of truth).
  if (viewMode === 'tile-list') {
    return <WorkgroupTileListView
      workgroups={workgroups}
      canWrite={canWriteRateCreation}
      onSelect={(idx) => { setSelectedWgIndex(idx); setViewMode('editor') }}
      onBackToMain={() => navigate('/rates/main')}
      onReload={() => void loadData()}
      loading={loading}
      error={error}
    />
  }

  // Editor mode: a klasszikus szerkesztő UI bootstrap-betöltést vár.
  if (loading && !overview) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="animate-spin text-blue-600" size={32} />
        <span className="ml-3 text-gray-600">Árfolyamok betöltése...</span>
      </div>
    )
  }

  const modifiedCount = rates.filter(r => r.modified).length

  // ===================== Editor view =====================
  return (
    /* 2026-04-29 v2.3.13 (Árfolyamkészítés zoom-fit): a top-toolbar magassága
       9.5rem-ról 8rem-ra csökkentve, hogy 17 valuta scrollozás nélkül elférjen
       632px viewport-ban is (audit-feedback alapján). */
    <div className="h-[calc(100vh-8rem)] flex flex-col">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-1 rounded flex items-center gap-2 text-xs mb-1">
          <AlertTriangle size={14} /> {error}
        </div>
      )}

      {/* === HEADER BAR === */}
      <div className="flex items-center justify-between bg-white px-3 py-1.5 rounded shadow-sm border mb-1">
        <div className="flex items-center gap-2">
          <h1 className="text-sm font-bold text-gray-800">{t('rates.arfolyamkeszites')}</h1>
          {/* FK-02/03/04: vissza a csempés listanézetre — a docx kérése „visszagombbal". */}
          <button
            onClick={() => setViewMode('tile-list')}
            className="flex items-center gap-1 px-2 py-0.5 text-[11px] font-medium border border-blue-400 bg-blue-50 hover:bg-blue-100 text-blue-800 rounded"
            title="Vissza a csoport árfolyamlapok csempés listájához"
          >
            <ArrowLeft size={11} /> Csempés nézet
          </button>
          {/* Spec szerint: Munkacsoport felület felső menü → MÁSIK MUNKACSOPORT (visszalépés a 0-s lapra/csoport-választóra) */}
          <button
            onClick={() => navigate('/rates/main')}
            className="flex items-center gap-1 px-2 py-0.5 text-[11px] font-medium border border-orange-400 bg-orange-50 hover:bg-orange-100 text-orange-800 rounded"
            title="Vissza a Főlap (0-s lap) elszámoló árfolyamokhoz"
          >
            <Home size={11} /> FŐLAP
          </button>
          {/* T9.F: képletszintaxis-súgó — itt, ahol a J–S/#NNL képleteket írják. */}
          <FormulaSyntaxHelpButton onClick={() => setShowFormulaHelp(true)} />
          {selectedWg && (
            <span className="text-xs text-gray-500 ml-2">
              <span className="font-mono font-bold">{selectedWg.legacyGroupNumber ?? '—'}</span>
              <span className="mx-1">·</span>
              <span className="font-semibold text-gray-700">{selectedWg.name}</span>
              <span className="ml-1 text-gray-400">({selectedWg.code})</span>
            </span>
          )}
        </div>
        <div className="flex items-center gap-3 text-xs">
          {overview && (
            <span className="text-gray-400 flex items-center gap-1">
              <Clock size={11} />
              {new Date(overview.generatedAt).toLocaleString('hu-HU')}
            </span>
          )}
          <button onClick={undo} disabled={undoStack.current.length === 0}
            className="p-0.5 rounded hover:bg-gray-100 disabled:opacity-30" title="Visszavonás (Ctrl+Z)">
            <Undo2 size={13} />
          </button>
          <button onClick={redo} disabled={redoStack.current.length === 0}
            className="p-0.5 rounded hover:bg-gray-100 disabled:opacity-30" title="Mégis (Ctrl+Y)">
            <Redo2 size={13} />
          </button>
          {modifiedCount > 0 && (
            <span className="text-orange-600 font-medium">{modifiedCount} {t('rates.mod')}</span>
          )}
          <button onClick={() => void loadData()} disabled={loading}
            className="px-2 py-0.5 border rounded text-xs hover:bg-gray-50 flex items-center gap-1">
            <RefreshCw size={11} className={loading ? 'animate-spin' : ''} />
          </button>
        </div>
      </div>

      {/* === MAIN LAYOUT === */}
      <div className="flex gap-1.5 flex-1 min-h-0">

        {/* === LEFT: RATE TABLE === */}
        <RateGrid
          rates={rates}
          selectedWg={selectedWg}
          updateRate={updateRate}
          validationErrors={validationErrors}
          formulas={formulas}
          cellErrors={cellErrors}
          onCommitCell={commitWorkgroupCell}
          revertSignal={rateRevertSignal}
        />

        {/* FK02-B / FR-2..5: 10%-eltérés megerősítő modal (cella-commit interception).
            "Mégse" → a mentés abortál ÉS a cella visszaáll a perzisztált értékre (revert-jelzés). */}
        {rateConfirm && (
          <ConfirmDialog
            state={rateConfirm}
            onCancel={() => { setRateConfirm(null); setRateRevertSignal(n => n + 1) }}
          />
        )}

        {/* === RIGHT: WORKGROUP PANEL === */}
        <div className="w-64 flex-shrink-0 flex flex-col gap-1 min-h-0">

          {/* FK-02/03/04 (2026-05-28): a régi 54-csempés jobb-oldali választó ELTÁVOLÍTVA.
              A csempés listanézet (viewMode='tile-list') a teljes szélességben kezeli a
              csoportváltást. Helyette egy „Vissza" gombbal kompakt info-kártya — utalja
              a usert, hogy a csoportlistába visszamehet. */}
          <button
            onClick={() => setViewMode('tile-list')}
            className="bg-white rounded border shadow-sm px-2 py-1.5 flex-shrink-0 text-left hover:bg-blue-50 transition-colors"
            title="Vissza a csoport árfolyamlapok csempés listájához"
          >
            <div className="text-[10px] text-gray-500 uppercase font-bold mb-1 flex items-center gap-1">
              <ArrowLeft size={10} /> Csempés nézet
            </div>
            <div className="text-[11px] font-semibold text-gray-700 truncate">
              {selectedWg?.name ?? '—'}
            </div>
            <div className="text-[10px] text-gray-500">
              #{selectedWg?.legacyGroupNumber ?? '—'} · {selectedWg?.branches.length ?? 0} iroda
            </div>
          </button>

          {/* Aktuális függvény (FR-RFM-22) + Kitöltési segítség (FR-RFM-23) */}
          <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-shrink-0">
            <div className="flex items-center justify-between mb-1">
              <span className="text-[10px] text-gray-500 uppercase font-bold">Aktuális függvény</span>
              <span
                className="px-1.5 py-0.5 rounded bg-indigo-50 border border-indigo-200 text-indigo-800 font-mono text-[11px] font-bold"
                title="A csoportlapon aktív képletkód-azonosító (a munkacsoport sorszámából képezve)."
              >
                {currentFunctionCode(selectedWg?.legacyGroupNumber)}
              </span>
            </div>
            <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">Kitöltési segítség</div>
            <div className="grid grid-cols-3 gap-1">
              <button
                onClick={() => applyFillDown(false)}
                disabled={!canWriteRateCreation}
                className="px-1 py-1 rounded border border-green-300 bg-green-50 hover:bg-green-100 disabled:opacity-40 text-green-800 text-[9px] font-semibold leading-tight"
                title="A 0-s vételi/eladási árfolyamot lehúzza az ÜRES kedvezménysávokba (kézi értékek megmaradnak)"
              >
                Lehúzás (üres)
              </button>
              <button
                onClick={() => applyFillDown(true)}
                disabled={!canWriteRateCreation}
                className="px-1 py-1 rounded border border-amber-300 bg-amber-50 hover:bg-amber-100 disabled:opacity-40 text-amber-800 text-[9px] font-semibold leading-tight"
                title="A 0-s árfolyamot MINDEN kedvezménysávba felülírva lehúzza (Excel drag-fill)"
              >
                Lehúzás (mind)
              </button>
              <button
                onClick={applyClearBands}
                disabled={!canWriteRateCreation}
                className="px-1 py-1 rounded border border-red-300 bg-red-50 hover:bg-red-100 disabled:opacity-40 text-red-800 text-[9px] font-semibold leading-tight"
                title="A 3 kedvezménysáv kiürítése (visszaesik a 0-s alapárfolyamra)"
              >
                Sávok törlése
              </button>
            </div>
          </div>

          {/* Branch list */}
          <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-1 min-h-0 flex flex-col overflow-hidden">
            <div className="flex items-center justify-between mb-1">
              <span className="text-[10px] text-gray-500 uppercase font-bold flex items-center gap-1">
                <Building2 size={10} />
                {t('rates.irodak')} ({selectedWg?.branches.length ?? 0})
              </span>
              <button onClick={() => void openBranchPicker()}
                disabled={!canWriteRateCreation}
                className="w-5 h-5 rounded bg-blue-500 hover:bg-blue-600 text-white flex items-center justify-center"
                title="Iroda hozzáadása">
                <Plus size={12} />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto space-y-0.5">
              {selectedWg?.branches.length ? (
                selectedWg.branches.map(b => (
                  <div key={b.id} className="flex items-center justify-between px-1.5 py-0.5 bg-gray-50 rounded border border-gray-200 text-[11px] text-gray-700 group">
                    <span className="truncate">{b.name}</span>
                    <button onClick={() => void removeBranch(b.id)}
                      disabled={!canWriteRateCreation}
                      className="opacity-0 group-hover:opacity-100 text-red-400 hover:text-red-600 flex-shrink-0 ml-1"
                      title="Eltávolítás">
                      <X size={12} />
                    </button>
                  </div>
                ))
              ) : (
                <div className="text-gray-400 italic text-center text-[10px] py-2">{t('rates.nincsIrodaHozzarendelve')}</div>
              )}
            </div>
          </div>

          {/* Limit boundaries - editable */}
          <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-shrink-0">
            <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">{t('rates.hatarokFt')}</div>
            <div className="space-y-1">
              {([
                { key: 'l1' as const, label: 'Alsó' },
                { key: 'l2' as const, label: 'Középső' },
                { key: 'l3' as const, label: 'Felső' },
              ]).map(({ key, label }) => (
                <div key={key} className="flex items-center gap-1">
                  <span className="text-[10px] font-bold text-blue-700 w-14">{label}</span>
                  <input
                    type="text"
                    value={editLimits[key]}
                    onChange={e => handleLimitChange(key, e.target.value)}
                    disabled={!canWriteRateCreation}
                    className="flex-1 px-1.5 py-0.5 text-right font-mono text-[11px] font-bold border rounded bg-gray-50 focus:bg-white focus:border-blue-400 focus:outline-none"
                  />
                </div>
              ))}
            </div>
            {limitsModified && canWriteRateCreation && (
              <button onClick={() => void handleSaveLimits()} disabled={savingLimits}
                className="w-full mt-1 px-2 py-0.5 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white text-[10px] font-bold rounded">
                {savingLimits ? 'Mentés...' : 'Határok mentése'}
              </button>
            )}
          </div>

          {/* Publish button - always visible */}
          <button
            onClick={() => void handlePublish()}
            disabled={publishing || !selectedWg || !canWriteRateCreation}
            className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-400 text-white font-bold py-2.5 px-3 rounded shadow flex items-center justify-center gap-2 transition-colors flex-shrink-0"
          >
            {publishing ? (
              <RefreshCw size={16} className="animate-spin" />
            ) : (
              <Send size={16} />
            )}
            <span className="text-xs">{t('rates.arfolyamokSzetkuldese')}</span>
          </button>
        </div>
      </div>

      {/* === BRANCH PICKER MODAL === */}
      <BranchPickerModal
        open={branchModalOpen}
        selectedWgName={selectedWg?.name}
        branchFilter={branchFilter}
        setBranchFilter={setBranchFilter}
        groupedBranches={groupedBranches}
        selectedBranchIds={selectedBranchIds}
        toggleBranch={toggleBranch}
        onClose={() => setBranchModalOpen(false)}
        onSave={() => void handleSaveBranches()}
        saving={savingBranches}
        canWriteRateCreation={canWriteRateCreation}
      />
      {/* T9.F: képletszintaxis-súgó modal */}
      <FormulaSyntaxHelp open={showFormulaHelp} onClose={() => setShowFormulaHelp(false)} />
    </div>
  )
}

// ===================== FK-02/03/04 Tile-list view =====================
// Csempés listanézet (a régi „bal oldali sávos" 54-csoport választó HELYETT).
// Spec: Kasza Helga / Bali Henriett 2026-05-28 docx (FK-02 + FK-03 + FK-04).
// - Egy csempén: sorszám, név, kód, árfolyamvédelem-checkbox a jobb felső sarokban.
// - Egy klikk a csempére → azonnal megnyitja a csoport árfolyamlap szerkesztőt.
// - 10 választható csempeszín (tileColor mező a backendben).

/** WorkgroupDetailDTO → RateWorkgroupSaveDTO (a karbantartó create/update payload-ja). */
function toWorkgroupSaveDTO(wg: WorkgroupDetailDTO, overrides?: Partial<RateWorkgroupSaveDTO>): RateWorkgroupSaveDTO {
  return {
    name: wg.name,
    code: wg.code,
    legacyGroupNumber: wg.legacyGroupNumber ?? undefined,
    active: wg.active,
    tileColor: wg.tileColor ?? null,
    protectionEnabled: wg.protectionEnabled ?? null,
    limit1Boundary: wg.limit1Boundary,
    limit2Boundary: wg.limit2Boundary,
    limit3Boundary: wg.limit3Boundary,
    ...overrides,
  }
}

interface TileListProps {
  workgroups: WorkgroupDetailDTO[]
  /** FK-02: csak írásjogú árfolyamkészítő (FOERTEKTAR/UGYVEZETO/ADMIN) láthatja a karbantartó akciókat. */
  canWrite: boolean
  onSelect: (idx: number) => void
  onBackToMain: () => void
  onReload: () => void
  loading: boolean
  error: string | null
}

// Exportált a fókuszált FK-02 teszthez (a teljes RateCreationPage túl nehéz egységként).
export function WorkgroupTileListView({ workgroups, canWrite, onSelect, onBackToMain, onReload, loading, error }: TileListProps) {
  // FK-02 §3: az árfolyamkészítő EGYSÉGES munkacsoport-kezelő felülete. A korábbi
  // read-only csempe helyett itt érhetők el a karbantartó műveletek is (létrehozás,
  // átnevezés/szín/határ, törlés, interaktív árfolyamvédelem) — a megosztott
  // `workgroupMaintenance` primitíveken + `rateWorkgroupApi`-n keresztül, hogy a
  // WorkgroupManager-rel egyetlen forrásból menjen az írás. A csempe-kattintás
  // változatlanul a csoport árfolyamlapját nyitja meg (onSelect).
  const [editorOpen, setEditorOpen] = useState(false)
  const [editorMode, setEditorMode] = useState<'create' | 'rename'>('create')
  const [editingId, setEditingId] = useState<string | null>(null)
  const [draft, setDraft] = useState<RateWorkgroupSaveDTO>({ name: '', code: '', active: true, tileColor: DEFAULT_TILE.key })
  const [confirm, setConfirm] = useState<ConfirmState | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const openCreate = () => {
    setEditorMode('create')
    setEditingId(null)
    setDraft({ name: '', code: '', legacyGroupNumber: undefined, active: true, tileColor: DEFAULT_TILE.key,
      protectionEnabled: true, limit1Boundary: null, limit2Boundary: null, limit3Boundary: null })
    setActionError(null)
    setEditorOpen(true)
  }

  const openRename = (wg: WorkgroupDetailDTO) => {
    setEditorMode('rename')
    setEditingId(wg.id)
    setDraft(toWorkgroupSaveDTO(wg))
    setActionError(null)
    setEditorOpen(true)
  }

  const saveEditor = async () => {
    if (!draft.name.trim() || !draft.code.trim()) {
      setActionError('A név és a kód megadása kötelező.')
      return
    }
    try {
      if (editorMode === 'create') {
        await rateWorkgroupApi.create(draft)
      } else if (editingId) {
        await rateWorkgroupApi.update(editingId, draft)
      }
      setEditorOpen(false)
      setActionError(null)
      onReload()
    } catch (err) {
      logger.error('RateCreationPage', 'Munkacsoport mentése sikertelen:', err)
      setActionError('A mentés sikertelen (a kód már létezhet).')
    }
  }

  // FK-04/E: árfolyamvédelem-toggle a csempén. A teljes mezőkészletet visszaküldjük
  // (a backend PUT teljes csere), csak a protectionEnabled-et írjuk felül.
  const toggleProtection = async (wg: WorkgroupDetailDTO, next: boolean) => {
    try {
      await rateWorkgroupApi.update(wg.id, toWorkgroupSaveDTO(wg, { protectionEnabled: next }))
      setActionError(null) // Copilot: sikeres művelet törölje a korábbi hibabannert.
      onReload()
    } catch (err) {
      logger.error('RateCreationPage', 'Árfolyamvédelem-toggle sikertelen:', err)
      setActionError('A védelem mentése sikertelen.')
    }
  }

  const requestDelete = (wg: WorkgroupDetailDTO) => {
    setConfirm({
      title: 'Munkacsoport törlése',
      message: `Biztosan törli a(z) "${wg.name}" munkacsoportot? A hozzárendelt pénztárak felszabadulnak, az árfolyam-előzmények megmaradnak.`,
      confirmLabel: 'Törlés',
      danger: true,
      onConfirm: async () => {
        try {
          await rateWorkgroupApi.remove(wg.id)
          setConfirm(null)
          setActionError(null) // Copilot: sikeres törlés törölje a korábbi hibabannert.
          onReload()
        } catch (err) {
          logger.error('RateCreationPage', 'Munkacsoport törlése sikertelen:', err)
          setActionError('A törlés sikertelen.')
          setConfirm(null)
        }
      },
    })
  }

  return (
    <div className="space-y-3">
      {/* HEADER */}
      <div className="flex items-center justify-between bg-white px-3 py-2 rounded shadow-sm border">
        <div className="flex items-center gap-2">
          <h1 className="text-base font-bold text-gray-800">Csoport árfolyamlapok</h1>
          <span className="text-xs text-gray-500">({workgroups.length})</span>
          <button
            onClick={onBackToMain}
            className="ml-2 flex items-center gap-1 px-2 py-0.5 text-[11px] font-medium border border-orange-400 bg-orange-50 hover:bg-orange-100 text-orange-800 rounded"
            title="Vissza a Főlap (0-s lap) elszámoló árfolyamokhoz"
          >
            <Home size={11} /> FŐLAP
          </button>
        </div>
        <div className="flex items-center gap-2">
          {canWrite && (
            <button
              onClick={openCreate}
              className="flex items-center gap-1 px-2 py-1 text-[11px] font-semibold border border-blue-500 bg-blue-600 hover:bg-blue-700 text-white rounded"
              title="Új munkacsoport létrehozása"
            >
              <Plus size={12} /> Új munkacsoport
            </button>
          )}
          <button
            onClick={onReload}
            disabled={loading}
            className="p-1 rounded hover:bg-gray-100 disabled:opacity-30"
            title="Frissítés"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          </button>
        </div>
      </div>

      {(error || actionError) && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded flex items-center gap-2 text-sm">
          <AlertTriangle size={14} /> {actionError ?? error}
        </div>
      )}

      {/* CSEMPÉS GRID */}
      {loading && workgroups.length === 0 ? (
        <div className="flex items-center justify-center h-64">
          <RefreshCw className="animate-spin text-blue-600" size={32} />
          <span className="ml-3 text-gray-600">Csoportok betöltése…</span>
        </div>
      ) : workgroups.length === 0 ? (
        <div className="bg-white rounded shadow-sm border p-6 text-center text-gray-500">
          Még nincs csoport árfolyamlap.{canWrite ? ' Hozzon létre egyet az „Új munkacsoport” gombbal.' : ' Új létrehozása a Munkacsoportok kezelő felületen lehetséges.'}
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
          {workgroups.map((wg, idx) => {
            const protectionOn = wg.protectionEnabled ?? true
            return (
              <div
                key={wg.id}
                className={`relative rounded-lg border-2 p-3 transition-shadow hover:shadow-md ${tileClasses(wg.tileColor)}`}
              >
                {/* FK-04/E: árfolyamvédelem — abszolút a jobb felső sarokban, a megnyitó-gomb
                    FÖLÖTT (z-10). Így NEM ágyazódik interaktív elem a gombba (a11y), és a
                    billentyű-események sem buborékolnak a megnyitásba. */}
                <div className="absolute top-2 right-2 z-10">
                  {canWrite ? (
                    <label
                      className="inline-flex items-center gap-1 text-[10px] font-bold cursor-pointer select-none"
                      title="Árfolyamvédelem: ha be van kapcsolva, a csoport-lap mentése blokkolja a hibás (vétel > J vagy eladás < J) értékeket."
                    >
                      <input
                        type="checkbox"
                        checked={protectionOn}
                        onChange={e => void toggleProtection(wg, e.target.checked)}
                        className="h-3.5 w-3.5"
                        aria-label={`Árfolyamvédelem a(z) ${wg.name} csoporton`}
                      />
                      VÉDELEM
                    </label>
                  ) : (
                    <span
                      className={`inline-flex items-center gap-0.5 text-[10px] font-bold ${protectionOn ? 'text-green-700' : 'text-gray-400'}`}
                      title={protectionOn ? 'Árfolyamvédelem BE' : 'Árfolyamvédelem KI'}
                    >
                      {protectionOn ? <ShieldCheck size={12} /> : <Shield size={12} />}
                      VÉDELEM
                    </span>
                  )}
                </div>

                {/* Megnyitó gomb = a fő kattintható terület. Valódi <button> (natív
                    billentyű+fókusz), interaktív gyerek NÉLKÜL — a checkbox és az akciók
                    sibling-ek, nem beágyazottak. */}
                <button
                  type="button"
                  onClick={() => onSelect(idx)}
                  className="block w-full text-left pr-16"
                  aria-label={`${wg.name} (${wg.code}) árfolyamlap megnyitása`}
                >
                  <div className="text-2xl font-bold leading-none font-mono mb-2">
                    {String(wg.legacyGroupNumber ?? (idx + 1)).padStart(2, '0')}
                  </div>
                  <div className="text-sm font-semibold truncate" title={wg.name}>{wg.name}</div>
                  <div className="text-xs opacity-70 mt-0.5">
                    <span className="font-mono">{wg.code}</span>
                    <span className="mx-1">·</span>
                    <span>{wg.branches.length} iroda</span>
                  </div>
                </button>

                {/* FK-02 §3: karbantartó akciók (átnevezés/szín/határ, törlés) — csak írásjoggal.
                    A megnyitó-gomb mellett sibling, így nincs gombon belüli gomb. */}
                {canWrite && (
                  <div className="mt-2 flex items-center gap-1 border-t border-black/10 pt-1.5">
                    <button
                      type="button"
                      onClick={() => openRename(wg)}
                      className="inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-medium rounded bg-white/70 hover:bg-white border border-black/10"
                      title="Átnevezés / szín / kedvezményhatárok"
                    >
                      <Pencil size={10} /> Szerk.
                    </button>
                    <button
                      type="button"
                      onClick={() => requestDelete(wg)}
                      className="inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-medium rounded bg-white/70 hover:bg-red-50 text-red-700 border border-red-200"
                      title="Munkacsoport törlése"
                    >
                      <Trash2 size={10} /> Törlés
                    </button>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      {editorOpen && (
        <WorkgroupEditor
          mode={editorMode}
          draft={draft}
          setDraft={setDraft}
          onSave={() => { void saveEditor() }}
          onCancel={() => { setEditorOpen(false); setActionError(null) }}
        />
      )}
      {confirm && <ConfirmDialog state={confirm} onCancel={() => setConfirm(null)} />}
    </div>
  )
}
