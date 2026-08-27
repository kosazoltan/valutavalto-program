import { useState, useEffect, useCallback } from 'react'
import { Clock, Search, RefreshCw, Plus, AlertTriangle, Play, Power } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface SchedulerJobItem {
  id: string | number
  taskName?: string
  cronExpression?: string
  taskType?: string
  lastRunAt?: string
  nextRunAt?: string
  isActive?: boolean
  lastResult?: string | null
  parameters?: string | null
}

interface SchedulerFormState {
  taskName: string
  cronExpression: string
  taskType: string
  parameters: string
}

export default function SchedulerPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<SchedulerJobItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [form, setForm] = useState<SchedulerFormState | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<SchedulerJobItem[]>('/scheduler/tasks')
      setItems(safeArray<(typeof items)[0]>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SchedulerPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const openNewForm = () => {
    setError(null)
    setMessage(null)
    setForm({
      taskName: '',
      cronExpression: '0 0 * * * *',
      taskType: 'HEALTH_CHECK',
      parameters: '',
    })
  }

  const createTask = async () => {
    if (!form) return
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      await api.post('/scheduler/tasks', {
        taskName: form.taskName.trim(),
        cronExpression: form.cronExpression.trim(),
        taskType: form.taskType,
        isActive: true,
        parameters: form.parameters.trim() || null,
      })
      setForm(null)
      setMessage('Ütemezett feladat létrehozva.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SchedulerPage', 'Létrehozási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const toggleTask = async (item: SchedulerJobItem) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      await api.put(`/scheduler/tasks/${item.id}/toggle`, null, {
        params: { active: !item.isActive },
      })
      setMessage(item.isActive ? 'Feladat deaktiválva.' : 'Feladat aktiválva.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SchedulerPage', 'Aktív státusz váltási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const runNow = async (item: SchedulerJobItem) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      await api.post(`/scheduler/tasks/${item.id}/run-now`)
      setMessage('Feladat manuális futtatása elindítva.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SchedulerPage', 'Manuális futtatási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
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
          <Clock className="h-6 w-6" />
          {t('scheduler.utemezesek')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button onClick={openNewForm} className="form-button-primary flex items-center gap-1">
            <Plus className="h-4 w-4" />
            {t('common.new')}
          </button>
        </div>
      </div>

      {form && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">{i18n.t('literals.uj-utemezett-feladat')}</h2>
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <div>
              <label htmlFor="scheduler-task-name" className="form-label">
                {i18n.t('literals.feladat-neve')}
              </label>
              <input
                id="scheduler-task-name"
                value={form.taskName}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, taskName: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="scheduler-cron" className="form-label">
                {i18n.t('literals.cron-kifejezes')}
              </label>
              <input
                id="scheduler-cron"
                value={form.cronExpression}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, cronExpression: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="scheduler-task-type" className="form-label">
                {i18n.t('literals.feladattipus')}
              </label>
              <select
                id="scheduler-task-type"
                value={form.taskType}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, taskType: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              >
                <option value="RATE_SYNC">{i18n.t('literals.rate-sync')}</option>
                <option value="BACKUP">{i18n.t('literals.backup')}</option>
                <option value="REPORT">{i18n.t('literals.report')}</option>
                <option value="CLOSING_REMINDER">{i18n.t('literals.closing-reminder')}</option>
                <option value="HEALTH_CHECK">{i18n.t('literals.health-check')}</option>
              </select>
            </div>
            <div>
              <label htmlFor="scheduler-parameters" className="form-label">
                {i18n.t('literals.parameterek-json')}
              </label>
              <input
                id="scheduler-parameters"
                value={form.parameters}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, parameters: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void createTask()}
              disabled={saving || !form.taskName.trim() || !form.cronExpression.trim()}
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button type="button" onClick={() => setForm(null)} className="form-button">
              {i18n.t('literals.megse')}
            </button>
          </div>
        </div>
      )}

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

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {message && (
        <div className="rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
          {message}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('scheduler.feladat')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('scheduler.utemezes')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.tipus')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('scheduler.utolsoFutas')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('scheduler.kovetkezoFutas')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.eredmeny')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.active')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('common.actions')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.taskName ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.cronExpression ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.taskType ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.lastRunAt ? new Date(item.lastRunAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">
                    {item.nextRunAt ? new Date(item.nextRunAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.lastResult ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.isActive ? 'Igen' : 'Nem'}</td>
                  <td className="px-4 py-3 text-right whitespace-nowrap">
                    <button
                      onClick={() => void runNow(item)}
                      disabled={saving}
                      className="form-button mr-2 p-1 text-blue-600"
                      title="Futtatás most"
                    >
                      <Play className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => void toggleTask(item)}
                      disabled={saving}
                      className="form-button p-1 text-slate-700"
                      title={item.isActive ? 'Deaktiválás' : 'Aktiválás'}
                    >
                      <Power className="h-4 w-4" />
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
