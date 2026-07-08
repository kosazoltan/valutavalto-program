import { useState, useCallback, useMemo } from 'react'
import { CheckCircle2, ShieldAlert, AlertTriangle, Search, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { navReportApi } from '../../services/api/index'
import type {
  NavClosing,
  NavClosingSummary,
  NavClosingValidationResult,
  NavReport,
  NavReportableTransaction,
} from '../../services/api/index'
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

function parseNavAmount(value: string): number | null {
  const trimmed = value.trim().replace(',', '.')
  if (!/^\d+(\.\d{1,2})?$/.test(trimmed)) return null
  const amount = Number(trimmed)
  return Number.isFinite(amount) && amount >= 0 ? amount : null
}

function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}

export default function NavReportPage() {
  const { t } = useTranslation()

  const [date, setDate] = useState<string>(localIsoDate())
  const [report, setReport] = useState<NavReport | null>(null)
  const [reportableTransactions, setReportableTransactions] = useState<NavReportableTransaction[]>(
    [],
  )
  const [closings, setClosings] = useState<NavClosing[]>([])
  const [closingSummary, setClosingSummary] = useState<NavClosingSummary | null>(null)
  const [loading, setLoading] = useState(false)
  const [exporting, setExporting] = useState(false)
  const [ptgszlahExporting, setPtgszlahExporting] = useState<'monthly' | 'custom' | null>(null)
  const [navAmounts, setNavAmounts] = useState<Record<string, string>>({})
  const [validationResults, setValidationResults] = useState<
    Record<string, NavClosingValidationResult>
  >({})
  const [justifications, setJustifications] = useState<Record<string, string>>({})
  const [validatingClosingId, setValidatingClosingId] = useState<string | null>(null)
  const [approvingClosingId, setApprovingClosingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const reloadClosings = useCallback(async () => {
    const navClosings = await navReportApi.listClosings({
      dateFrom: date,
      dateTo: date,
      page: 0,
      size: 10,
    })
    setClosings(navClosings)
    return navClosings
  }, [date])

  const handleQuery = useCallback(async () => {
    if (!date) {
      setError(t('reports.navReport.errors.noDate'))
      setReport(null)
      setReportableTransactions([])
      setClosings([])
      setClosingSummary(null)
      return
    }
    setLoading(true)
    setError(null)
    try {
      const [data, reportable, navClosings] = await Promise.all([
        navReportApi.getDaily(date),
        navReportApi.getReportable(date),
        navReportApi.listClosings({ dateFrom: date, dateTo: date, page: 0, size: 10 }),
      ])
      setReport(data)
      setReportableTransactions(reportable)
      setClosings(navClosings)
      setClosingSummary(null)
      setValidationResults({})
      setJustifications({})
    } catch (err) {
      logger.error('NavReportPage', 'Lekérdezés hiba:', err)
      setError(getErrorMessage(err))
      setReport(null)
      setReportableTransactions([])
      setClosings([])
      setClosingSummary(null)
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
      downloadBlob(blob, `nav_report_${date}.csv`)
    } catch (err) {
      logger.error('NavReportPage', 'CSV export hiba:', err)
      setError(await getBlobErrorMessage(err))
    } finally {
      setExporting(false)
    }
  }, [date, t])

  const handleClosingSummary = useCallback(async (id: string) => {
    try {
      setError(null)
      setClosingSummary(await navReportApi.getClosingSummary(id))
    } catch (err) {
      logger.error('NavReportPage', 'NAV zárás összesítő hiba:', err)
      setError(getErrorMessage(err))
      setClosingSummary(null)
    }
  }, [])

  const handleValidateAmount = useCallback(
    async (closing: NavClosing) => {
      if (!closing.branchId || !closing.closingDate) {
        setError(t('reports.navReport.discrepancy.errors.missingContext'))
        return
      }
      const navAmount = parseNavAmount(navAmounts[closing.id] ?? '')
      if (navAmount == null) {
        setError(t('reports.navReport.discrepancy.errors.invalidAmount'))
        return
      }

      setValidatingClosingId(closing.id)
      setError(null)
      try {
        const result = await navReportApi.validateNavAmount(
          closing.branchId,
          closing.closingDate,
          navAmount,
        )
        setValidationResults((previous) => ({ ...previous, [closing.id]: result }))
        setJustifications((previous) => ({ ...previous, [closing.id]: previous[closing.id] ?? '' }))
      } catch (err) {
        logger.error('NavReportPage', 'NAV záró összeg validáció hiba:', err)
        setError(getErrorMessage(err))
      } finally {
        setValidatingClosingId(null)
      }
    },
    [navAmounts, t],
  )

  const handleApproveDiscrepancy = useCallback(
    async (closing: NavClosing) => {
      const result = validationResults[closing.id]
      const navAmount = parseNavAmount(navAmounts[closing.id] ?? '')
      const justification = (justifications[closing.id] ?? '').trim()
      if (!result || result.isMatch || !result.closingId || navAmount == null) {
        setError(t('reports.navReport.discrepancy.errors.missingValidation'))
        return
      }
      if (justification.length < 20) {
        setError(t('reports.navReport.discrepancy.errors.shortJustification'))
        return
      }

      setApprovingClosingId(closing.id)
      setError(null)
      try {
        await navReportApi.approveDiscrepancy(result.closingId, navAmount, justification)
        await reloadClosings()
        setClosingSummary(await navReportApi.getClosingSummary(result.closingId))
        setValidationResults((previous) => {
          const next = { ...previous }
          delete next[closing.id]
          return next
        })
        setJustifications((previous) => ({ ...previous, [closing.id]: '' }))
      } catch (err) {
        logger.error('NavReportPage', 'NAV eltérés jóváhagyás hiba:', err)
        setError(getErrorMessage(err))
      } finally {
        setApprovingClosingId(null)
      }
    },
    [justifications, navAmounts, reloadClosings, t, validationResults],
  )

  const handleExportMonthlyPtgszlah = useCallback(async () => {
    if (!date) {
      setError(t('reports.navReport.errors.noDate'))
      return
    }
    const [yearText, monthText] = date.split('-')
    const year = Number(yearText)
    const month = Number(monthText)
    if (!Number.isInteger(year) || !Number.isInteger(month)) {
      setError(t('reports.navReport.errors.noDate'))
      return
    }
    setPtgszlahExporting('monthly')
    setError(null)
    try {
      const blob = await navReportApi.exportMonthlyPtgszlah(year, month)
      downloadBlob(blob, `PTGSZLAH_${year}_${String(month).padStart(2, '0')}.xml`)
    } catch (err) {
      logger.error('NavReportPage', 'PTGSZLAH havi XML export hiba:', err)
      setError(await getBlobErrorMessage(err))
    } finally {
      setPtgszlahExporting(null)
    }
  }, [date, t])

  const handleExportCustomPtgszlah = useCallback(async () => {
    if (!date) {
      setError(t('reports.navReport.errors.noDate'))
      return
    }
    setPtgszlahExporting('custom')
    setError(null)
    try {
      const blob = await navReportApi.exportCustomPtgszlah(date, date)
      downloadBlob(blob, `PTGSZLAH_${date}_${date}.xml`)
    } catch (err) {
      logger.error('NavReportPage', 'PTGSZLAH napi XML export hiba:', err)
      setError(await getBlobErrorMessage(err))
    } finally {
      setPtgszlahExporting(null)
    }
  }, [date, t])

  const rows = useMemo(() => reportableTransactions, [reportableTransactions])

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
          <label className="block text-xs text-gray-500 mb-1" htmlFor="nav-date">
            {t('reports.navReport.date')}
          </label>
          <input
            id="nav-date"
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="form-input w-full text-sm"
          />
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
        <div className="flex flex-wrap gap-2 md:col-span-3">
          <button
            type="button"
            onClick={() => void handleExportMonthlyPtgszlah()}
            disabled={ptgszlahExporting === 'monthly'}
            className="form-button flex items-center gap-2"
          >
            <Download className="h-4 w-4" />
            {ptgszlahExporting === 'monthly'
              ? t('reports.navReport.xmlExporting')
              : t('reports.navReport.ptgszlahMonthly')}
          </button>
          <button
            type="button"
            onClick={() => void handleExportCustomPtgszlah()}
            disabled={ptgszlahExporting === 'custom'}
            className="form-button flex items-center gap-2"
          >
            <Download className="h-4 w-4" />
            {ptgszlahExporting === 'custom'
              ? t('reports.navReport.xmlExporting')
              : t('reports.navReport.ptgszlahDaily')}
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.navReport.loading')}
        </div>
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
              <div className="font-mono font-semibold text-green-700">
                {formatHuf(toNum(report.totalAmountHuf))}
              </div>
            </div>
          </div>

          <div className="bg-white rounded shadow p-4 space-y-3" data-testid="nav-closing-panel">
            <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
              <h2 className="text-sm font-semibold text-gray-900">
                {t('reports.navReport.closings.title')}
              </h2>
              <span className="text-xs text-gray-500">
                {t('reports.navReport.closings.count', { count: closings.length })}
              </span>
            </div>
            {closings.length === 0 ? (
              <p className="rounded border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                {t('reports.navReport.closings.empty')}
              </p>
            ) : (
              <div className="grid gap-2 md:grid-cols-2">
                {closings.map((closing) => (
                  <div
                    key={closing.id}
                    className="rounded border border-gray-200 bg-gray-50 px-3 py-2"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <div className="break-words text-sm font-semibold text-gray-900">
                          {closing.closingDate}
                        </div>
                        <div className="mt-1 text-xs text-gray-600">
                          {t('reports.navReport.closings.revenue')}:{' '}
                          {formatHuf(toNum(closing.totalRevenue))}
                        </div>
                      </div>
                      <span className="shrink-0 rounded bg-white px-2 py-1 text-xs font-semibold text-gray-700">
                        {closing.status ?? '-'}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => void handleClosingSummary(closing.id)}
                      className="mt-2 min-h-9 rounded border border-gray-200 bg-white px-3 text-xs font-semibold text-gray-700"
                    >
                      {t('reports.navReport.closings.summaryButton')}
                    </button>
                    <div
                      className="mt-3 space-y-2 rounded border border-gray-200 bg-white p-3"
                      data-testid={`nav-discrepancy-${closing.id}`}
                    >
                      <div className="grid gap-2 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end">
                        <div>
                          <label
                            className="block text-xs font-medium text-gray-600"
                            htmlFor={`nav-amount-${closing.id}`}
                          >
                            {t('reports.navReport.discrepancy.navAmount')}
                          </label>
                          <input
                            id={`nav-amount-${closing.id}`}
                            type="number"
                            min="0"
                            step="0.01"
                            inputMode="decimal"
                            value={navAmounts[closing.id] ?? ''}
                            onChange={(event) =>
                              setNavAmounts((previous) => ({
                                ...previous,
                                [closing.id]: event.target.value,
                              }))
                            }
                            className="form-input mt-1 w-full text-sm"
                          />
                        </div>
                        <button
                          type="button"
                          onClick={() => void handleValidateAmount(closing)}
                          disabled={validatingClosingId === closing.id}
                          className="min-h-9 rounded bg-blue-600 px-3 text-xs font-semibold text-white disabled:opacity-50"
                        >
                          {validatingClosingId === closing.id
                            ? t('reports.navReport.discrepancy.validating')
                            : t('reports.navReport.discrepancy.validate')}
                        </button>
                      </div>
                      <div className="grid grid-cols-1 gap-1 text-xs text-gray-600 sm:grid-cols-2">
                        <div>
                          {t('reports.navReport.discrepancy.context.branch')}:{' '}
                          {closing.branchId ?? '-'}
                        </div>
                        <div>
                          {t('reports.navReport.discrepancy.context.date')}: {closing.closingDate}
                        </div>
                        <div className="sm:col-span-2 break-all">
                          {t('reports.navReport.discrepancy.context.closingId')}: {closing.id}
                        </div>
                      </div>
                      {validationResults[closing.id] && (
                        <div
                          className={`rounded border p-3 text-sm ${
                            validationResults[closing.id]!.isMatch
                              ? 'border-green-200 bg-green-50 text-green-900'
                              : 'border-red-200 bg-red-50 text-red-900'
                          }`}
                        >
                          <div className="flex items-center gap-2 font-semibold">
                            {validationResults[closing.id]!.isMatch ? (
                              <CheckCircle2 className="h-4 w-4" />
                            ) : (
                              <AlertTriangle className="h-4 w-4" />
                            )}
                            {validationResults[closing.id]!.isMatch
                              ? t('reports.navReport.discrepancy.match')
                              : t('reports.navReport.discrepancy.mismatch')}
                          </div>
                          <div className="mt-2 grid gap-1 sm:grid-cols-2">
                            <div>
                              {t('reports.navReport.discrepancy.context.branch')}:{' '}
                              {validationResults[closing.id]!.branchName ??
                                validationResults[closing.id]!.branchCode ??
                                '-'}
                            </div>
                            <div>
                              {t('reports.navReport.discrepancy.context.date')}:{' '}
                              {validationResults[closing.id]!.closingDate ?? '-'}
                            </div>
                            <div>
                              {t('reports.navReport.discrepancy.result.navAmount')}:{' '}
                              {formatHuf(toNum(validationResults[closing.id]!.navAmount))}
                            </div>
                            <div>
                              {t('reports.navReport.discrepancy.result.systemAmount')}:{' '}
                              {formatHuf(toNum(validationResults[closing.id]!.systemAmount))}
                            </div>
                            <div>
                              {t('reports.navReport.discrepancy.result.discrepancy')}:{' '}
                              {formatHuf(toNum(validationResults[closing.id]!.discrepancy))}
                            </div>
                            <div>
                              {t('reports.navReport.discrepancy.context.closingId')}:{' '}
                              {validationResults[closing.id]!.closingId}
                            </div>
                          </div>
                          {!validationResults[closing.id]!.isMatch && (
                            <div className="mt-3 space-y-2">
                              <label
                                className="block text-xs font-medium"
                                htmlFor={`nav-justification-${closing.id}`}
                              >
                                {t('reports.navReport.discrepancy.justification')}
                              </label>
                              <textarea
                                id={`nav-justification-${closing.id}`}
                                value={justifications[closing.id] ?? ''}
                                onChange={(event) =>
                                  setJustifications((previous) => ({
                                    ...previous,
                                    [closing.id]: event.target.value,
                                  }))
                                }
                                className="form-input min-h-20 w-full resize-y text-sm"
                              />
                              <button
                                type="button"
                                onClick={() => void handleApproveDiscrepancy(closing)}
                                disabled={
                                  approvingClosingId === closing.id ||
                                  (justifications[closing.id] ?? '').trim().length < 20
                                }
                                className="min-h-9 rounded bg-red-700 px-3 text-xs font-semibold text-white disabled:opacity-50"
                              >
                                {approvingClosingId === closing.id
                                  ? t('reports.navReport.discrepancy.approving')
                                  : t('reports.navReport.discrepancy.approve')}
                              </button>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
            {closingSummary && (
              <div className="grid grid-cols-2 gap-2 rounded border border-blue-200 bg-blue-50 p-3 text-sm">
                <div>
                  <div className="text-xs text-blue-700">
                    {t('reports.navReport.closings.summary.totalRevenue')}
                  </div>
                  <div className="font-mono font-semibold text-blue-950">
                    {formatHuf(toNum(closingSummary.totalRevenue))}
                  </div>
                </div>
                <div>
                  <div className="text-xs text-blue-700">
                    {t('reports.navReport.closings.summary.handlingFee')}
                  </div>
                  <div className="font-mono font-semibold text-blue-950">
                    {formatHuf(toNum(closingSummary.handlingFeeTotal))}
                  </div>
                </div>
                <div>
                  <div className="text-xs text-blue-700">
                    {t('reports.navReport.closings.summary.vat')}
                  </div>
                  <div className="font-mono font-semibold text-blue-950">
                    {formatHuf(toNum(closingSummary.vatAmount))}
                  </div>
                </div>
                <div>
                  <div className="text-xs text-blue-700">
                    {t('reports.navReport.closings.summary.transactions')}
                  </div>
                  <div className="font-semibold text-blue-950">
                    {toNum(closingSummary.transactionCount)}
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className="bg-white rounded shadow overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.receipt')}
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.time')}
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.type')}
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.currency')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.amount')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.huf')}
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.customer')}
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {t('reports.navReport.table.document')}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {rows.map((r) => (
                  <tr key={r.transactionId} className="hover:bg-gray-50">
                    <td className="px-3 py-2 text-sm font-mono">{r.receiptNumber}</td>
                    <td className="px-3 py-2 text-sm font-mono">{r.transactionTime}</td>
                    <td className="px-3 py-2 text-sm">{r.transactionType}</td>
                    <td className="px-3 py-2 text-sm font-semibold">{r.currencyCode}</td>
                    <td className="px-3 py-2 text-right text-sm font-mono">
                      {formatAmount(toNum(r.currencyAmount))}
                    </td>
                    <td className="px-3 py-2 text-right text-sm font-mono">
                      {formatHuf(toNum(r.hufAmount))}
                    </td>
                    <td className="px-3 py-2 text-sm">{r.customerName ?? '-'}</td>
                    <td className="px-3 py-2 text-sm font-mono">
                      {r.customerDocumentNumber ?? '-'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {!loading && report && rows.length === 0 && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.navReport.noResult')}
        </div>
      )}

      {!loading && !report && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.navReport.emptyState')}
        </div>
      )}
    </div>
  )
}
