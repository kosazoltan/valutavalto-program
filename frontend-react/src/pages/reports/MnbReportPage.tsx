import { useState, useEffect, useCallback } from 'react'
import {
  CalendarCheck,
  Download,
  FileText,
  Search,
  RefreshCw,
  AlertTriangle,
  Eye,
} from 'lucide-react'
import {
  mnbReportsApi,
  type MnbDailyReport,
  type MnbMonthlyReport,
  type MnbReport,
} from '../../services/api/mnbReports'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { downloadBlob } from '../../utils/downloadBlob'
import { safeArray } from '../../utils/safeArray'
import { asArray } from '../../utils/asArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

// Fix 2026-04-24 (Codex PR #183 P2): backend MnbReportDto tenyleges mezoi
// (NEM periodStart/periodEnd, hanem reportDate + egyeb)
// (Page<> interface-re nincs szukseg: interceptor unwrap-olja array-ra)

function todayIsoDate() {
  return new Date().toISOString().slice(0, 10)
}

function toMonth(date: string) {
  return date.slice(0, 7)
}

function formatNumber(value: number | undefined) {
  return typeof value === 'number' ? value.toLocaleString('hu-HU') : '-'
}

export default function MnbReportPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<MnbReport[]>([])
  const [selectedReport, setSelectedReport] = useState<MnbReport | null>(null)
  const [dailyReport, setDailyReport] = useState<MnbDailyReport | null>(null)
  const [monthlyReport, setMonthlyReport] = useState<MnbMonthlyReport | null>(null)
  const [validationMessages, setValidationMessages] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [summaryLoading, setSummaryLoading] = useState(false)
  const [dailyXmlLoading, setDailyXmlLoading] = useState(false)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [reportDate, setReportDate] = useState(todayIsoDate())

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      // Fix 2026-04-24: backend Page<MnbReportDto>, DE a client.ts interceptor
      // MAR auto-unwrappeli Page<T> -> T[] (`response.data` maga az array). AI review
      // (Codex PR #180 P1 interceptor figyelmeztetes).
      // AI review (Sourcery PR #186): magic konstans helyett megneves (silent truncation kockazat >100 rekord-nal)
      const MNB_REPORTS_PAGE_SIZE = 500
      const data = await mnbReportsApi.list({ size: MNB_REPORTS_PAGE_SIZE })
      setItems(safeArray<MnbReport>(asArray<MnbReport>(data)))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MnbReportPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const loadReadOnlySummary = useCallback(async () => {
    try {
      setSummaryLoading(true)
      setError(null)
      const [daily, monthly, validation] = await Promise.all([
        mnbReportsApi.getDaily(reportDate),
        mnbReportsApi.getMonthly(toMonth(reportDate)),
        mnbReportsApi.validate(reportDate),
      ])
      setDailyReport(daily)
      setMonthlyReport(monthly)
      setValidationMessages(validation)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MnbReportPage', 'MNB ellenőrzési adatok betöltési hiba:', err)
      setError(msg)
    } finally {
      setSummaryLoading(false)
    }
  }, [reportDate])

  const handleShowDetails = async (item: MnbReport) => {
    try {
      setDetailLoadingId(item.id)
      setError(null)
      const detailed = await mnbReportsApi.get(item.id)
      setSelectedReport(detailed)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MnbReportPage', 'MNB riport részlet betöltési hiba:', err)
      setError(msg)
    } finally {
      setDetailLoadingId(null)
    }
  }

  const handleDownloadDailyXml = async () => {
    try {
      setDailyXmlLoading(true)
      setError(null)
      const blob = await mnbReportsApi.downloadDailyXml(reportDate)
      downloadBlob(blob, `mnb_daily_${reportDate}.xml`)
    } catch (err) {
      const msg = await getBlobErrorMessage(err)
      logger.error('MnbReportPage', 'MNB napi XML letöltési hiba:', err)
      setError(msg)
    } finally {
      setDailyXmlLoading(false)
    }
  }

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileText className="h-6 w-6" />
          {t('mnb.mnbJelentesek')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Keresés..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
        <div className="rounded border border-gray-200 bg-white p-3">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end">
            <div className="flex-1">
              <label className="form-label" htmlFor="mnb-report-date">
                {i18n.t('literals.mnb-ellenorzesi-nap')}
              </label>
              <input
                id="mnb-report-date"
                type="date"
                value={reportDate}
                onChange={(e) => setReportDate(e.target.value)}
                className="form-input w-full"
              />
            </div>
            <button
              type="button"
              onClick={() => void loadReadOnlySummary()}
              disabled={summaryLoading}
              className="form-button justify-center"
            >
              <CalendarCheck className={`h-4 w-4 ${summaryLoading ? 'animate-spin' : ''}`} />
              {i18n.t('literals.read-only-ellenorzes')}
            </button>
            <button
              type="button"
              onClick={() => void handleDownloadDailyXml()}
              disabled={dailyXmlLoading}
              className="form-button justify-center"
            >
              <Download className={`h-4 w-4 ${dailyXmlLoading ? 'animate-pulse' : ''}`} />
              {i18n.t('literals.napi-xml')}
            </button>
          </div>
          <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-3">
            <div className="rounded border border-emerald-200 bg-emerald-50 p-3">
              <div className="text-xs text-emerald-700">{i18n.t('literals.napi-tranzakcio')}</div>
              <div className="text-xl font-semibold text-emerald-900">
                {formatNumber(dailyReport?.totalTransactions)}
              </div>
            </div>
            <div className="rounded border border-blue-200 bg-blue-50 p-3">
              <div className="text-xs text-blue-700">{i18n.t('literals.havi-tranzakcio')}</div>
              <div className="text-xl font-semibold text-blue-900">
                {formatNumber(monthlyReport?.totalTransactions)}
              </div>
            </div>
            <div className="rounded border border-amber-200 bg-amber-50 p-3">
              <div className="text-xs text-amber-700">{i18n.t('literals.validacios-uzenet')}</div>
              <div className="text-xl font-semibold text-amber-900">
                {validationMessages.length}
              </div>
            </div>
          </div>
          {validationMessages.length > 0 && (
            <ul className="mt-3 space-y-1 text-sm text-amber-800">
              {validationMessages.map((message) => (
                <li key={message}>{message}</li>
              ))}
            </ul>
          )}
        </div>

        <div className="rounded border border-gray-200 bg-white p-3">
          <div className="text-sm font-semibold text-gray-900">
            {i18n.t('literals.riport-reszlet')}
          </div>
          {selectedReport ? (
            <dl className="mt-3 grid grid-cols-2 gap-2 text-sm">
              <dt className="text-gray-500">{i18n.t('literals.tipus')}</dt>
              <dd className="font-medium text-gray-900">{selectedReport.reportType ?? '-'}</dd>
              <dt className="text-gray-500">{i18n.t('literals.datum-2')}</dt>
              <dd className="font-medium text-gray-900">{selectedReport.reportDate ?? '-'}</dd>
              <dt className="text-gray-500">{i18n.t('literals.vetel-huf')}</dt>
              <dd className="font-medium text-gray-900">
                {formatNumber(selectedReport.totalBuyHuf)}
              </dd>
              <dt className="text-gray-500">{i18n.t('literals.eladas-huf')}</dt>
              <dd className="font-medium text-gray-900">
                {formatNumber(selectedReport.totalSellHuf)}
              </dd>
              <dt className="text-gray-500">{i18n.t('literals.sorok')}</dt>
              <dd className="font-medium text-gray-900">{selectedReport.lines?.length ?? 0}</dd>
              <dt className="text-gray-500">{i18n.t('literals.elutasitas-oka')}</dt>
              <dd className="font-medium text-gray-900">{selectedReport.rejectionReason ?? '-'}</dd>
            </dl>
          ) : (
            <p className="mt-3 text-sm text-gray-500">
              {i18n.t('literals.valassz-riportot-a-listabol')}
            </p>
          )}
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
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.type')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('reports.riportDatum')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('reports.tranzakcioDb')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.status2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('darius.bekuldes')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('common.actions')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.reportType ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.reportDate ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.totalTransactions ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.submittedAt ? new Date(item.submittedAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-right text-sm">
                    <button
                      type="button"
                      onClick={() => void handleShowDetails(item)}
                      disabled={detailLoadingId === item.id}
                      className="form-button justify-center text-xs"
                    >
                      <Eye
                        className={`h-3.5 w-3.5 ${detailLoadingId === item.id ? 'animate-pulse' : ''}`}
                      />
                      {i18n.t('literals.reszletek-2')}
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}
        {filtered.length}
        {i18n.t('literals.lit-10')}
        {items.length}
      </div>
    </div>
  )
}
