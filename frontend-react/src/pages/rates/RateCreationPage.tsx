import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { AxiosError } from 'axios'
import { RefreshCw, AlertTriangle, Send, Plus, X, Building2, Clock, Undo2, Redo2, Home, ArrowLeft, ShieldCheck, Shield } from 'lucide-react'
import {
  rateCreationApi,
  RateOverviewDTO,
  RateOverviewItem,
  WorkgroupDetailDTO,
  BranchListItem,
} from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import RateGrid from './components/RateGrid'
import BranchPickerModal from './components/BranchPickerModal'
import { fmtRate, parseNum, type EditableRate } from './types'
import { currentFunctionCode, fillDownLimitBands, clearLimitBands } from './fillHelpers'
import { validateWorkgroupProtection, workgroupProtectionLabel, type ProtectionRow } from './workgroupProtection'
import { isFormula, type WgValues } from './workgroupSheetFormula'
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
} from './workgroupSheetStorage'
import { useTranslation } from 'react-i18next'

/** FK-04/C: a 8 képletezhető string-mező (J=officialRate read-only auto, K=ISO kód kihagyva). */
const WG_STRING_FIELDS: Exclude<WgField, 'officialRate'>[] = [
  'buyRate', 'sellRate',
  'limit1BuyRate', 'limit1SellRate',
  'limit2BuyRate', 'limit2SellRate',
  'limit3BuyRate', 'limit3SellRate',
]

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
  // FK-04/C (Codex #906): az undo/redo a `rates` MELLETT a `formulas`-t is rögzíti — különben
  // egy képlet beírása után a Ctrl+Z csak a megjelenített értéket állítaná vissza, a képlet a
  // state/localStorage-ban maradna, és a recompute újra alkalmazná (képlet-szerkesztés nem volt visszavonható).
  type UndoSnapshot = { rates: EditableRate[]; formulas: Record<string, string> }
  const undoStack = useRef<UndoSnapshot[]>([])
  const redoStack = useRef<UndoSnapshot[]>([])
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
  // eslint-disable-next-line react-hooks/exhaustive-deps -- csak a csoport-id váltáskor töltünk újra
  }, [selectedWg?.id])

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
      saveSnapshot(computeRows) // fix-rátás csoport pillanatképe is elérhető #NN-hez
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
      setRates(editableRates)
    } catch (err) {
      logger.error('RateCreationPage', 'Betöltési hiba:', err)
      setError('Hiba az árfolyam adatok betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [isLocalRateMakerApp])

  useEffect(() => { void loadData() }, [loadData])

  const pushUndo = useCallback(() => {
    undoStack.current.push({ rates: rates.map(r => ({ ...r })), formulas: { ...formulas } })
    if (undoStack.current.length > 50) undoStack.current.shift()
    redoStack.current = []
  }, [rates, formulas])

  const undo = useCallback(() => {
    const prev = undoStack.current.pop()
    if (!prev) return
    redoStack.current.push({ rates: rates.map(r => ({ ...r })), formulas: { ...formulas } })
    setRates(prev.rates)
    setFormulas(prev.formulas)
  }, [rates, formulas])

  const redo = useCallback(() => {
    const nextState = redoStack.current.pop()
    if (!nextState) return
    undoStack.current.push({ rates: rates.map(r => ({ ...r })), formulas: { ...formulas } })
    setRates(nextState.rates)
    setFormulas(nextState.formulas)
  }, [rates, formulas])

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
      setRates(prev => prev.map((x, i) => (i === index ? { ...x, [field]: trimmed, modified: true } : x)))
    }
  }, [canWriteRateCreation, rates, pushUndo])

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
        />

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
    </div>
  )
}

// ===================== FK-02/03/04 Tile-list view =====================
// Csempés listanézet (a régi „bal oldali sávos" 54-csoport választó HELYETT).
// Spec: Kasza Helga / Bali Henriett 2026-05-28 docx (FK-02 + FK-03 + FK-04).
// - Egy csempén: sorszám, név, kód, árfolyamvédelem-checkbox a jobb felső sarokban.
// - Egy klikk a csempére → azonnal megnyitja a csoport árfolyamlap szerkesztőt.
// - 10 választható csempeszín (tileColor mező a backendben).

