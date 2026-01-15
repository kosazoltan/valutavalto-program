import { useState, useEffect } from 'react'
import { Users, Plus, Edit, Trash2, Search, X, Save, Shield } from 'lucide-react'
import { roleApi, Role, RoleCreateRequest, permissionApi, Permission } from '../../services/api'

export default function RolePage() {
  const [roles, setRoles] = useState<Role[]>([])
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [filteredRoles, setFilteredRoles] = useState<Role[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [showPermissionsModal, setShowPermissionsModal] = useState(false)
  const [editingRole, setEditingRole] = useState<Role | null>(null)
  const [selectedRole, setSelectedRole] = useState<Role | null>(null)
  const [formData, setFormData] = useState<RoleCreateRequest>({
    code: '',
    name: '',
    description: '',
    permissionIds: []
  })


  useEffect(() => {
    void loadData()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    filterRoles()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [roles, searchTerm])

  const createDefaultRolesIfNeeded = async (existingRoles: Role[] = []): Promise<Role[]> => {
    const defaultRoles: RoleCreateRequest[] = [
      {
        code: 'ADMIN',
        name: 'Admin',
        description: 'Rendszergazda - teljes hozzáférés'
      },
      {
        code: 'DEPOSITORY',
        name: 'Értéktáros',
        description: 'Értéktáros - értékek kezelése'
      },
      {
        code: 'TERRITORIAL_MANAGER',
        name: 'Területi vezető',
        description: 'Területi vezető - terület irányítása'
      },
      {
        code: 'CONTROLLER',
        name: 'Kontroller',
        description: 'Kontroller - ellenőrzési feladatok'
      },
      {
        code: 'CASHIER',
        name: 'Pénztáros',
        description: 'Pénztáros - pénztári műveletek'
      }
    ]

    try {
      let created = 0
      
      for (const roleData of defaultRoles) {
        try {
          // Ellenőrizzük, hogy már létezik-e a kóddal
          const existingRole = existingRoles.find(r => r.code === roleData.code)
          if (!existingRole) {
            await roleApi.create(roleData)
            created++
          }
        } catch (err) {
          // Ha már létezik, akkor kihagyjuk (várható hiba)
          console.debug('Szerepkör már létezik vagy nem hozható létre:', roleData.code, err)
        }
      }
      
      if (created > 0) {
        // Újratöltjük az adatokat
        const rolesData = await roleApi.list()
        return rolesData
      }

      return existingRoles
    } catch (err) {
      console.error('Alapértelmezett szerepkörök létrehozása sikertelen:', err)
      return existingRoles
    }
  }

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      const [rolesData, permissionsData] = await Promise.all([
        roleApi.list(),
        permissionApi.getActive()
      ])

      // Ha nincs szerepkör, automatikusan létrehozzuk az alapértelmezetteket
      let finalRolesData = rolesData
      if (rolesData.length === 0) {
        finalRolesData = await createDefaultRolesIfNeeded(rolesData)
      }

      setRoles(finalRolesData)
      setPermissions(permissionsData)
    } catch (err) {
      console.error('Szerepkörök betöltési hiba:', err)
      // Ha hiba van a betöltésnél, próbáljuk meg létrehozni az alapértelmezetteket
      try {
        const rolesData = await roleApi.list()
        if (rolesData.length === 0) {
          const createdRoles = await createDefaultRolesIfNeeded([])
          setRoles(createdRoles)
        } else {
          setRoles(rolesData)
        }
      } catch (innerErr) {
        console.error('Szerepkörök újratöltése sikertelen:', innerErr)
        setError('Hiba a szerepkörök betöltésekor')
      }
    } finally {
      setLoading(false)
    }
  }

  const filterRoles = () => {
    let filtered = roles

    if (searchTerm) {
      filtered = filtered.filter(r =>
        r.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.description?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }

    setFilteredRoles(filtered)
  }

  const handleCreateDefaultRoles = async () => {
    if (!confirm('Ez létrehozza az alapértelmezett munkaköröket (admin, értéktáros, területi vezető, kontroller, pénztáros). Folytassuk?')) {
      return
    }

    try {
      setLoading(true)
      setError(null)
      const updatedRoles = await createDefaultRolesIfNeeded(roles)
      setRoles(updatedRoles)

      const created = updatedRoles.filter(r =>
        ['ADMIN', 'DEPOSITORY', 'TERRITORIAL_MANAGER', 'CONTROLLER', 'CASHIER'].includes(r.code)
      ).length

      alert(`Alapértelmezett szerepkörök ellenőrizve. Összesen ${created} alapértelmezett szerepkör elérhető.`)
    } catch (err) {
      console.error('Alapértelmezett szerepkörök létrehozási hiba:', err)
      setError('Hiba történt az alapértelmezett szerepkörök létrehozása során')
    } finally {
      setLoading(false)
    }
  }

  const handleCreate = () => {
    setEditingRole(null)
    setFormData({
      code: '',
      name: '',
      description: '',
      permissionIds: []
    })
    setShowForm(true)
  }

  const handleEdit = (role: Role) => {
    setEditingRole(role)
    // Get permission IDs from permission names
    const permissionIds = permissions
      .filter(p => role.permissions?.includes(p.name))
      .map(p => p.id)
    setFormData({
      code: role.code,
      name: role.name,
      description: role.description || '',
      permissionIds: permissionIds
    })
    setShowForm(true)
  }

  const handleManagePermissions = (role: Role) => {
    setSelectedRole(role)
    setShowPermissionsModal(true)
  }

  const handleSave = async () => {
    try {
      setError(null)
      if (editingRole) {
        await roleApi.update(editingRole.id, formData)
      } else {
        await roleApi.create(formData)
      }
      await loadData()
      setShowForm(false)
      setEditingRole(null)
    } catch (err) {
      console.error('Szerepkör mentési hiba:', err)
      setError('Hiba történt a mentés során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törölni szeretné ezt a szerepkört?')) {
      return
    }

    try {
      setError(null)
      await roleApi.delete(id)
      await loadData()
    } catch (err) {
      console.error('Szerepkör törlési hiba:', err)
      setError('Hiba történt a törlés során')
    }
  }

  const handleToggleActive = async (id: string) => {
    try {
      setError(null)
      await roleApi.toggleActive(id)
      await loadData()
    } catch (err) {
      console.error('Szerepkör állapotváltási hiba:', err)
      setError('Hiba történt az állapotváltás során')
    }
  }

  const handleAddPermission = async (permissionId: string) => {
    if (!selectedRole) return

    try {
      setError(null)
      await roleApi.addPermission(selectedRole.id, permissionId)
      await loadData()
      const updatedRole = await roleApi.getById(selectedRole.id)
      setSelectedRole(updatedRole)
    } catch (err) {
      console.error('Jogosultság hozzáadási hiba:', err)
      setError('Hiba történt a jogosultság hozzáadása során')
    }
  }

  const handleRemovePermission = async (permissionId: string) => {
    if (!selectedRole) return

    try {
      setError(null)
      await roleApi.removePermission(selectedRole.id, permissionId)
      await loadData()
      const updatedRole = await roleApi.getById(selectedRole.id)
      setSelectedRole(updatedRole)
    } catch (err) {
      console.error('Jogosultság eltávolítási hiba:', err)
      setError('Hiba történt a jogosultság eltávolítása során')
    }
  }

  const groupedPermissions = permissions.reduce((acc, perm) => {
    if (!acc[perm.module]) {
      acc[perm.module] = []
    }
    acc[perm.module]?.push(perm)
    return acc
  }, {} as Record<string, Permission[]>)

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
          <Users />
          Szerepkörök
        </h1>
        <div className="flex gap-2">
          <button
            onClick={handleCreateDefaultRoles}
            className="form-button flex items-center gap-2"
            disabled={loading}
          >
            <Plus size={16} />
            Alapértelmezett munkakörök létrehozása
          </button>
          <button
            onClick={handleCreate}
            className="form-button-primary flex items-center gap-2"
          >
            <Plus size={16} />
            Új szerepkör
          </button>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Filters */}
      <div className="form-panel">
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
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingRole ? 'Szerepkör szerkesztése' : 'Új szerepkör'}
              </h2>
              <button
                onClick={() => {
                  setShowForm(false)
                  setEditingRole(null)
                }}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="form-label">Szerepkör kód *</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                  disabled={!!editingRole}
                  placeholder="pl: CASHIER"
                />
              </div>

              <div>
                <label className="form-label">Szerepkör név *</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="pl: Pénztáros"
                />
              </div>


              <div>
                <label className="form-label">Leírás</label>
                <textarea
                  className="form-input"
                  rows={3}
                  value={formData.description || ''}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Szerepkör leírása..."
                />
              </div>


              <div className="flex justify-end gap-2 pt-4 border-t">
                <button
                  onClick={() => {
                    setShowForm(false)
                    setEditingRole(null)
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

      {/* Permissions Modal */}
      {showPermissionsModal && selectedRole && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                Jogosultságok kezelése: {selectedRole.name}
              </h2>
              <button
                onClick={() => {
                  setShowPermissionsModal(false)
                  setSelectedRole(null)
                }}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>

            <div className="space-y-4">
              {Object.entries(groupedPermissions).map(([module, modulePermissions]) => (
                <div key={module} className="border rounded-lg p-4">
                  <h3 className="font-bold text-gray-700 mb-2">{module}</h3>
                  <div className="grid grid-cols-2 gap-2">
                    {modulePermissions.map(permission => {
                      // Backend returns permission names in the permissions array, not IDs
                      const hasPermission = selectedRole.permissions?.includes(permission.name) || false
                      return (
                        <div
                          key={permission.id}
                          className={`p-2 rounded border flex items-center justify-between ${
                            hasPermission ? 'bg-blue-50 border-blue-200' : 'bg-gray-50'
                          }`}
                        >
                          <div>
                            <div className="font-medium text-sm">{permission.name}</div>
                            <div className="text-xs text-gray-500">{permission.code}</div>
                          </div>
                          {hasPermission ? (
                            <button
                              onClick={() => handleRemovePermission(permission.id)}
                              className="text-red-600 hover:text-red-800"
                              title="Eltávolítás"
                            >
                              <X size={16} />
                            </button>
                          ) : (
                            <button
                              onClick={() => handleAddPermission(permission.id)}
                              className="text-green-600 hover:text-green-800"
                              title="Hozzáadás"
                            >
                              <Plus size={16} />
                            </button>
                          )}
                        </div>
                      )
                    })}
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-end gap-2 pt-4 border-t mt-4">
              <button
                onClick={() => {
                  setShowPermissionsModal(false)
                  setSelectedRole(null)
                }}
                className="form-button"
              >
                Bezárás
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Roles Table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Kód</th>
              <th>Név</th>
              <th>Típus</th>
              <th>Hierarchia</th>
              <th>Jogosultságok</th>
              <th>Típus</th>
              <th>Státusz</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filteredRoles.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">
                  Nincs találat
                </td>
              </tr>
            ) : (
              filteredRoles.map((role) => (
                <tr key={role.id}>
                  <td className="font-mono text-sm">{role.code}</td>
                  <td>{role.name}</td>
                  <td>
                    <span className="badge badge-blue">{role.roleType}</span>
                  </td>
                  <td>{role.hierarchyLevel || 0}</td>
                  <td>
                    <button
                      onClick={() => handleManagePermissions(role)}
                      className="text-blue-600 hover:text-blue-800 flex items-center gap-1"
                    >
                      <Shield size={14} />
                      {role.permissions?.length || 0} jogosultság
                    </button>
                  </td>
                  <td>
                    {role.isSystemRole ? (
                      <span className="badge badge-orange">Rendszer</span>
                    ) : (
                      <span className="badge badge-gray">Egyedi</span>
                    )}
                  </td>
                  <td>
                    <button
                      onClick={() => handleToggleActive(role.id)}
                      className={`badge ${role.isActive ? 'badge-green' : 'badge-red'}`}
                    >
                      {role.isActive ? 'Aktív' : 'Inaktív'}
                    </button>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleEdit(role)}
                        className="form-button text-sm flex items-center gap-1"
                      >
                        <Edit size={14} />
                        Szerkesztés
                      </button>
                      {!role.isSystemRole && (
                        <button
                          onClick={() => handleDelete(role.id)}
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

