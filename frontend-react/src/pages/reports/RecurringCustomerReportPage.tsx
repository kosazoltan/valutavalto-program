import { useState, useCallback, useMemo } from 'react'
import { Users, AlertTriangle, Search } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { recurringCustomerApi } from '../../services/api/index'
import type { RecurringCustomer } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * Visszatérő ügyfél monitoring riport (AML) — legacy ugyfelcontrol/idoszakos parity.
 *
 * Backend végpont: GET /api/v1/reports/recurring-customers?from&to&minTransactions
 * Pmt. 16. § fokozott ügyfél-átvilágítás (enhanced due diligence) jelölthöz.
 */

function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0
  const n = typeof v === 'string' ? Number(v) : v
  return Number.isNaN(n) ? 0 : n
}

function formatHuf(n: number): string {
  return n.toLocaleString('hu-HU') + ' Ft'
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

export default function RecurringCustomerReportPage() {
  const { t } = useTranslation()

  const today = useMemo(() => new Date(), [])
  const monthStart = useMemo(() => {
    const d = new Date(today)
    d.setDate(1)
    return d
  }, [today])

  const [from, setFrom] = useState<string>(isoDate(monthStart))
  const [to, setTo] = useState<string>(isoDate(today))
  const [minTransactions, setMinTransactions] = useState<number>(3)
  const [rows, setRows] = useState<RecurringCustomer[]>([])
  const [queried, setQueried] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleQuery = useCallback(async () => {
    if (!from || !to) {
      setError(t('reports.recurringCustomer.errors.noDateRange'))
      return
    }
    if (minTransactions < 2) {
      setError(t('reports.recurringCustomer.errors.minTooLow'))
      return
    }
    setLoading(true)
    setError(null)
    try {
      const data = await recurringCustomerApi.getRecurring(from, to, minTransactions)
      setRows(data ?? [])
      setQueried(true)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RecurringCustomerReportPage', 'Lekérdezés hiba:', err)
      setError(msg)
      setRows([])
      setQueried(true)
    } finally {
      setLoading(false)
    }
  }, [from, to, minTransactions, t])

  const totals = useMemo(() => {
    let totalTransactions = 0
    let totalHuf = 0
    for (const r of rows) {
      totalTransactions += toNum(r.transactionCount)
      totalHuf += toNum(r.totalHufAmount)
    }
    return { totalTransactions, totalHuf }
  }, [rows])

  return (
    <div className="form-panel space-y-4">
      <div>
        <h1 className="form-title flex items-center gap-2">
          <Users className="h-6 w-6" />
          {t('reports.recurringCustomer.title')}
        </h1>
        <p className="text-xs text-gray-500 mt-1">{t('reports.recurringCustomer.subtitle')}</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="rc-from">{t('reports.recurringCustomer.from')}</label>
          <input id="rc-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} className="form-input w-full text-sm" />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="rc-to">{t('reports.recurringCustomer.to')}</label>
          <input id="rc-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} className="form-input w-full text-sm" />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="rc-min">{t('reports.recurringCustomer.minTransactions')}</label>
          <input
            id="rc-min"
            type="number"
            min={2}
            value={minTransactions}
            onChange={(e) => setMinTransactions(Number(e.target.value))}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <button
            type="button"
            onClick={() => void handleQuery()}
            disabled={loading}
            className="form-button-primary flex items-center gap-2"
          >
            <Search className="h-4 w-4" />
            {loading ? t('reports.recurringCustomer.loading') : t('reports.recurringCustomer.submit')}
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.recurringCustomer.loading')}</div>
      )}

      {!loading && rows.length > 0 && (
        <>
          <div className="bg-white rounded shadow p-4 grid grid-cols-3 gap-3 text-sm">
            <div>
              <div className="text-gray-500 text-xs">{t('reports.recurringCustomer.summary.customers')}</div>
              <div className="font-semibold">{rows.length}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">{t('reports.recurringCustomer.summary.totalTransactions')}</div>
              <div className="font-semibold">{totals.totalTransactions}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">{t('reports.recurringCustomer.summary.totalHuf')}</div>
              <div className="font-mono font-semibold text-green-700">{formatHuf(totals.totalHuf)}</div>
            </div>
          </div>

          <div className="bg-white rounded shadow overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.recurringCustomer.table.customerId')}</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.recurringCustomer.table.customerName')}</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.recurringCustomer.table.transactionCount')}</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.recurringCustomer.table.totalHuf')}</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.recurringCustomer.table.period')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {rows.map((r) => (
                  <tr key={r.customerId} className="hover:bg-gray-50">
                    <td className="px-3 py-2 text-sm font-mono">{r.customerId}</td>
                    <td className="px-3 py-2 text-sm">{r.customerName}</td>
                    <td className="px-3 py-2 text-right text-sm font-mono font-semibold">{toNum(r.transactionCount)}</td>
                    <td className="px-3 py-2 text-right text-sm font-mono">{formatHuf(toNum(r.totalHufAmount))}</td>
                    <td className="px-3 py-2 text-xs font-mono text-gray-500">{r.periodStart} – {r.periodEnd}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {!loading && queried && rows.length === 0 && !error && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.recurringCustomer.noResult', { count: minTransactions })}
        </div>
      )}

      {!loading && !queried && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.recurringCustomer.emptyState')}
        </div>
      )}
    </div>
  )
}