const TILE_PALETTE_RCP: { key: string; tile: string }[] = [
  { key: 'slate',  tile: 'bg-slate-100 border-slate-300 text-slate-800 hover:bg-slate-200' },
  { key: 'red',    tile: 'bg-red-100 border-red-300 text-red-800 hover:bg-red-200' },
  { key: 'orange', tile: 'bg-orange-100 border-orange-300 text-orange-800 hover:bg-orange-200' },
  { key: 'amber',  tile: 'bg-amber-100 border-amber-300 text-amber-800 hover:bg-amber-200' },
  { key: 'green',  tile: 'bg-green-100 border-green-300 text-green-800 hover:bg-green-200' },
  { key: 'teal',   tile: 'bg-teal-100 border-teal-300 text-teal-800 hover:bg-teal-200' },
  { key: 'sky',    tile: 'bg-sky-100 border-sky-300 text-sky-800 hover:bg-sky-200' },
  { key: 'indigo', tile: 'bg-indigo-100 border-indigo-300 text-indigo-800 hover:bg-indigo-200' },
  { key: 'purple', tile: 'bg-purple-100 border-purple-300 text-purple-800 hover:bg-purple-200' },
  { key: 'pink',   tile: 'bg-pink-100 border-pink-300 text-pink-800 hover:bg-pink-200' },
]
function tileColorClassesRcp(colorKey: string | null | undefined): string {
  return (TILE_PALETTE_RCP.find(p => p.key === colorKey) ?? TILE_PALETTE_RCP[0]!).tile
}

interface TileListProps {
  workgroups: WorkgroupDetailDTO[]
  onSelect: (idx: number) => void
  onBackToMain: () => void
  onReload: () => void
  loading: boolean
  error: string | null
}

function WorkgroupTileListView({ workgroups, onSelect, onBackToMain, onReload, loading, error }: TileListProps) {
  // FK-04/E.1 (mai PR #882): árfolyamvédelem checkbox a csempén — a tényleges
  // toggle-flow a rateWorkgroupApi.update-en megy. A csempés nézet read-only
  // megjelenítést ad: a flag pillanatképét mutatja. A részletes szerkesztés
  // (átnevezés, szín, határok) a /rate-management → Munkacsoportok tab-on
  // (WorkgroupManager) történik, hogy egyetlen forrásból menjen az írás.
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
        <button
          onClick={onReload}
          disabled={loading}
          className="p-1 rounded hover:bg-gray-100 disabled:opacity-30"
          title="Frissítés"
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded flex items-center gap-2 text-sm">
          <AlertTriangle size={14} /> {error}
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
          Még nincs csoport árfolyamlap. Új létrehozása a Munkacsoportok kezelő felületen lehetséges.
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
          {workgroups.map((wg, idx) => {
            const protectionOn = wg.protectionEnabled ?? true
            return (
              <button
                key={wg.id}
                onClick={() => onSelect(idx)}
                className={`text-left rounded-lg border-2 p-3 transition-shadow hover:shadow-md ${tileColorClassesRcp(wg.tileColor)}`}
              >
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div className="text-2xl font-bold leading-none font-mono">
                    {String(wg.legacyGroupNumber ?? (idx + 1)).padStart(2, '0')}
                  </div>
                  {/* FK-04/E.1: árfolyamvédelem-jelző (read-only). A toggle a
                      /rate-management → Munkacsoportok tab-on van — single source of truth. */}
                  <span
                    className={`inline-flex items-center gap-0.5 text-[10px] font-bold ${
                      protectionOn ? 'text-green-700' : 'text-gray-400'
                    }`}
                    title={protectionOn ? 'Árfolyamvédelem BE — a vétel/eladás-szabály a mentésnél érvényre jut.' : 'Árfolyamvédelem KI — a mentés a szabálysértő értékekkel is engedélyezett.'}
                  >
                    {protectionOn ? <ShieldCheck size={12} /> : <Shield size={12} />}
                    VÉDELEM
                  </span>
                </div>
                <div className="text-sm font-semibold truncate" title={wg.name}>{wg.name}</div>
                <div className="text-xs opacity-70 mt-0.5">
                  <span className="font-mono">{wg.code}</span>
                  <span className="mx-1">·</span>
                  <span>{wg.branches.length} iroda</span>
                </div>
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}
