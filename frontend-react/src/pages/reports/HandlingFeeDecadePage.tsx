import { useState, useEffect, useCallback, useMemo } from 'react'
import { FileText, AlertTriangle, Search, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api, branchApi } from '../../services/api/index'
import type { BranchInfo } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * Kezelési díj dekád riport.
 *
 * Backend: GET /api/v1/handling-fees/report?branchId={uuid}&from={ISO date}&to={ISO date}
 *
 * A backend HandlingFeeReportDto egy összesített riportot ad vissza (totalGrossFee,
 * totalDiscount, totalNetFee, totalCommissionShare, transactionCount, items[]).
 * A "dekád × valuta × kezelési díj cash/card bontás" jelenleg NEM elérhető a
 * backenden — ezért a frontend a tranzakció-listát maga csoportosítja dekádra.
 *
 * A "készpénz / bankkártya" bontást a tranzakcióhoz tartozó payment method
 * tárolása teszi lehetővé, ami a HandlingFeeTransactionDto-ban jelenleg NINCS jelen.
 * TODO(backend): paymentMethod mező hozzáadása HandlingFeeTransactionDto-hoz, vagy
 * dedikált aggregátor endpoint (GET /api/v1/handling-fees/decade-report).
 */

interface HandlingFeeTxn {
  id?: string
  transactionId?: number | null
  feeType?: string | null
  amount?: number | string | null
  discountPercent?: number | null
  discountReason?: string | null
  netFee?: number | string | null
  workerCommissionShare?: number | string | null
  createdAt?: string | null
}

interface HandlingFeeReport {
  dateFrom?: string
  dateTo?: string
  totalGrossFee?: number | string
  totalDiscount?: number | string
  totalNetFee?: number | string
  totalCommissionShare?: number | string
  transactionCount?: number
  items?: HandlingFeeTxn[]
}

interface DecadeRow {
  decadeKey: string
  decadeLabel: string
  count: number
  grossFee: number
  netFee: number
  discount: number
}

function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0
  const n = typeof v === 'string' ? Number(v) : v
  return Number.isNaN(n) ? 0 : n
}

function formatHuf(n: number): string {
  return n.toLocaleString('hu-HU') + ' Ft'
}

