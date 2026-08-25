import { useCallback, useEffect, useMemo, useState } from 'react'
import { AlertTriangle, Download, FileText, Search } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api, branchApi } from '../../services/api/index'
import type { BranchInfo } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { downloadBlob } from '../../utils/downloadBlob'

interface DailyRow {
  date: string
  bankCode?: string
  code?: string
  buyFee: number | string
  sellFee: number | string
}

interface DailySummary {
  startDate?: string
  endDate?: string
  totalBuyFee?: number | string
  totalSellFee?: number | string
  rows?: DailyRow[]
}

const ALL_BRANCHES = '__ALL__'

function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0
  const n = typeof v === 'string' ? Number(v) : v
  return Number.isNaN(n) ? 0 : n
}

function formatHuf(n: number): string {
  return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '\u00a0') + ' Ft'
}

function branchLabel(branch: BranchInfo): string {
  return branch.bankCode && branch.bankCode.trim() !== ''
    ? `${branch.code} – ${branch.bankCode} – ${branch.name}`
    : `${branch.code} – ${branch.name}`
}

export default function HandlingFeeDecadePage() {
  const { t } = useTranslation()
  const today = useMemo(() => new Date(), [])
  const monthStart = useMemo(() => {
    const date = new Date(today)
    date.setDate(1)
    return date
  }, [today])

  const [from, setFrom] = useState(localIsoDate(monthStart))
  const [to, setTo] = useState(localIsoDate(today))
  const [branchId, setBranchId] = useState('')
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [report, setReport] = useState<DailySummary | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadBranches = useCallback(async () => {
    try {
      const list = await branchApi.listActive()
      setBranches(list)
      setBranchId((current) => current || list[0]?.id || '')
    } catch (err) {
      logger.error('HandlingFeeDecadePage', 'Branch betöltés hiba:', err)
    }
  }, [])

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
      const params: Record<string, string> = { startDate: from, endDate: to }
      if (branchId !== ALL_BRANCHES) params.branchId = branchId
      const response = await api.get<DailySummary>('/handling-fees/daily-summary', {
        params,
      })
      setReport(response.data ?? null)
    } catch (err) {
      logger.error('HandlingFeeDecadePage', 'Lekérdezés hiba:', err)
      setError(getErrorMessage(err))
      setReport(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, from, t, to])

  const handleExportCsv = useCallback(async () => {
    if (!branchId || !from || !to) return

    setError(null)
    try {
      const params: Record<string, string> = { startDate: from, endDate: to }
      if (branchId !== ALL_BRANCHES) params.branchId = branchId
      const response = await api.get('/handling-fees/daily-summary/csv', {
        params,
        responseType: 'blob',
      })
      downloadBlob(
        response.data as BlobPart,
        `kezelesi-dij-napi-${from}-${to}.csv`,
        'text/csv; charset=UTF-8',
      )
    } catch (err) {
      logger.error('HandlingFeeDecadePage', 'CSV export hiba:', err)
      setError(await getBlobErrorMessage(err))
    }
  }, [branchId, from, to])

  const rows = report?.rows ?? []
  const totalBuyFee = Math.round(toNum(report?.totalBuyFee))
  const totalSellFee = Math.round(toNum(report?.totalSellFee))

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileText className="h-6 w-6" />
          {t('reports.handlingFeeDecade.title')}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="hf-from">
            {t('reports.handlingFeeDecade.from')}
          </label>
          <input
            id="hf-from"
            type="date"
            value={from}
            onChange={(event) => setFrom(event.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="hf-to">
            {t('reports.handlingFeeDecade.to')}
          </label>
          <input
            id="hf-to"
            type="date"
            value={to}
            onChange={(event) => setTo(event.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="hf-branch">
            {t('reports.handlingFeeDecade.branch')}
          </label>
          <select
            id="hf-branch"
            value={branchId}
            onChange={(event) => setBranchId(event.target.value)}
            className="form-input w-full text-sm"
          >
            <option value="">{t('reports.handlingFeeDecade.branchPlaceholder')}</option>
            <option value={ALL_BRANCHES}>{t('reports.handlingFeeDecade.allBranchesOption')}</option>
            {branches.map((branch) => (
              <option key={branch.id} value={branch.id}>
                {branchLabel(branch)}
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
            {loading
              ? t('reports.handlingFeeDecade.loading')
              : t('reports.handlingFeeDecade.submit')}
          </button>
          <button
            type="button"
            onClick={() => void handleExportCsv()}
            disabled={loading || !report || !branchId}
            className="form-button flex items-center gap-2"
            title={t('reports.handlingFeeDecade.csvTitle')}
          >
            <Download className="h-4 w-4" />
            CSV
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.handlingFeeDecade.loading')}
        </div>
      )}

      {!loading && report && (
        <div className="space-y-4">
          <div className="bg-white rounded shadow p-4 grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.handlingFeeDecade.summary.period')}
              </div>
              <div className="font-semibold">
                {report.startDate ?? from} - {report.endDate ?? to}
              </div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.handlingFeeDecade.summary.buyTotal')}
              </div>
              <div className="font-mono font-semibold">{formatHuf(totalBuyFee)}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.handlingFeeDecade.summary.sellTotal')}
              </div>
              <div className="font-mono font-semibold">{formatHuf(totalSellFee)}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.handlingFeeDecade.summary.grandTotal')}
              </div>
              <div className="font-mono font-semibold text-green-700">
                {formatHuf(totalBuyFee + totalSellFee)}
              </div>
            </div>
          </div>

          <div className="bg-white rounded shadow">
            <div className="bg-gray-50 px-4 py-2 border-b">
              <h2 className="font-semibold">{t('reports.handlingFeeDecade.dailyBreakdown')}</h2>
            </div>
            <div className="overflow-x-auto">
              <table className="data-grid min-w-full">
                <thead>
                  <tr>
                    <th>{t('reports.handlingFeeDecade.table.date')}</th>
                    <th>{t('reports.handlingFeeDecade.table.bankCode')}</th>
                    <th>{t('reports.handlingFeeDecade.table.branchCode')}</th>
                    <th className="text-right">{t('reports.handlingFeeDecade.table.buyFee')}</th>
                    <th className="text-right">{t('reports.handlingFeeDecade.table.sellFee')}</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.length === 0 && (
                    <tr>
                      <td colSpan={5} className="text-center text-gray-500">
                        {t('reports.handlingFeeDecade.table.noData')}
                      </td>
                    </tr>
                  )}
                  {rows.map((row) => (
                    <tr key={`${row.date}|${row.bankCode ?? ''}|${row.code ?? ''}`}>
                      <td>{new Date(row.date).toLocaleDateString('hu-HU')}</td>
                      <td>{row.bankCode ?? ''}</td>
                      <td>{row.code ?? ''}</td>
                      <td className="text-right font-mono whitespace-nowrap">
                        {formatHuf(Math.round(toNum(row.buyFee)))}
                      </td>
                      <td className="text-right font-mono whitespace-nowrap">
                        {formatHuf(Math.round(toNum(row.sellFee)))}
                      </td>
                    </tr>
                  ))}
                  <tr className="font-semibold">
                    <td>{t('reports.handlingFeeDecade.table.totalRow')}</td>
                    <td />
                    <td />
                    <td className="text-right font-mono whitespace-nowrap">
                      {formatHuf(totalBuyFee)}
                    </td>
                    <td className="text-right font-mono whitespace-nowrap">
                      {formatHuf(totalSellFee)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
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
