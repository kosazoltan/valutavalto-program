import { useState, useEffect, useCallback } from 'react'
import { Database, Search, RefreshCw, AlertTriangle, Download, RotateCcw, Plus } from 'lucide-react'
import { api, configExportApi } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'

interface BackupItem {
  id: string | number
  backupType?: string
  createdAt?: string
  sizeBytes?: string
  status?: string
  createdByName?: string
}

function downloadJsonFile(filename: string, data: unknown) {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
  const url = window.URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  window.URL.revokeObjectURL(url)
}

export default function BackupPage() {
  const { t } = useTranslation()
  const branchId = useAuthStore((state) => state.worker?.branchId)
  const [items, setItems] = useState<BackupItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [busyAction, setBusyAction] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<BackupItem[] | { content?: BackupItem[] }>('/backup/history')
      const rows = Array.isArray(response.data) ? response.data : response.data?.content
      setItems(safeArray<BackupItem>(rows))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BackupPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  const createBackup = async () => {
    try {
      setBusyAction('create')
      setError(null)
      await api.post('/backup/create', { type: 'FULL' })
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BackupPage', 'Mentés létrehozási hiba:', err)
      setError(msg)
    } finally {
      setBusyAction(null)
    }
  }

  const downloadBackup = async (id: BackupItem['id']) => {
    const backupId = String(id)
    try {
      setBusyAction(`download:${backupId}`)
      setError(null)
      const response = await api.get<Blob>(`/backup/${backupId}/download`, { responseType: 'blob' })
      const url = window.URL.createObjectURL(response.data)
      const link = document.createElement('a')
      link.href = url
      link.download = `backup_${backupId}.sql`
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BackupPage', 'Mentés letöltési hiba:', err)
      setError(msg)
    } finally {
      setBusyAction(null)
    }
  }

  const restoreBackup = async (id: BackupItem['id']) => {
    const backupId = String(id)
    if (
      !window.confirm(
        'Biztosan visszaállítja a kiválasztott mentést? A művelet éles adatállapotot módosíthat.',
      )
    ) {
      return
    }

    try {
      setBusyAction(`restore:${backupId}`)
      setError(null)
      await api.post(`/backup/${backupId}/restore`)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BackupPage', 'Mentés visszaállítási hiba:', err)
      setError(msg)
    } finally {
      setBusyAction(null)
    }
  }

  const exportBranchConfig = async () => {
    if (!branchId) {
      setError('A telephely konfiguráció exportjához bejelentkezett telephely szükséges.')
      return
    }

    try {
      setBusyAction('config-export-branch')
      setError(null)
      const bundle = await configExportApi.exportBranch(branchId)
      downloadJsonFile(`config_${bundle.branchCode || branchId}.json`, bundle)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BackupPage', 'Konfiguráció export hiba:', err)
      setError(msg)
    } finally {
      setBusyAction(null)
    }
  }

  const exportAllConfigs = async () => {
    try {
      setBusyAction('config-export-all')
      setError(null)
      const bundles = await configExportApi.exportAll()
      downloadJsonFile(`config_all_${new Date().toISOString().slice(0, 10)}.json`, bundles)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BackupPage', 'Összes konfiguráció export hiba:', err)
      setError(msg)
    } finally {
      setBusyAction(null)
    }
  }

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Database className="h-6 w-6" />
          {t('backup.mentesEsVisszaallitas')}
        </h1>
        <div className="flex items-center gap-2">
          <button
            onClick={() => void createBackup()}
            disabled={busyAction !== null}
            className="form-button flex items-center gap-2"
          >
            <Plus className="h-4 w-4" />
            Új teljes mentés
          </button>
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

      <section className="rounded border border-blue-200 bg-blue-50 p-3">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="text-sm font-semibold text-blue-950">Konfiguráció export</h2>
            <p className="mt-1 text-sm text-blue-800">
              Telephelyi rendszerparaméterek, árfolyam-beállítások, kerekítés, nyomtatási sablonok
              és LED konfiguráció JSON mentése.
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() => void exportBranchConfig()}
              disabled={busyAction !== null || !branchId}
              className="form-button flex items-center gap-2"
            >
              <Download className="h-4 w-4" />
              Telephely config
            </button>
            <button
              type="button"
              onClick={() => void exportAllConfigs()}
              disabled={busyAction !== null}
              className="form-button flex items-center gap-2"
            >
              <Download className="h-4 w-4" />
              Összes config
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

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('backup.tipus')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('backup.letrehozva')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('backup.meret')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('backup.allapot')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('backup.keszitette')}
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
                  Betöltés...
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
                  <td className="px-4 py-3 text-sm">{item.backupType ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.createdAt ? new Date(item.createdAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.sizeBytes ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.createdByName ?? '-'}</td>
                  <td className="px-4 py-3 text-right text-sm">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => void downloadBackup(item.id)}
                        disabled={busyAction !== null}
                        className="form-button p-2"
                        title="Letöltés"
                      >
                        <Download className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => void restoreBackup(item.id)}
                        disabled={busyAction !== null || item.status !== 'COMPLETED'}
                        className="form-button p-2 text-red-700"
                        title="Visszaállítás"
                      >
                        <RotateCcw className="h-4 w-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}
        {filtered.length} / {items.length}
      </div>
    </div>
  )
}
