import { useState, useEffect, useCallback, useMemo } from 'react'
import { TrendingUp, AlertTriangle, Search } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { averageRateApi, currencyApi, branchApi } from '../../services/api/index'
import type { AverageRateReport, Currency, BranchInfo } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * Átlag árfolyam riport (legacy ATLAGARF parity) — súlyozott (HUF-súlyozott) átlagárfolyam
 * időszak + iroda + valuta + típus szerint.
 *
 * Backend végpont: GET /api/v1/reports/average-rate?from&to[&branchId][&currencyId][&transactionType]
 */

function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0
  const n = typeof v === 'string' ? Number(v) : v
  return Number.isNaN(n) ? 0 : n
}

function formatHuf(n: number): string {
  return n.toLocaleString('hu-HU') + ' Ft'
}

function formatAmount(n: number): string {
  return n.toLocaleString('hu-HU', { maximumFractionDigits: 2 })
}

function formatRate(n: number): string {
  return n.toLocaleString('hu-HU', { minimumFractionDigits: 4, maximumFractionDigits: 4 })
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

export default function AverageRateReportPage() {
  const { t } = useTranslation()

  const today = useMemo(() => new Date(), [])
  const monthStart = useMemo(() => {
    const d = new Date(today)
    d.setDate(1)
    return d
  }, [today])

  const [from, setFrom] = useState<string>(isoDate(monthStart))
  const [to, setTo] = useState<string>(isoDate(today))
  const [branchId, setBranchId] = useState<string>('')
  const [currencyId, setCurrencyId] = useState<string>('')
  const [transactionType, setTransactionType] = useState<string>('')
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [rows, setRows] = useState<AverageRateReport[]>([])
  const [queried, setQueried] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadFilters = useCallback(async () => {
    try {
      const [cur, br] = await Promise.all([currencyApi.getActive(), branchApi.listActive()])
      setCurrencies(cur ?? [])
      setBranches(br ?? [])
    } catch (err) {
      logger.error('AverageRateReportPage', 'Szűrő-listák betöltés hiba:', err)
    }
  }, [])

  useEffect(() => {
    void loadFilters()
  }, [loadFilters])

  const handleQuery = useCallback(async () => {
    if (!from || !to) {
      setError(t('reports.averageRate.errors.noDateRange'))
      return
    }
    setLoading(true)
    setError(null)
    try {
      const data = await averageRateApi.getReport(
        from,
        to,
        branchId || undefined,
        currencyId ? Number(currencyId) : undefined,
        transactionType || undefined,
      )
      setRows(data ?? [])
      setQueried(true)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('AverageRateReportPage', 'Lekérdezés hiba:', err)
      setError(msg)
      setRows([])
      setQueried(true)
    } finally {
      setLoading(false)
    }
  }, [from, to, branchId, currencyId, transactionType, t])

  const typeLabel = useCallback((type: string | null): string => {
    if (type === 'BUY') return t('reports.averageRate.typeBuy')
    if (type === 'SELL') return t('reports.averageRate.typeSell')
    return t('reports.averageRate.typeAll')
  }, [t])

  return (
    <div className="form-panel space-y-4">
      <div>
        <h1 className="form-title flex items-center gap-2">
          <TrendingUp className="h-6 w-6" />
          {t('reports.averageRate.title')}
        </h1>
        <p className="text-xs text-gray-500 mt-1">{t('reports.averageRate.subtitle')}</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-6 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-from">{t('reports.averageRate.from')}</label>
          <input id="ar-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} className="form-input w-full text-sm" />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-to">{t('reports.averageRate.to')}</label>
          <input id="ar-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} className="form-input w-full text-sm" />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-branch">{t('reports.averageRate.branch')}</label>
          <select id="ar-branch" value={branchId} onChange={(e) => setBranchId(e.target.value)} className="form-input w-full text-sm">
            <option value="">{t('reports.averageRate.branchAll')}</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>{b.code} - {b.name}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-currency">{t('reports.averageRate.currency')}</label>
          <select id="ar-currency" value={currencyId} onChange={(e) => setCurrencyId(e.target.value)} className="form-input w-full text-sm">
            <option value="">{t('reports.averageRate.currencyAll')}</option>
            {currencies.map((c) => (
              <option key={c.id} value={c.id}>{c.code}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-type">{t('reports.averageRate.type')}</label>
          <select id="ar-type" value={transactionType} onChange={(e) => setTransactionType(e.target.value)} className="form-input w-full text-sm">
            <option value="">{t('reports.averageRate.typeAll')}</option>
            <option value="BUY">{t('reports.averageRate.typeBuy')}</option>
            <option value="SELL">{t('reports.averageRate.typeSell')}</option>
          </select>
        </div>
        <div>
          <button
            type="button"
            onClick={() => void handleQuery()}
            disabled={loading}
            className="form-button-primary flex items-center gap-2"
          >
            <Search className="h-4 w-4" />
            {loading ? t('reports.averageRate.loading') : t('reports.averageRate.submit')}
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.averageRate.loading')}</div>
      )}

      {!loading && rows.length > 0 && (
        <div className="bg-white rounded shadow overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.averageRate.table.branch')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.averageRate.table.currency')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.averageRate.table.type')}</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.averageRate.table.transactionCount')}</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.averageRate.table.totalCurrency')}</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.averageRate.table.totalHuf')}</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.averageRate.table.weightedAverage')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {rows.map((r, idx) => (
                <tr key={`${r.currencyId}-${r.branchId ?? 'all'}-${r.transactionType ?? 'all'}-${idx}`} className="hover:bg-gray-50">
                  <td className="px-3 py-2 text-sm">{r.branchCode ?? t('reports.averageRate.branchAll')}</td>
                  <td className="px-3 py-2 text-sm font-semibold">{r.currencyCode}</td>
                  <td className="px-3 py-2 text-sm">{typeLabel(r.transactionType)}</td>
                  <td className="px-3 py-2 text-right text-sm font-mono">{toNum(r.transactionCount)}</td>
                  <td className="px-3 py-2 text-right text-sm font-mono">{formatAmount(toNum(r.totalCurrencyAmount))}</td>
                  <td className="px-3 py-2 text-right text-sm font-mono">{formatHuf(toNum(r.totalHufAmount))}</td>
                  <td className="px-3 py-2 text-right text-sm font-mono font-semibold text-green-700">{formatRate(toNum(r.weightedAverageRate))}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {!loading && queried && rows.length === 0 && !error && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.averageRate.noResult')}</div>
      )}

      {!loading && !queried && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.averageRate.emptyState')}</div>
      )}
    </div>
  )
}
