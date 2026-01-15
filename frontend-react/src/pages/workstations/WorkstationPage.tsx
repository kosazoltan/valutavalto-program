import { useState, useEffect } from 'react'
import { Monitor, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { workstationApi, Workstation, WorkstationCreateRequest } from '../../services/api'
import { getErrorMessage } from '../../utils/errorHandling'

export default function WorkstationPage() {
  const [workstations, setWorkstations] = useState<Workstation[]>([])
  const [filteredWorkstations, setFilteredWorkstations] = useState<Workstation[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingWorkstation, setEditingWorkstation] = useState<Workstation | null>(null)
  const [formData, setFormData] = useState<WorkstationCreateRequest>({
    code: '',
    name: '',
    workstationType: 'CASHIER',
    isActive: true
  })

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      await loadData()
    }

    load().catch(err => {
      if (mounted) {
        console.error('Failed to load workstations:', err)
      }
    })

    return () => {
      mounted = false
    }
  }, [])

  useEffect(() => {
    filterWorkstations()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [workstations, searchTerm])

  const loadData = async (): Promise<void> => {
    try {
      setLoading(true)
      const data = await workstationApi.list()
      setWorkstations(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      console.error('Failed to load workstations:', err)
      alert(`Hiba történt a betöltés során: ${errorMessage}`)
    } finally {
      setLoading(false)
    }
  }

  const filterWorkstations = () => {
    let filtered = workstations
    if (searchTerm) {
      filtered = filtered.filter(w =>
        w.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
        w.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        w.machineName?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }
    setFilteredWorkstations(filtered)
  }

  const handleCreate = () => {
    setEditingWorkstation(null)
    setFormData({
      code: '',
      name: '',
      workstationType: 'CASHIER',
      isActive: true
    })
    setShowForm(true)
  }

  const handleEdit = (workstation: Workstation) => {
    setEditingWorkstation(workstation)
    setFormData({
      code: workstation.code,
      name: workstation.name,
      branchId: workstation.branchId,
      machineName: workstation.machineName,
      ipAddress: workstation.ipAddress,
      macAddress: workstation.macAddress,
      workstationType: workstation.workstationType,
      softwareVersion: workstation.softwareVersion,
      isActive: workstation.isActive
    })
    setShowForm(true)
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
      alert(`Hiba történt a mentés során: ${errorMessage}`)
      console.error('Failed to save workstation:', err)
    }
  }

  const handleDelete = async (id: string): Promise<void> => {
    if (!confirm('Biztosan törölni szeretné ezt a munkaállomást?')) return
    try {
      await workstationApi.delete(id)
      await loadData()
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      alert(`Hiba történt a törlés során: ${errorMessage}`)
      console.error('Failed to delete workstation:', err)
    }
  }

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Monitor />
          Munkaállomások
        </h1>
        <button onClick={handleCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          Új munkaállomás
        </button>
      </div>

      <div className="form-panel">
        <div>
          <label className="form-label">Keresés</label>
          <div className="relative">
            <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
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
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingWorkstation ? 'Munkaállomás szerkesztése' : 'Új munkaállomás'}
              </h2>
              <button onClick={() => { setShowForm(false); setEditingWorkstation(null) }} className="text-gray-500">
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="form-label">Kód *</label>
                <input type="text" className="form-input" value={formData.code} onChange={(e) => setFormData({ ...formData, code: e.target.value })} />
              </div>
              <div>
                <label className="form-label">Név *</label>
                <input type="text" className="form-input" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} />
              </div>
              <div>
                <label className="form-label">Típus *</label>
                <select className="form-input" value={formData.workstationType} onChange={(e) => setFormData({ ...formData, workstationType: e.target.value })}>
                  <option value="CASHIER">Pénztár</option>
                  <option value="ADMIN">Admin</option>
                  <option value="POS">POS</option>
                </select>
              </div>
              <div>
                <label className="form-label">Gépnév</label>
                <input type="text" className="form-input" value={formData.machineName || ''} onChange={(e) => setFormData({ ...formData, machineName: e.target.value })} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">IP cím</label>
                  <input type="text" className="form-input" value={formData.ipAddress || ''} onChange={(e) => setFormData({ ...formData, ipAddress: e.target.value })} />
                </div>
                <div>
                  <label className="form-label">MAC cím</label>
                  <input type="text" className="form-input" value={formData.macAddress || ''} onChange={(e) => setFormData({ ...formData, macAddress: e.target.value })} />
                </div>
              </div>
              <div>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" checked={formData.isActive ?? true} onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })} />
                  <span>Aktív</span>
                </label>
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button onClick={() => { setShowForm(false); setEditingWorkstation(null) }} className="form-button">Mégse</button>
                <button onClick={handleSave} className="form-button-primary flex items-center gap-2"><Save size={16} />Mentés</button>
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
              <th>Típus</th>
              <th>Gépnév</th>
              <th>IP cím</th>
              <th>Online</th>
              <th>Státusz</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filteredWorkstations.length === 0 ? (
              <tr><td colSpan={8} className="text-center text-gray-500 py-4">Nincs találat</td></tr>
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
                      <button onClick={() => handleEdit(w)} className="form-button text-xs"><Edit size={12} />Szerkesztés</button>
                      <button onClick={() => handleDelete(w.id)} className="form-button text-xs text-red-600"><Trash2 size={12} />Törlés</button>
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

