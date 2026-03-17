import { useState, useEffect, useCallback, useMemo } from 'react'
import { RefreshCw, AlertTriangle, Send, Plus, X, Building2, Clock } from 'lucide-react'
import {
  rateCreationApi,
  RateOverviewDTO,
  RateOverviewItem,
  WorkgroupDetailDTO,
  BranchListItem
} from '../../services/api'
import { toast } from '../../components/ui/toaster'
import { formatDecimal } from '../../utils/numberFormat'

// ===================== Types =====================

interface EditableRate {
  currencyId: number
  currencyCode: string
  currencyName: string
  officialRate: number | null
  buyRate: string
  sellRate: string
  limit1BuyRate: string
  limit1SellRate: string
  limit2BuyRate: string
  limit2SellRate: string
  limit3BuyRate: string
  limit3SellRate: string
  hasRate: boolean
  modified: boolean
}

function parseNum(val: string): number {
  return parseFloat(val.replace(',', '.')) || 0
}

function fmtRate(val: number | null | undefined, decimals = 4): string {
  if (val == null || val === 0) return ''
  return val.toFixed(decimals).replace('.', ',')
}

function fmtAmount(val: number | null | undefined): string {
  if (val == null || val === 0) return ''
  return Math.round(val).toLocaleString('hu-HU')
}

// ===================== Main Component =====================

