import { Fragment, useState, useEffect, useCallback, useMemo } from 'react'
import { Users, AlertTriangle, Search, ChevronDown, ChevronRight, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api, reportApi } from '../../services/api/index'
import type { WorkerMaster, WorkerPerformanceReport } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { downloadBlob } from '../../utils/downloadBlob'

/**
 * Pénztáros forgalmi riport — kiadott / eladott valuták worker bontásban.
 *
 * Backend végpont: GET /api/v1/reports/worker/{workerId}?startDate=...&endDate=...
 * A frontend az aktív workerek listáját lekéri, majd worker-filter szerint hívja a riportot.
 */

interface RowState {
  worker: WorkerMaster
  report: WorkerPerformanceReport | null
  error: string | null
}

function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0
  const n = typeof v === 'string' ? Number(v) : v
  return Number.isNaN(n) ? 0 : n
}

function formatHuf(n: number): string {
  return n.toLocaleString('hu-HU') + ' Ft'
}

function totalTransactionCount(report: WorkerPerformanceReport): number {
  return report.totalTransactionCount ?? report.totalTransactions ?? 0
}

function totalBuyCount(report: WorkerPerformanceReport): number {
  return report.totalBuyCount ?? report.buyTransactions ?? 0
}

function totalSellCount(report: WorkerPerformanceReport): number {
  return report.totalSellCount ?? report.sellTransactions ?? 0
}

