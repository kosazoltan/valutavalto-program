import { useState, useEffect, useCallback } from 'react'
import { Download, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'

/**
 * Fix #146 live UI test: a korabbi page a nemletezo GET /booking-export-ot
 * hivta (404). A backend 3 sub-endpointot exposol CSV letoltessel:
 *  - GET /api/v1/booking/daily?branchId=&date=
 *  - GET /api/v1/booking/monthly?branchId=&month=YYYY-MM
 *  - GET /api/v1/booking/inventory?branchId=&date=
 *
 * Ezert a page 3-gombos export launcher (branch+datum valaszto + letoltes).
 */

interface BranchDto {
  id: string
  code?: string
  name: string
}

export default function BookingExportPage() {
  const { t } = useTranslation()
  const workerBranchId = useAuthStore((s) => s.worker?.branchId ?? '')
  const [branches, setBranches] = useState<BranchDto[]>([])
  const [branchId, setBranchId] = useState<string>(workerBranchId)
  const [date, setDate] = useState<string>(() => localIsoDate())
  const [month, setMonth] = useState<string>(() => new Date().toISOString().slice(0, 7))
  const [busy, setBusy] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)

  const loadBranches = useCallback(async () => {
    try {
      const r = await api.get<BranchDto[]>('/branches')
      setBranches(Array.isArray(r.data) ? r.data : [])
      setBranchId((prev) => (prev ? prev : workerBranchId))
    } catch (err) {
      logger.warn('BookingExportPage', 'Branch load failed', err)
    }
  }, [workerBranchId])

  useEffect(() => {
    void loadBranches()
  }, [loadBranches])

  async function downloadCsv(
    path: '/booking/daily' | '/booking/monthly' | '/booking/inventory',
    params: Record<string, string>,
    filename: string,
  ) {
    if (!branchId) {
      setError('Valassz penztari egyseget (branch)')
      return
    }
    try {
      setBusy(path)
      setError(null)
      setInfo(null)
      const response =
        path === '/booking/daily'
          ? await api.get('/booking/daily', {
              params: { branchId, ...params },
              responseType: 'blob',
            })
          : path === '/booking/monthly'
            ? await api.get('/booking/monthly', {
                params: { branchId, ...params },
                responseType: 'blob',
              })
            : await api.get('/booking/inventory', {
                params: { branchId, ...params },
                responseType: 'blob',
              })
      const blob = new Blob([response.data as BlobPart], { type: 'text/csv;charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      a.remove()
      URL.revokeObjectURL(url)
      setInfo('Letoltes: ' + filename)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BookingExportPage', 'Export error: ' + path, err)
      setError(msg)
    } finally {
      setBusy(null)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Download className="h-6 w-6" />
          {t('export.konyvelesExportCsv')}
        </h1>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 bg-white rounded shadow p-4">
        <div>
          <label className="block text-xs text-gray-500 mb-1">{t('export.penztariEgyseg')}</label>
          <select
            value={branchId}
            onChange={(e) => setBranchId(e.target.value)}
            className="form-input w-full"
          >
            <option value="">{t('export.valassz')}</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name}
                {b.code ? ' (' + b.code + ')' : ''}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1">{t('export.datumNapiKeszlet')}</label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="form-input w-full"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1">{t('export.honapHavi')}</label>
          <input
            type="month"
            value={month}
            onChange={(e) => setMonth(e.target.value)}
            className="form-input w-full"
          />
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}
      {info && (
        <div className="bg-green-50 text-green-700 border border-green-200 rounded p-2 text-sm">
          {info}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <button
          onClick={() =>
            void downloadCsv('/booking/daily', { date }, 'konyveles-napi-' + date + '.csv')
          }
          disabled={busy !== null}
          className="form-button-primary flex items-center justify-center gap-2 py-4"
        >
          <Download className="h-5 w-5" />
          {t('export.napiExport')}
          {date})
        </button>
        <button
          onClick={() =>
            void downloadCsv('/booking/monthly', { month }, 'konyveles-havi-' + month + '.csv')
          }
          disabled={busy !== null}
          className="form-button-primary flex items-center justify-center gap-2 py-4"
        >
          <Download className="h-5 w-5" />
          {t('export.haviExport')}
          {month})
        </button>
        <button
          onClick={() =>
            void downloadCsv('/booking/inventory', { date }, 'keszlet-' + date + '.csv')
          }
          disabled={busy !== null}
          className="form-button-primary flex items-center justify-center gap-2 py-4"
        >
          <Download className="h-5 w-5" />
          {t('export.keszletExport')}
          {date})
        </button>
      </div>

      <div className="text-xs text-gray-500">
        {t('export.tippALetoltottCsvFajlKonvertalhatoExcelBeUtf8EncodingVagyKozvetlenul')}
        {t('export.beolvashatoAKonyvelesiRendszerbe')}
      </div>
    </div>
  )
}
