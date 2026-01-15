import { useState, useEffect } from 'react'
import { Building, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { organizationApi, Organization } from '../../services/api'

export default function OrganizationPage() {
  const [organizations, setOrganizations] = useState<Organization[]>([])
  const [filteredOrganizations, setFilteredOrganizations] = useState<Organization[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingOrg, setEditingOrg] = useState<Organization | null>(null)
  const [formData, setFormData] = useState<Partial<Organization>>({
    code: '',
    name: '',
    description: '',
    isActive: true
  })

  useEffect(() => {
    void loadData()
  }, [])

  useEffect(() => {
    filterOrganizations()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [organizations, searchTerm])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await organizationApi.list()
      setOrganizations(data)
    } catch (err) {
      console.error('Szervezetek betöltési hiba:', err)
      setError('Hiba a szervezetek betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const filterOrganizations = () => {
    let filtered = organizations
    if (searchTerm) {
      filtered = filtered.filter(o =>
        o.code?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        o.name?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }
    setFilteredOrganizations(filtered)
  }

  const handleCreate = () => {
    setEditingOrg(null)
    setFormData({ code: '', name: '', description: '', isActive: true })
    setShowForm(true)
  }

  const handleEdit = (org: Organization) => {
    setEditingOrg(org)
    setFormData(org)
    setShowForm(true)
  }

  const handleSave = async () => {
    try {
      setError(null)
      // TODO: Get current user ID
      const workerId = 'current-user-id'
      if (editingOrg) {
        await organizationApi.update(editingOrg.id, formData)
      } else {
        await organizationApi.create(formData, workerId)
      }
      await loadData()
      setShowForm(false)
      setEditingOrg(null)
    } catch (err) {
      console.error('Mentési hiba:', err)
      setError('Hiba történt a mentés során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törölni szeretné ezt a szervezetet?')) return
    try {
      setError(null)
      await organizationApi.delete(id)
      await loadData()
    } catch (err) {
      console.error('Törlési hiba:', err)
      setError('Hiba történt a törlés során')
    }
  }

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building />
          Szervezetek
        </h1>
        <button type="button" onClick={handleCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          Új szervezet
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
        <div>
          <label className="form-label">Keresés</label>
          <div className="relative">
            <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
            <input type="text" className="form-input pl-8" placeholder="Kód vagy név..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">{editingOrg ? 'Szervezet szerkesztése' : 'Új szervezet'}</h2>
              <button type="button" onClick={() => { setShowForm(false); setEditingOrg(null) }} className="text-gray-500"><X size={20} /></button>
            </div>
            <div className="space-y-4">
              <div><label className="form-label">Kód *</label><input type="text" className="form-input" value={formData.code} onChange={(e) => setFormData({ ...formData, code: e.target.value })} /></div>
              <div><label className="form-label">Név *</label><input type="text" className="form-input" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} /></div>
              <div><label className="form-label">Leírás</label><textarea className="form-input" rows={3} value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} /></div>
              <div><label className="flex items-center gap-2"><input type="checkbox" className="rounded" checked={formData.isActive ?? true} onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })} /><span>Aktív</span></label></div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button type="button" onClick={() => { setShowForm(false); setEditingOrg(null) }} className="form-button">Mégse</button>
                <button type="button" onClick={handleSave} className="form-button-primary flex items-center gap-2"><Save size={16} />Mentés</button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr><th>Kód</th><th>Név</th><th>Szülő</th><th>Státusz</th><th>Műveletek</th></tr>
          </thead>
          <tbody>
            {filteredOrganizations.length === 0 ? (
              <tr><td colSpan={5} className="text-center text-gray-500 py-4">Nincs találat</td></tr>
            ) : (
              filteredOrganizations.map((o) => (
                <tr key={o.id}>
                  <td className="font-mono text-sm">{o.code}</td>
                  <td>{o.name}</td>
                  <td>{o.parentName || '-'}</td>
                  <td><span className={`badge ${o.isActive ? 'badge-green' : 'badge-red'}`}>{o.isActive ? 'Aktív' : 'Inaktív'}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button type="button" onClick={() => handleEdit(o)} className="form-button text-xs"><Edit size={12} />Szerkesztés</button>
                      <button type="button" onClick={() => handleDelete(o.id)} className="form-button text-xs text-red-600"><Trash2 size={12} />Törlés</button>
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

