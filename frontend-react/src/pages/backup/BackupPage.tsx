import { useState, useEffect, useCallback } from 'react'
import { Database, Search, RefreshCw, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'

interface BackupItem {
  id: string | number
  backupType?: string
  createdAt?: string
  sizeBytes?: string
  status?: string
  createdByName?: string
}

export default function BackupPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<BackupItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<BackupItem[]>('/backup')
      setItems(safeArray<typeof items[0]>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BackupPage', 'Betöltési hiba:', err)
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
          <Database className="h-6 w-6" />
          {t('backup.mentesEsVisszaallitas')}
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
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('backup.tipus')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('backup.letrehozva')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('backup.meret')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('backup.allapot')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('backup.keszitette')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.noData')}</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.backupType ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.createdAt ? new Date(item.createdAt).toLocaleString('hu-HU') : '-'}</td>
                <td className="px-4 py-3 text-sm">{item.sizeBytes ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.createdByName ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}{filtered.length} / {items.length}
      </div>
    </div>
  )
}
