import { useState, useEffect, useCallback } from 'react'
import { Clock, Search, RefreshCw, Plus, Edit2, Trash2, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

interface SchedulerJobItem {
  id: string | number
  jobName?: string
  cronExpression?: string
  lastRun?: string
  nextRun?: string
  isActive?: boolean
}

export default function SchedulerPage() {
  const [items, setItems] = useState<SchedulerJobItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<SchedulerJobItem[]>('/scheduler')
      setItems(Array.isArray(response.data) ? response.data : [])
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SchedulerPage', 'Betoltesi hiba:', err)
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

  const handleDelete = async (id: string | number) => {
    if (!confirm('Biztosan torli?')) return
    try {
      await api.delete(`/scheduler/${id}`)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('SchedulerPage', 'Torlesi hiba:', err)
    }
  }

  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center justify-between">
        <h1 className="flex items-center gap-2 text-xl font-bold">
          <Clock className="h-6 w-6" />
          Utemezesek
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="rounded bg-gray-100 p-2 hover:bg-gray-200" title="Frissites">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button className="flex items-center gap-1 rounded bg-blue-600 px-3 py-2 text-sm text-white hover:bg-blue-700">
            <Plus className="h-4 w-4" /> Uj
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2">
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
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Feladat</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Utemezes</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Utolso futatas</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Kovetkezo futatas</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Aktiv</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">Muveletek</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">Betoltes...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">Nincs adat</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.jobName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.cronExpression ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.lastRun ? new Date(item.lastRun).toLocaleString('hu-HU') : '-'}</td>
                <td className="px-4 py-3 text-sm">{item.nextRun ? new Date(item.nextRun).toLocaleString('hu-HU') : '-'}</td>
                <td className="px-4 py-3 text-sm">{item.isActive ? 'Igen' : 'Nem'}</td>
                <td className="px-4 py-3 text-right">
                  <button className="mr-2 rounded p-1 text-blue-600 hover:bg-blue-50" title="Szerkesztes">
                    <Edit2 className="h-4 w-4" />
                  </button>
                  <button onClick={() => handleDelete(item.id)} className="rounded p-1 text-red-600 hover:bg-red-50" title="Torles">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
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
