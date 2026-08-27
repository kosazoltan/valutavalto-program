import { useState, useEffect, useMemo } from 'react'
import { Monitor, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { workstationApi, Workstation, WorkstationCreateRequest } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function WorkstationPage() {
  const { t } = useTranslation()
  const [workstations, setWorkstations] = useState<Workstation[]>([])
  const [activeWorkstations, setActiveWorkstations] = useState<Workstation[]>([])
  const [loading, setLoading] = useState(true)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingWorkstation, setEditingWorkstation] = useState<Workstation | null>(null)
  const [formData, setFormData] = useState<WorkstationCreateRequest>({
    code: '',
    name: '',
    workstationType: 'CASHIER',
    isActive: true,
  })

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      try {
        await loadData()
      } catch (err) {
        logger.error('WorkstationPage', 'Failed to load workstations:', err)
        throw err
      }
    }

    load().catch((err) => {
      if (mounted) {
        logger.error('WorkstationPage', 'Failed to load workstations:', err)
      }
    })

    return () => {
      mounted = false
    }
  }, [])

  const filteredWorkstations = useMemo(() => {
    if (!searchTerm) return workstations
    const term = searchTerm.toLowerCase()
    return workstations.filter(
      (w) =>
        w.code.toLowerCase().includes(term) ||
        w.name.toLowerCase().includes(term) ||
        w.machineName?.toLowerCase().includes(term),
    )
  }, [workstations, searchTerm])

  const loadData = async (): Promise<void> => {
    try {
      setLoading(true)
      const [data, active] = await Promise.all([workstationApi.list(), workstationApi.getActive()])
      setWorkstations(data)
      setActiveWorkstations(active)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      logger.error('WorkstationPage', 'Failed to load workstations:', err)
      toast.error('Betöltési hiba', `Hiba történt a betöltés során: ${errorMessage}`)
    } finally {
      setLoading(false)
    }
  }

  const handleCreate = () => {
    setEditingWorkstation(null)
    setFormData({
      code: '',
      name: '',
      workstationType: 'CASHIER',
      isActive: true,
    })
    setShowForm(true)
  }

  const handleEdit = async (workstation: Workstation) => {
    try {
      setDetailLoadingId(workstation.id)
      const detailed = await workstationApi.getById(workstation.id)
      setEditingWorkstation(detailed)
      setFormData({
        code: detailed.code,
        name: detailed.name,
        branchId: detailed.branchId,
        machineName: detailed.machineName,
        ipAddress: detailed.ipAddress,
        macAddress: detailed.macAddress,
        workstationType: detailed.workstationType,
        softwareVersion: detailed.softwareVersion,
        isActive: detailed.isActive,
      })
      setShowForm(true)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      toast.error(
        'Részlet betöltési hiba',
        `Hiba történt a munkaállomás betöltése során: ${errorMessage}`,
      )
      logger.error('WorkstationPage', 'Failed to load workstation details:', err)
    } finally {
      setDetailLoadingId(null)
    }
  }

  const handleSave = async (): Promise<void> => {
    try {
      if (editingWorkstation) {
        await workstationApi.update(editingWorkstation.id, formData)
      } else {
        await workstationApi.create(formData)
      }
      await loadData()
      setShowForm(false)
      setEditingWorkstation(null)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      toast.error('Mentési hiba', `Hiba történt a mentés során: ${errorMessage}`)
      logger.error('WorkstationPage', 'Failed to save workstation:', err)
    }
  }

  const handleDelete = async (id: string): Promise<void> => {
    if (!confirm('Biztosan törölni szeretné ezt a munkaállomást?')) return
    try {
      await workstationApi.delete(id)
      await loadData()
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      toast.error('Törlési hiba', `Hiba történt a törlés során: ${errorMessage}`)
      logger.error('WorkstationPage', 'Failed to delete workstation:', err)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Monitor />
          {t('workstations.munkaallomasok')}
        </h1>
        <button onClick={handleCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          {t('workstations.ujMunkaallomas')}
        </button>
      </div>

      <div className="form-panel">
        <div className="mb-3 grid grid-cols-1 gap-2 sm:grid-cols-3">
          <div className="rounded border border-gray-200 bg-white p-3">
            <div className="text-xs text-gray-500">{i18n.t('literals.osszes-munkaallomas')}</div>
            <div className="text-2xl font-semibold text-gray-900">{workstations.length}</div>
          </div>
          <div className="rounded border border-emerald-200 bg-emerald-50 p-3">
            <div className="text-xs text-emerald-700">{i18n.t('literals.aktiv-munkaallomas')}</div>
            <div className="text-2xl font-semibold text-emerald-800">
              {activeWorkstations.length}
            </div>
          </div>
          <div className="rounded border border-blue-200 bg-blue-50 p-3">
            <div className="text-xs text-blue-700">{i18n.t('literals.online-jelzes')}</div>
            <div className="text-2xl font-semibold text-blue-800">
              {workstations.filter((w) => w.isOnline).length}
            </div>
          </div>
        </div>
        <div>
          <label className="form-label">{t('common.search')}</label>
          <div className="relative">
            <Search
              className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
              size={16}
            />
            <input
              type="text"
              className="form-input pl-8"
              placeholder="Kód, név vagy gépnév..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingWorkstation ? 'Munkaállomás szerkesztése' : 'Új munkaállomás'}
              </h2>
              <button
                onClick={() => {
                  setShowForm(false)
                  setEditingWorkstation(null)
                }}
                className="text-gray-500"
              >
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="form-label">{t('common.codeRequired')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">{t('common.nameRequired')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">{t('circulars.tipus')}</label>
                <select
                  className="form-input"
                  value={formData.workstationType}
                  onChange={(e) => setFormData({ ...formData, workstationType: e.target.value })}
                >
                  <option value="CASHIER">{t('branch.branch')}</option>
                  <option value="ADMIN">{t('workstations.admin')}</option>
                  <option value="POS">{i18n.t('literals.pos')}</option>
                </select>
              </div>
              <div>
                <label className="form-label">{t('workstations.gepnev')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.machineName || ''}
                  onChange={(e) => setFormData({ ...formData, machineName: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('common.ipAddress')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.ipAddress || ''}
                    onChange={(e) => setFormData({ ...formData, ipAddress: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">{t('workstations.macCim')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.macAddress || ''}
                    onChange={(e) => setFormData({ ...formData, macAddress: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    className="rounded"
                    checked={formData.isActive ?? true}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  />
                  <span>{t('common.active')}</span>
                </label>
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button
                  onClick={() => {
                    setShowForm(false)
                    setEditingWorkstation(null)
                  }}
                  className="form-button"
                >
                  {t('common.cancel')}
                </button>
                <button
                  onClick={handleSave}
                  className="form-button-primary flex items-center gap-2"
                >
                  <Save size={16} />
                  {t('common.save')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="form-panel overflow-x-auto">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.code')}</th>
              <th>{t('common.name')}</th>
              <th>{t('common.type')}</th>
              <th>{t('workstations.gepnev')}</th>
              <th>{t('common.ipAddress')}</th>
              <th>{t('common.online')}</th>
              <th>{t('common.status')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredWorkstations.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filteredWorkstations.map((w) => (
                <tr key={w.id}>
                  <td className="font-mono text-sm">{w.code}</td>
                  <td>{w.name}</td>
                  <td>{w.workstationType}</td>
                  <td>{w.machineName || '-'}</td>
                  <td>{w.ipAddress || '-'}</td>
                  <td>
                    <span className={`badge ${w.isOnline ? 'badge-green' : 'badge-gray'}`}>
                      {w.isOnline ? 'Online' : 'Offline'}
                    </span>
                  </td>
                  <td>
                    <span className={`badge ${w.isActive ? 'badge-green' : 'badge-red'}`}>
                      {w.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => void handleEdit(w)}
                        disabled={detailLoadingId === w.id}
                        className="form-button text-xs disabled:opacity-50"
                      >
                        <Edit
                          size={12}
                          className={detailLoadingId === w.id ? 'animate-pulse' : ''}
                        />
                        {t('common.edit')}
                      </button>
                      <button
                        onClick={() => handleDelete(w.id)}
                        className="form-button text-xs text-red-600"
                      >
                        <Trash2 size={12} />
                        {t('common.delete')}
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
