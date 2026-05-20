import { useState, useCallback, useMemo } from 'react'
import { ShieldAlert, AlertTriangle, Search, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { navReportApi } from '../../services/api/index'
import type { NavReport } from '../../services/api/index'
import { localIsoDate } from '../../utils/dateFormat'
import { logger } from '../../utils/logger'
import { getErrorMessage, getBlobErrorMessage } from '../../utils/errorHandling'

/**
 * NAV adatszolgáltatás riport — a 2M+ Ft (NAV_THRESHOLD) feletti, jelenthető
 * tranzakciók listája egy napra. Csak SUPERVISOR/MANAGER/ADMIN (compliance).
 *
 * Backend: GET /api/v1/nav-reports/daily?date (JSON) + /csv?date (export).
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

export default function NavReportPage() {
  const { t } = useTranslation()

  const [date, setDate] = useState<string>(localIsoDate())
  const [report, setReport] = useState<NavReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [exporting, setExporting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleQuery = useCallback(async () => {
    if (!date) {
      setError(t('reports.navReport.errors.noDate'))
      return
    }
    setLoading(true)
    setError(null)
    try {
      const data = await navReportApi.getDaily(date)
      setReport(data)
    } catch (err) {
      logger.error('NavReportPage', 'Lekérdezés hiba:', err)
      setError(getErrorMessage(err))
      setReport(null)
    } finally {
      setLoading(false)
    }
  }, [date, t])

  const handleExportCsv = useCallback(async () => {
    if (!date) {
      setError(t('reports.navReport.errors.noDate'))
      return
    }
    setExporting(true)
    setError(null)
    try {
      const blob = await navReportApi.exportCsv(date)
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `nav_report_${date}.csv`
      document.body.appendChild(a)
      a.click()
      a.remove()
      URL.revokeObjectURL(url)
    } catch (err) {
      logger.error('NavReportPage', 'CSV export hiba:', err)
      setError(await getBlobErrorMessage(err))
    } finally {
      setExporting(false)
    }
  }, [date, t])

  const rows = useMemo(() => report?.transactions ?? [], [report])

  return (
    <div className="form-panel space-y-4">
      <div>
        <h1 className="form-title flex items-center gap-2">
          <ShieldAlert className="h-6 w-6" />
          {t('reports.navReport.title')}
        </h1>
        <p className="text-xs text-gray-500 mt-1">{t('reports.navReport.subtitle')}</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="nav-date">{t('reports.navReport.date')}</label>
          <input id="nav-date" type="date" value={date} onChange={(e) => setDate(e.target.value)} className="form-input w-full text-sm" />
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => void handleQuery()}
            disabled={loading}
            className="form-button-primary flex items-center gap-2"
          >
            <Search className="h-4 w-4" />
            {loading ? t('reports.navReport.loading') : t('reports.navReport.submit')}
          </button>
          <button
            type="button"
            onClick={() => void handleExportCsv()}
            disabled={exporting}
            className="form-button flex items-center gap-2"
          >
            <Download className="h-4 w-4" />
            {exporting ? t('reports.navReport.exporting') : t('reports.navReport.exportCsv')}
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.navReport.loading')}</div>
      )}

      {!loading && report && rows.length > 0 && (
        <>
          <div className="bg-white rounded shadow p-4 grid grid-cols-2 gap-3 text-sm">
            <div>
              <div className="text-gray-500 text-xs">{t('reports.navReport.summary.count')}</div>
              <div className="font-semibold">{report.reportableTransactionCount}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">{t('reports.navReport.summary.totalHuf')}</div>
              <div className="font-mono font-semibold text-green-700">{formatHuf(toNum(report.totalAmountHuf))}</div>
            </div>
          </div>

          <div className="bg-white rounded shadow overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.receipt')}</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.time')}</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.type')}</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.currency')}</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.amount')}</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.huf')}</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.customer')}</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.navReport.table.document')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {rows.map((r) => (
                  <tr key={r.transactionId} className="hover:bg-gray-50">
                    <td className="px-3 py-2 text-sm font-mono">{r.receiptNumber}</td>
                    <td className="px-3 py-2 text-sm font-mono">{r.transactionTime}</td>
                    <td className="px-3 py-2 text-sm">{r.transactionType}</td>
                    <td className="px-3 py-2 text-sm font-semibold">{r.currencyCode}</td>
                    <td className="px-3 py-2 text-right text-sm font-mono">{formatAmount(toNum(r.currencyAmount))}</td>
                    <td className="px-3 py-2 text-right text-sm font-mono">{formatHuf(toNum(r.hufAmount))}</td>
                    <td className="px-3 py-2 text-sm">{r.customerName ?? '-'}</td>
                    <td className="px-3 py-2 text-sm font-mono">{r.customerDocumentNumber ?? '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {!loading && report && rows.length === 0 && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.navReport.noResult')}</div>
      )}

      {!loading && !report && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.navReport.emptyState')}</div>
      )}
    </div>
  )
}
