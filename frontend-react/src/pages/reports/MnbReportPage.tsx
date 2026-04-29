import { useState, useEffect, useCallback } from 'react'
import { FileText, Search, RefreshCw, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { asArray } from '../../utils/asArray'

// Fix 2026-04-24 (Codex PR #183 P2): backend MnbReportDto tenyleges mezoi
// (NEM periodStart/periodEnd, hanem reportDate + egyeb)
interface MnbReportItem {
  id: string | number
  reportType?: string
  reportDate?: string
  status?: string
  submittedAt?: string
  branchId?: string
  totalBuyHuf?: number
  totalSellHuf?: number
  totalTransactions?: number
}

// (Page<> interface-re nincs szukseg: interceptor unwrap-olja array-ra)

export default function MnbReportPage() {
  const [items, setItems] = useState<MnbReportItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      // Fix 2026-04-24: backend Page<MnbReportDto>, DE a client.ts interceptor
      // MAR auto-unwrappeli Page<T> -> T[] (`response.data` maga az array). AI review
      // (Codex PR #180 P1 interceptor figyelmeztetes).
      // AI review (Sourcery PR #186): magic konstans helyett megneves (silent truncation kockazat >100 rekord-nal)
      const MNB_REPORTS_PAGE_SIZE = 500
      const response = await api.get<MnbReportItem[]>('/mnb/reports', { params: { size: MNB_REPORTS_PAGE_SIZE } })
      setItems(safeArray<MnbReportItem>(asArray<MnbReportItem>(response.data)))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MnbReportPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = items.filter(item => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some(v =>
      v != null && String(v).toLowerCase().includes(term)
    )
  })

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileText className="h-6 w-6" />
          MNB jelentések
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Keresés..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Típus</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Riport dátum</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Tranzakció db</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Állapot</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Beküldés</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Nincs adat</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.reportType ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.reportDate ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.totalTransactions ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.submittedAt ? new Date(item.submittedAt).toLocaleString('hu-HU') : '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        Összesen: {filtered.length} / {items.length}
      </div>
    </div>
  )
}