function decadeOf(dateIso: string): { key: string; label: string } {
  const d = new Date(dateIso)
  const y = d.getFullYear()
  const m = d.getMonth() + 1
  const day = d.getDate()
  const dec = day <= 10 ? 1 : day <= 20 ? 2 : 3
  const range = dec === 1 ? '1-10.' : dec === 2 ? '11-20.' : '21-vége'
  const key = `${y}-${String(m).padStart(2, '0')}-${dec}`
  const label = `${y}. ${String(m).padStart(2, '0')}. hó / ${dec}. dekád (${range})`
  return { key, label }
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

export default function HandlingFeeDecadePage() {
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
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [report, setReport] = useState<HandlingFeeReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadBranches = useCallback(async () => {
    try {
      const list = await branchApi.listActive()
      setBranches(list)
      if (list.length > 0 && !branchId) {
        const first = list[0]
        if (first) setBranchId(first.id)
      }
    } catch (err) {
      logger.error('HandlingFeeDecadePage', 'Branch betöltés hiba:', err)
    }
  }, [branchId])

  useEffect(() => {
    void loadBranches()
  }, [loadBranches])

  const handleQuery = useCallback(async () => {
    if (!branchId) {
      setError(t('reports.handlingFeeDecade.errors.noBranch'))
      return
    }
    if (!from || !to) {
      setError(t('reports.handlingFeeDecade.errors.noDateRange'))
      return
    }
    setLoading(true)
    setError(null)
    try {
      const response = await api.get<HandlingFeeReport>('/handling-fees/report', {
        params: { branchId, from, to },
      })
      setReport(response.data ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('HandlingFeeDecadePage', 'Lekérdezés hiba:', err)
      setError(msg)
      setReport(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, from, to, t])

  const decadeRows: DecadeRow[] = useMemo(() => {
    if (!report?.items) return []
    const map = new Map<string, DecadeRow>()
    for (const item of report.items) {
      if (!item.createdAt) continue
      const d = decadeOf(item.createdAt)
      const existing = map.get(d.key)
      const gross = toNum(item.amount)
      const net = toNum(item.netFee)
      const discount = item.discountPercent ? gross - net : 0
      if (existing) {
        existing.count += 1
        existing.grossFee += gross
        existing.netFee += net
        existing.discount += discount
      } else {
        map.set(d.key, {
          decadeKey: d.key,
          decadeLabel: d.label,
          count: 1,
          grossFee: gross,
          netFee: net,
          discount,
        })
      }
    }
    return Array.from(map.values()).sort((a, b) => a.decadeKey.localeCompare(b.decadeKey))
  }, [report])

  const handleExportCsv = useCallback(async () => {
    if (!from || !to) return
    setError(null)
    try {
      // A ReportController biztosit /reports/handling-fees/csv endpointot
      const r = await api.get('/reports/handling-fees/csv', {
        params: { startDate: from, endDate: to },
        responseType: 'blob',
      })
      const blob = new Blob([r.data as BlobPart], { type: 'text/csv; charset=UTF-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `kezelesi-dij-${from}-${to}.csv`
      document.body.appendChild(a)
      a.click()
      a.remove()
      URL.revokeObjectURL(url)
    } catch (err) {
      logger.error('HandlingFeeDecadePage', 'CSV export hiba:', err)
      setError(getErrorMessage(err))
    }
  }, [from, to])

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileText className="h-6 w-6" />
          {t('reports.handlingFeeDecade.title')}
        </h1>
      </div>

      <div className="bg-yellow-50 border border-yellow-200 rounded p-2 text-yellow-800 text-xs flex items-start gap-2">
        <AlertTriangle className="h-4 w-4 flex-shrink-0 mt-0.5" />
        <span>{t('reports.handlingFeeDecade.warning')}</span>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="hf-from">{t('reports.handlingFeeDecade.from')}</label>
          <input
            id="hf-from"
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="hf-to">{t('reports.handlingFeeDecade.to')}</label>
          <input
            id="hf-to"
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="hf-branch">{t('reports.handlingFeeDecade.branch')}</label>
          <select
            id="hf-branch"
            value={branchId}
            onChange={(e) => setBranchId(e.target.value)}
            className="form-input w-full text-sm"
          >
            <option value="">{t('reports.handlingFeeDecade.branchPlaceholder')}</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.code} - {b.name}
              </option>
            ))}
          </select>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => void handleQuery()}
            disabled={loading || !branchId}
            className="form-button-primary flex items-center gap-2"
          >
            <Search className="h-4 w-4" />
            {loading ? t('reports.handlingFeeDecade.loading') : t('reports.handlingFeeDecade.submit')}
          </button>
          <button
            type="button"
            onClick={() => void handleExportCsv()}
            disabled={loading || !report}
            className="form-button flex items-center gap-2"
            title="CSV export (időszaki, iroda-független)"
          >
            <Download className="h-4 w-4" />
            CSV
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">{t('reports.handlingFeeDecade.loading')}</div>
      )}

      {!loading && report && (
        <div className="space-y-4">
          <div className="bg-white rounded shadow p-4 grid grid-cols-2 md:grid-cols-5 gap-3 text-sm">
            <div>
              <div className="text-gray-500 text-xs">{t('reports.handlingFeeDecade.summary.period')}</div>
              <div className="font-semibold">
                {report.dateFrom} - {report.dateTo}
              </div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">{t('reports.handlingFeeDecade.summary.transactions')}</div>
              <div className="font-semibold">{report.transactionCount ?? 0}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">{t('reports.handlingFeeDecade.summary.grossFee')}</div>
              <div className="font-mono font-semibold">{formatHuf(toNum(report.totalGrossFee))}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">{t('reports.handlingFeeDecade.summary.discount')}</div>
              <div className="font-mono font-semibold">{formatHuf(toNum(report.totalDiscount))}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">{t('reports.handlingFeeDecade.summary.netFee')}</div>
              <div className="font-mono font-semibold text-green-700">
                {formatHuf(toNum(report.totalNetFee))}
              </div>
            </div>
          </div>

          <div className="bg-white rounded shadow">
            <div className="bg-gray-50 px-4 py-2 border-b">
              <h2 className="font-semibold">{t('reports.handlingFeeDecade.decadeBreakdown')}</h2>
            </div>
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.handlingFeeDecade.table.decade')}</th>
                  <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.handlingFeeDecade.table.transactions')}</th>
                  <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.handlingFeeDecade.table.grossFee')}</th>
                  <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.handlingFeeDecade.table.discount')}</th>
                  <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.handlingFeeDecade.table.netFee')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {decadeRows.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-4 text-center text-sm text-gray-500">
                      {t('reports.handlingFeeDecade.table.noData')}
                    </td>
                  </tr>
                )}
                {decadeRows.map((r) => (
                  <tr key={r.decadeKey} className="hover:bg-gray-50">
                    <td className="px-4 py-2 text-sm">{r.decadeLabel}</td>
                    <td className="px-4 py-2 text-right text-sm font-mono">{r.count}</td>
                    <td className="px-4 py-2 text-right text-sm font-mono">{formatHuf(r.grossFee)}</td>
                    <td className="px-4 py-2 text-right text-sm font-mono">{formatHuf(r.discount)}</td>
                    <td className="px-4 py-2 text-right text-sm font-mono font-semibold text-green-700">
                      {formatHuf(r.netFee)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {!loading && !report && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.handlingFeeDecade.emptyState')}
        </div>
      )}
    </div>
  )
}