export default function CashierTurnoverReportPage() {
  const { t } = useTranslation()

  const today = useMemo(() => new Date(), [])
  const monthStart = useMemo(() => {
    const d = new Date(today)
    d.setDate(1)
    return d
  }, [today])

  const [from, setFrom] = useState<string>(localIsoDate(monthStart))
  const [to, setTo] = useState<string>(localIsoDate(today))
  const [workerFilter, setWorkerFilter] = useState<number | ''>('')
  const [workers, setWorkers] = useState<WorkerMaster[]>([])
  const [rows, setRows] = useState<RowState[]>([])
  const [expanded, setExpanded] = useState<Set<number>>(new Set())
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadWorkers = useCallback(async () => {
    try {
      const response = await api.get<WorkerMaster[]>('/workers/active')
      setWorkers(response.data ?? [])
    } catch (err) {
      logger.error('CashierTurnoverReportPage', 'Worker betöltés hiba:', err)
    }
  }, [])

  useEffect(() => {
    void loadWorkers()
  }, [loadWorkers])

  const handleQuery = useCallback(async () => {
    if (!from || !to) {
      setError(t('reports.cashierTurnover.errors.noDateRange'))
      return
    }
    setLoading(true)
    setError(null)
    try {
      const targets: WorkerMaster[] =
        workerFilter === '' ? workers : workers.filter((w) => w.id === workerFilter)
      if (targets.length === 0) {
        setRows([])
        setError(t('reports.cashierTurnover.errors.noActiveCashier'))
        return
      }
      const results = await Promise.all(
        targets.map(async (w): Promise<RowState> => {
          try {
            const report = await reportApi.getWorkerPerformance(w.id, from, to)
            return { worker: w, report, error: null }
          } catch (err) {
            const msg = getErrorMessage(err)
            logger.error('CashierTurnoverReportPage', `worker ${w.id} report hiba:`, err)
            return { worker: w, report: null, error: msg }
          }
        }),
      )
      setRows(results)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('CashierTurnoverReportPage', 'Lekérdezés hiba:', err)
      setError(msg)
      setRows([])
    } finally {
      setLoading(false)
    }
  }, [from, to, workerFilter, workers, t])

  const totals = useMemo(() => {
    let totalTransactions = 0
    let buyCount = 0
    let sellCount = 0
    let totalBuyHuf = 0
    let totalSellHuf = 0
    let totalHandlingFees = 0
    for (const r of rows) {
      if (!r.report) continue
      totalTransactions += totalTransactionCount(r.report)
      buyCount += totalBuyCount(r.report)
      sellCount += totalSellCount(r.report)
      totalBuyHuf += toNum(r.report.totalBuyHuf)
      totalSellHuf += toNum(r.report.totalSellHuf)
      totalHandlingFees += toNum(r.report.totalHandlingFees)
    }
    return {
      totalTransactions,
      buyCount,
      sellCount,
      totalBuyHuf,
      totalSellHuf,
      totalHandlingFees,
      totalTurnoverHuf: totalBuyHuf + totalSellHuf,
    }
  }, [rows])

  const toggleExpand = (workerId: number) => {
    setExpanded((prev) => {
      const next = new Set(prev)
      if (next.has(workerId)) next.delete(workerId)
      else next.add(workerId)
      return next
    })
  }

  const handleDownloadCsv = useCallback(async () => {
    if (workerFilter === '') {
      setError(t('reports.cashierTurnover.errors.csvSelectOne'))
      return
    }
    setError(null)
    try {
      const r = await api.get(`/reports/worker/${workerFilter}/csv`, {
        params: { startDate: from, endDate: to },
        responseType: 'blob',
      })
      downloadBlob(
        r.data as BlobPart,
        `penztaros-teljesitmeny-${workerFilter}-${from}-${to}.csv`,
        'text/csv; charset=UTF-8',
      )
    } catch (err) {
      logger.error('CashierTurnoverReportPage', 'CSV export hiba:', err)
      setError(await getBlobErrorMessage(err))
    }
  }, [workerFilter, from, to, t])

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Users className="h-6 w-6" />
          {t('reports.cashierTurnover.title')}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-5 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ct-from">
            {t('reports.cashierTurnover.from')}
          </label>
          <input
            id="ct-from"
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ct-to">
            {t('reports.cashierTurnover.to')}
          </label>
          <input
            id="ct-to"
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div className="md:col-span-2">
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ct-worker">
            {t('reports.cashierTurnover.workerLabel')}
          </label>
          <select
            id="ct-worker"
            value={workerFilter === '' ? '' : String(workerFilter)}
            onChange={(e) => setWorkerFilter(e.target.value === '' ? '' : Number(e.target.value))}
            className="form-input w-full text-sm"
          >
            <option value="">
              {t('reports.cashierTurnover.workerAll', { count: workers.length })}
            </option>
            {workers.map((w) => (
              <option key={w.id} value={w.id}>
                {w.workerCode ?? w.id} - {w.fullName}
                {w.branchName ? ` (${w.branchName})` : ''}
              </option>
            ))}
          </select>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => void handleQuery()}
            disabled={loading || workers.length === 0}
            className="form-button-primary flex items-center gap-2"
          >
            <Search className="h-4 w-4" />
            {loading ? t('reports.cashierTurnover.loading') : t('reports.cashierTurnover.submit')}
          </button>
          <button
            type="button"
            onClick={() => void handleDownloadCsv()}
            disabled={loading || workerFilter === ''}
            className="form-button flex items-center gap-2"
            title="CSV — csak konkrét pénztárosra"
          >
            <Download className="h-4 w-4" />
            CSV
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.cashierTurnover.loading')}
        </div>
      )}

      {!loading && rows.length > 0 && (
        <>
          <div className="bg-white rounded shadow p-4 grid grid-cols-2 md:grid-cols-6 gap-3 text-sm">
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.cashierTurnover.summary.cashiers')}
              </div>
              <div className="font-semibold">{rows.length}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.cashierTurnover.summary.totalTransactions')}
              </div>
              <div className="font-semibold">{totals.totalTransactions}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.cashierTurnover.summary.buyCount')}
              </div>
              <div className="font-semibold">{totals.buyCount}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.cashierTurnover.summary.sellCount')}
              </div>
              <div className="font-semibold">{totals.sellCount}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.cashierTurnover.summary.handlingFee')}
              </div>
              <div className="font-mono font-semibold">{formatHuf(totals.totalHandlingFees)}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.cashierTurnover.summary.totalTurnover')}
              </div>
              <div className="font-mono font-semibold text-green-700">
                {formatHuf(totals.totalTurnoverHuf)}
              </div>
            </div>
          </div>

          <div className="bg-white rounded shadow">
            <div className="bg-gray-50 px-4 py-2 border-b">
              <h2 className="font-semibold">{t('reports.cashierTurnover.perWorkerBreakdown')}</h2>
            </div>
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 w-8"></th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {t('reports.cashierTurnover.table.cashier')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {t('reports.cashierTurnover.table.transactions')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {t('reports.cashierTurnover.table.buyHuf')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {t('reports.cashierTurnover.table.sellHuf')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {t('reports.cashierTurnover.table.turnoverHuf')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {t('reports.cashierTurnover.table.handlingFee')}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {rows.map((row) => {
                  const isOpen = expanded.has(row.worker.id)
                  return (
                    <Fragment key={row.worker.id}>
                      <tr key={`row-${row.worker.id}`} className="hover:bg-gray-50">
                        <td className="px-3 py-2">
                          <button
                            type="button"
                            onClick={() => toggleExpand(row.worker.id)}
                            className="text-gray-500 hover:text-gray-700"
                            aria-expanded={isOpen}
                            aria-label={
                              isOpen
                                ? t('reports.cashierTurnover.table.collapse')
                                : t('reports.cashierTurnover.table.expand')
                            }
                          >
                            {isOpen ? (
                              <ChevronDown className="h-4 w-4" />
                            ) : (
                              <ChevronRight className="h-4 w-4" />
                            )}
                          </button>
                        </td>
                        <td className="px-3 py-2 text-sm">
                          <div className="font-semibold">{row.worker.fullName}</div>
                          <div className="text-xs text-gray-500">
                            {row.worker.workerCode ?? '-'}
                            {row.worker.branchName ? ` · ${row.worker.branchName}` : ''}
                          </div>
                        </td>
                        <td className="px-3 py-2 text-right text-sm font-mono">
                          {row.report ? totalTransactionCount(row.report) : '-'}
                        </td>
                        <td className="px-3 py-2 text-right text-sm font-mono">
                          {row.report ? formatHuf(toNum(row.report.totalBuyHuf)) : '-'}
                        </td>
                        <td className="px-3 py-2 text-right text-sm font-mono">
                          {row.report ? formatHuf(toNum(row.report.totalSellHuf)) : '-'}
                        </td>
                        <td className="px-3 py-2 text-right text-sm font-mono font-semibold">
                          {row.report
                            ? formatHuf(
                                toNum(row.report.totalBuyHuf) + toNum(row.report.totalSellHuf),
                              )
                            : '-'}
                        </td>
                        <td className="px-3 py-2 text-right text-sm font-mono">
                          {row.report ? formatHuf(toNum(row.report.totalHandlingFees)) : '-'}
                        </td>
                      </tr>
                      {isOpen && (
                        <tr key={`detail-${row.worker.id}`}>
                          <td colSpan={7} className="px-6 py-3 bg-gray-50 text-xs">
                            {row.error ? (
                              <div className="text-red-700">
                                {t('reports.cashierTurnover.details.errorPrefix', {
                                  error: row.error,
                                })}
                              </div>
                            ) : row.report ? (
                              <>
                                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                                  <div>
                                    <div className="text-gray-500">
                                      {t('reports.cashierTurnover.details.buyCount')}
                                    </div>
                                    <div className="font-mono">{totalBuyCount(row.report)}</div>
                                  </div>
                                  <div>
                                    <div className="text-gray-500">
                                      {t('reports.cashierTurnover.details.sellCount')}
                                    </div>
                                    <div className="font-mono">{totalSellCount(row.report)}</div>
                                  </div>
                                  <div>
                                    <div className="text-gray-500">
                                      {t(
                                        'reports.cashierTurnover.details.averageDailyTransactions',
                                      )}
                                    </div>
                                    <div className="font-mono">
                                      {row.report.averageDailyTransactions?.toFixed(2) ?? '-'}
                                    </div>
                                  </div>
                                  <div>
                                    <div className="text-gray-500">
                                      {t('reports.cashierTurnover.details.period')}
                                    </div>
                                    <div className="font-mono">
                                      {row.report.startDate} - {row.report.endDate}
                                    </div>
                                  </div>
                                  <div>
                                    <div className="text-gray-500">
                                      {t('reports.cashierTurnover.details.averageTransactionValue')}
                                    </div>
                                    <div className="font-mono">
                                      {formatHuf(toNum(row.report.averageTransactionValue))}
                                    </div>
                                  </div>
                                </div>

                                <div className="mt-3 overflow-x-auto">
                                  <div className="font-semibold text-gray-700 mb-2">
                                    {t('reports.cashierTurnover.details.currencyBreakdown')}
                                  </div>
                                  <table className="min-w-full divide-y divide-gray-200 bg-white">
                                    <thead className="bg-gray-100">
                                      <tr>
                                        <th className="px-3 py-2 text-left font-medium text-gray-500">
                                          {t('reports.cashierTurnover.currencyTable.currency')}
                                        </th>
                                        <th className="px-3 py-2 text-right font-medium text-gray-500">
                                          {t('reports.cashierTurnover.currencyTable.buyCount')}
                                        </th>
                                        <th className="px-3 py-2 text-right font-medium text-gray-500">
                                          {t('reports.cashierTurnover.currencyTable.buyAmount')}
                                        </th>
                                        <th className="px-3 py-2 text-right font-medium text-gray-500">
                                          {t('reports.cashierTurnover.currencyTable.buyHuf')}
                                        </th>
                                        <th className="px-3 py-2 text-right font-medium text-gray-500">
                                          {t('reports.cashierTurnover.currencyTable.sellCount')}
                                        </th>
                                        <th className="px-3 py-2 text-right font-medium text-gray-500">
                                          {t('reports.cashierTurnover.currencyTable.sellAmount')}
                                        </th>
                                        <th className="px-3 py-2 text-right font-medium text-gray-500">
                                          {t('reports.cashierTurnover.currencyTable.sellHuf')}
                                        </th>
                                      </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-200">
                                      {(row.report.currencyTurnovers ?? []).length === 0 && (
                                        <tr>
                                          <td
                                            colSpan={7}
                                            className="px-3 py-3 text-center text-gray-500"
                                          >
                                            {t('reports.cashierTurnover.currencyTable.noData')}
                                          </td>
                                        </tr>
                                      )}
                                      {(row.report.currencyTurnovers ?? []).map((currency) => (
                                        <tr key={currency.currencyCode}>
                                          <td className="px-3 py-2 whitespace-nowrap">
                                            {currency.currencyCode} - {currency.currencyName}
                                          </td>
                                          <td className="px-3 py-2 text-right font-mono">
                                            {currency.buyCount}
                                          </td>
                                          <td className="px-3 py-2 text-right font-mono">
                                            {toNum(currency.buyAmount).toLocaleString('hu-HU')}
                                          </td>
                                          <td className="px-3 py-2 text-right font-mono whitespace-nowrap">
                                            {formatHuf(toNum(currency.buyHuf))}
                                          </td>
                                          <td className="px-3 py-2 text-right font-mono">
                                            {currency.sellCount}
                                          </td>
                                          <td className="px-3 py-2 text-right font-mono">
                                            {toNum(currency.sellAmount).toLocaleString('hu-HU')}
                                          </td>
                                          <td className="px-3 py-2 text-right font-mono whitespace-nowrap">
                                            {formatHuf(toNum(currency.sellHuf))}
                                          </td>
                                        </tr>
                                      ))}
                                    </tbody>
                                  </table>
                                </div>
                              </>
                            ) : (
                              <div className="text-gray-500">
                                {t('reports.cashierTurnover.details.noData')}
                              </div>
                            )}
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  )
                })}
                <tr className="bg-gray-100 font-semibold">
                  <td className="px-3 py-2"></td>
                  <td className="px-3 py-2 text-sm">{t('reports.cashierTurnover.table.total')}</td>
                  <td className="px-3 py-2 text-right text-sm font-mono">
                    {totals.totalTransactions}
                  </td>
                  <td className="px-3 py-2 text-right text-sm font-mono">
                    {formatHuf(totals.totalBuyHuf)}
                  </td>
                  <td className="px-3 py-2 text-right text-sm font-mono">
                    {formatHuf(totals.totalSellHuf)}
                  </td>
                  <td className="px-3 py-2 text-right text-sm font-mono text-green-700">
                    {formatHuf(totals.totalTurnoverHuf)}
                  </td>
                  <td className="px-3 py-2"></td>
                </tr>
              </tbody>
            </table>
          </div>
        </>
      )}

      {!loading && rows.length === 0 && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.cashierTurnover.emptyState')}
        </div>
      )}
    </div>
  )
}
