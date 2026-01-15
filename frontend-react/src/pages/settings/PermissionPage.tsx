import { useState, useEffect } from 'react'
import { Shield, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { permissionApi, Permission, PermissionCreateRequest } from '../../services/api'
import { getErrorMessage } from '../../utils/errorHandling'

export default function PermissionPage() {
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [filteredPermissions, setFilteredPermissions] = useState<Permission[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedModule, setSelectedModule] = useState<string>('')
  const [showForm, setShowForm] = useState(false)
  const [editingPermission, setEditingPermission] = useState<Permission | null>(null)
  const [formData, setFormData] = useState<PermissionCreateRequest>({
    code: '',
    name: '',
    description: '',
    module: '',
    isSystemPermission: false,
    isActive: true
  })

  const modules = Array.from(new Set(permissions.map(p => p.module))).sort()

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      await loadPermissions()
    }

    load().catch(err => {
      if (mounted) {
        console.error('Failed to load permissions:', err)
      }
    })

    return () => {
      mounted = false
    }
  }, [])

  useEffect(() => {
    filterPermissions()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [permissions, searchTerm, selectedModule])

  const loadPermissions = async (): Promise<void> => {
    try {
      setLoading(true)
      const data = await permissionApi.list()
      setPermissions(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      console.error('Failed to load permissions:', err)
      alert(`Hiba történt a betöltés során: ${errorMessage}`)
    } finally {
      setLoading(false)
    }
  }

  const filterPermissions = () => {
    let filtered = permissions

    if (searchTerm) {
      filtered = filtered.filter(p =>
        p.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.description?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }

    if (selectedModule) {
      filtered = filtered.filter(p => p.module === selectedModule)
    }

    setFilteredPermissions(filtered)
  }

  const handleCreate = () => {
    setEditingPermission(null)
    setFormData({
      code: '',
      name: '',
      description: '',
      module: '',
      isSystemPermission: false,
      isActive: true
    })
    setShowForm(true)
  }

  const handleEdit = (permission: Permission) => {
    setEditingPermission(permission)
    setFormData({
      code: permission.code,
      name: permission.name,
      description: permission.description || '',
      module: permission.module,
      isSystemPermission: permission.isSystemPermission,
      isActive: permission.isActive
    })
    setShowForm(true)
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
      console.error('Hiba a jogosultság mentésekor:', error)
      alert('Hiba történt a mentés során')
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
      console.error('Hiba a jogosultság törlésekor:', error)
      alert('Hiba történt a törlés során')
    }
  }

  const handleToggleActive = async (id: string) => {
    try {
      await permissionApi.toggleActive(id)
      await loadPermissions()
    } catch (error) {
      console.error('Hiba a jogosultság állapotváltásakor:', error)
      alert('Hiba történt az állapotváltás során')
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
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Shield />
          Jogosultságok
        </h1>
        <button
          onClick={handleCreate}
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          Új jogosultság
        </button>
      </div>

      {/* Filters */}
      <div className="form-panel">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="form-label">Keresés</label>
            <div className="relative">
              <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
              <input
                type="text"
                className="form-input pl-8"
                placeholder="Kód, név vagy leírás..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          <div>
            <label className="form-label">Modul</label>
            <select
              className="form-input"
              value={selectedModule}
              onChange={(e) => setSelectedModule(e.target.value)}
            >
              <option value="">Összes modul</option>
              {modules.map(module => (
                <option key={module} value={module}>{module}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
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
                <label className="form-label">Jogosultság kód *</label>
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
                <label className="form-label">Jogosultság név *</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="pl: Tranzakció létrehozása"
                />
              </div>

              <div>
                <label className="form-label">Modul *</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.module}
                  onChange={(e) => setFormData({ ...formData, module: e.target.value })}
                  placeholder="pl: TRANSACTION"
                />
              </div>

              <div>
                <label className="form-label">Leírás</label>
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
                    onChange={(e) => setFormData({ ...formData, isSystemPermission: e.target.checked })}
                    disabled={!!editingPermission}
                  />
                  <span>Rendszer jogosultság</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    className="rounded"
                    checked={formData.isActive ?? true}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  />
                  <span>Aktív</span>
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
                  Mégse
                </button>
                <button
                  onClick={handleSave}
                  className="form-button-primary flex items-center gap-2"
                >
                  <Save size={16} />
                  Mentés
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Permissions Table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Kód</th>
              <th>Név</th>
              <th>Modul</th>
              <th>Leírás</th>
              <th>Típus</th>
              <th>Státusz</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filteredPermissions.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">
                  Nincs találat
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
                      <span className="badge badge-orange">Rendszer</span>
                    ) : (
                      <span className="badge badge-gray">Egyedi</span>
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
                        onClick={() => handleEdit(permission)}
                        className="form-button text-sm flex items-center gap-1"
                      >
                        <Edit size={14} />
                        Szerkesztés
                      </button>
                      {!permission.isSystemPermission && (
                        <button
                          onClick={() => handleDelete(permission.id)}
                          className="form-button text-sm text-red-600 flex items-center gap-1"
                        >
                          <Trash2 size={14} />
                          Törlés
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

