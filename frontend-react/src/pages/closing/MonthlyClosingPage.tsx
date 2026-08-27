import { useState, useEffect, useCallback } from 'react'
import {
  Calendar,
  Search,
  RefreshCw,
  AlertTriangle,
  Printer,
  Download,
  CheckCircle,
  Eye,
} from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api, monthlyClosingApi, type MonthlyClosingSummary } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { downloadBlob } from '../../utils/downloadBlob'
import i18n from '../../i18n'

// FK-040 (2026-06-22): a HRK (horvát kuna) pénztár-bank készletmozgás 2025-01-01 óta
// nem forgalmazott — a havi zárásban sem számolni, sem nyilvántartani nem kell vele.
// A korábbi oldal feltétel nélkül, bedrótozva renderelte a "HRK havi készletmozgás" +
// "HRK napi napló" szekciókat (ez okozta a /hrk/journal 400-at is), ezért az AKTÍV
// értéktári havi zárásból kivezettük. A backend `/hrk/*` végpontok és a HrkTransaction
// entity SZÁNDÉKOSAN megmaradnak a sok éves történeti adat migrációja miatt — itt csak az
// elavult operatív UI tűnik el, a valós havi zárás (lent) változatlan.

interface MonthlyClosingSummaryItem {
  id: string | number
  yearMonth?: string
  branchName?: string
  status?: string
  closedAt?: string
  closedByName?: string
}

const currentYearMonth = (): string => new Date().toISOString().slice(0, 7)
const formatHuf = (value: number | string | null | undefined): string => {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed)
    ? `${parsed.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} Ft`
    : '-'
}
const formatDateTime = (value?: string | null): string =>
  value ? value.replace('T', ' ').slice(0, 16) : '-'

