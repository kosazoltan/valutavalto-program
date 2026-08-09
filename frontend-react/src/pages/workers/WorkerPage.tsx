import { useState, useEffect, useMemo } from 'react'
import { Users, Plus, Edit, Search, X, Save, Power, Upload } from 'lucide-react'
import BulkEmailModal from '../../components/BulkEmailModal'
import { api } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import type { components } from '@valuta/shared-api'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'

type WorkerDto = components['schemas']['WorkerDto']
// Runtime-ban mindig megletszo mezok: a backend JPA entitas @NotNull-lal
// kenyszeriti, de az OpenAPI spec nincs 'required' annotaciokkal marklosva.
// Local kontraktus: Required<Pick> a stabil mezoket nem-null-kent kezeli.
type Worker = Required<
  Pick<WorkerDto, 'id' | 'workerCode' | 'firstName' | 'lastName' | 'fullName'>
> &
  Partial<WorkerDto> & { isActive?: boolean }

interface WorkerForm {
  workerCode: string
  firstName: string
  lastName: string
  email: string
  phone: string
  branchId: string
}

const emptyForm: WorkerForm = {
  workerCode: '',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  branchId: '',
}

export default function WorkerPage() {
  const { t } = useTranslation()
  const authWorker = useAuthStore((state) => state.worker)
  const branchId = authWorker?.branchId ?? ''
  const branchName = authWorker?.branchName ?? ''
  const [workers, setWorkers] = useState<Worker[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [listScope, setListScope] = useState<'all' | 'branch'>('all')
  const [showForm, setShowForm] = useState(false)
  const [editingWorker, setEditingWorker] = useState<Worker | null>(null)
  const [form, setForm] = useState<WorkerForm>(emptyForm)
  const [saving, setSaving] = useState(false)
  const [showBulkModal, setShowBulkModal] = useState(false)

  const filtered = useMemo(() => {
    if (!searchTerm) return workers
    const t = searchTerm.toLowerCase()
    return workers.filter(
      (w) =>
        w.fullName.toLowerCase().includes(t) ||
        w.workerCode.toLowerCase().includes(t) ||
        (w.email ?? '').toLowerCase().includes(t),
    )
  }, [workers, searchTerm])

  const load = async (scope: 'all' | 'branch' = listScope) => {
    try {
      setLoading(true)
      setError(null)
      const res =
        scope === 'branch' && branchId
          ? await api.get(`/workers/branch/${branchId}`)
          : await api.get('/workers')
      setWorkers(safeArray<Worker>(res.data))
    } catch (err) {
      logger.error('WorkerPage', 'load error', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load('all')
    // Lint-audit 2026-08-09: szandekos mount-only betoltes. A `load` minden
    // renderben ujragyartodik (nem memoizalt), igy a deps-be veve vegtelen
    // fetch-hurkot okozna.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const showAllWorkers = async () => {
    setListScope('all')
    await load('all')
  }

  const showBranchWorkers = async () => {
    if (!branchId) {
      toast.warning(
        'Hiányzó fiók',
        'A fiók szerinti dolgozólista betöltéséhez hiányzik a bejelentkezett fiók azonosítója.',
      )
      return
    }
    setListScope('branch')
    await load('branch')
  }

  const openCreate = () => {
    setEditingWorker(null)
    setForm(emptyForm)
    setShowForm(true)
  }

  const openEdit = (w: Worker) => {
    setEditingWorker(w)
    setForm({
      workerCode: w.workerCode,
      firstName: w.firstName,
      lastName: w.lastName,
      email: w.email ?? '',
      phone: w.phone ?? '',
      branchId: w.branchId ?? '',
    })
    setShowForm(true)
  }

  const handleSave = async () => {
    if (!form.workerCode.trim() || !form.firstName.trim() || !form.lastName.trim()) {
      toast.warning('Hiányzó adat', 'Munkáskód, kereszt- és vezetéknév kötelező!')
      return
    }
    try {
      setSaving(true)
      if (editingWorker) {
        await api.put(`/workers/${editingWorker.id}`, form)
        toast.success('Dolgozó sikeresen módosítva!')
      } else {
        await api.post('/workers', form)
        toast.success('Dolgozó sikeresen létrehozva!')
      }
      setShowForm(false)
      await load(listScope)
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const handleToggle = async (w: Worker) => {
    try {
      if (w.active ?? w.isActive) {
        await api.post(`/workers/${w.id}/deactivate`)
      } else {
        await api.post(`/workers/${w.id}/activate`)
      }
      await load(listScope)
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Betöltés...</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <BulkEmailModal
        open={showBulkModal}
        onClose={() => setShowBulkModal(false)}
        onSuccess={() => {
          void load()
          setShowBulkModal(false)
        }}
      />
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Users />
          {t('workers.dolgozok')}
        </h1>
        <button
          onClick={() => setShowBulkModal(true)}
          className="mr-2 flex items-center gap-2 px-3 py-1.5 border border-primary-300 text-primary-700 rounded hover:bg-primary-50 text-sm"
        >
          <Upload size={14} />
          {t('workers.emailImport')}
        </button>
        <button onClick={openCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          {t('workers.ujDolgozo')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
        <div className="flex flex-col gap-3 md:flex-row md:items-center">
          <div className="relative flex-1">
            <Search
              className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
              size={16}
            />
            <input
              type="text"
              className="form-input pl-8"
              placeholder="Keresés névben, kódban, emailben..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <button
              type="button"
              onClick={() => void showAllWorkers()}
              className={`form-button min-h-10 ${listScope === 'all' ? 'border-primary-500 text-primary-700' : ''}`}
            >
              Összes dolgozó
            </button>
            <button
              type="button"
              onClick={() => void showBranchWorkers()}
              disabled={!branchId}
              className={`form-button min-h-10 ${listScope === 'branch' ? 'border-primary-500 text-primary-700' : ''} disabled:opacity-60`}
              title={branchName || 'Saját fiók'}
            >
              Saját fiók
            </button>
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingWorker ? 'Dolgozó szerkesztése' : 'Új dolgozó'}
              </h2>
              <button
                onClick={() => setShowForm(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="form-label">{t('workers.munkaskod')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={form.workerCode}
                  onChange={(e) => setForm({ ...form, workerCode: e.target.value })}
                  disabled={!!editingWorker}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('workers.keresztnev')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.firstName}
                    onChange={(e) => setForm({ ...form, firstName: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">{t('workers.vezeteknev')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.lastName}
                    onChange={(e) => setForm({ ...form, lastName: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="form-label">{t('common.email')}</label>
                <input
                  type="email"
                  className="form-input"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">{t('common.phone')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                />
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button onClick={() => setShowForm(false)} className="form-button">
                  {t('common.cancel')}
                </button>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="form-button-primary flex items-center gap-2"
                >
                  <Save size={16} />
                  {saving ? 'Mentés...' : 'Mentés'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="space-y-3 md:hidden">
        {filtered.length === 0 ? (
          <div className="rounded border border-gray-200 bg-white p-4 text-center text-gray-500">
            {t('common.noResult')}
          </div>
        ) : (
          filtered.map((w) => (
            <article key={w.id} className="rounded border border-gray-200 bg-white p-3 shadow-sm">
              <div className="mb-3 flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="truncate text-lg font-bold text-gray-900">{w.fullName}</p>
                  <p className="truncate text-sm text-gray-500">{w.workerCode}</p>
                </div>
                <span className={`badge ${(w.active ?? w.isActive) ? 'badge-green' : 'badge-red'}`}>
                  {(w.active ?? w.isActive) ? 'Aktív' : 'Inaktív'}
                </span>
              </div>
              <dl className="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
                <div className="col-span-2">
                  <dt className="text-gray-500">{t('commissions.fiok')}</dt>
                  <dd className="font-medium text-gray-900">{w.branchName ?? '-'}</dd>
                </div>
                <div>
                  <dt className="text-gray-500">{t('common.email')}</dt>
                  <dd className="break-words text-gray-900">{w.email ?? '-'}</dd>
                </div>
                <div>
                  <dt className="text-gray-500">{t('common.phone')}</dt>
                  <dd className="break-words text-gray-900">{w.phone ?? '-'}</dd>
                </div>
              </dl>
              <div className="mt-3 grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => openEdit(w)}
                  className="form-button flex min-h-10 items-center justify-center gap-1 text-xs"
                >
                  <Edit size={12} />
                  {t('common.edit')}
                </button>
                <button
                  type="button"
                  onClick={() => void handleToggle(w)}
                  className="form-button flex min-h-10 items-center justify-center gap-1 text-xs"
                >
                  <Power size={12} />
                  {(w.active ?? w.isActive) ? 'Deaktiválás' : 'Aktiválás'}
                </button>
              </div>
            </article>
          ))
        )}
      </div>

      <div className="form-panel hidden md:block">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.code')}</th>
              <th>{t('representatives.teljesNev')}</th>
              <th>{t('common.email')}</th>
              <th>{t('common.phone')}</th>
              <th>{t('commissions.fiok')}</th>
              <th>{t('common.status')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filtered.map((w) => (
                <tr key={w.id}>
                  <td className="font-mono text-sm">{w.workerCode}</td>
                  <td>{w.fullName}</td>
                  <td>{w.email ?? '-'}</td>
                  <td>{w.phone ?? '-'}</td>
                  <td>{w.branchName ?? '-'}</td>
                  <td>
                    <span
                      className={`badge ${(w.active ?? w.isActive) ? 'badge-green' : 'badge-red'}`}
                    >
                      {(w.active ?? w.isActive) ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-1 flex-wrap">
                      <button
                        onClick={() => openEdit(w)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Edit size={12} />
                        {t('common.edit')}
                      </button>
                      <button
                        onClick={() => handleToggle(w)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Power size={12} />
                        {(w.active ?? w.isActive) ? 'Deaktiválás' : 'Aktiválás'}
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
