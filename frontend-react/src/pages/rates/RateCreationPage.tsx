import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { AxiosError } from 'axios'
import {
  RefreshCw,
  AlertTriangle,
  Send,
  Plus,
  X,
  Building2,
  Clock,
  Undo2,
  Redo2,
  Home,
  ArrowLeft,
  ShieldCheck,
  Shield,
  Pencil,
  Trash2,
  CheckCircle2,
  Copy,
  PanelRightClose,
  PanelRightOpen,
} from 'lucide-react'
import {
  rateCreationApi,
  rateWorkgroupApi,
  RateOverviewDTO,
  RateOverviewItem,
  type RateCreationDTO,
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
import { sortByDisplayOrder } from './currencyDisplayOrder'
import { currentFunctionCode } from './fillHelpers'
import {
  validateWorkgroupProtection,
  workgroupProtectionLabel,
  type ProtectionRow,
} from './workgroupProtection'
import { sortWorkgroupsBySequence } from './workgroupOrdering'
import { isFormula, type WgValues } from './workgroupSheetFormula'
import { applyCrossGroupCopy, type CrossGroupCopyCell } from './crossGroupCopy'
import { isSignificantDeviation } from './deviationCheck'
import { publishAllWorkgroups, summarizePublishAll } from './publishAllWorkgroups'
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
  persistGroupRateValues,
  loadGroupRateValuesFromOfflineDb,
  saveGroupRateValuesToOfflineDbAwait,
  isGroupRateOfflineDbAvailable,
  exportRateMakerSheetSnapshot,
  importRateMakerSheetSnapshot,
  dirtyCurrencyIdsFromOverlay,
} from './workgroupSheetStorage'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

/** FK-04/C: a 8 képletezhető string-mező (J=officialRate read-only auto, K=ISO kód kihagyva). */
const WG_STRING_FIELDS: Exclude<WgField, 'officialRate'>[] = [
  'buyRate',
  'sellRate',
  'limit1BuyRate',
  'limit1SellRate',
  'limit2BuyRate',
  'limit2SellRate',
  'limit3BuyRate',
  'limit3SellRate',
]

// FK04 (FR-4): a korábbi hard-coded MAIN_SHEET_CURRENCY_ORDER konstans MEGSZŰNT — a
// csoport-árfolyamlap valuta-sorrendje a currency tábla displayOrder mezőjéből jön
// (V317 kanonikus sorrend; a backend overview item hordozza). A rendezés a
// ./currencyDisplayOrder modulban (ismeretlen kód a végére, ABC-ben — változatlan viselkedés).

