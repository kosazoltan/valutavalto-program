import { useState, useEffect, useCallback } from 'react'
import { Clock, Search, RefreshCw, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'

interface RateHistoryItem {
  id: string | number
  currencyCode?: string
  buyRate?: string
  sellRate?: string
  validFrom?: string
  createdByName?: string
}

export default function RateHistoryPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<RateHistoryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')

  // Fix 2026-04-24 (Issue #184): default utolso 30 nap + from/to parameter
  // A backend uj opcionalis currency paramot tamogat, ha nincs -> minden valuta
  // AI review fix (Sourcery + Codex PR #185 P2): local date komponenseket hasznaljuk,
  // NEM toISOString() (UTC-t adna, es CET/CEST este off-by-one hiba lehet)
  const formatLocalDate = (d: Date): string => {
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const today = new Date()
      const defaultFrom = new Date(today)
      defaultFrom.setDate(today.getDate() - 30)
      const fromStr = dateFrom || formatLocalDate(defaultFrom)
      const toStr = dateTo || formatLocalDate(today)
      const response = await api.get<RateHistoryItem[]>('/rate-history', {
        params: { from: fromStr, to: toStr }
      })
      setItems(safeArray<typeof items[0]>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateHistoryPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [dateFrom, dateTo])

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
          <Clock className="h-6 w-6" />
          {t('rates.arfolyamTortenelem')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2">
          <div className="flex gap-2">
            <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
              className="form-input px-2 py-1" />
            <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
              className="form-input px-2 py-1" />
          </div>
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
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('common.currency')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('rates.veteliArf')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('rates.eladasiArf')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('rates.ervenyes')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('rates.modositotta')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.noData')}</td></tr>
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
        {t('audit.osszesen')}{filtered.length} / {items.length}
      </div>
    </div>
  )
}