export default function RateCreationPage() {
  const [overview, setOverview] = useState<RateOverviewDTO | null>(null)
  const [workgroups, setWorkgroups] = useState<WorkgroupDetailDTO[]>([])
  const [rates, setRates] = useState<EditableRate[]>([])
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
  }, [selectedWg?.id]) // eslint-disable-line react-hooks/exhaustive-deps

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
      console.error('Betöltési hiba:', err)
      setError('Hiba az árfolyam adatok betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void loadData() }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const updateRate = (index: number, field: keyof EditableRate, value: string) => {
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
    } catch {
      toast.error('Hiba', 'Nem sikerült a határok mentése')
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
    setSavingBranches(true)
    try {
      await rateCreationApi.updateWorkgroupBranches(selectedWg.id, Array.from(selectedBranchIds))
      toast.success('Mentve', 'Irodák frissítve')
      setBranchModalOpen(false)
      void loadData()
    } catch {
      toast.error('Hiba', 'Nem sikerült az irodák mentése')
    } finally {
      setSavingBranches(false)
    }
  }

  const removeBranch = async (branchId: string) => {
    if (!selectedWg) return
    const newIds = selectedWg.branches.filter(b => b.id !== branchId).map(b => b.id)
    try {
      await rateCreationApi.updateWorkgroupBranches(selectedWg.id, newIds)
      toast.success('Eltávolítva', 'Iroda eltávolítva a csoportból')
      void loadData()
    } catch {
      toast.error('Hiba', 'Nem sikerült az iroda eltávolítása')
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
    <div className="h-[calc(100vh-9.5rem)] flex flex-col">
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
        <div className="flex-1 bg-white rounded shadow-sm border overflow-hidden flex flex-col min-w-0">
          <div className="overflow-auto flex-1">
            <table className="w-full text-xs border-collapse">
              <thead className="sticky top-0 z-20">
                <tr className="bg-green-800 text-white text-[10px]">
                  <th colSpan={2} className="px-1 py-0.5 text-left border-r border-green-600">Elsz.árf.</th>
                  <th className="px-1 py-0.5 border-r border-green-600">Valuta</th>
                  <th colSpan={2} className="px-1 py-0.5 border-r border-green-600 text-center">
                    0 - {fmtAmount(selectedWg?.limit1Boundary)}
                  </th>
                  <th colSpan={2} className="px-1 py-0.5 border-r border-green-600 text-center">
                    {fmtAmount(selectedWg?.limit1Boundary)} - {fmtAmount(selectedWg?.limit2Boundary)}
                  </th>
                  <th colSpan={2} className="px-1 py-0.5 border-r border-green-600 text-center">
                    {fmtAmount(selectedWg?.limit2Boundary)} - {fmtAmount(selectedWg?.limit3Boundary)}
                  </th>
                  <th colSpan={2} className="px-1 py-0.5 text-center">Saját hat.</th>
                </tr>
                <tr className="bg-green-700 text-white text-[10px]">
                  <th className="px-1 py-0.5 text-left w-14 border-r border-green-500">MNB</th>
                  <th className="px-1 py-0.5 w-4 border-r border-green-500"></th>
                  <th className="px-1 py-0.5 w-10 border-r border-green-500 font-bold">Kód</th>
                  <th className="px-1 py-0.5 w-[72px] text-green-200 border-r border-green-500">Vet</th>
                  <th className="px-1 py-0.5 w-[72px] text-red-200 border-r border-green-500">Elad</th>
                  <th className="px-1 py-0.5 w-[72px] text-green-200 border-r border-green-500">V+</th>
                  <th className="px-1 py-0.5 w-[72px] text-red-200 border-r border-green-500">E-</th>
                  <th className="px-1 py-0.5 w-[72px] text-green-200 border-r border-green-500">V+</th>
                  <th className="px-1 py-0.5 w-[72px] text-red-200 border-r border-green-500">E-</th>
                  <th className="px-1 py-0.5 w-[72px] text-green-200">Vmax</th>
                  <th className="px-1 py-0.5 w-[72px] text-red-200">Emin</th>
                </tr>
                <tr className="bg-gray-200 text-gray-500 text-[9px] font-bold">
                  <th className="px-1 py-0 border-r">J</th>
                  <th className="px-1 py-0 border-r"></th>
                  <th className="px-1 py-0 border-r">K</th>
                  <th className="px-1 py-0 border-r">L</th>
                  <th className="px-1 py-0 border-r">M</th>
                  <th className="px-1 py-0 border-r">N</th>
                  <th className="px-1 py-0 border-r">O</th>
                  <th className="px-1 py-0 border-r">P</th>
                  <th className="px-1 py-0 border-r">Q</th>
                  <th className="px-1 py-0">R</th>
                  <th className="px-1 py-0">S</th>
                </tr>
              </thead>
              <tbody>
                {rates.map((r, idx) => {
                  const buy = parseNum(r.buyRate)
                  const sell = parseNum(r.sellRate)
                  const isInvalid = buy > 0 && sell > 0 && buy >= sell
                  const rowBg = r.modified
                    ? 'bg-yellow-50'
                    : !r.hasRate
                      ? 'bg-gray-50'
                      : idx % 2 === 0 ? 'bg-white' : 'bg-gray-50/50'

                  return (
                    <tr key={r.currencyId} className={`${rowBg} border-b border-gray-100 hover:bg-blue-50/30`}>
                      <td className="px-1 py-0 text-right font-mono text-blue-800 font-bold border-r text-[11px]">
                        {r.officialRate ? formatDecimal(r.officialRate, 2, 4) : '0'}
                      </td>
                      <td className="px-0 py-0 text-center border-r w-4">
                        {r.modified && <span className="inline-block w-1.5 h-1.5 rounded-full bg-orange-400" />}
                        {isInvalid && <AlertTriangle size={9} className="text-red-500 inline" />}
                      </td>
                      <td className="px-1 py-0 text-center font-bold text-blue-700 border-r text-[11px]">
                        {r.currencyCode}
                      </td>
                      {/* Rate input cells */}
                      {(['buyRate', 'sellRate', 'limit1BuyRate', 'limit1SellRate', 'limit2BuyRate', 'limit2SellRate', 'limit3BuyRate', 'limit3SellRate'] as const).map((field) => {
                        const isBuy = field.includes('buy') || field === 'buyRate'
                        const colorClass = isBuy ? 'text-green-700' : 'text-red-700'
                        const focusBg = isBuy ? 'focus:bg-green-50' : 'focus:bg-red-50'
                        return (
                          <td key={field} className="px-0 py-0 border-r last:border-r-0">
                            <input type="text" value={r[field]}
                              onChange={e => updateRate(idx, field, e.target.value)}
                              className={`w-full px-0.5 py-0 text-right font-mono text-[11px] ${colorClass} font-bold border-0 bg-transparent ${focusBg} focus:outline-none`}
                            />
                          </td>
                        )
                      })}
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>

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
                    className="flex-1 px-1.5 py-0.5 text-right font-mono text-[11px] font-bold border rounded bg-gray-50 focus:bg-white focus:border-blue-400 focus:outline-none"
                  />
                </div>
              ))}
            </div>
            {limitsModified && (
              <button onClick={() => void handleSaveLimits()} disabled={savingLimits}
                className="w-full mt-1 px-2 py-0.5 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white text-[10px] font-bold rounded">
                {savingLimits ? 'Mentés...' : 'Határok mentése'}
              </button>
            )}
          </div>

          {/* Publish button - always visible */}
          <button
            onClick={() => void handlePublish()}
            disabled={publishing || !selectedWg}
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
      {branchModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-lg shadow-xl w-[600px] max-h-[80vh] flex flex-col">
            {/* Modal header */}
            <div className="flex items-center justify-between px-4 py-2 border-b">
              <h2 className="text-sm font-bold text-gray-800">
                Irodák kezelése — {selectedWg?.name}
              </h2>
              <button onClick={() => setBranchModalOpen(false)} className="text-gray-400 hover:text-gray-600">
                <X size={18} />
              </button>
            </div>

            {/* Search */}
            <div className="px-4 py-2 border-b">
              <input
                type="text"
                placeholder="Keresés név, kód vagy város szerint..."
                value={branchFilter}
                onChange={e => setBranchFilter(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border rounded focus:border-blue-400 focus:outline-none"
              />
            </div>

            {/* Branch list grouped by city */}
            <div className="flex-1 overflow-y-auto px-4 py-2">
              {groupedBranches.map(([city, branches]) => (
                <div key={city} className="mb-2">
                  <div className="text-[10px] font-bold text-gray-500 uppercase mb-0.5">{city}</div>
                  <div className="space-y-0.5">
                    {branches.map(b => (
                      <label key={b.id} className="flex items-center gap-2 px-2 py-1 rounded hover:bg-gray-50 cursor-pointer text-xs">
                        <input
                          type="checkbox"
                          checked={selectedBranchIds.has(b.id)}
                          onChange={() => toggleBranch(b.id)}
                          className="rounded border-gray-300 text-green-600 focus:ring-green-500"
                        />
                        <span className="font-mono text-gray-500 w-12">{b.code}</span>
                        <span className="text-gray-800">{b.name}</span>
                      </label>
                    ))}
                  </div>
                </div>
              ))}
              {groupedBranches.length === 0 && (
                <div className="text-center text-gray-400 py-8 text-sm">Nincs találat</div>
              )}
            </div>

            {/* Modal footer */}
            <div className="flex items-center justify-between px-4 py-2 border-t bg-gray-50">
              <span className="text-xs text-gray-500">{selectedBranchIds.size} iroda kiválasztva</span>
              <div className="flex gap-2">
                <button onClick={() => setBranchModalOpen(false)}
                  className="px-3 py-1.5 text-xs border rounded hover:bg-gray-100">
                  Mégse
                </button>
                <button onClick={() => void handleSaveBranches()} disabled={savingBranches}
                  className="px-3 py-1.5 text-xs bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white rounded font-bold">
                  {savingBranches ? 'Mentés...' : 'Mentés'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