// FK02-B / FR-2..5 (2026-06-01): jelentős (≥10%) eltérés az ELŐZŐ MENTETT értékhez képest →
// megerősítő modal (elgépelés-védelem). Az arány-számítás a ./deviationCheck modulban.
/** WgField → ember-olvasható oszlopnév a megerősítő üzenethez. */
const WG_FIELD_LABEL: Record<string, string> = {
  buyRate: 'alap vétel',
  sellRate: 'alap eladás',
  limit1BuyRate: '1. sáv vétel',
  limit1SellRate: '1. sáv eladás',
  limit2BuyRate: '2. sáv vétel',
  limit2SellRate: '2. sáv eladás',
  limit3BuyRate: '3. sáv vétel',
  limit3SellRate: '3. sáv eladás',
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
  const canWriteRateCreation = useAuthStore(
    (state) =>
      isLocalRateMakerApp &&
      (state.hasRole('ADMIN') || state.hasCanonicalRole(['foertektar', 'ugyvezeto', 'admin'])),
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
  type UndoSnapshot = {
    rates: EditableRate[]
    formulas: Record<string, string>
    savedRateValues: Record<string, string>
  }
  const undoStack = useRef<UndoSnapshot[]>([])
  const redoStack = useRef<UndoSnapshot[]>([])
  // FK02-B / FR-2..5: a PERZISZTÁLT (loadData-kor betöltött, utoljára publikált/mentett) árfolyamok
  // numerikus pillanatképe, kulcs `${currencyId}.${field}`. A 10%-eltérés ehhez mér — NEM a session
  // közbeni, még nem publikált értékhez —, így a lépésenkénti elcsúszás (400→430→470) is kiszúrható.
  const baselineRatesRef = useRef<Record<string, number>>({})
  // FK02-B / FR-11, FR-12 (Codex P1): a szerver-bootstrap NYERS string-értékei kulcsonként
  // (`${currencyId}.${field}`). Csoportváltáskor a fix cellákat erre állítjuk vissza, mielőtt az
  // aktuális csoport override-jait rátennénk — így nincs kereszt-csoport „bleed".
  const serverRateValuesRef = useRef<Record<string, string>>({})
  // FK02-E (FR-6, FR-9): a J (elszámoló / officialRate) szerver-alapértéke valutánként (currencyId →
  // szám). A J cella üres (nincs override) állapotban ezt mutatja; ürítéskor erre áll vissza.
  const serverOfficialRateRef = useRef<Record<number, number | null>>({})
  const serverSheetVersionRef = useRef<number | null>(null)
  const [selectedWgIndex, setSelectedWgIndex] = useState<number>(0)
  /**
   * FK-02/03/04 (Kasza Helga / Bali Henriett 2026-05-28): a régi „bal oldali sávos"
   * 54-csempés választó helyett egységes csempés listanézet az induló képernyő.
   * - 'tile-list' (default): csempés grid az összes csoport árfolyamlappal
   * - 'editor': egy csoport árfolyamlap szerkesztése (rate-tábla + iroda-panel)
   * A csempére klikk azonnal megnyitja a szerkesztőt (megerősítés nélkül, docx-spec).
   */
  const [viewMode, setViewMode] = useState<'tile-list' | 'editor'>('tile-list')
  // FK02-E (FR-12): a jobb oldali munkacsoport-panel elrejtése — így a táblázat a teljes szélességet
  // kitölti, a számok nagyobb területen jelennek meg.
  const [panelCollapsed, setPanelCollapsed] = useState(false)
  const [loading, setLoading] = useState(false)
  const [publishing, setPublishing] = useState(false)
  // FK05 (FR-8): "X / Y munkacsoport elküldve" folyamat-visszajelzés a szétküldés alatt.
  const [publishProgress, setPublishProgress] = useState<{ done: number; total: number } | null>(
    null,
  )
  // FK05 (FR-6): iroda-mentési hiba a modalon belül (nem csak toast).
  const [branchSaveError, setBranchSaveError] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  // T9.F: képletszintaxis-súgó (A–I / J–S / !Fxxx / #NNL) a csoport-lap szerkesztőhöz.
  const [showFormulaHelp, setShowFormulaHelp] = useState(false)
  const [rateAdvice, setRateAdvice] = useState<RateCreationDTO | null>(null)
  const [rateAdviceError, setRateAdviceError] = useState<string | null>(null)
  const [rateAdviceLoadingId, setRateAdviceLoadingId] = useState<number | null>(null)
  const [prepareAllLoading, setPrepareAllLoading] = useState(false)
  const [prepareAllMessage, setPrepareAllMessage] = useState<string | null>(null)

  // FK-04/C képletezés: felhasználói képletek (kulcs `${currencyId}.${field}`) csoportonként,
  // a kiszámolt cellánkénti hibák, és a 0-s lap / kereszt-csoport hivatkozás-kontextus.
  const [formulas, setFormulas] = useState<Record<string, string>>({})
  const [cellErrors, setCellErrors] = useState<Record<string, string>>({})
  // FK02-D (FR-9..13): cross-csoport másolás állapota — a kijelölt forrás-cellák, a kijelölt
  // célcsoportok, és a megerősítő dialog nyitottsága.
  const [copyCells, setCopyCells] = useState<Array<{
    currencyId: number
    field: WgField
    raw: string
  }> | null>(null)
  const [copyTargetIds, setCopyTargetIds] = useState<Set<string>>(new Set())
  const [copyConfirmOpen, setCopyConfirmOpen] = useState(false)
  // A 0-s lap (A–I) + más csoportok J–S pillanatképei localStorage-ból; ref, hogy a recompute
  // effekt függőség-listája stabil maradjon (a Map-eket csoport-nyitáskor frissítjük).
  const sheetCtxRef = useRef<{
    sheet0ByCurrency: Map<
      string,
      ReturnType<typeof loadSheet0ByCurrency> extends Map<string, infer V> ? V : never
    >
    otherGroupsByCurrency: Map<number, Map<string, WgValues>>
  }>({ sheet0ByCurrency: new Map(), otherGroupsByCurrency: new Map() })
  // Védi a recompute setRates-ét a végtelen effekt-loop ellen (0-s lap minta).
  const recomputeGuardRef = useRef(false)

  // Limit editing state
  const [editLimits, setEditLimits] = useState<{ l1: string; l2: string; l3: string }>({
    l1: '',
    l2: '',
    l3: '',
  })
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
    // Codex #910 P1: az undo/redo stack csoportváltáskor és teljes frissítéskor ÉRVÉNYTELEN;
    // különben elavult állapotot állíthatna vissza az aktuális csoport localStorage-kulcsa alá.
    undoStack.current = []
    redoStack.current = []
    // eslint-disable-next-line react-hooks/exhaustive-deps -- csoportváltáskor ÉS minden reloadnál
  }, [selectedWg?.id, reloadVersion])

  // FK02-B / FR-11, FR-12: az aktuális csoport FIX (nem-formulás) cella-állapotának alkalmazása.
  // Minden string-mezőt a SZERVER-baseline-ra állít vissza, majd rátenni a csoport override-jait
  // (Codex P1: így csoportváltáskor nincs kereszt-csoport „bleed" — a nem-override-olt cellák a
  // szerver-értékre esnek vissza, nem az előző csoportéra). A formula-cellákat a recompute UTÓLAG
  // felülírja (ezért itt nem kezeljük külön, és nem függünk a — váltáskor még elavult — formulas-tól).
  // Külön effekt, hogy a `loadData()` UTÁNI azonos csoportos reloadkor is lefusson (`reloadVersion`).
  // Csak OLVAS a localStorage-ból, NEM ír — a mentett override-okat nem törli.
  useEffect(() => {
    if (!selectedWg) return
    const saved = loadGroupRateValues(selectedWg.id)
    const dirtyIds = dirtyCurrencyIdsFromOverlay(saved)
    const server = serverRateValuesRef.current
    setRates((prev) => {
      let changed = false
      const next = prev.map((r) => {
        let nr = r
        for (const field of WG_STRING_FIELDS) {
          const key = `${r.currencyId}.${field}`
          const target = key in saved ? saved[key]! : (server[key] ?? '')
          if (nr[field] !== target) {
            if (nr === r) nr = { ...r }
            nr[field] = target
            changed = true
          }
        }
        // FK02-E (FR-7, FR-9): a J (officialRate) override visszaállítása — mentett override, vagy a
        // szerver-alapérték (0-s lap A). A formula-J-t a recompute effekt utólag felülírja.
        const ofKey = `${r.currencyId}.officialRate`
        const ofTarget =
          ofKey in saved
            ? numOrNull(saved[ofKey]!)
            : (serverOfficialRateRef.current[r.currencyId] ?? null)
        if (nr.officialRate !== ofTarget) {
          if (nr === r) nr = { ...r }
          nr.officialRate = ofTarget
          changed = true
        }
        const modified = dirtyIds.has(r.currencyId)
        if (nr.modified !== modified) {
          if (nr === r) nr = { ...r }
          nr.modified = modified
          changed = true
        }
        return nr
      })
      return changed ? next : prev
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps -- csoportváltáskor ÉS minden reloadnál
  }, [selectedWg?.id, reloadVersion])

  // FK02-B / FR-11, FR-12: SQLite-first TARTÓS overlay (Electron). A fenti szinkron localStorage-
  // overlay UTÁN fut; ha az Electron SQLite-ban van mentett érték (a localStorage-nál tartósabb
  // forrás — pl. törölt/elavult localStorage esetén is megőrzi), rámossa a cellákra ÉS visszaírja
  // a localStorage-ba, hogy a szinkron út is naprakész legyen. Böngészőben/dev-ben no-op (üres).
  useEffect(() => {
    if (!selectedWg) return
    const groupId = selectedWg.id
    let cancelled = false
    void loadGroupRateValuesFromOfflineDb(groupId).then((saved) => {
      if (cancelled || !saved || Object.keys(saved).length === 0) return
      saveGroupRateValues(groupId, saved) // a szinkron localStorage utat is szinkronizáljuk
      const dirtyIds = dirtyCurrencyIdsFromOverlay(loadGroupRateValues(groupId))
      setRates((prev) => {
        let changed = false
        const next = prev.map((r) => {
          let nr = r
          for (const field of WG_STRING_FIELDS) {
            const key = `${r.currencyId}.${field}`
            if (key in saved && nr[field] !== saved[key]) {
              if (nr === r) nr = { ...r }
              nr[field] = saved[key]!
              changed = true
            }
          }
          // FK02-E (FR-7): a J (officialRate) override SQLite-first visszaállítása, ha van mentve.
          const ofKey = `${r.currencyId}.officialRate`
          if (ofKey in saved) {
            const ofVal = numOrNull(saved[ofKey]!)
            if (nr.officialRate !== ofVal) {
              if (nr === r) nr = { ...r }
              nr.officialRate = ofVal
              changed = true
            }
          }
          const modified = dirtyIds.has(r.currencyId)
          if (nr.modified !== modified) {
            if (nr === r) nr = { ...r }
            nr.modified = modified
            changed = true
          }
          return nr
        })
        return changed ? next : prev
      })
    })
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- csoportváltáskor ÉS minden reloadnál
  }, [selectedWg?.id, reloadVersion])

  // FK-04/C: a csoport képleteinek perzisztálása minden változáskor (localStorage, csoportonként).
  useEffect(() => {
    if (selectedWg) saveGroupFormulas(selectedWg.id, formulas)
  }, [formulas, selectedWg])

  // FK02-E (FR-4): az EUA sor M (eladás) oszlopának alapértelmezett képlete `!MEUR` — az aktuális
  // csoport EUR sorának M (eladás) oszlopa. Akkor injektáljuk, ha nincs rá mentett képlet ÉS nincs
  // fix érték-override (a felhasználó képlettel vagy értékkel felülírhatja; ürítés után visszaáll).
  useEffect(() => {
    if (!selectedWg) return
    const eua = rates.find((r) => r.currencyCode.toUpperCase() === 'EUA')
    if (!eua) return
    const key = `${eua.currencyId}.sellRate`
    if (formulas[key]) return
    if (key in loadGroupRateValues(selectedWg.id)) return
    setFormulas((prev) => (prev[key] ? prev : { ...prev, [key]: '!MEUR' }))
    // eslint-disable-next-line react-hooks/exhaustive-deps -- csoportváltáskor/reloadkor, ha EUA megjelent
  }, [selectedWg?.id, reloadVersion, rates.length])

  // FK-04/C reaktív újraszámítás: a képlet-cellákat feloldja és visszaírja a `rates`
  // string-mezőkbe (a fix cellák változatlanok). Jacobi-fixpont + ciklus-védelem a
  // workgroupSheetCompute-ban; a guard-ref akadályozza a saját setRates-loopot.
  useEffect(() => {
    if (recomputeGuardRef.current) {
      recomputeGuardRef.current = false
      return
    }

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
      logger.warn(
        'RateCreationPage',
        'Munkacsoport-lap képlet-újraszámítás nem konvergált (körhivatkozás-gyanú) — a részeredményt elvetjük',
      )
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
    // cellErrors szándékosan kihagyva: rates/formulas/reload változásra számolunk újra
    // eslint-disable-next-line react-hooks/exhaustive-deps -- a friss sheet0-kontextus reloadnál is újraszámítandó
  }, [rates, formulas, selectedWg?.legacyGroupNumber, reloadVersion])

  const loadData = useCallback(async () => {
    setLoading(true)
    setError(null)
    setRateAdvice(null)
    setRateAdviceError(null)
    try {
      let overviewData: RateOverviewDTO
      let wgData: WorkgroupDetailDTO[]

      if (isLocalRateMakerApp) {
        // FK07-fix-2: az első await előtti, konzisztens lokális érték + marker + képlet baseline.
        const preImportBaseline = exportRateMakerSheetSnapshot()
        const [bootstrap, serverSheet] = await Promise.all([
          rateCreationApi.getLocalRateMakerBootstrap(),
          rateCreationApi.getLocalRateMakerSheet().catch((sheetErr: unknown) => {
            logger.warn(
              'RateCreationPage',
              'Szerveroldali rate-maker munkaív betöltése sikertelen — helyi állapot marad',
              sheetErr,
            )
            return null
          }),
        ])
        if (serverSheet?.sheetJson) {
          const imported = importRateMakerSheetSnapshot(
            serverSheet.sheetJson,
            localStorage,
            preImportBaseline,
          )
          logger.info(
            'RateCreationPage',
            `Szerveroldali rate-maker munkaív importálva: ${imported} localStorage kulcs`,
          )
        }
        serverSheetVersionRef.current = serverSheet?.version ?? null
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
      // FK02-D (FR-14): a csempék/fülek MINDIG sorszám szerint növekvő sorrendben — a forrásnál
      // rendezünk, hogy a selectedWgIndex is e stabil sorrendre mutasson.
      const orderedWg = sortWorkgroupsBySequence(wgData)
      setWorkgroups(orderedWg)
      setSelectedWgIndex((current) => (orderedWg[current] ? current : 0))

      const editableRates: EditableRate[] = (overviewData.currencies ?? []).map(
        (c: RateOverviewItem) => ({
          currencyId: c.currencyId,
          currencyCode: c.currencyCode,
          currencyName: c.currencyName,
          displayOrder: c.displayOrder,
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
        }),
      )
      // FK04 (FR-4): a currency tábla displayOrder mezője szerint rendezünk (V317 kanonikus
      // sorrend) — a Főlappal konzisztens nézet; az EUA a RUB és TRY közé kerül (15. hely).
      setRates(sortByDisplayOrder(editableRates))
      // FK02-B / FR-2..5: a perzisztált baseline rögzítése (a 10%-eltérés ehhez mér; publish/save
      // utáni újratöltéskor frissül). Csak a numerikusan értelmezhető mezőket tároljuk.
      const baseline: Record<string, number> = {}
      const serverValues: Record<string, string> = {}
      const serverOfficial: Record<number, number | null> = {}
      for (const er of editableRates) {
        serverOfficial[er.currencyId] = er.officialRate
        for (const field of WG_STRING_FIELDS) {
          const key = `${er.currencyId}.${field}`
          const raw = typeof er[field] === 'string' ? (er[field] as string) : ''
          serverValues[key] = raw
          const n = numOrNull(raw)
          if (n !== null) baseline[key] = n
        }
      }
      baselineRatesRef.current = baseline
      serverRateValuesRef.current = serverValues
      serverOfficialRateRef.current = serverOfficial
      // FK02-B / FR-11, FR-12: a fix-érték overlay effekt újrafuttatása (azonos csoportos reload is).
      setReloadVersion((v) => v + 1)
    } catch (err) {
      logger.error('RateCreationPage', 'Betöltési hiba:', err)
      setError('Hiba az árfolyam adatok betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [isLocalRateMakerApp])

  const handlePrepareRate = useCallback(async (rate: EditableRate) => {
    setRateAdviceLoadingId(rate.currencyId)
    setRateAdviceError(null)
    try {
      const prepared = await rateCreationApi.prepareRateCreation(String(rate.currencyId))
      setRateAdvice(prepared)
    } catch (err) {
      logger.error('RateCreationPage', 'Árfolyam-előkészítés betöltési hiba:', err)
      setRateAdviceError('Backend árfolyam-javaslat betöltése sikertelen')
    } finally {
      setRateAdviceLoadingId(null)
    }
  }, [])

  const handlePrepareAllRates = useCallback(async () => {
    setPrepareAllLoading(true)
    setPrepareAllMessage(null)
    try {
      const result = await rateCreationApi.prepareAllCurrencies()
      await loadData()
      const generatedCount =
        typeof result.generatedCount === 'number' ? result.generatedCount : null
      setPrepareAllMessage(
        generatedCount === null
          ? 'Tömeges árfolyamtervezet elkészült.'
          : `Tömeges árfolyamtervezet elkészült: ${generatedCount} valuta.`,
      )
    } catch (err) {
      logger.error('RateCreationPage', 'Tömeges árfolyamtervezet generálás hiba:', err)
      setError('Tömeges árfolyamtervezet generálása sikertelen')
    } finally {
      setPrepareAllLoading(false)
    }
  }, [loadData])

  useEffect(() => {
    void loadData()
  }, [loadData])

  useEffect(() => {
    if (!isLocalRateMakerApp || loading || !overview || rates.length === 0) return
    const timer = window.setTimeout(() => {
      const snapshot = exportRateMakerSheetSnapshot()
      const sheetJson = JSON.stringify(snapshot)
      void rateCreationApi
        .putLocalRateMakerSheet(sheetJson, {
          source: 'rate-maker',
          baseVersion: serverSheetVersionRef.current,
        })
        .then((saved) => {
          serverSheetVersionRef.current = saved.version ?? null
        })
        .catch((sheetErr: unknown) => {
          logger.warn(
            'RateCreationPage',
            'Szerveroldali rate-maker munkaív mentése sikertelen — helyi állapot marad',
            sheetErr,
          )
        })
    }, 1500)
    return () => window.clearTimeout(timer)
  }, [isLocalRateMakerApp, loading, overview, rates, formulas, reloadVersion, selectedWg?.id])

  // FK02-B / FR-11, FR-12: a pillanatnyi (perzisztált) fix-érték store a snapshothoz/visszaállításhoz.
  const currentSavedRateValues = useCallback((): Record<string, string> => {
    const id = selectedWg?.id
    return id ? loadGroupRateValues(id) : {}
  }, [selectedWg?.id])

  const pushUndo = useCallback(() => {
    undoStack.current.push({
      rates: rates.map((r) => ({ ...r })),
      formulas: { ...formulas },
      savedRateValues: currentSavedRateValues(),
    })
    if (undoStack.current.length > 50) undoStack.current.shift()
    redoStack.current = []
  }, [rates, formulas, currentSavedRateValues])

  const undo = useCallback(() => {
    const prev = undoStack.current.pop()
    if (!prev) return
    const id = selectedWg?.id
    redoStack.current.push({
      rates: rates.map((r) => ({ ...r })),
      formulas: { ...formulas },
      savedRateValues: currentSavedRateValues(),
    })
    setRates(prev.rates)
    setFormulas(prev.formulas)
    if (id) persistGroupRateValues(id, prev.savedRateValues) // FK02-B: dual-write (localStorage + SQLite)
  }, [rates, formulas, currentSavedRateValues, selectedWg?.id])

  const redo = useCallback(() => {
    const nextState = redoStack.current.pop()
    if (!nextState) return
    const id = selectedWg?.id
    undoStack.current.push({
      rates: rates.map((r) => ({ ...r })),
      formulas: { ...formulas },
      savedRateValues: currentSavedRateValues(),
    })
    setRates(nextState.rates)
    setFormulas(nextState.formulas)
    if (id) persistGroupRateValues(id, nextState.savedRateValues) // FK02-B: dual-write (localStorage + SQLite)
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
    setRates((prev) => {
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
  const commitWorkgroupCell = useCallback(
    (index: number, field: WgField, raw: string) => {
      if (!canWriteRateCreation) return
      const r = rates[index]
      if (!r) return
      const key = `${r.currencyId}.${field}`
      const trimmed = raw.trim()
      const wgId = selectedWg?.id

      const applyCommit = () => {
        pushUndo()
        const saved = wgId ? loadGroupRateValues(wgId) : {}
        let overlayMutated = false
        if (isFormula(trimmed)) {
          setFormulas((prev) => (prev[key] === trimmed ? prev : { ...prev, [key]: trimmed }))
        } else {
          setFormulas((prev) => {
            if (!prev[key]) return prev
            const copy = { ...prev }
            delete copy[key]
            return copy
          })
        }

        // FK02-B / FR-11, FR-12: a fix (nem-formulás) érték localStorage-perzisztálása csoportonként,
        // hogy lapváltás/újratöltés után is megmaradjon. CSAK a szerver-baseline-tól ELTÉRŐ értéket
        // tároljuk override-ként (Codex P2): a szerverrel megegyező érték (pl. fókusz+blur változtatás
        // nélkül) NEM pinelődik, így nem árnyékolja a jövőbeni szerver-változást. Formula vagy
        // szerver-egyezés → kulcstörlés; üres a szerver nem-üres értékén = szándékos '' override. J nincs.
        if (wgId && field !== 'officialRate') {
          const serverNum = baselineRatesRef.current[key]
          const nextNum = numOrNull(trimmed)
          const sameAsServer =
            (trimmed === '' && serverNum === undefined) ||
            (nextNum !== null && nextNum === serverNum)
          if (isFormula(trimmed) || sameAsServer) {
            if (key in saved) {
              delete saved[key]
              overlayMutated = true
            }
          } else if (saved[key] !== trimmed) {
            saved[key] = trimmed
            overlayMutated = true
          }
        }

        // FK02-E (FR-7, FR-9): a J (officialRate) override perzisztálása. A szerver-alapértéktől eltérő
        // fix érték marad override-ként; formula vagy üres/alapérték → kulcstörlés (reloadkor a J a
        // szerver-alapértékre = 0-s lap A oszlopra áll vissza). A formula maga külön (saveGroupFormulas) megy.
        if (wgId && field === 'officialRate') {
          const ofKey = `${r.currencyId}.officialRate`
          const n = numOrNull(trimmed)
          const serverDefault = serverOfficialRateRef.current[r.currencyId] ?? null
          const isDefault = !isFormula(trimmed) && (n === null || n === serverDefault)
          if (isFormula(trimmed) || isDefault) {
            if (ofKey in saved) {
              delete saved[ofKey]
              overlayMutated = true
            }
          } else if (saved[ofKey] !== trimmed) {
            saved[ofKey] = trimmed
            overlayMutated = true
          }
        }

        if (wgId && overlayMutated) {
          // FK02-B / FR-11,12: dual-write — localStorage (szinkron) + tartós Electron SQLite (best-effort).
          persistGroupRateValues(wgId, saved)
        }
        const rowDirty = dirtyCurrencyIdsFromOverlay(saved).has(r.currencyId)
        setRates((prev) =>
          prev.map((x, i) => {
            if (i !== index) return x
            if (isFormula(trimmed)) return { ...x, modified: rowDirty }
            if (field === 'officialRate') {
              // J (Elszámoló) NUMBER mező (a többi string). Fix override → parse; üres → vissza a
              // szerver-alapértékre (FK02-E FR-9: a 0-s lap A oszlopa), NEM marad üres.
              const resolved =
                numOrNull(trimmed) ?? serverOfficialRateRef.current[r.currencyId] ?? null
              return { ...x, officialRate: resolved, modified: rowDirty }
            }
            return { ...x, [field]: trimmed, modified: rowDirty }
          }),
        )
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
          const pct = Math.round(
            (Math.abs((nextVal as number) - (prevVal as number)) / Math.abs(prevVal as number)) *
              100,
          )
          setRateConfirm({
            title: 'Nagy árfolyam-eltérés',
            message: `${r.currencyCode} – ${WG_FIELD_LABEL[field] ?? field}: ${prevVal} → ${nextVal} (${pct}% eltérés a korábbi értékhez képest). Biztosan elmenti?`,
            confirmLabel: 'Igen, mentem',
            danger: true,
            onConfirm: () => {
              applyCommit()
              setRateConfirm(null)
            },
          })
          return
        }
      }
      applyCommit()
    },
    [canWriteRateCreation, rates, pushUndo, selectedWg?.id],
  )

  // FK02-B / FR-6..10: kötegelt cella-alkalmazás a RateGrid lebegő toolbarjához (Lehúzás / Sávok
  // törlése). EGYETLEN undo-lépés, modal NÉLKÜL (a tömeges műveletet a felhasználó tudatosan indítja),
  // a képlet/fix érték kezelése a commit-tal azonos, a localStorage-perzisztálás sparse (szerver-diff).
  const applyBulkCells = useCallback(
    (cells: Array<{ row: number; field: WgField; raw: string }>) => {
      if (!canWriteRateCreation || cells.length === 0) return
      const wgId = selectedWg?.id
      pushUndo()

      // Képletek frissítése: formula-input → tárol; egyéb → a kulcs törlése (a fix érték a rates-be megy).
      setFormulas((prevF) => {
        const f = { ...prevF }
        for (const { row, field, raw } of cells) {
          const r = rates[row]
          if (!r) continue
          const key = `${r.currencyId}.${field}`
          if (isFormula(raw.trim())) f[key] = raw.trim()
          else delete f[key]
        }
        return f
      })

      // localStorage-perzisztálás (sparse): csak a szerver-baseline-tól ELTÉRŐ fix érték marad override-ként.
      const saved = wgId ? loadGroupRateValues(wgId) : {}
      if (wgId) {
        for (const { row, field, raw } of cells) {
          const r = rates[row]
          if (!r) continue
          const key = `${r.currencyId}.${field}`
          const trimmed = raw.trim()
          // Codex P2 #1112 (FK03): a J (officialRate) bulk-szerkesztése IS perzisztálódik
          // override-ként — a commitCell J-ágával azonos szabállyal (szerver-alapértékkel
          // egyező vagy üres/formula → kulcstörlés). Korábban a J kimaradt (continue), így
          // a toolbar-műveletek J-változása újratöltéskor elveszett volna.
          if (field === 'officialRate') {
            const n = numOrNull(trimmed)
            const serverDefault = serverOfficialRateRef.current[r.currencyId] ?? null
            const isDefault = !isFormula(trimmed) && (n === null || n === serverDefault)
            if (isFormula(trimmed) || isDefault) delete saved[key]
            else saved[key] = trimmed
            continue
          }
          const serverNum = baselineRatesRef.current[key]
          const nextNum = numOrNull(trimmed)
          const sameAsServer =
            (trimmed === '' && serverNum === undefined) ||
            (nextNum !== null && nextNum === serverNum)
          if (isFormula(trimmed) || sameAsServer) delete saved[key]
          else saved[key] = trimmed
        }
        persistGroupRateValues(wgId, saved) // FK02-B: dual-write (localStorage + SQLite)
      }

      const dirtyIds = dirtyCurrencyIdsFromOverlay(saved)
      // Fix (nem-formula) értékek visszaírása a rates string-mezőkbe (a formula-cellákat a recompute tölti).
      setRates((prev) =>
        prev.map((x, i) => {
          const forRow = cells.filter((c) => c.row === i)
          if (forRow.length === 0) return x
          const nr: EditableRate = { ...x, modified: dirtyIds.has(x.currencyId) }
          for (const { field, raw } of forRow) {
            const trimmed = raw.trim()
            if (isFormula(trimmed)) continue
            // Codex #1112 (FK03): a J üres értéke a SZERVER-alapértékre áll vissza
            // (FK02-E FR-9), a commitCell-lel azonosan — nem marad null/üres.
            if (field === 'officialRate')
              nr.officialRate =
                numOrNull(trimmed) ?? serverOfficialRateRef.current[x.currencyId] ?? null
            else nr[field] = trimmed
          }
          return nr
        }),
      )
    },
    [canWriteRateCreation, rates, pushUndo, selectedWg?.id],
  )

  // ===================== FK02-D: cross-csoport másolás (FR-9..13) =====================

  // A RateGrid „Másolás más csoportba" gomb átadja a kijelölt cellákat → megnyitjuk a választót.
  const handleCopyToGroups = useCallback(
    (cells: Array<{ currencyId: number; field: WgField; raw: string }>) => {
      if (!canWriteRateCreation || cells.length === 0) return
      setCopyCells(cells)
      setCopyTargetIds(new Set())
      setCopyConfirmOpen(false)
    },
    [canWriteRateCreation],
  )

  const toggleCopyTarget = useCallback((id: string) => {
    setCopyTargetIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }, [])

  const closeCopyModal = useCallback(() => {
    setCopyCells(null)
    setCopyTargetIds(new Set())
    setCopyConfirmOpen(false)
  }, [])

  // Megerősítés után: a kijelölt cellák tartalma a célcsoport(ok) azonos pozícióiba (dual-write).
  const executeCrossGroupCopy = useCallback(async () => {
    if (!copyCells || copyTargetIds.size === 0) return
    const payload: CrossGroupCopyCell[] = copyCells.map((c) => {
      const key = `${c.currencyId}.${c.field}`
      const isF = isFormula(c.raw)
      return { key, formula: isF ? c.raw : undefined, value: isF ? undefined : c.raw }
    })
    const succeeded: string[] = []
    for (const targetId of copyTargetIds) {
      try {
        // Codex P1: ahol a group-rate SQLite IPC ELÉRHETŐ (kozponti rate-maker host), a SQLite az
        // autoritás — onnan hidratáljuk a cél értékeit, hogy a localStorage-cache divergenciája
        // (másik eszközről szinkronizált adat) NE okozzon adatvesztést. Ahol az IPC NINCS bekötve
        // (standalone arfolyam-keszito host, web), a localStorage az autoritás — különben `{}`
        // töltődne és felülírná a meglévő értékeket. A formulák localStorage-only-k.
        const dbAvailable = isGroupRateOfflineDbAvailable()
        const targetValues = dbAvailable
          ? await loadGroupRateValuesFromOfflineDb(targetId)
          : loadGroupRateValues(targetId)
        const { formulas: nf, values: nv } = applyCrossGroupCopy(
          loadGroupFormulas(targetId),
          targetValues,
          payload,
        )
        // Codex P2: SQLite-FIRST — az autoritatív SQLite-írást ELŐBB await-eljük (IPC-hostban);
        // CSAK siker esetén commitoljuk a localStorage-ot. Így bukásnál NINCS részleges commit
        // (a cél localStorage-a sem íródik felül egy sikertelennek jelzett másolásnál).
        if (dbAvailable) {
          const dbOk = (await saveGroupRateValuesToOfflineDbAwait(targetId, nv)).ok
          if (!dbOk) {
            logger.warn(
              'RateCreationPage',
              `Cross-csoport másolás: SQLite-mentés sikertelen — ${targetId}`,
            )
            continue
          }
        }
        saveGroupFormulas(targetId, nf) // localStorage (formulák)
        saveGroupRateValues(targetId, nv) // localStorage (értékek, szinkron)
        const wg = workgroups.find((w) => w.id === targetId)
        if (wg) succeeded.push(wg.name)
      } catch (e) {
        logger.error('RateCreationPage', 'Cross-csoport másolás hiba', e)
      }
    }
    if (succeeded.length > 0) {
      toast.success('Másolás kész', `${succeeded.length} munkacsoportba: ${succeeded.join(', ')}`)
    } else {
      toast.error('Másolás sikertelen', 'Egyik célcsoportba sem sikerült a másolás.')
    }
    closeCopyModal()
  }, [copyCells, copyTargetIds, workgroups, closeCopyModal])

  // ===================== Limit save =====================

  const handleSaveLimits = async () => {
    if (!selectedWg) return
    if (!canWriteRateCreation) {
      toast.error(
        'Nincs jogosultság',
        'A határok mentéséhez főértéktáros vagy ügyvezető szerepkör kell',
      )
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
        toast.error(
          'Nincs jogosultság',
          'A határok mentéséhez főértéktáros vagy ügyvezető szerepkör kell',
        )
      } else {
        toast.error('Hiba', 'Nem sikerült a határok mentése')
      }
    } finally {
      setSavingLimits(false)
    }
  }

  const handleLimitChange = (key: 'l1' | 'l2' | 'l3', val: string) => {
    setEditLimits((prev) => ({ ...prev, [key]: val }))
    setLimitsModified(true)
  }

  // ===================== Branch management =====================

  const openBranchPicker = async () => {
    if (!selectedWg) return
    try {
      const branches = await rateCreationApi.getBranches(selectedWg.id)
      setAllBranches(branches)
      setSelectedBranchIds(
        new Set(branches.filter((b) => b.assignedToCurrentWorkgroup).map((b) => b.id)),
      )
      setBranchFilter('')
      setBranchSaveError(null)
      setBranchModalOpen(true)
    } catch {
      toast.error('Hiba', 'Nem sikerült az irodák betöltése')
    }
  }

  const handleSaveBranches = async () => {
    if (!selectedWg) return
    if (!canWriteRateCreation) {
      toast.error(
        'Nincs jogosultság',
        'Irodák mentéséhez főértéktáros vagy ügyvezető szerepkör kell',
      )
      return
    }
    setSavingBranches(true)
    setBranchSaveError(null)
    try {
      await rateCreationApi.updateWorkgroupBranches(selectedWg.id, Array.from(selectedBranchIds))
      toast.success('Mentve', 'Irodák frissítve')
      setBranchModalOpen(false)
      void loadData()
    } catch (err) {
      // FK05 (FR-6): a hiba a MODALON BELÜL jelenik meg, érthető szöveggel. A backend
      // move-strategy miatt 409 normál úton nem keletkezik (RateCreationService
      // updateWorkgroupBranches áthelyez); a defenzív ág a constraint-versenyt
      // (uk_branch_workgroup_exclusive) és a régi szerververziót fedi.
      if (err instanceof AxiosError && err.response?.status === 403) {
        setBranchSaveError(
          'Nincs jogosultság: irodák mentéséhez főértéktáros vagy ügyvezető szerepkör kell.',
        )
      } else if (err instanceof AxiosError && err.response?.status === 409) {
        setBranchSaveError(
          'Ez a pénztár már szerepel egy másik munkacsoportban. Először helyezze át onnan, majd adja hozzá ide.',
        )
      } else {
        const msg =
          err instanceof AxiosError
            ? (err.response?.data as { message?: string } | undefined)?.message
            : undefined
        setBranchSaveError(msg ?? 'Nem sikerült az irodák mentése.')
      }
    } finally {
      setSavingBranches(false)
    }
  }

  const removeBranch = async (branchId: string) => {
    if (!selectedWg) return
    if (!canWriteRateCreation) {
      toast.error(
        'Nincs jogosultság',
        'Iroda eltávolításához főértéktáros vagy ügyvezető szerepkör kell',
      )
      return
    }
    const newIds = selectedWg.branches.filter((b) => b.id !== branchId).map((b) => b.id)
    try {
      await rateCreationApi.updateWorkgroupBranches(selectedWg.id, newIds)
      toast.success('Eltávolítva', 'Iroda eltávolítva a csoportból')
      void loadData()
    } catch (err) {
      if (err instanceof AxiosError && err.response?.status === 403) {
        toast.error(
          'Nincs jogosultság',
          'Iroda eltávolításához főértéktáros vagy ügyvezető szerepkör kell',
        )
      } else {
        toast.error('Hiba', 'Nem sikerült az iroda eltávolítása')
      }
    }
  }

  const toggleBranch = (id: string) => {
    setSelectedBranchIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
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

    if (Object.keys(cellErrors).length > 0) {
      toast.error(
        'Nem küldhető szét',
        'Hibás árfolyam-képlet cella(k) van(nak) a lapon — előbb javítsa a hibás képleteket.',
      )
      return
    }

    const validRates = rates.filter((r) => {
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
        toast.error(
          'Hibás árfolyam',
          `${r.currencyCode}: Vétel (${r.buyRate}) >= Eladás (${r.sellRate})`,
        )
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
        .filter((r) => validationErrors[r.currencyId])
        .map((r) => r.currencyCode)
      toast.error(
        'Validációs hiba',
        `${affectedCodes.join(', ')}: Javítsd a hibákat a publikálás előtt!`,
      )
      return
    }

    setPublishing(true)
    try {
      // FK05 (FR-2, FR-8): a szétküldés az ÖSSZES munkacsoportot publikálja, nem csak az
      // aktuálisat. Az aktuális csoport a KÉPERNYŐ friss állapotából megy (inMemoryGroupRates),
      // a többi a tárolt overlay + képletek headless kiértékeléséből (publishAllWorkgroups).
      // A csoport-overlay törlését (FK02-B server-authority) a helper végzi csoportonként.
      const inMemoryRates = validRates.map((r) => ({
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
      const result = await publishAllWorkgroups({
        inMemoryGroupRates: { groupId: selectedWg.id, rates: inMemoryRates },
        preloaded:
          overview && workgroups.length > 0
            ? { overview: overview.currencies, workgroups }
            : undefined,
        onProgress: (done, total) => setPublishProgress({ done, total }),
      })
      const summary = summarizePublishAll(result)
      if (summary.ok) toast.success(summary.title, summary.detail)
      else toast.warning(summary.title, summary.detail)
      void loadData()
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Hiba a publikálás során'
      toast.error('Publikálási hiba', msg)
    } finally {
      setPublishProgress(null)
      setPublishing(false)
    }
  }

  // FK05 (FR-6): kijelölt, de MÁSIK munkacsoporthoz tartozó pénztárak — a backend
  // move-strategy mentéskor áthelyezi őket; itt előre, érthetően jelezzük a modalban.
  const branchMoveWarnings = useMemo(() => {
    if (!selectedWg) return []
    const out: string[] = []
    for (const b of allBranches) {
      if (!selectedBranchIds.has(b.id) || b.assignedToCurrentWorkgroup) continue
      const other = workgroups.find(
        (w) => w.id !== selectedWg.id && w.branches.some((x) => x.id === b.id),
      )
      if (other) out.push(`${b.code} — ${b.name} (jelenleg: ${other.name})`)
    }
    return out
  }, [allBranches, selectedBranchIds, workgroups, selectedWg])

  // Grouped branches for modal
  const groupedBranches = useMemo(() => {
    const filtered = branchFilter
      ? allBranches.filter(
          (b) =>
            b.name.toLowerCase().includes(branchFilter.toLowerCase()) ||
            b.code.toLowerCase().includes(branchFilter.toLowerCase()) ||
            b.city.toLowerCase().includes(branchFilter.toLowerCase()),
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
      const l1b = parseNum(r.limit1BuyRate),
        l1s = parseNum(r.limit1SellRate)
      if (l1b > 0 && l1s > 0 && l1b >= l1s) errs.push('L1: Vétel ≥ Eladás')
      const l2b = parseNum(r.limit2BuyRate),
        l2s = parseNum(r.limit2SellRate)
      if (l2b > 0 && l2s > 0 && l2b >= l2s) errs.push('L2: Vétel ≥ Eladás')
      const l3b = parseNum(r.limit3BuyRate),
        l3s = parseNum(r.limit3SellRate)
      if (l3b > 0 && l3s > 0 && l3b >= l3s) errs.push('L3: Vétel ≥ Eladás')
      // Buy rate should be ≤ official rate (if both present)
      if (r.officialRate && buy > 0 && buy > r.officialRate * 1.1) {
        errs.push('Vétel > MNB +10%')
      }
      if (selectedWg) {
        const protectionViolations = validateWorkgroupProtection(
          [
            {
              currencyCode: r.currencyCode,
              official: r.officialRate,
              buy,
              sell,
              limit1Buy: l1b,
              limit1Sell: l1s,
              limit2Buy: l2b,
              limit2Sell: l2s,
              limit3Buy: l3b,
              limit3Sell: l3s,
            },
          ],
          selectedWg.protectionEnabled ?? true,
          workgroupProtectionLabel(selectedWg.legacyGroupNumber, selectedWg.code),
        )
        errs.push(...protectionViolations.map((violation) => violation.message))
      }
      if (errs.length > 0) errors[r.currencyId] = errs
    }
    return errors
  }, [rates, selectedWg])

  // ===================== FK-02/03/04: Tile-list view =====================
  // Csempés listanézet az induló képernyő — a régi „bal oldali sávos" 54-csempés
  // jobboldali választó HELYETT a UI teljes szélességében.
  //
  // FONTOS: a tile-list ág a `loading && !overview` ÚTÁN visszatérő `<Loader/>`-nél
  // ELŐBB futtatandó, hogy az első bootstrap-load alatt is a csempés UI látsszon
  // (a WorkgroupTileListView saját maga rendel loading-state placeholder-t a
  // `workgroups` üres és `loading=true` esetére — single source of truth).
  if (viewMode === 'tile-list') {
    return (
      <WorkgroupTileListView
        workgroups={workgroups}
        canWrite={canWriteRateCreation}
        onSelect={(idx) => {
          setSelectedWgIndex(idx)
          setViewMode('editor')
        }}
        onBackToMain={() => navigate('/rates/main')}
        onReload={() => void loadData()}
        loading={loading}
        error={error}
      />
    )
  }

  // Editor mode: a klasszikus szerkesztő UI bootstrap-betöltést vár.
  if (loading && !overview) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="animate-spin text-blue-600" size={32} />
        <span className="ml-3 text-gray-600">{i18n.t('literals.arfolyamok-betoltese')}</span>
      </div>
    )
  }

  const modifiedCount = rates.filter((r) => r.modified).length

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
            <ArrowLeft size={11} />
            {i18n.t('literals.csempes-nezet')}
          </button>
          {/* Spec szerint: Munkacsoport felület felső menü → MÁSIK MUNKACSOPORT (visszalépés a 0-s lapra/csoport-választóra) */}
          <button
            onClick={() => navigate('/rates/main')}
            className="flex items-center gap-1 px-2 py-0.5 text-[11px] font-medium border border-orange-400 bg-orange-50 hover:bg-orange-100 text-orange-800 rounded"
            title="Vissza a Főlap (0-s lap) elszámoló árfolyamokhoz"
          >
            <Home size={11} />
            {i18n.t('literals.folap')}
          </button>
          {/* T9.F: képletszintaxis-súgó — itt, ahol a J–S/#NNL képleteket írják. */}
          <FormulaSyntaxHelpButton onClick={() => setShowFormulaHelp(true)} />
          {selectedWg && (
            <span className="text-xs text-gray-500 ml-2">
              <span className="font-mono font-bold">{selectedWg.legacyGroupNumber ?? '—'}</span>
              <span className="mx-1">{i18n.t('literals.lit-45')}</span>
              <span className="font-semibold text-gray-700">{selectedWg.name}</span>
              <span className="ml-1 text-gray-400">
                {i18n.t('literals.lit-19')}
                {selectedWg.code}
                {i18n.t('literals.lit-2')}
              </span>
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
          <button
            onClick={undo}
            disabled={undoStack.current.length === 0}
            className="p-0.5 rounded hover:bg-gray-100 disabled:opacity-30"
            title="Visszavonás (Ctrl+Z)"
          >
            <Undo2 size={13} />
          </button>
          <button
            onClick={redo}
            disabled={redoStack.current.length === 0}
            className="p-0.5 rounded hover:bg-gray-100 disabled:opacity-30"
            title="Mégis (Ctrl+Y)"
          >
            <Redo2 size={13} />
          </button>
          {modifiedCount > 0 && (
            <>
              <span
                role="status"
                data-testid="wg-dirty-indicator"
                className="text-orange-600 font-medium"
              >
                {modifiedCount} {t('rates.mod')}
              </span>
              {canWriteRateCreation && selectedWg && (
                <button
                  type="button"
                  data-testid="wg-dirty-discard"
                  className="px-2 py-0.5 border border-orange-300 rounded text-orange-700 hover:bg-orange-50"
                  title="A csoport nem publikált módosításainak elvetése — vissza az utolsó publikált értékekre"
                  onClick={() => {
                    const groupId = selectedWg.id
                    setRateConfirm({
                      title: 'Eltérések elvetése',
                      message:
                        'Biztosan elveti a csoport nem publikált fix árfolyam-eltéréseit, és visszaáll az utolsó publikált értékekre?',
                      confirmLabel: 'Igen',
                      danger: true,
                      onConfirm: () => {
                        pushUndo()
                        persistGroupRateValues(groupId, {})
                        setReloadVersion((v) => v + 1)
                        setRateConfirm(null)
                      },
                    })
                  }}
                >
                  {i18n.t('literals.elteresek-elvetese')}
                </button>
              )}
            </>
          )}
          <button
            onClick={() => void loadData()}
            disabled={loading}
            className="px-2 py-0.5 border rounded text-xs hover:bg-gray-50 flex items-center gap-1"
          >
            <RefreshCw size={11} className={loading ? 'animate-spin' : ''} />
          </button>
          <button
            type="button"
            onClick={() => void handlePrepareAllRates()}
            disabled={loading || prepareAllLoading}
            className="px-2 py-0.5 border rounded text-xs hover:bg-gray-50 flex items-center gap-1 disabled:opacity-50"
            data-testid="rate-prepare-all"
          >
            <CheckCircle2 size={11} className={prepareAllLoading ? 'animate-pulse' : ''} />
            {prepareAllLoading ? 'Tervezet...' : 'Összes tervezet'}
          </button>
          {/* FK02-E (FR-12): munkacsoport-panel elrejtése/megjelenítése — a táblázat kitölti a helyet. */}
          <button
            onClick={() => setPanelCollapsed((c) => !c)}
            className="px-2 py-0.5 border rounded text-xs hover:bg-gray-50 flex items-center gap-1"
            title={
              panelCollapsed
                ? 'Munkacsoport-panel megjelenítése'
                : 'Munkacsoport-panel elrejtése (nagyobb táblázat)'
            }
          >
            {panelCollapsed ? <PanelRightOpen size={13} /> : <PanelRightClose size={13} />}
          </button>
        </div>
      </div>
      {prepareAllMessage && (
        <div className="mb-1 rounded border border-emerald-200 bg-emerald-50 px-3 py-1 text-xs text-emerald-800">
          {prepareAllMessage}
        </div>
      )}

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
          onBulkApply={applyBulkCells}
          onCopyToGroups={handleCopyToGroups}
          canEdit={canWriteRateCreation}
          onPrepareRate={handlePrepareRate}
          preparingCurrencyId={rateAdviceLoadingId}
          syncing={publishing}
        />

        {/* FK02-B / FR-2..5: 10%-eltérés megerősítő modal (cella-commit interception).
            "Mégse" → a mentés abortál ÉS a cella visszaáll a perzisztált értékre (revert-jelzés). */}
        {rateConfirm && (
          <ConfirmDialog
            state={rateConfirm}
            onCancel={() => {
              setRateConfirm(null)
              setRateRevertSignal((n) => n + 1)
            }}
          />
        )}

        {/* === RIGHT: WORKGROUP PANEL === (FK02-E FR-12: elrejthető) */}
        {!panelCollapsed && (
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
                <ArrowLeft size={10} />
                {i18n.t('literals.csempes-nezet')}
              </div>
              <div className="text-[11px] font-semibold text-gray-700 truncate">
                {selectedWg?.name ?? '—'}
              </div>
              <div className="text-[10px] text-gray-500">
                {i18n.t('literals.lit-12')}
                {selectedWg?.legacyGroupNumber ?? '—'}
                {i18n.t('literals.lit-9')}
                {selectedWg?.branches.length ?? 0}
                {i18n.t('literals.iroda-2')}
              </div>
            </button>

            <div
              className="bg-white rounded border shadow-sm px-2 py-1.5 flex-shrink-0"
              data-testid="rate-prepare-panel"
            >
              <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">
                {i18n.t('literals.backend-javaslat')}
              </div>
              {rateAdviceError && <div className="text-[10px] text-red-600">{rateAdviceError}</div>}
              {rateAdvice ? (
                <div className="space-y-1 text-[11px]">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-semibold text-gray-700">
                      {rateAdvice.currencyCode}
                      {i18n.t('literals.lit-17')}
                      {rateAdvice.currencyName}
                    </span>
                    <span className="rounded bg-blue-50 px-1.5 py-0.5 font-mono text-blue-800">
                      {rateAdvice.recommendedMiddleRate}
                    </span>
                  </div>
                  <div className="grid grid-cols-2 gap-1 font-mono">
                    <div className="rounded bg-green-50 px-1.5 py-1 text-green-800">
                      <div className="text-[9px] font-sans uppercase text-green-700">
                        {i18n.t('literals.ajanlott-vetel')}
                      </div>
                      {rateAdvice.recommendedBuyRate}
                    </div>
                    <div className="rounded bg-red-50 px-1.5 py-1 text-red-800">
                      <div className="text-[9px] font-sans uppercase text-red-700">
                        {i18n.t('literals.ajanlott-eladas')}
                      </div>
                      {rateAdvice.recommendedSellRate}
                    </div>
                  </div>
                  <div className="text-[10px] text-gray-500">
                    {i18n.t('literals.bank-3')}
                    {rateAdvice.bankRates.length}
                    {i18n.t('literals.versenytars')} {rateAdvice.competitorRates.length}
                  </div>
                </div>
              ) : (
                <div className="text-[10px] text-gray-500">
                  {i18n.t('literals.valuta-sorban-kattints-a-javaslat-gombra')}
                </div>
              )}
            </div>

            {/* Aktuális függvény (FR-RFM-22) + Kitöltési segítség (FR-RFM-23) */}
            <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-shrink-0">
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-gray-500 uppercase font-bold">
                  {i18n.t('literals.aktualis-fuggveny')}
                </span>
                <span
                  className="px-1.5 py-0.5 rounded bg-indigo-50 border border-indigo-200 text-indigo-800 font-mono text-[11px] font-bold"
                  title="A csoportlapon aktív képletkód-azonosító (a munkacsoport sorszámából képezve)."
                >
                  {currentFunctionCode(selectedWg?.legacyGroupNumber)}
                </span>
              </div>
              {/* FK02-B / FR-6..10: a régi GLOBÁLIS (egész táblázatra ható) destruktív gombok eltávolítva.
                Helyette a táblázatban egér-drag / Shift+kattintás kijelölés + lebegő toolbar (Lehúzás
                üres / Lehúzás mind / Sávok törlése) — kizárólag a kijelölt tartományra hat. */}
              <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">
                {i18n.t('literals.kitoltesi-segitseg')}
              </div>
              <div className="text-[10px] text-gray-500 leading-tight">
                {i18n.t('literals.jelolj-ki-cellakat-a-tablazatban-eger-hu')}{' '}
                <span className="font-semibold text-amber-700">
                  {i18n.t('literals.lehuzas-mind')}
                </span>
                {i18n.t('literals.felso-sor-masolasa-lefele')}
                <span className="font-semibold text-gray-700">
                  {i18n.t('literals.urites')}
                </span>{' '}
                {i18n.t('literals.kijelolt-cellak-kiuritese-vagy')}{' '}
                <span className="font-semibold text-red-700">
                  {i18n.t('literals.savok-torlese')}
                </span>
                {i18n.t('literals.lit-5')}
              </div>
            </div>

            {/* Branch list */}
            <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-1 min-h-0 flex flex-col overflow-hidden">
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] text-gray-500 uppercase font-bold flex items-center gap-1">
                  <Building2 size={10} />
                  {t('rates.irodak')}
                  {i18n.t('literals.lit')}
                  {selectedWg?.branches.length ?? 0}
                  {i18n.t('literals.lit-2')}
                </span>
                <button
                  onClick={() => void openBranchPicker()}
                  disabled={!canWriteRateCreation}
                  className="w-5 h-5 rounded bg-blue-500 hover:bg-blue-600 text-white flex items-center justify-center"
                  title="Iroda hozzáadása"
                >
                  <Plus size={12} />
                </button>
              </div>
              <div className="flex-1 overflow-y-auto space-y-0.5">
                {selectedWg?.branches.length ? (
                  selectedWg.branches.map((b) => (
                    <div
                      key={b.id}
                      className="flex items-center justify-between px-1.5 py-0.5 bg-gray-50 rounded border border-gray-200 text-[11px] text-gray-700 group"
                    >
                      <span className="truncate">{b.name}</span>
                      <button
                        onClick={() => void removeBranch(b.id)}
                        disabled={!canWriteRateCreation}
                        className="opacity-0 group-hover:opacity-100 text-red-400 hover:text-red-600 flex-shrink-0 ml-1"
                        title="Eltávolítás"
                      >
                        <X size={12} />
                      </button>
                    </div>
                  ))
                ) : (
                  <div className="text-gray-400 italic text-center text-[10px] py-2">
                    {t('rates.nincsIrodaHozzarendelve')}
                  </div>
                )}
              </div>
            </div>

            {/* Limit boundaries - editable */}
            <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-shrink-0">
              <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">
                {t('rates.hatarokFt')}
              </div>
              <div className="space-y-1">
                {[
                  { key: 'l1' as const, label: 'Alsó' },
                  { key: 'l2' as const, label: 'Középső' },
                  { key: 'l3' as const, label: 'Felső' },
                ].map(({ key, label }) => (
                  <div key={key} className="flex items-center gap-1">
                    <span className="text-[10px] font-bold text-blue-700 w-14">{label}</span>
                    <input
                      type="text"
                      value={editLimits[key]}
                      onChange={(e) => handleLimitChange(key, e.target.value)}
                      disabled={!canWriteRateCreation}
                      className="flex-1 px-1.5 py-0.5 text-right font-mono text-[11px] font-bold border rounded bg-gray-50 focus:bg-white focus:border-blue-400 focus:outline-none"
                    />
                  </div>
                ))}
              </div>
              {limitsModified && canWriteRateCreation && (
                <button
                  onClick={() => void handleSaveLimits()}
                  disabled={savingLimits}
                  className="w-full mt-1 px-2 py-0.5 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white text-[10px] font-bold rounded"
                >
                  {savingLimits ? 'Mentés...' : 'Határok mentése'}
                </button>
              )}
            </div>

            {/* FR-HL-10 (hibalista): dedikált ELLENŐRZÉS gomb — a háromlépcsős flow (Ellenőrzés →
              Mentés/auto-perzisztálás → Szétküldés) explicit szétválasztása. A gombra kattintáskor a
              fókuszált cella blur-je commitol, így a validationErrors (FR-HL-09 Ellenőrzés-oszlop)
              naprakész. Ez KLIENS-oldali pre-check (limit/MNB/árfolyamvédelem); a tényleges kiküldés
              a szerver-oldali árfolyamvédelmi ellenőrzést (RatePublishService) is elvégzi. */}
            <button
              onClick={() => {
                const errorCount = Object.values(validationErrors).filter(
                  (e) => e && e.length > 0,
                ).length
                if (errorCount === 0) {
                  toast.success(
                    'Ellenőrzés',
                    'A kliens-ellenőrzés rendben — a kiküldés a szerver-oldali védelmet is ellenőrzi.',
                  )
                } else {
                  toast.warning(
                    'Ellenőrzés',
                    `${errorCount} valutánál eltérés/hiba (lásd az „Ellenőrzés” oszlopot).`,
                  )
                }
              }}
              disabled={!selectedWg}
              className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-bold py-2 px-3 rounded shadow flex items-center justify-center gap-2 transition-colors flex-shrink-0"
            >
              <CheckCircle2 size={16} />
              <span className="text-xs">{i18n.t('literals.ellenorzes')}</span>
            </button>

            {/* Publish button - always visible */}
            <button
              onClick={() => void handlePublish()}
              disabled={publishing || !selectedWg || !canWriteRateCreation}
              className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-400 text-white font-bold py-2.5 px-3 rounded shadow flex items-center justify-center gap-2 transition-colors flex-shrink-0"
            >
              {publishing ? <RefreshCw size={16} className="animate-spin" /> : <Send size={16} />}
              <span className="text-xs" data-testid="publish-button-label">
                {publishing && publishProgress
                  ? t('rates.munkacsoportElkuldve', {
                      done: publishProgress.done,
                      total: publishProgress.total,
                    })
                  : t('rates.arfolyamokSzetkuldese')}
              </span>
            </button>
          </div>
        )}
      </div>

      {/* === BRANCH PICKER MODAL === */}
      <BranchPickerModal
        open={branchModalOpen}
        moveWarnings={branchMoveWarnings}
        saveError={branchSaveError}
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

      {/* FK02-D (FR-9..13): cross-csoport másolás — célcsoport-választó csempénézet + megerősítés */}
      {copyCells && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          onClick={closeCopyModal}
        >
          <div
            className="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[85vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between px-5 py-3 border-b">
              <h2 className="text-lg font-bold flex items-center gap-2">
                <Copy size={18} />
                {i18n.t('literals.masolas-mas-csoportba')}
              </h2>
              <button
                onClick={closeCopyModal}
                className="p-1 text-gray-500 hover:text-gray-800"
                aria-label="Bezárás"
              >
                <X size={20} />
              </button>
            </div>
            <div className="px-5 py-3 text-sm text-gray-600">
              {copyCells.length}
              {i18n.t('literals.kijelolt-cella-tartalma-a-kivalasztott-m')}
            </div>
            <div className="px-5 pb-3 overflow-y-auto">
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                {sortWorkgroupsBySequence(workgroups)
                  .filter((w) => w.id !== selectedWg?.id)
                  .map((wg) => {
                    const selected = copyTargetIds.has(wg.id)
                    return (
                      <button
                        key={wg.id}
                        type="button"
                        onClick={() => toggleCopyTarget(wg.id)}
                        className={`text-left rounded-lg border-2 p-3 transition-colors ${selected ? 'border-sky-500 bg-sky-100' : 'border-gray-200 bg-white hover:bg-gray-50'}`}
                      >
                        <div className="text-2xl font-bold leading-none text-gray-800">
                          {wg.legacyGroupNumber ?? '—'}
                        </div>
                        <div className="mt-2 text-sm font-medium truncate" title={wg.name}>
                          {wg.name}
                        </div>
                        {selected && (
                          <div className="mt-1 text-xs font-semibold text-sky-700">
                            {i18n.t('literals.kijelolve')}
                          </div>
                        )}
                      </button>
                    )
                  })}
              </div>
              {workgroups.filter((w) => w.id !== selectedWg?.id).length === 0 && (
                <div className="text-center py-6 text-gray-400 text-sm">
                  {i18n.t('literals.nincs-masik-munkacsoport')}
                </div>
              )}
            </div>
            <div className="px-5 py-3 border-t flex justify-end gap-2">
              <button
                onClick={closeCopyModal}
                className="px-4 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 text-sm font-medium"
              >
                {i18n.t('literals.megse')}
              </button>
              <button
                onClick={() => setCopyConfirmOpen(true)}
                disabled={copyTargetIds.size === 0}
                className="px-4 py-2 rounded-lg bg-sky-600 text-white hover:bg-sky-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-semibold"
              >
                {i18n.t('literals.veglegesites')}
                {copyTargetIds.size}
                {i18n.t('literals.lit-2')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* FK02-D (FR-12): megerősítő dialog a cross-csoport másoláshoz */}
      {copyConfirmOpen && copyCells && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-md w-full p-6">
            <h3 className="text-lg font-bold mb-3">{i18n.t('literals.masolas-megerositese')}</h3>
            <p className="text-sm text-gray-700 mb-5">
              {i18n.t('literals.biztosan-masolod-ezekbe-a-munkacsoportok')}{' '}
              <span className="font-semibold">
                {workgroups
                  .filter((w) => copyTargetIds.has(w.id))
                  .map((w) => w.name)
                  .join(', ')}
              </span>
              {i18n.t('literals.a-celcsoport-ok-erintett-cellainak-korab')}
            </p>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setCopyConfirmOpen(false)}
                className="px-4 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 text-sm font-medium"
              >
                {i18n.t('literals.nem')}
              </button>
              <button
                onClick={() => void executeCrossGroupCopy()}
                className="px-4 py-2 rounded-lg bg-sky-600 text-white hover:bg-sky-700 text-sm font-semibold"
              >
                {i18n.t('literals.igen-masolas')}
              </button>
            </div>
          </div>
        </div>
      )}
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
function toWorkgroupSaveDTO(
  wg: WorkgroupDetailDTO,
  overrides?: Partial<RateWorkgroupSaveDTO>,
): RateWorkgroupSaveDTO {
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
export function WorkgroupTileListView({
  workgroups,
  canWrite,
  onSelect,
  onBackToMain,
  onReload,
  loading,
  error,
}: TileListProps) {
  // FK-02 §3: az árfolyamkészítő EGYSÉGES munkacsoport-kezelő felülete. A korábbi
  // read-only csempe helyett itt érhetők el a karbantartó műveletek is (létrehozás,
  // átnevezés/szín/határ, törlés, interaktív árfolyamvédelem) — a megosztott
  // `workgroupMaintenance` primitíveken + `rateWorkgroupApi`-n keresztül, hogy a
  // WorkgroupManager-rel egyetlen forrásból menjen az írás. A csempe-kattintás
  // változatlanul a csoport árfolyamlapját nyitja meg (onSelect).
  const [editorOpen, setEditorOpen] = useState(false)
  const [editorMode, setEditorMode] = useState<'create' | 'rename'>('create')
  const [editingId, setEditingId] = useState<string | null>(null)
  const [draft, setDraft] = useState<RateWorkgroupSaveDTO>({
    name: '',
    code: '',
    active: true,
    tileColor: DEFAULT_TILE.key,
  })
  const [confirm, setConfirm] = useState<ConfirmState | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const openCreate = () => {
    setEditorMode('create')
    setEditingId(null)
    // FK02-E (FR-1, FR-2): a kódot ÉS a sorszámot a szerver osztja ki (a teljes cég-scope alapján,
    // az inaktív csoportok foglalt sorszámát is figyelembe véve) → a felhasználó nem lát ütközési
    // hibát. A sorszám üresen marad; igény esetén felülírható.
    setDraft({
      name: '',
      code: '',
      legacyGroupNumber: undefined,
      active: true,
      tileColor: DEFAULT_TILE.key,
      protectionEnabled: true,
      limit1Boundary: null,
      limit2Boundary: null,
      limit3Boundary: null,
    })
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
    // FK02-E (FR-1): a kód és (üres esetén) a sorszám is a szerveren képződik — csak a név kötelező.
    if (!draft.name.trim()) {
      setActionError('A név megadása kötelező.')
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
          <h1 className="text-base font-bold text-gray-800">
            {i18n.t('literals.csoport-arfolyamlapok')}
          </h1>
          <span className="text-xs text-gray-500">
            {i18n.t('literals.lit-19')}
            {workgroups.length}
            {i18n.t('literals.lit-2')}
          </span>
          <button
            onClick={onBackToMain}
            className="ml-2 flex items-center gap-1 px-2 py-0.5 text-[11px] font-medium border border-orange-400 bg-orange-50 hover:bg-orange-100 text-orange-800 rounded"
            title="Vissza a Főlap (0-s lap) elszámoló árfolyamokhoz"
          >
            <Home size={11} />
            {i18n.t('literals.folap')}
          </button>
        </div>
        <div className="flex items-center gap-2">
          {canWrite && (
            <button
              onClick={openCreate}
              className="flex items-center gap-1 px-2 py-1 text-[11px] font-semibold border border-blue-500 bg-blue-600 hover:bg-blue-700 text-white rounded"
              title="Új munkacsoport létrehozása"
            >
              <Plus size={12} />
              {i18n.t('literals.uj-munkacsoport')}
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
          <span className="ml-3 text-gray-600">{i18n.t('literals.csoportok-betoltese')}</span>
        </div>
      ) : workgroups.length === 0 ? (
        <div className="bg-white rounded shadow-sm border p-6 text-center text-gray-500">
          {i18n.t('literals.meg-nincs-csoport-arfolyamlap')}
          {canWrite
            ? ' Hozzon létre egyet az „Új munkacsoport” gombbal.'
            : ' Új létrehozása a Munkacsoportok kezelő felületen lehetséges.'}
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
                        onChange={(e) => void toggleProtection(wg, e.target.checked)}
                        className="h-3.5 w-3.5"
                        aria-label={`Árfolyamvédelem a(z) ${wg.name} csoporton`}
                      />
                      {i18n.t('literals.vedelem')}
                    </label>
                  ) : (
                    <span
                      className={`inline-flex items-center gap-0.5 text-[10px] font-bold ${protectionOn ? 'text-green-700' : 'text-gray-400'}`}
                      title={protectionOn ? 'Árfolyamvédelem BE' : 'Árfolyamvédelem KI'}
                    >
                      {protectionOn ? <ShieldCheck size={12} /> : <Shield size={12} />}
                      {i18n.t('literals.vedelem')}
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
                    {String(wg.legacyGroupNumber ?? idx + 1).padStart(2, '0')}
                  </div>
                  <div className="text-sm font-semibold truncate" title={wg.name}>
                    {wg.name}
                  </div>
                  <div className="text-xs opacity-70 mt-0.5">
                    <span className="font-mono">{wg.code}</span>
                    <span className="mx-1">{i18n.t('literals.lit-45')}</span>
                    <span>
                      {wg.branches.length}
                      {i18n.t('literals.iroda-2')}
                    </span>
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
                      <Pencil size={10} />
                      {i18n.t('literals.szerk')}
                    </button>
                    <button
                      type="button"
                      onClick={() => requestDelete(wg)}
                      className="inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-medium rounded bg-white/70 hover:bg-red-50 text-red-700 border border-red-200"
                      title="Munkacsoport törlése"
                    >
                      <Trash2 size={10} />
                      {i18n.t('literals.torles-2')}
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
          onSave={() => {
            void saveEditor()
          }}
          onCancel={() => {
            setEditorOpen(false)
            setActionError(null)
          }}
        />
      )}
      {confirm && <ConfirmDialog state={confirm} onCancel={() => setConfirm(null)} />}
    </div>
  )
}