export default function MonthlyClosingPage() {
  const { t } = useTranslation()
  // 2026-04-29 B35 fix: a backend /closing/monthly endpoint csak {branchId}-os
  // GET-eket implemental, root-level lista nincs. A current worker branch-et
  // hasznaljuk a multi-tenant biztonsag tiszteletben tartasaval.
  const branchId = useAuthStore((state) => state.worker?.branchId)
  const [items, setItems] = useState<MonthlyClosingSummaryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedMonthlyReport, setSelectedMonthlyReport] = useState<MonthlyClosingSummary | null>(
    null,
  )
  const [monthlyReportLoadingKey, setMonthlyReportLoadingKey] = useState<string | null>(null)
  const [closingYearMonth, setClosingYearMonth] = useState(currentYearMonth)
  const [monthlyClosing, setMonthlyClosing] = useState(false)

  const loadData = useCallback(async () => {
    if (!branchId) {
      setError(t('monthlyClose.branchRequired'))
      setLoading(false)
      return
    }
    try {
      setLoading(true)
      setError(null)
      const data = await monthlyClosingApi.getAllClosedMonths(branchId)
      setItems(safeArray<(typeof items)[0]>(data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [branchId, t])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  const downloadMonthlyPdf = async (yearMonth?: string) => {
    if (!branchId || !yearMonth) return
    try {
      const response = await api.get<Blob>(`/closing/monthly/${branchId}/${yearMonth}/pdf`, {
        responseType: 'blob',
      })
      downloadBlob(response.data, `havi-zaras-${yearMonth}.pdf`)
    } catch (err) {
      const msg = await getBlobErrorMessage(err)
      logger.error('MonthlyClosingPage', 'PDF letöltési hiba:', err)
      setError(msg)
    }
  }

  const loadMonthlyReport = async (item: MonthlyClosingSummaryItem) => {
    if (!branchId || !item.yearMonth) return
    try {
      setMonthlyReportLoadingKey(String(item.id))
      setError(null)
      setSelectedMonthlyReport(await monthlyClosingApi.getReport(branchId, item.yearMonth))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'Havi zárás részletek betöltési hiba:', err)
      setError(msg)
    } finally {
      setMonthlyReportLoadingKey(null)
    }
  }

  const performMonthlyClosing = async () => {
    if (!branchId) {
      setError(t('monthlyClose.branchRequired'))
      return
    }
    if (!closingYearMonth) {
      setError('Havi záráshoz hónapot kell választani.')
      return
    }
    if (
      !window.confirm(`Biztosan végrehajtja a havi zárást erre a hónapra: ${closingYearMonth}?`)
    ) {
      return
    }

    try {
      setMonthlyClosing(true)
      setError(null)
      const summary = await monthlyClosingApi.performClosing(branchId, closingYearMonth)
      setSelectedMonthlyReport(summary)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'Havi zárás végrehajtási hiba:', err)
      setError(msg)
    } finally {
      setMonthlyClosing(false)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Calendar className="h-6 w-6" />
          {t('monthlyClose.title')}
        </h1>
        <div className="no-print flex items-center gap-2">
          <button onClick={() => window.print()} className="form-button" title={t('common.print')}>
            <Printer className="h-4 w-4" /> {t('common.print')}
          </button>
          <button
            onClick={() => void loadData()}
            className="form-button p-2"
            title={t('common.refresh')}
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="no-print flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder={t('common.searchPlaceholder')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      <section
        className="rounded-lg border border-amber-200 bg-amber-50 p-4"
        data-testid="monthly-closing-action-panel"
      >
        <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div>
            <h2 className="text-base font-bold text-amber-950">
              {i18n.t('literals.havi-zaras-vegrehajtasa')}
            </h2>
            <p className="mt-1 text-sm text-amber-900">
              {i18n.t('literals.a-kivalasztott-honapot-a-bejelentkezett')}
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end">
            <div>
              <label htmlFor="monthly-closing-year-month" className="form-label">
                {i18n.t('literals.zarando-honap')}
              </label>
              <input
                id="monthly-closing-year-month"
                type="month"
                value={closingYearMonth}
                onChange={(event) => setClosingYearMonth(event.target.value)}
                className="form-input bg-white"
              />
            </div>
            <button
              type="button"
              onClick={() => void performMonthlyClosing()}
              disabled={monthlyClosing || !branchId}
              className="form-button-primary inline-flex min-h-10 items-center gap-2"
            >
              <CheckCircle className="h-4 w-4" />
              {monthlyClosing ? 'Havi zárás...' : 'Havi zárás végrehajtása'}
            </button>
          </div>
        </div>
      </section>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {selectedMonthlyReport && (
        <section
          className="rounded-md border border-blue-200 bg-blue-50 p-4 text-sm text-blue-950"
          data-testid="monthly-closing-report-panel"
        >
          <div className="mb-3 flex flex-wrap items-start justify-between gap-2">
            <div>
              <h2 className="text-base font-bold">{selectedMonthlyReport.yearMonth}</h2>
              <div className="text-xs text-blue-700">
                {t('monthlyClose.branch')}
                {i18n.t('literals.lit-22')}
                {selectedMonthlyReport.branchName ?? branchId}
              </div>
            </div>
            <div className="rounded bg-white px-2 py-1 text-xs font-semibold text-blue-800">
              {selectedMonthlyReport.closedAt ? 'LEZÁRVA' : 'NYITOTT'}
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
            <div className="rounded bg-white p-2">
              <div className="text-xs text-blue-700">{t('monthlyClose.closedAt')}</div>
              <div className="font-semibold">{formatDateTime(selectedMonthlyReport.closedAt)}</div>
            </div>
            <div className="rounded bg-white p-2">
              <div className="text-xs text-blue-700">{t('monthlyClose.closedBy')}</div>
              <div className="font-semibold">
                {selectedMonthlyReport.closedByWorkerName ??
                  selectedMonthlyReport.closedByWorkerId ??
                  '-'}
              </div>
            </div>
            <div className="rounded bg-white p-2">
              <div className="text-xs text-blue-700">{i18n.t('literals.tranzakcio')}</div>
              <div className="font-semibold">{selectedMonthlyReport.transactionCount ?? 0}</div>
            </div>
            <div className="rounded bg-white p-2">
              <div className="text-xs text-blue-700">{i18n.t('literals.kezelesi-dij')}</div>
              <div className="font-semibold">
                {formatHuf(selectedMonthlyReport.totalHandlingFee)}
              </div>
            </div>
            <div className="rounded bg-white p-2">
              <div className="text-xs text-blue-700">{i18n.t('literals.vetel-huf')}</div>
              <div className="font-semibold">{formatHuf(selectedMonthlyReport.totalBuyHuf)}</div>
            </div>
            <div className="rounded bg-white p-2">
              <div className="text-xs text-blue-700">{i18n.t('literals.eladas-huf')}</div>
              <div className="font-semibold">{formatHuf(selectedMonthlyReport.totalSellHuf)}</div>
            </div>
            <div className="rounded bg-white p-2 md:col-span-2">
              <div className="text-xs text-blue-700">{i18n.t('literals.valuta-bontas')}</div>
              <div
                className="truncate font-mono text-xs"
                title={selectedMonthlyReport.currencyBreakdown ?? ''}
              >
                {selectedMonthlyReport.currencyBreakdown ?? '-'}
              </div>
            </div>
          </div>
        </section>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('monthlyClose.month')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('monthlyClose.branch')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('monthlyClose.status')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('monthlyClose.closedAt')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('monthlyClose.closedBy')}
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
                  {t('common.loading')}
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
                  <td className="px-4 py-3 text-sm">{item.yearMonth ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.branchName ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.closedAt ? new Date(item.closedAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.closedByName ?? '-'}</td>
                  <td className="px-4 py-3 text-right">
                    <button
                      type="button"
                      onClick={() => void loadMonthlyReport(item)}
                      disabled={!item.yearMonth || monthlyReportLoadingKey === String(item.id)}
                      className="form-button mr-2 inline-flex items-center gap-2 text-xs disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      <Eye
                        className={`h-4 w-4 ${monthlyReportLoadingKey === String(item.id) ? 'animate-pulse' : ''}`}
                      />
                      {i18n.t('literals.reszletek-2')}
                    </button>
                    <button
                      type="button"
                      onClick={() => void downloadMonthlyPdf(item.yearMonth)}
                      disabled={!item.yearMonth}
                      className="form-button inline-flex items-center gap-2 text-xs"
                    >
                      <Download className="h-4 w-4" />
                      {i18n.t('literals.pdf')}
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('common.total')}
        {i18n.t('literals.lit-22')}
        {filtered.length}
        {i18n.t('literals.lit-10')}
        {items.length}
      </div>
    </div>
  )
}
