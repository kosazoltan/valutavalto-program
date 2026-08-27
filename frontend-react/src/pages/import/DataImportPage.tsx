import { useState, useEffect, useCallback } from 'react'
import type { ChangeEvent } from 'react'
import { Upload, Search, RefreshCw, AlertTriangle, PlayCircle, RotateCcw } from 'lucide-react'
import {
  api,
  configExportApi,
  type ConfigBundleDto,
  type ConfigImportResultDto,
} from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'
import { toast } from '../../components/ui/toaster'
import i18n from '../../i18n'

interface DataImportItem {
  id: string | number
  importType?: string
  sourceFile?: string
  status?: string
  totalRecords?: number
  importedRecords?: number
  failedRecords?: number
  errorLog?: string
  completedAt?: string
  createdAt?: string
}

const todayIso = () => new Date().toISOString().slice(0, 10)

function readFileText(file: File): Promise<string> {
  if (typeof file.text === 'function') {
    return file.text()
  }

  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(String(reader.result ?? ''))
    reader.onerror = () => reject(reader.error ?? new Error('A fájl nem olvasható.'))
    reader.readAsText(file)
  })
}

export default function DataImportPage() {
  const { t } = useTranslation()
  const branchId = useAuthStore((state) => state.worker?.branchId)
  const [items, setItems] = useState<DataImportItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [importDate, setImportDate] = useState(todayIso)
  const [fromDate, setFromDate] = useState(todayIso)
  const [toDate, setToDate] = useState(todayIso)
  const [busyAction, setBusyAction] = useState<string | null>(null)
  const [configImportResult, setConfigImportResult] = useState<ConfigImportResultDto | null>(null)

  const loadData = useCallback(async () => {
    if (!branchId) {
      setItems([])
      setError('Az adatimport történethez bejelentkezett telephely szükséges.')
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      setError(null)
      const response = await api.get<{ content?: DataImportItem[] } | DataImportItem[]>(
        '/data-import/history',
        {
          params: { branchId },
        },
      )
      const rows = Array.isArray(response.data) ? response.data : response.data?.content
      setItems(safeArray<DataImportItem>(rows))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('DataImportPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [branchId])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const runImport = async (kind: 'daily-closing' | 'inventory' | 'transactions' | 'full') => {
    if (!branchId) {
      setError('Az import indításához bejelentkezett telephely szükséges.')
      return
    }
    if (
      kind === 'full' &&
      !window.confirm('Biztosan teljes adatimportot indít a bejelentkezett telephelyre?')
    ) {
      return
    }

    try {
      setBusyAction(kind)
      setError(null)
      const basePayload = { branchId }
      if (kind === 'daily-closing') {
        await api.post('/data-import/daily-closing', { ...basePayload, date: importDate })
      } else if (kind === 'inventory') {
        await api.post('/data-import/inventory', basePayload)
      } else if (kind === 'transactions') {
        await api.post('/data-import/transactions', { ...basePayload, fromDate, toDate })
      } else {
        await api.post('/data-import/full', basePayload)
      }
      toast.success('Import elindítva')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('DataImportPage', 'Import indítási hiba:', err)
      setError(msg)
      toast.error('Import hiba', msg)
    } finally {
      setBusyAction(null)
    }
  }

  const retryImport = async (id: DataImportItem['id']) => {
    try {
      const importId = String(id)
      setBusyAction(`retry:${importId}`)
      setError(null)
      await api.post(`/data-import/${importId}/retry`)
      toast.success('Import újrapróbálás elindítva')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('DataImportPage', 'Import újrapróbálási hiba:', err)
      setError(msg)
      toast.error('Újrapróbálás hiba', msg)
    } finally {
      setBusyAction(null)
    }
  }

  const importConfigFile = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (!file) return
    if (!branchId) {
      setError('A konfiguráció importhoz bejelentkezett telephely szükséges.')
      return
    }
    if (
      !window.confirm(
        'Biztosan importálja a kiválasztott telephelyi konfigurációt? A művelet rendszerbeállításokat módosíthat.',
      )
    ) {
      return
    }

    try {
      setBusyAction('config-import')
      setError(null)
      setConfigImportResult(null)
      const bundle = JSON.parse(await readFileText(file)) as ConfigBundleDto
      const result = await configExportApi.importBranch(branchId, bundle)
      setConfigImportResult(result)
      if (result.success) {
        toast.success('Konfiguráció import kész')
      } else {
        toast.error(
          'Konfiguráció import hiba',
          result.errors?.join(', ') || 'A backend hibát jelzett.',
        )
      }
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('DataImportPage', 'Konfiguráció import hiba:', err)
      setError(msg)
      toast.error('Konfiguráció import hiba', msg)
    } finally {
      setBusyAction(null)
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
          <Upload className="h-6 w-6" />
          {t('import.adatimport')}
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

      <div className="grid gap-3 md:grid-cols-[1fr_1fr_auto] md:items-end">
        <label className="block">
          <span className="form-label">{i18n.t('literals.import-datum')}</span>
          <input
            type="date"
            value={importDate}
            onChange={(e) => setImportDate(e.target.value)}
            className="form-input"
          />
        </label>
        <div className="grid grid-cols-2 gap-2">
          <label className="block">
            <span className="form-label">{i18n.t('literals.tranzakcio-kezdete')}</span>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
              className="form-input"
            />
          </label>
          <label className="block">
            <span className="form-label">{i18n.t('literals.tranzakcio-vege')}</span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
              className="form-input"
            />
          </label>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void runImport('daily-closing')}
            disabled={busyAction !== null || !branchId}
            className="form-button flex items-center gap-2"
          >
            <PlayCircle className="h-4 w-4" />
            {i18n.t('literals.napi-zaras-2')}
          </button>
          <button
            type="button"
            onClick={() => void runImport('inventory')}
            disabled={busyAction !== null || !branchId}
            className="form-button flex items-center gap-2"
          >
            <PlayCircle className="h-4 w-4" />
            {i18n.t('literals.keszlet')}
          </button>
          <button
            type="button"
            onClick={() => void runImport('transactions')}
            disabled={busyAction !== null || !branchId}
            className="form-button flex items-center gap-2"
          >
            <PlayCircle className="h-4 w-4" />
            {i18n.t('literals.tranzakciok')}
          </button>
          <button
            type="button"
            onClick={() => void runImport('full')}
            disabled={busyAction !== null || !branchId}
            className="form-button flex items-center gap-2"
          >
            <PlayCircle className="h-4 w-4" />
            {i18n.t('literals.teljes-import')}
          </button>
        </div>
      </div>

      <section className="rounded border border-blue-200 bg-blue-50 p-3">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="text-sm font-semibold text-blue-950">
              {i18n.t('literals.konfiguracio-import')}
            </h2>
            <p className="mt-1 text-sm text-blue-800">
              {i18n.t('literals.korabban-exportalt-telephelyi-konfigurac')}
            </p>
          </div>
          <label
            className={`form-button inline-flex cursor-pointer items-center gap-2 ${busyAction !== null || !branchId ? 'pointer-events-none opacity-60' : ''}`}
          >
            <Upload className="h-4 w-4" />
            {i18n.t('literals.config-json-import')}
            <input
              type="file"
              accept="application/json,.json"
              className="sr-only"
              disabled={busyAction !== null || !branchId}
              onChange={(event) => void importConfigFile(event)}
            />
          </label>
        </div>
        {configImportResult && (
          <div
            className={`mt-3 rounded border p-3 text-sm ${configImportResult.success ? 'border-emerald-200 bg-emerald-50 text-emerald-900' : 'border-red-200 bg-red-50 text-red-900'}`}
          >
            <div className="font-semibold">
              {configImportResult.success ? 'Import sikeres' : 'Import hibával zárult'}
            </div>
            <div className="mt-1">
              {i18n.t('literals.parameter')}
              {configImportResult.importedSystemParams}
              {i18n.t('literals.arfolyam-2')} {configImportResult.importedRateSettings}
              {i18n.t('literals.kerekites')} {configImportResult.importedRoundingRules}
              {i18n.t('literals.sablon')} {configImportResult.importedPrintTemplates}
              {i18n.t('literals.led')} {configImportResult.ledConfigImported ? 'igen' : 'nem'}
            </div>
            {configImportResult.warnings?.length ? (
              <div className="mt-2">
                {i18n.t('literals.figyelmeztetes-2')}
                {configImportResult.warnings.join(', ')}
              </div>
            ) : null}
            {configImportResult.errors?.length ? (
              <div className="mt-2">
                {i18n.t('literals.hiba')}
                {configImportResult.errors.join(', ')}
              </div>
            ) : null}
          </div>
        )}
      </section>

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
                {t('backup.tipus')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('import.fajlnev')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('backup.allapot')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('import.rekordok')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('import.importalva')}
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
                  <td className="px-4 py-3 text-sm">{item.importType ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.sourceFile ?? '-'}
                    {item.errorLog ? (
                      <div className="mt-1 text-xs text-red-600">{item.errorLog}</div>
                    ) : null}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.importedRecords ?? 0}
                    {i18n.t('literals.lit-10')}
                    {item.totalRecords ?? 0}
                    {item.failedRecords ? ` (${item.failedRecords} hiba)` : ''}
                  </td>
                  <td className="px-4 py-3 text-sm">
                    {item.completedAt || item.createdAt
                      ? new Date(item.completedAt ?? item.createdAt ?? '').toLocaleString('hu-HU')
                      : '-'}
                  </td>
                  <td className="px-4 py-3 text-right text-sm">
                    <button
                      type="button"
                      onClick={() => void retryImport(item.id)}
                      disabled={busyAction !== null || item.status !== 'FAILED'}
                      className="form-button inline-flex items-center gap-2"
                      title="Újrapróbálás"
                    >
                      <RotateCcw className="h-4 w-4" />
                      {i18n.t('literals.retry')}
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
