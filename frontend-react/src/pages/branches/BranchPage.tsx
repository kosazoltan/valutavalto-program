import { useState, useEffect, useMemo } from 'react'
import { Building2, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { api } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'

interface Branch {
  id: string
  code: string
  name: string
  city?: string
  address?: string
  phone?: string
  email?: string
  companyId?: string
  companyName?: string
  isActive: boolean
}

interface BranchForm {
  code: string
  name: string
  city: string
  address: string
  phone: string
  email: string
}

const emptyForm: BranchForm = { code: '', name: '', city: '', address: '', phone: '', email: '' }

export default function BranchPage() {
  const [branches, setBranches] = useState<Branch[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingBranch, setEditingBranch] = useState<Branch | null>(null)
  const [form, setForm] = useState<BranchForm>(emptyForm)
  const [saving, setSaving] = useState(false)

  const filtered = useMemo(() => {
    if (!searchTerm) return branches
    const t = searchTerm.toLowerCase()
    return branches.filter(
      (b) =>
        b.name.toLowerCase().includes(t) ||
        b.code.toLowerCase().includes(t) ||
        (b.city ?? '').toLowerCase().includes(t),
    )
  }, [branches, searchTerm])

  const load = async () => {
    try {
      setLoading(true)
      setError(null)
      const res = await api.get('/branches')
      setBranches(safeArray<Branch>(res.data))
    } catch (err) {
      logger.error('BranchPage', 'load error', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const openCreate = () => {
    setEditingBranch(null)
    setForm(emptyForm)
    setShowForm(true)
  }

  const openEdit = (b: Branch) => {
    setEditingBranch(b)
    setForm({
      code: b.code,
      name: b.name,
      city: b.city ?? '',
      address: b.address ?? '',
      phone: b.phone ?? '',
      email: b.email ?? '',
    })
    setShowForm(true)
  }

  const handleSave = async () => {
    if (!form.code.trim() || !form.name.trim()) {
      toast.warning('Hiányzó adat', 'Kód és név kötelező!')
      return
    }
    try {
      setSaving(true)
      if (editingBranch) {
        await api.put(`/branches/${editingBranch.id}`, form)
        toast.success('Fiók sikeresen módosítva!')
      } else {
        await api.post('/branches', form)
        toast.success('Fiók sikeresen létrehozva!')
      }
      setShowForm(false)
      await load()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli ezt a fiókot?')) return
    try {
      await api.delete(`/branches/${id}`)
      toast.success('Fiók törölve!')
      await load()
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
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building2 />
          Fiókok
        </h1>
        <button onClick={openCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          Új fiók
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      <div className="form-panel">
        <div className="relative">
          <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
          <input
            type="text"
            className="form-input pl-8"
            placeholder="Keresés névben, kódban, városban..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">{editingBranch ? 'Fiók szerkesztése' : 'Új fiók'}</h2>
              <button onClick={() => setShowForm(false)} className="text-gray-500 hover:text-gray-700">
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Kód *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.code}
                    onChange={(e) => setForm({ ...form, code: e.target.value })}
                    disabled={!!editingBranch}
                  />
                </div>
                <div>
                  <label className="form-label">Név *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="form-label">Város</label>
                <input
                  type="text"
                  className="form-input"
                  value={form.city}
                  onChange={(e) => setForm({ ...form, city: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">Cím</label>
                <input
                  type="text"
                  className="form-input"
                  value={form.address}
                  onChange={(e) => setForm({ ...form, address: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Telefon</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.phone}
                    onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">Email</label>
                  <input
                    type="email"
                    className="form-input"
                    value={form.email}
                    onChange={(e) => setForm({ ...form, email: e.target.value })}
                  />
                </div>
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button onClick={() => setShowForm(false)} className="form-button">Mégse</button>
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

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Kód</th>
              <th>Név</th>
              <th>Város</th>
              <th>Email</th>
              <th>Telefon</th>
              <th>Státusz</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">Nincs találat</td>
              </tr>
            ) : (
              filtered.map((b) => (
                <tr key={b.id}>
                  <td className="font-mono text-sm">{b.code}</td>
                  <td>{b.name}</td>
                  <td>{b.city ?? '-'}</td>
                  <td>{b.email ?? '-'}</td>
                  <td>{b.phone ?? '-'}</td>
                  <td>
                    <span className={`badge ${b.isActive ? 'badge-green' : 'badge-red'}`}>
                      {b.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-1 flex-wrap">
                      <button
                        onClick={() => openEdit(b)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Edit size={12} />
                        Szerkesztés
                      </button>
                      <button
                        onClick={() => handleDelete(b.id)}
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
