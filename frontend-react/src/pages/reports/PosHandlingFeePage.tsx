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
  netAmount: number | string
  feeAmount: number | string
}

interface DailySummary {
  startDate?: string
  endDate?: string
  totalNetAmount?: number | string
  totalFeeAmount?: number | string
  rows?: DailyRow[]
}

type QueryParams = Record<string, string> & {
  startDate: string
  endDate: string
  branchId?: string
}

const ALL_BRANCHES = '__ALL__'

function toNum(value: number | string | null | undefined): number {
  if (value == null) return 0
  const number = typeof value === 'string' ? Number(value) : value
  return Number.isNaN(number) ? 0 : number
}

function formatHuf(value: number): string {
  return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, '\u00a0') + ' Ft'
}

function branchLabel(branch: BranchInfo): string {
  return branch.bankCode && branch.bankCode.trim() !== ''
    ? `${branch.code} – ${branch.bankCode} – ${branch.name}`
    : `${branch.code} – ${branch.name}`
}

export default function PosHandlingFeePage() {
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
  const [lastQueryParams, setLastQueryParams] = useState<QueryParams | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadBranches = useCallback(async () => {
    try {
      const list = await branchApi.listActive()
      setBranches(list)
      setBranchId((current) => current || list[0]?.id || '')
    } catch (err) {
      logger.error('PosHandlingFeePage', 'Branch betöltés hiba:', err)
    }
  }, [])

  useEffect(() => {
    void loadBranches()
  }, [loadBranches])

  const handleQuery = useCallback(async () => {
    if (!branchId) {
      setError(t('reports.posHandlingFee.errors.noBranch'))
      return
    }
    if (!from || !to) {
      setError(t('reports.posHandlingFee.errors.noDateRange'))
      return
    }

    setLoading(true)
    setError(null)
    const params: QueryParams = { startDate: from, endDate: to }
    if (branchId !== ALL_BRANCHES) params.branchId = branchId
    try {
      const response = await api.get<DailySummary>('/handling-fees/pos-daily-summary', { params })
      setReport(response.data ?? null)
      setLastQueryParams(params)
    } catch (err) {
      logger.error('PosHandlingFeePage', 'Lekérdezés hiba:', err)
      setError(getErrorMessage(err))
      setReport(null)
      setLastQueryParams(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, from, t, to])

  const handleExportCsv = useCallback(async () => {
    if (!lastQueryParams) return

    setError(null)
    try {
      const response = await api.get('/handling-fees/pos-daily-summary/csv', {
        params: lastQueryParams,
        responseType: 'blob',
      })
      downloadBlob(
        response.data as BlobPart,
        `kezelesi-dij-pos-napi-${lastQueryParams.startDate}-${lastQueryParams.endDate}.csv`,
        'text/csv; charset=UTF-8',
      )
    } catch (err) {
      logger.error('PosHandlingFeePage', 'CSV export hiba:', err)
      setError(await getBlobErrorMessage(err))
    }
  }, [lastQueryParams])

  const rows = report?.rows ?? []
  const totalNetAmount = Math.round(toNum(report?.totalNetAmount))
  const totalFeeAmount = Math.round(toNum(report?.totalFeeAmount))

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileText className="h-6 w-6" />
          {t('reports.posHandlingFee.title')}
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
          <label className="block text-xs text-gray-500 mb-1" htmlFor="pos-hf-from">
            {t('reports.posHandlingFee.from')}
          </label>
          <input
            id="pos-hf-from"
            type="date"
            value={from}
            onChange={(event) => setFrom(event.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="pos-hf-to">
            {t('reports.posHandlingFee.to')}
          </label>
          <input
            id="pos-hf-to"
            type="date"
            value={to}
            onChange={(event) => setTo(event.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="pos-hf-branch">
            {t('reports.posHandlingFee.branch')}
          </label>
          <select
            id="pos-hf-branch"
            value={branchId}
            onChange={(event) => setBranchId(event.target.value)}
            className="form-input w-full text-sm"
          >
            <option value="">{t('reports.posHandlingFee.branchPlaceholder')}</option>
            <option value={ALL_BRANCHES}>{t('reports.posHandlingFee.allBranchesOption')}</option>
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
            {loading ? t('reports.posHandlingFee.loading') : t('reports.posHandlingFee.submit')}
          </button>
          <button
            type="button"
            onClick={() => void handleExportCsv()}
            disabled={loading || !report || !lastQueryParams}
            className="form-button flex items-center gap-2"
            title={t('reports.posHandlingFee.csvTitle')}
          >
            <Download className="h-4 w-4" />
            CSV
          </button>
        </div>
      </div>

      {loading && (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('reports.posHandlingFee.loading')}
        </div>
      )}

      {!loading && report && (
        <div className="space-y-4">
          <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.posHandlingFee.summary.period')}
              </div>
              <div className="font-semibold">
                {report.startDate ?? lastQueryParams?.startDate} -{' '}
                {report.endDate ?? lastQueryParams?.endDate}
              </div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.posHandlingFee.summary.netTotal')}
              </div>
              <div className="font-mono font-semibold">{formatHuf(totalNetAmount)}</div>
            </div>
            <div>
              <div className="text-gray-500 text-xs">
                {t('reports.posHandlingFee.summary.feeTotal')}
              </div>
              <div className="font-mono font-semibold">{formatHuf(totalFeeAmount)}</div>
            </div>
          </div>

          <div className="bg-white rounded shadow">
            <div className="bg-gray-50 px-4 py-2 border-b">
              <h2 className="font-semibold">{t('reports.posHandlingFee.dailyBreakdown')}</h2>
            </div>
            <div className="overflow-x-auto">
              <table className="data-grid min-w-full">
                <thead>
                  <tr>
                    <th>{t('reports.posHandlingFee.table.date')}</th>
                    <th>{t('reports.posHandlingFee.table.bankCode')}</th>
                    <th>{t('reports.posHandlingFee.table.branchCode')}</th>
                    <th className="text-right">{t('reports.posHandlingFee.table.netAmount')}</th>
                    <th className="text-right">{t('reports.posHandlingFee.table.feeAmount')}</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.length === 0 && (
                    <tr>
                      <td colSpan={5} className="text-center text-gray-500">
                        {t('reports.posHandlingFee.table.noData')}
                      </td>
                    </tr>
                  )}
                  {rows.map((row) => (
                    <tr key={`${row.date}|${row.bankCode ?? ''}|${row.code ?? ''}`}>
                      <td>{new Date(row.date).toLocaleDateString('hu-HU')}</td>
                      <td>{row.bankCode ?? ''}</td>
                      <td>{row.code ?? ''}</td>
                      <td className="text-right font-mono whitespace-nowrap">
                        {formatHuf(Math.round(toNum(row.netAmount)))}
                      </td>
                      <td className="text-right font-mono whitespace-nowrap">
                        {formatHuf(Math.round(toNum(row.feeAmount)))}
                      </td>
                    </tr>
                  ))}
                  <tr className="font-semibold">
                    <td>{t('reports.posHandlingFee.table.totalRow')}</td>
                    <td />
                    <td />
                    <td className="text-right font-mono whitespace-nowrap">
                      {formatHuf(totalNetAmount)}
                    </td>
                    <td className="text-right font-mono whitespace-nowrap">
                      {formatHuf(totalFeeAmount)}
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
          {t('reports.posHandlingFee.emptyState')}
        </div>
      )}
    </div>
  )
}
