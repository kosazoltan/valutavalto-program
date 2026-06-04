import { useState, useEffect, useCallback } from 'react'
import { Calendar, Search, RefreshCw, AlertTriangle, Printer } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'

interface MonthlyClosingSummaryItem {
  id: string | number
  yearMonth?: string
  branchName?: string
  status?: string
  closedAt?: string
  closedByName?: string
}

export default function MonthlyClosingPage() {
  const { t } = useTranslation()
  // 2026-04-29 B35 fix: a backend /closing/monthly endpoint csak {branchId}-os
  // GET-eket implemental, root-level lista nincs. A current worker branch-et
  // hasznaljuk a multi-tenant biztonsag tiszteletben tartasaval.
  const branchId = useAuthStore((state) => state.worker?.branchId)
  const [items, setItems] = useState<MonthlyClosingSummaryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    if (!branchId) {
      setError(t('monthlyClose.branchRequired'))
      setLoading(false)
      return
    }
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<MonthlyClosingSummaryItem[]>(`/closing/monthly/${branchId}`)
      setItems(safeArray<typeof items[0]>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [branchId, t])

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
          <Calendar className="h-6 w-6" />
          {t('monthlyClose.title')}
        </h1>
        <div className="no-print flex items-center gap-2">
          <button onClick={() => window.print()} className="form-button" title={t('common.print')}>
            <Printer className="h-4 w-4" /> {t('common.print')}
          </button>
          <button onClick={() => void loadData()} className="form-button p-2" title={t('common.refresh')}>
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="no-print flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder={t('common.searchPlaceholder')}
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
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.month')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.branch')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.status')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.closedAt')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.closedBy')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.loading')}</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.noData')}</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.yearMonth ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.branchName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.closedAt ? new Date(item.closedAt).toLocaleString('hu-HU') : '-'}</td>
                <td className="px-4 py-3 text-sm">{item.closedByName ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('common.total')}: {filtered.length} / {items.length}
      </div>
    </div>
  )
}
