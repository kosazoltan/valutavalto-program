import { useState, useEffect, useCallback } from 'react'
import { BookOpen, AlertTriangle, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { dailyJournalApi, branchApi } from '../../services/api/index'
import type { BranchInfo } from '../../services/api/index'
import { localIsoDate } from '../../utils/dateFormat'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage } from '../../utils/errorHandling'
import { downloadBlob } from '../../utils/downloadBlob'

/**
 * Napkönyv (napi forgalmi napló) PDF letöltő oldal — legacy NAPKONYV parity.
 *
 * Backend végpont: GET /api/v1/reports/daily-journal?branchId&date → application/pdf
 */
export default function DailyJournalPage() {
  const { t } = useTranslation()

  const [branchId, setBranchId] = useState<string>('')
  const [date, setDate] = useState<string>(localIsoDate())
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadBranches = useCallback(async () => {
    try {
      const list = await branchApi.listActive()
      setBranches(list ?? [])
    } catch (err) {
      logger.error('DailyJournalPage', 'Iroda-lista betöltés hiba:', err)
    }
  }, [])

  useEffect(() => {
    void loadBranches()
  }, [loadBranches])

  const handleDownload = useCallback(async () => {
    if (!branchId) {
      setError(t('reports.dailyJournal.errors.noBranch'))
      return
    }
    if (!date) {
      setError(t('reports.dailyJournal.errors.noDate'))
      return
    }
    setLoading(true)
    setError(null)
    try {
      const blob = await dailyJournalApi.downloadPdf(branchId, date)
      downloadBlob(blob, `napkonyv-${date}-${branchId.slice(0, 8)}.pdf`)
    } catch (err) {
      logger.error('DailyJournalPage', 'Napkönyv letöltés hiba:', err)
      setError(await getBlobErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [branchId, date, t])

  return (
    <div className="form-panel space-y-4">
      <div>
        <h1 className="form-title flex items-center gap-2">
          <BookOpen className="h-6 w-6" />
          {t('reports.dailyJournal.title')}
        </h1>
        <p className="text-xs text-gray-500 mt-1">{t('reports.dailyJournal.subtitle')}</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
        <div className="md:col-span-1">
          <label className="block text-xs text-gray-500 mb-1" htmlFor="dj-branch">
            {t('reports.dailyJournal.branch')}
          </label>
          <select
            id="dj-branch"
            value={branchId}
            onChange={(e) => setBranchId(e.target.value)}
            className="form-input w-full text-sm"
          >
            <option value="">{t('reports.dailyJournal.branchPlaceholder')}</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.code} - {b.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="dj-date">
            {t('reports.dailyJournal.date')}
          </label>
          <input
            id="dj-date"
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <button
            type="button"
            onClick={() => void handleDownload()}
            disabled={loading || !branchId}
            className="form-button-primary flex items-center gap-2"
          >
            <Download className="h-4 w-4" />
            {loading ? t('reports.dailyJournal.downloading') : t('reports.dailyJournal.download')}
          </button>
        </div>
      </div>

      <div className="text-center text-sm text-gray-500 py-6">{t('reports.dailyJournal.hint')}</div>
    </div>
  )
}
