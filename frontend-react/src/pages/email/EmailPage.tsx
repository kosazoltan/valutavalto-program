import { useState, useEffect, useCallback } from 'react'
import { Mail, Search, RefreshCw, Plus, Edit2, Trash2, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'

interface EmailAccountItem {
  id: string | number
  email?: string
  provider?: string
  isDefault?: boolean
  isActive?: boolean
}

export default function EmailPage() {
  const [items, setItems] = useState<EmailAccountItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      // Codex PR #144 P1 fix: backend payload = { accounts, configurable }, nem bare array.
      const response = await api.get<{ accounts?: EmailAccountItem[]; configurable?: EmailAccountItem[] }>('/email/accounts')
      setItems(safeArray<EmailAccountItem>(response.data?.accounts))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Betöltési hiba:', err)
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
    if (!confirm('Biztosan törli?')) return
    try {
      await api.delete(`/email/accounts/${id}`)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('EmailPage', 'Törlési hiba:', err)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Mail className="h-6 w-6" />
          Email beállítások
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button className="form-button-primary flex items-center gap-1">
            <Plus className="h-4 w-4" /> Új
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
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Email cím</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Szolgáltató</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Alapértelmezett</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Aktív</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">Műveletek</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Nincs adat</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.email ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.provider ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.isDefault ? 'Igen' : 'Nem'}</td>
                <td className="px-4 py-3 text-sm">{item.isActive ? 'Igen' : 'Nem'}</td>
                <td className="px-4 py-3 text-right">
                  <button className="form-button mr-2 p-1 text-blue-600" title="Szerkesztés">
                    <Edit2 className="h-4 w-4" />
                  </button>
                  <button onClick={() => handleDelete(item.id)} className="form-button p-1 text-red-600" title="Törlés">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
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
