import { useState, useEffect, useMemo } from 'react'
import { Users, Plus, Edit, Search, X, Save, Power } from 'lucide-react'
import { api } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'

interface Worker {
  id: number
  workerCode: string
  firstName: string
  lastName: string
  fullName: string
  email?: string
  phone?: string
  branchId?: string
  branchName?: string
  isActive: boolean
  createdAt?: string
}

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
  const [workers, setWorkers] = useState<Worker[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingWorker, setEditingWorker] = useState<Worker | null>(null)
  const [form, setForm] = useState<WorkerForm>(emptyForm)
  const [saving, setSaving] = useState(false)

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

  const load = async () => {
    try {
      setLoading(true)
      setError(null)
      const res = await api.get('/workers')
      setWorkers(safeArray<Worker>(res.data))
    } catch (err) {
      logger.error('WorkerPage', 'load error', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

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
      await load()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const handleToggle = async (w: Worker) => {
    try {
      if (w.isActive) {
        await api.post(`/workers/${w.id}/deactivate`)
      } else {
        await api.post(`/workers/${w.id}/activate`)
      }
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
          <Users />
          Dolgozók
        </h1>
        <button onClick={openCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          Új dolgozó
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
            placeholder="Keresés névben, kódban, emailben..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingWorker ? 'Dolgozó szerkesztése' : 'Új dolgozó'}
              </h2>
              <button onClick={() => setShowForm(false)} className="text-gray-500 hover:text-gray-700">
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="form-label">Munkáskód *</label>
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
                  <label className="form-label">Keresztnév *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.firstName}
                    onChange={(e) => setForm({ ...form, firstName: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">Vezetéknév *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.lastName}
                    onChange={(e) => setForm({ ...form, lastName: e.target.value })}
                  />
                </div>
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
              <div>
                <label className="form-label">Telefon</label>
                <input
                  type="text"
                  className="form-input"
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                />
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button onClick={() => setShowForm(false)} className="form-button">
                  Mégse
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

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Kód</th>
              <th>Teljes név</th>
              <th>Email</th>
              <th>Telefon</th>
              <th>Fiók</th>
              <th>Státusz</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">
                  Nincs találat
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
                    <span className={`badge ${w.isActive ? 'badge-green' : 'badge-red'}`}>
                      {w.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-1 flex-wrap">
                      <button
                        onClick={() => openEdit(w)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Edit size={12} />
                        Szerkesztés
                      </button>
                      <button
                        onClick={() => handleToggle(w)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Power size={12} />
                        {w.isActive ? 'Deaktiválás' : 'Aktiválás'}
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
