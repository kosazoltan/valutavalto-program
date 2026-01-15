import { useState, useEffect } from 'react'
import { Users, Plus, Edit, Trash2, Search, X, Save, Key } from 'lucide-react'
import { userApi, UserDetail, UserCreateRequest, UserUpdateRequest, roleApi, Role } from '../../services/api'

export default function UserPage() {
  const [users, setUsers] = useState<UserDetail[]>([])
  const [roles, setRoles] = useState<Role[]>([])
  const [filteredUsers, setFilteredUsers] = useState<UserDetail[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [showPasswordModal, setShowPasswordModal] = useState(false)
  const [editingUser, setEditingUser] = useState<UserDetail | null>(null)
  const [selectedUser, setSelectedUser] = useState<UserDetail | null>(null)
  const [newPassword, setNewPassword] = useState('')
  const [formData, setFormData] = useState<UserCreateRequest>({
    username: '',
    email: '',
    password: '',
    fullName: '',
    roleId: '',
    branchId: ''
  })

  useEffect(() => {
    void loadData()
  }, [])

  useEffect(() => {
    filterUsers()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [users, searchTerm])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      const [usersData, rolesData] = await Promise.all([
        userApi.list(),
        roleApi.list()
      ])
      setUsers(usersData)
      setRoles(rolesData.filter(r => r.isActive))
    } catch (err) {
      console.error('Felhasználók betöltési hiba:', err)
      setError('Hiba a felhasználók betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const filterUsers = () => {
    let filtered = users

    if (searchTerm) {
      filtered = filtered.filter(u =>
        u.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.email?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }

    setFilteredUsers(filtered)
  }

  const handleCreate = () => {
    setEditingUser(null)
    setFormData({
      username: '',
      email: '',
      password: '',
      fullName: '',
      roleId: '',
      branchId: ''
    })
    setShowForm(true)
  }

  const handleEdit = (user: UserDetail) => {
    setEditingUser(user)
    setFormData({
      username: user.username,
      email: user.email || '',
      password: '',
      fullName: user.name || '',
      roleId: user.roles?.[0] || '', // Backend uses single roleId
      branchId: user.defaultBranchId || ''
    })
    setShowForm(true)
  }

  const handleChangePassword = (user: UserDetail) => {
    setSelectedUser(user)
    setNewPassword('')
    setShowPasswordModal(true)
  }

  const handleSave = async () => {
    // Validáció
    if (!editingUser) {
      // Új felhasználó validáció
      if (!formData.username || !formData.username.trim()) {
        alert('A felhasználónév megadása kötelező!')
        return
      }
      if (!formData.password || formData.password.length < 8) {
        alert('A jelszónak minimum 8 karakternek kell lennie!')
        return
      }
      if (!formData.email || !formData.email.trim()) {
        alert('Az email megadása kötelező!')
        return
      }
      // Email formátum ellenőrzése
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRegex.test(formData.email)) {
        alert('Kérjük, adjon meg egy érvényes email címet!')
        return
      }
    } else {
      // Szerkesztés validáció
      if (!formData.email || !formData.email.trim()) {
        alert('Az email megadása kötelező!')
        return
      }
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRegex.test(formData.email)) {
        alert('Kérjük, adjon meg egy érvényes email címet!')
        return
      }
    }

    try {
      if (editingUser) {
        const updateData: UserUpdateRequest = {
          email: formData.email.trim(),
          fullName: formData.fullName?.trim() || undefined,
          roleId: formData.roleId || undefined,
          branchId: formData.branchId || undefined
        }
        await userApi.update(editingUser.id, updateData)
        alert('Felhasználó sikeresen frissítve!')
      } else {
        const createData: UserCreateRequest = {
          username: formData.username.trim(),
          email: formData.email.trim(),
          password: formData.password,
          fullName: formData.fullName?.trim() || undefined,
          roleId: formData.roleId || undefined,
          branchId: formData.branchId || undefined
        }
        await userApi.create(createData)
        alert('Felhasználó sikeresen létrehozva!')
      }
      await loadData()
      setShowForm(false)
      setEditingUser(null)
    } catch (error: unknown) {
      const errorMessage = error instanceof Error && 'response' in error && 
                          typeof error.response === 'object' && error.response !== null &&
                          'data' in error.response && 
                          typeof error.response.data === 'object' && error.response.data !== null
                          ? ('message' in error.response.data && typeof error.response.data.message === 'string' 
                             ? error.response.data.message 
                             : 'error' in error.response.data && typeof error.response.data.error === 'string'
                             ? error.response.data.error
                             : 'Hiba történt a mentés során')
                          : error instanceof Error ? error.message : 'Hiba történt a mentés során'
      alert(`Hiba: ${errorMessage}`)
    }
  }

  const handleSavePassword = async () => {
    if (!selectedUser || !newPassword) {
      alert('Kérjük, adja meg az új jelszót')
      return
    }

    try {
      setError(null)
      await userApi.changePassword(selectedUser.id, newPassword)
      setShowPasswordModal(false)
      setSelectedUser(null)
      setNewPassword('')
      alert('Jelszó sikeresen megváltoztatva')
    } catch (err) {
      console.error('Jelszó módosítási hiba:', err)
      setError('Hiba történt a jelszó módosítása során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törölni szeretné ezt a felhasználót?')) {
      return
    }

    try {
      setError(null)
      await userApi.delete(id)
      await loadData()
    } catch (err) {
      console.error('Felhasználó törlési hiba:', err)
      setError('Hiba történt a törlés során')
    }
  }

  const handleToggleActive = async (id: string) => {
    try {
      setError(null)
      await userApi.toggleActive(id)
      await loadData()
    } catch (err) {
      console.error('Felhasználó állapotváltási hiba:', err)
      setError('Hiba történt az állapotváltás során')
    }
  }

  const handleArchive = async (id: string) => {
    if (!confirm('Biztosan archiválni szeretné ezt a felhasználót?')) {
      return
    }

    try {
      setError(null)
      await userApi.archive(id)
      await loadData()
    } catch (err) {
      console.error('Felhasználó archiválási hiba:', err)
      setError('Hiba történt az archiválás során')
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
          <Users />
          Felhasználók
        </h1>
        <button
          onClick={handleCreate}
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          Új felhasználó
        </button>
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
              placeholder="Felhasználónév, név vagy email..."
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
                {editingUser ? 'Felhasználó szerkesztése' : 'Új felhasználó'}
              </h2>
              <button
                onClick={() => {
                  setShowForm(false)
                  setEditingUser(null)
                }}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="form-label">Felhasználónév *</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.username}
                  onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                  disabled={!!editingUser}
                  placeholder="pl: janos.kovacs"
                />
              </div>

              {!editingUser && (
                <div>
                  <label className="form-label">Jelszó *</label>
                  <input
                    type="password"
                    className="form-input"
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    placeholder="Minimum 8 karakter"
                  />
                </div>
              )}

              <div>
                <label className="form-label">Teljes név</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.fullName}
                  onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                  placeholder="pl: Kovács János"
                />
              </div>

              <div>
                <label className="form-label">Email *</label>
                <input
                  type="email"
                  className="form-input"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  placeholder="pl: janos.kovacs@example.com"
                />
              </div>

              <div>
                <label className="form-label">Szerepkör</label>
                <select
                  className="form-input"
                  value={formData.roleId}
                  onChange={(e) => setFormData({ ...formData, roleId: e.target.value })}
                >
                  <option value="">Nincs szerepkör</option>
                  {roles.map(role => (
                    <option key={role.id} value={role.id}>{role.name}</option>
                  ))}
                </select>
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t">
                <button
                  onClick={() => {
                    setShowForm(false)
                    setEditingUser(null)
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

      {/* Password Change Modal */}
      {showPasswordModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                Jelszó megváltoztatása: {selectedUser.username}
              </h2>
              <button
                onClick={() => {
                  setShowPasswordModal(false)
                  setSelectedUser(null)
                  setNewPassword('')
                }}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="form-label">Új jelszó *</label>
                <input
                  type="password"
                  className="form-input"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Minimum 8 karakter"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t">
                <button
                  onClick={() => {
                    setShowPasswordModal(false)
                    setSelectedUser(null)
                    setNewPassword('')
                  }}
                  className="form-button"
                >
                  Mégse
                </button>
                <button
                  onClick={handleSavePassword}
                  className="form-button-primary flex items-center gap-2"
                >
                  <Key size={16} />
                  Mentés
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Users Table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Felhasználónév</th>
              <th>Név</th>
              <th>Email</th>
              <th>Szerepkörök</th>
              <th>Alapértelmezett fiók</th>
              <th>Státusz</th>
              <th>Utolsó belépés</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">
                  Nincs találat
                </td>
              </tr>
            ) : (
              filteredUsers.map((user) => (
                <tr key={user.id}>
                  <td className="font-mono text-sm">{user.username}</td>
                  <td>{user.name || '-'}</td>
                  <td>{user.email || '-'}</td>
                  <td>
                    {user.roles && user.roles.length > 0 ? (
                      <div className="flex flex-wrap gap-1">
                        {user.roles.map((role, idx) => (
                          <span key={idx} className="badge badge-blue text-xs">{role}</span>
                        ))}
                      </div>
                    ) : (
                      '-'
                    )}
                  </td>
                  <td>{user.defaultBranchName || '-'}</td>
                  <td>
                    <div className="flex gap-1">
                      <button
                        onClick={() => handleToggleActive(user.id)}
                        className={`badge ${user.isActive ? 'badge-green' : 'badge-red'}`}
                      >
                        {user.isActive ? 'Aktív' : 'Inaktív'}
                      </button>
                      {user.isLocked && (
                        <span className="badge badge-orange">Zárolt</span>
                      )}
                    </div>
                  </td>
                  <td className="text-sm">
                    {user.lastLoginAt ? new Date(user.lastLoginAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td>
                    <div className="flex gap-1 flex-wrap">
                      <button
                        onClick={() => handleEdit(user)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Edit size={12} />
                        Szerkesztés
                      </button>
                      <button
                        onClick={() => handleChangePassword(user)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Key size={12} />
                        Jelszó
                      </button>
                      <button
                        onClick={() => handleArchive(user.id)}
                        className="form-button text-xs text-orange-600 flex items-center gap-1"
                      >
                        Archiválás
                      </button>
                      <button
                        onClick={() => handleDelete(user.id)}
                        className="form-button text-xs text-red-600 flex items-center gap-1"
                      >
                        <Trash2 size={12} />
                        Törlés
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

