import { useState, useEffect, useMemo } from 'react'
import { Shield, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { permissionApi, Permission, PermissionCreateRequest } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function PermissionPage() {
  const { t } = useTranslation()
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [allPermissions, setAllPermissions] = useState<Permission[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedModule, setSelectedModule] = useState<string>('')
  const [showForm, setShowForm] = useState(false)
  const [editingPermission, setEditingPermission] = useState<Permission | null>(null)
  const [editingPermissionLoadingId, setEditingPermissionLoadingId] = useState<string | null>(null)
  const [formData, setFormData] = useState<PermissionCreateRequest>({
    code: '',
    name: '',
    description: '',
    module: '',
    isSystemPermission: false,
    isActive: true,
  })

  const modules = Array.from(new Set(allPermissions.map((p) => p.module))).sort()

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      try {
        await loadPermissions()
      } catch (err) {
        logger.error('PermissionPage', 'Failed to load permissions:', err)
        throw err
      }
    }

    load().catch((err) => {
      if (mounted) {
        logger.error('PermissionPage', 'Failed to load permissions:', err)
      }
    })

    return () => {
      mounted = false
    }
  }, [])

  const loadPermissions = async (): Promise<void> => {
    try {
      setLoading(true)
      const data = await permissionApi.list()
      setPermissions(data)
      setAllPermissions(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      logger.error('PermissionPage', 'Failed to load permissions:', err)
      toast.error('Hiba történt a betöltés során', errorMessage)
    } finally {
      setLoading(false)
    }
  }

  const filteredPermissions = useMemo(() => {
    let filtered = permissions

    if (searchTerm) {
      filtered = filtered.filter(
        (p) =>
          p.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
          p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          p.description?.toLowerCase().includes(searchTerm.toLowerCase()),
      )
    }

    return filtered
  }, [permissions, searchTerm])

  const handleModuleChange = async (module: string): Promise<void> => {
    setSelectedModule(module)
    try {
      setLoading(true)
      const data = module ? await permissionApi.getByModule(module) : await permissionApi.list()
      setPermissions(data)
      if (!module) {
        setAllPermissions(data)
      }
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      logger.error('PermissionPage', 'Failed to load permissions by module:', err)
      toast.error('Hiba történt a modul jogosultságainak betöltése során', errorMessage)
    } finally {
      setLoading(false)
    }
  }

  const handleCreate = () => {
    setEditingPermission(null)
    setFormData({
      code: '',
      name: '',
      description: '',
      module: '',
      isSystemPermission: false,
      isActive: true,
    })
    setShowForm(true)
  }

  const handleEdit = async (permission: Permission) => {
    try {
      setEditingPermissionLoadingId(permission.id)
      const detail = await permissionApi.getById(permission.id)
      setEditingPermission(detail)
      setFormData({
        code: detail.code,
        name: detail.name,
        description: detail.description || '',
        module: detail.module,
        isSystemPermission: detail.isSystemPermission,
        isActive: detail.isActive,
      })
      setShowForm(true)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      logger.error('PermissionPage', 'Failed to load permission detail:', err)
      toast.error('Hiba történt a jogosultság részleteinek betöltése során', errorMessage)
    } finally {
      setEditingPermissionLoadingId(null)
    }
  }

  const handleSave = async () => {
    try {
      if (editingPermission) {
        await permissionApi.update(editingPermission.id, formData)
      } else {
        await permissionApi.create(formData)
      }
      await loadPermissions()
      setShowForm(false)
      setEditingPermission(null)
    } catch (error) {
      logger.error('PermissionPage', 'Hiba a jogosultság mentésekor:', error)
      toast.error('Hiba történt a mentés során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törölni szeretné ezt a jogosultságot?')) {
      return
    }

    try {
      await permissionApi.delete(id)
      await loadPermissions()
    } catch (error) {
      logger.error('PermissionPage', 'Hiba a jogosultság törlésekor:', error)
      toast.error('Hiba történt a törlés során')
    }
  }

  const handleToggleActive = async (id: string) => {
    try {
      await permissionApi.toggleActive(id)
      await loadPermissions()
    } catch (error) {
      logger.error('PermissionPage', 'Hiba a jogosultság állapotváltásakor:', error)
      toast.error('Hiba történt az állapotváltás során')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">{i18n.t('literals.betoltes')}</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Shield />
          {t('settings.permissions')}
        </h1>
        <button onClick={handleCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          {t('settings.ujJogosultsag')}
        </button>
      </div>

      {/* Filters */}
      <div className="form-panel">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="form-label" htmlFor="permission-search">
              {t('common.search')}
            </label>
            <div className="relative">
              <Search
                className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={16}
              />
              <input
                id="permission-search"
                type="text"
                className="form-input pl-8"
                placeholder="Kód, név vagy leírás..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          <div>
            <label className="form-label" htmlFor="permission-module-filter">
              {t('settings.modul')}
            </label>
            <select
              id="permission-module-filter"
              className="form-input"
              value={selectedModule}
              onChange={(e) => void handleModuleChange(e.target.value)}
            >
              <option value="">{t('settings.osszesModul')}</option>
              {modules.map((module) => (
                <option key={module} value={module}>
                  {module}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingPermission ? 'Jogosultság szerkesztése' : 'Új jogosultság'}
              </h2>
              <button
                onClick={() => {
                  setShowForm(false)
                  setEditingPermission(null)
                }}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="form-label">{t('settings.jogosultsagKod')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                  disabled={!!editingPermission}
                  placeholder="pl: TRANSACTION_CREATE"
                />
              </div>

              <div>
                <label className="form-label">{t('settings.jogosultsagNev')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="pl: Tranzakció létrehozása"
                />
              </div>

              <div>
                <label className="form-label">{t('settings.modul2')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.module}
                  onChange={(e) => setFormData({ ...formData, module: e.target.value })}
                  placeholder="pl: TRANSACTION"
                />
              </div>

              <div>
                <label className="form-label">{t('common.description')}</label>
                <textarea
                  className="form-input"
                  rows={3}
                  value={formData.description || ''}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Jogosultság leírása..."
                />
              </div>

              <div className="space-y-2">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    className="rounded"
                    checked={formData.isSystemPermission ?? false}
                    onChange={(e) =>
                      setFormData({ ...formData, isSystemPermission: e.target.checked })
                    }
                    disabled={!!editingPermission}
                  />
                  <span>{t('settings.rendszerJogosultsag')}</span>
                </label>
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
                    setEditingPermission(null)
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

      {/* Permissions Table */}
      <div className="form-panel overflow-x-auto">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.code')}</th>
              <th>{t('common.name')}</th>
              <th>{t('settings.modul')}</th>
              <th>{t('common.description')}</th>
              <th>{t('common.type')}</th>
              <th>{t('common.status')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredPermissions.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filteredPermissions.map((permission) => (
                <tr key={permission.id}>
                  <td className="font-mono text-sm">{permission.code}</td>
                  <td>{permission.name}</td>
                  <td>
                    <span className="badge badge-blue">{permission.module}</span>
                  </td>
                  <td className="max-w-xs truncate" title={permission.description}>
                    {permission.description || '-'}
                  </td>
                  <td>
                    {permission.isSystemPermission ? (
                      <span className="badge badge-orange">{t('settings.system')}</span>
                    ) : (
                      <span className="badge badge-gray">{t('settings.egyedi')}</span>
                    )}
                  </td>
                  <td>
                    <button
                      onClick={() => handleToggleActive(permission.id)}
                      className={`badge ${permission.isActive ? 'badge-green' : 'badge-red'}`}
                    >
                      {permission.isActive ? 'Aktív' : 'Inaktív'}
                    </button>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        onClick={() => void handleEdit(permission)}
                        disabled={editingPermissionLoadingId === permission.id}
                        className="form-button text-sm flex items-center gap-1 disabled:opacity-50"
                      >
                        <Edit size={14} />
                        {t('common.edit')}
                      </button>
                      {!permission.isSystemPermission && (
                        <button
                          onClick={() => handleDelete(permission.id)}
                          className="form-button text-sm text-red-600 flex items-center gap-1"
                        >
                          <Trash2 size={14} />
                          {t('common.delete')}
                        </button>
                      )}
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
