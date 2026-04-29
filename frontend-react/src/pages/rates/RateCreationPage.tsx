import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { AxiosError } from 'axios'
import { RefreshCw, AlertTriangle, Send, Plus, X, Building2, Clock, Undo2, Redo2 } from 'lucide-react'
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

// ===================== Main Component =====================

export default function RateCreationPage() {
  const canWriteRateCreation = useAuthStore((state) => state.isSupervisorOrAbove())
  const [overview, setOverview] = useState<RateOverviewDTO | null>(null)
  const [workgroups, setWorkgroups] = useState<WorkgroupDetailDTO[]>([])
  const [rates, setRates] = useState<EditableRate[]>([])
  const undoStack = useRef<EditableRate[][]>([])
  const redoStack = useRef<EditableRate[][]>([])
  const [selectedWgIndex, setSelectedWgIndex] = useState<number>(0)
  const [loading, setLoading] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const [error, setError] = useState<string | null>(null)

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

  const loadData = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [overviewData, wgData] = await Promise.all([
        rateCreationApi.getOverview(),
        rateCreationApi.getWorkgroupDetails()
      ])
      setOverview(overviewData)
      setWorkgroups(wgData)

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
  }, [])

  useEffect(() => { void loadData() }, [loadData])

  const pushUndo = useCallback(() => {
    undoStack.current.push(rates.map(r => ({ ...r })))
    if (undoStack.current.length > 50) undoStack.current.shift()
    redoStack.current = []
  }, [rates])

  const undo = useCallback(() => {
    if (undoStack.current.length === 0) return
    redoStack.current.push(rates.map(r => ({ ...r })))
    setRates(undoStack.current.pop()!)
  }, [rates])

  const redo = useCallback(() => {
    if (redoStack.current.length === 0) return
    undoStack.current.push(rates.map(r => ({ ...r })))
    setRates(redoStack.current.pop()!)
  }, [rates])

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

  // ===================== Limit save =====================

  const handleSaveLimits = async () => {
    if (!selectedWg) return
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'A határok mentéséhez supervisor vagy magasabb szerepkör kell')
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
        toast.error('Nincs jogosultság', 'A határok mentéséhez supervisor vagy magasabb szerepkör kell')
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
      toast.error('Nincs jogosultság', 'Irodák mentéséhez supervisor vagy magasabb szerepkör kell')
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
        toast.error('Nincs jogosultság', 'Irodák mentéséhez supervisor vagy magasabb szerepkör kell')
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
      toast.error('Nincs jogosultság', 'Iroda eltávolításához supervisor vagy magasabb szerepkör kell')
      return
    }
    const newIds = selectedWg.branches.filter(b => b.id !== branchId).map(b => b.id)
    try {
      await rateCreationApi.updateWorkgroupBranches(selectedWg.id, newIds)
      toast.success('Eltávolítva', 'Iroda eltávolítva a csoportból')
      void loadData()
    } catch (err) {
      if (err instanceof AxiosError && err.response?.status === 403) {
        toast.error('Nincs jogosultság', 'Iroda eltávolításához supervisor vagy magasabb szerepkör kell')
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

  // ===================== Publish =====================

  const handlePublish = async () => {
    if (!selectedWg) {
      toast.warning('Munkacsoport szükséges', 'Válasszon munkacsoportot!')
      return
    }
    if (!canWriteRateCreation) {
      toast.error('Nincs jogosultság', 'Publikáláshoz supervisor vagy magasabb szerepkör kell')
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
      await rateCreationApi.publishGroupRate({
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
      toast.success('Publikálva!', `${validRates.length} árfolyam kiküldve: ${selectedWg.name} (${selectedWg.branches.length} iroda)`)
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

  if (loading && !overview) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="animate-spin text-blue-600" size={32} />
        <span className="ml-3 text-gray-600">Árfolyamok betöltése...</span>
      </div>
    )
  }

  const modifiedCount = rates.filter(r => r.modified).length

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
        <h1 className="text-sm font-bold text-gray-800">Árfolyamkészítés</h1>
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
            <span className="text-orange-600 font-medium">{modifiedCount} mod.</span>
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
        <RateGrid rates={rates} selectedWg={selectedWg} updateRate={updateRate} validationErrors={validationErrors} />

        {/* === RIGHT: WORKGROUP PANEL === */}
        <div className="w-64 flex-shrink-0 flex flex-col gap-1 min-h-0">

          {/* Workgroup selector: tiny numbered buttons */}
          <div className="bg-white rounded border shadow-sm px-2 py-1.5">
            <div className="flex items-center gap-1 flex-wrap">
              {workgroups.map((wg, idx) => (
                <button
                  key={wg.id}
                  onClick={() => setSelectedWgIndex(idx)}
                  className={`w-6 h-6 rounded text-[10px] font-bold border transition-colors ${
                    idx === selectedWgIndex
                      ? 'bg-green-600 text-white border-green-700 shadow-sm'
                      : 'bg-green-50 text-green-800 border-green-300 hover:bg-green-200'
                  }`}
                >
                  {wg.legacyGroupNumber ?? (idx + 1)}
                </button>
              ))}
            </div>
            {selectedWg && (
              <div className="text-xs font-bold text-gray-800 mt-1 truncate">{selectedWg.name}</div>
            )}
          </div>

          {/* Branch list */}
          <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-1 min-h-0 flex flex-col overflow-hidden">
            <div className="flex items-center justify-between mb-1">
              <span className="text-[10px] text-gray-500 uppercase font-bold flex items-center gap-1">
                <Building2 size={10} />
                Irodák ({selectedWg?.branches.length ?? 0})
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
                <div className="text-gray-400 italic text-center text-[10px] py-2">Nincs iroda hozzárendelve</div>
              )}
            </div>
          </div>

          {/* Limit boundaries - editable */}
          <div className="bg-white rounded border shadow-sm px-2 py-1.5 flex-shrink-0">
            <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">Határok (Ft)</div>
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
            <span className="text-xs">ÁRFOLYAMOK SZÉTKÜLDÉSE</span>
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
