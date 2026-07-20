import { useState, useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import { BookOpen, Printer, Calendar, RefreshCw } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { useAuthStore } from '../../stores/authStore'
import { dailyReportApi } from '../../services/api/index'
import { useTranslation } from 'react-i18next'

interface DaybookRow {
  annualSequence?: number
  receiptNumber: string
  timestamp: string
  atadasHuf?: number
  atvetelHuf?: number
  storno: boolean
}

interface DaybookData {
  branchId: string
  branchName: string
  date: string
  rows: DaybookRow[]
  totalAtadasHuf: number
  totalAtvetelHuf: number
}

export default function DaybookPage() {
  const { t } = useTranslation()
  const [searchParams] = useSearchParams()
  const worker = useAuthStore((state) => state.worker)
  const branchId = searchParams.get('branchId') || worker?.branchId || ''
  const initialDate = searchParams.get('date') || localIsoDate()

  const [date, setDate] = useState(initialDate)
  const [report, setReport] = useState<DaybookData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadReport = useCallback(async () => {
    if (!branchId) {
      toast.warning('Hiányzó adat', 'Fiók kiválasztása szükséges')
      return
    }
    try {
      setLoading(true)
      setError(null)
      const data = await dailyReportApi.get(branchId, date)
      setReport(data as DaybookData)
    } catch (err) {
      logger.error('DaybookPage', 'Napi HUF-napló betöltési hiba:', err)
      setReport(null)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  const handlePdfDownload = async () => {
    if (!branchId) return
    try {
      setError(null)
      const blob = await dailyReportApi.downloadPdf(branchId, date)
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `huf-daybook-${date}.pdf`
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
    } catch (err) {
      setError(getErrorMessage(err))
      toast.error('PDF letöltési hiba', getErrorMessage(err))
    }
  }

  const fmtHuf = (n: number) =>
    n.toLocaleString('hu-HU', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) + ' Ft'

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <BookOpen />
          {t('reports.napiKonyv')}
        </h1>
        <div className="flex gap-2">
          {report && (
            <button onClick={() => void handlePdfDownload()} className="form-button">
              <Printer size={16} />
              PDF
            </button>
          )}
        </div>
      </div>

      <div className="form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">{t('common.date')}</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input
              className="form-input"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>
        </div>
        <button
          onClick={() => void loadReport()}
          disabled={loading}
          className="form-button-primary"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />{' '}
          {loading ? 'Betöltés...' : 'Lekérdezés'}
        </button>
      </div>

      {error && (
        <div className="bg-yellow-50 border border-yellow-200 text-yellow-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {report && (
        <div className="form-panel">
          <div className="mb-3 text-sm text-gray-500">
            {report.branchName} — {report.date}
          </div>

          {report.rows.length === 0 ? (
            <div className="text-center text-gray-500 py-4">Nincs tétel erre a napra.</div>
          ) : (
            <table className="data-grid w-full text-sm">
              <thead>
                <tr>
                  <th>Sorszám</th>
                  <th>Bizonylat</th>
                  <th>{t('misc.ido')}</th>
                  <th className="text-right">Átadás (HUF)</th>
                  <th className="text-right">Átvétel (HUF)</th>
                </tr>
              </thead>
              <tbody>
                {report.rows.map((row) => (
                  <tr key={`${row.receiptNumber}-${row.timestamp}`}>
                    <td>{row.annualSequence ?? '-'}</td>
                    <td className="font-mono">
                      {row.receiptNumber}
                      {row.storno && <span className="ml-2 text-red-600 font-semibold">Sztornó</span>}
                    </td>
                    <td>{row.timestamp}</td>
                    <td className="text-right">{row.atadasHuf != null ? fmtHuf(row.atadasHuf) : ''}</td>
                    <td className="text-right">{row.atvetelHuf != null ? fmtHuf(row.atvetelHuf) : ''}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="font-semibold">
                  <td colSpan={3}>Összesen</td>
                  <td className="text-right">{fmtHuf(report.totalAtadasHuf)}</td>
                  <td className="text-right">{fmtHuf(report.totalAtvetelHuf)}</td>
                </tr>
              </tfoot>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
