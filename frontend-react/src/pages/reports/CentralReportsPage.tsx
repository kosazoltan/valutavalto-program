import { useState, useCallback } from 'react'
import { Building2, AlertTriangle, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { centralReportApi } from '../../services/api/index'
import { localIsoDate } from '../../utils/dateFormat'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage } from '../../utils/errorHandling'

/**
 * Központi konszolidált riportok (napi / heti / havi CSV) — cég-szintű összesítő.
 *
 * Backend: GET /api/v1/central-reports/{daily?date | weekly?weekStart | monthly?month}
 * → text/csv. Csak MANAGER/ADMIN. A backend a jelenlegi cégre szűr (company-scope).
 */

type CentralReportType = 'daily' | 'weekly' | 'monthly'

/** YYYY-MM (aktuális hónap) a havi riport input alapértékéhez. */
function currentMonth(): string {
  return localIsoDate().slice(0, 7)
}

export default function CentralReportsPage() {
  const { t } = useTranslation()

  const [reportType, setReportType] = useState<CentralReportType>('daily')
  const [day, setDay] = useState<string>(localIsoDate())
  const [weekStart, setWeekStart] = useState<string>(localIsoDate())
  const [month, setMonth] = useState<string>(currentMonth())
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleDownload = useCallback(async () => {
    const period = reportType === 'daily' ? day : reportType === 'weekly' ? weekStart : month
    if (!period) {
      setError(t('reports.centralReports.errors.noDate'))
      return
    }
    setLoading(true)
    setError(null)
    try {
      let blob: Blob
      let filename: string
      if (reportType === 'daily') {
        blob = await centralReportApi.daily(day)
        filename = `napi_riport_${day}.csv`
      } else if (reportType === 'weekly') {
        blob = await centralReportApi.weekly(weekStart)
        filename = `heti_riport_${weekStart}.csv`
      } else {
        blob = await centralReportApi.monthly(month)
        filename = `havi_riport_${month}.csv`
      }
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      a.remove()
      URL.revokeObjectURL(url)
    } catch (err) {
      logger.error('CentralReportsPage', 'CSV letöltés hiba:', err)
      setError(await getBlobErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [reportType, day, weekStart, month, t])

  return (
    <div className="form-panel space-y-4">
      <div>
        <h1 className="form-title flex items-center gap-2">
          <Building2 className="h-6 w-6" />
          {t('reports.centralReports.title')}
        </h1>
        <p className="text-xs text-gray-500 mt-1">{t('reports.centralReports.subtitle')}</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="cr-type">
            {t('reports.centralReports.reportType')}
          </label>
          <select
            id="cr-type"
            value={reportType}
            onChange={(e) => setReportType(e.target.value as CentralReportType)}
            className="form-input w-full text-sm"
          >
            <option value="daily">{t('reports.centralReports.typeDaily')}</option>
            <option value="weekly">{t('reports.centralReports.typeWeekly')}</option>
            <option value="monthly">{t('reports.centralReports.typeMonthly')}</option>
          </select>
        </div>

        {reportType === 'daily' && (
          <div>
            <label className="block text-xs text-gray-500 mb-1" htmlFor="cr-day">
              {t('reports.centralReports.date')}
            </label>
            <input
              id="cr-day"
              type="date"
              value={day}
              onChange={(e) => setDay(e.target.value)}
              className="form-input w-full text-sm"
            />
          </div>
        )}
        {reportType === 'weekly' && (
          <div>
            <label className="block text-xs text-gray-500 mb-1" htmlFor="cr-week">
              {t('reports.centralReports.weekStart')}
            </label>
            <input
              id="cr-week"
              type="date"
              value={weekStart}
              onChange={(e) => setWeekStart(e.target.value)}
              className="form-input w-full text-sm"
            />
          </div>
        )}
        {reportType === 'monthly' && (
          <div>
            <label className="block text-xs text-gray-500 mb-1" htmlFor="cr-month">
              {t('reports.centralReports.month')}
            </label>
            <input
              id="cr-month"
              type="month"
              value={month}
              onChange={(e) => setMonth(e.target.value)}
              className="form-input w-full text-sm"
            />
          </div>
        )}

        <div>
          <button
            type="button"
            onClick={() => void handleDownload()}
            disabled={loading}
            className="form-button-primary flex items-center gap-2"
          >
            <Download className="h-4 w-4" />
            {loading
              ? t('reports.centralReports.downloading')
              : t('reports.centralReports.download')}
          </button>
        </div>
      </div>

      <div className="text-center text-sm text-gray-500 py-6">
        {t('reports.centralReports.hint')}
      </div>
    </div>
  )
}
