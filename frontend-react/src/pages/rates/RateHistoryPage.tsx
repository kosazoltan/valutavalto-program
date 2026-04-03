import { useState, useEffect, useCallback } from 'react'
import { Clock, Search, RefreshCw, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

interface RateHistoryItem {
  id: string | number
  currencyCode?: string
  buyRate?: string
  sellRate?: string
  validFrom?: string
  createdByName?: string
}

export default function RateHistoryPage() {
  const [items, setItems] = useState<RateHistoryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<RateHistoryItem[]>('/rate-history')
      setItems(Array.isArray(response.data) ? response.data : [])
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateHistoryPage', 'Betoltesi hiba:', err)
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
    <div className="space-y-4 p-4">
      <div className="flex items-center justify-between">
        <h1 className="flex items-center gap-2 text-xl font-bold">
          <Clock className="h-6 w-6" />
          Arfolyam tortenelem
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="rounded bg-gray-100 p-2 hover:bg-gray-200" title="Frissites">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2">
          <div className="flex gap-2">
            <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
              className="rounded border border-gray-300 px-2 py-1 text-sm" />
            <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
              className="rounded border border-gray-300 px-2 py-1 text-sm" />
          </div>
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Kereses..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="w-full rounded border border-gray-300 py-2 pl-10 pr-3 text-sm focus:border-blue-500 focus:outline-none"
          />
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded bg-red-50 p-3 text-sm text-red-700">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="overflow-x-auto rounded border">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Valuta</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Veteli arf.</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Eladasi arf.</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Ervenyes</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Modositotta</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Betoltes...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Nincs adat</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.currencyCode ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.buyRate ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.sellRate ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.validFrom ? new Date(item.validFrom).toLocaleString('hu-HU') : '-'}</td>
                <td className="px-4 py-3 text-sm">{item.createdByName ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        Osszes: {filtered.length} / {items.length}
      </div>
    </div>
  )
}
