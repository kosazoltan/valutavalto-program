import { useState, useEffect } from 'react'
import { Building, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { ownCompanyApi, OwnCompany } from '../../services/api'

export default function OwnCompanyPage() {
  const [companies, setCompanies] = useState<OwnCompany[]>([])
  const [filteredCompanies, setFilteredCompanies] = useState<OwnCompany[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingCompany, setEditingCompany] = useState<OwnCompany | null>(null)
  const [formData, setFormData] = useState<Partial<OwnCompany>>({
    name: '',
    taxNumber: '',
    registrationNumber: '',
    address: '',
    phone: '',
    email: '',
    bankAccountNumber: '',
    iban: '',
    swift: '',
    licenseNumber: '',
    isActive: true
  })

  useEffect(() => {
    void loadData()
  }, [])

  useEffect(() => {
    filterCompanies()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [companies, searchTerm])

  const loadData = async () => {
    try {
      setLoading(true)
      const data = await ownCompanyApi.list()
      setCompanies(data)
    } catch (error) {
      console.error('Hiba az adatok betöltésekor:', error)
    } finally {
      setLoading(false)
    }
  }

  const filterCompanies = () => {
    let filtered = companies
    if (searchTerm) {
      filtered = filtered.filter(c =>
        c.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.taxNumber?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }
    setFilteredCompanies(filtered)
  }

  const handleCreate = () => {
    setEditingCompany(null)
    setFormData({ name: '', taxNumber: '', registrationNumber: '', address: '', phone: '', email: '', bankAccountNumber: '', iban: '', swift: '', licenseNumber: '', isActive: true })
    setShowForm(true)
  }

  const handleEdit = (company: OwnCompany) => {
    setEditingCompany(company)
    setFormData(company)
    setShowForm(true)
  }

  const handleSave = async () => {
    try {
      if (editingCompany) {
        await ownCompanyApi.update(editingCompany.id, formData)
      } else {
        await ownCompanyApi.create(formData)
      }
      await loadData()
      setShowForm(false)
      setEditingCompany(null)
    } catch (error) {
      console.error('Hiba a mentéskor:', error)
      alert('Hiba történt a mentés során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törölni szeretné ezt a céget?')) return
    try {
      await ownCompanyApi.delete(id)
      await loadData()
    } catch (error) {
      console.error('Hiba a törléskor:', error)
      alert('Hiba történt a törlés során')
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
          Saját Cégek
        </h1>
        <button onClick={handleCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          Új cég
        </button>
      </div>

      <div className="form-panel">
        <div>
          <label className="form-label">Keresés</label>
          <div className="relative">
            <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
            <input type="text" className="form-input pl-8" placeholder="Név vagy adószám..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-3xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">{editingCompany ? 'Cég szerkesztése' : 'Új cég'}</h2>
              <button onClick={() => { setShowForm(false); setEditingCompany(null) }} className="text-gray-500"><X size={20} /></button>
            </div>
            <div className="space-y-4">
              <div><label className="form-label">Név *</label><input type="text" className="form-input" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} /></div>
              <div className="grid grid-cols-2 gap-4">
                <div><label className="form-label">Adószám</label><input type="text" className="form-input" value={formData.taxNumber || ''} onChange={(e) => setFormData({ ...formData, taxNumber: e.target.value })} /></div>
                <div><label className="form-label">Cégjegyzékszám</label><input type="text" className="form-input" value={formData.registrationNumber || ''} onChange={(e) => setFormData({ ...formData, registrationNumber: e.target.value })} /></div>
              </div>
              <div><label className="form-label">Cím</label><input type="text" className="form-input" value={formData.address || ''} onChange={(e) => setFormData({ ...formData, address: e.target.value })} /></div>
              <div className="grid grid-cols-2 gap-4">
                <div><label className="form-label">Telefon</label><input type="text" className="form-input" value={formData.phone || ''} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} /></div>
                <div><label className="form-label">Email</label><input type="email" className="form-input" value={formData.email || ''} onChange={(e) => setFormData({ ...formData, email: e.target.value })} /></div>
              </div>
              <div><label className="form-label">Számlaszám</label><input type="text" className="form-input" value={formData.bankAccountNumber || ''} onChange={(e) => setFormData({ ...formData, bankAccountNumber: e.target.value })} /></div>
              <div className="grid grid-cols-2 gap-4">
                <div><label className="form-label">IBAN</label><input type="text" className="form-input" value={formData.iban || ''} onChange={(e) => setFormData({ ...formData, iban: e.target.value })} /></div>
                <div><label className="form-label">SWIFT</label><input type="text" className="form-input" value={formData.swift || ''} onChange={(e) => setFormData({ ...formData, swift: e.target.value })} /></div>
              </div>
              <div><label className="form-label">Engedély szám</label><input type="text" className="form-input" value={formData.licenseNumber || ''} onChange={(e) => setFormData({ ...formData, licenseNumber: e.target.value })} /></div>
              <div><label className="flex items-center gap-2"><input type="checkbox" className="rounded" checked={formData.isActive ?? true} onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })} /><span>Aktív</span></label></div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button onClick={() => { setShowForm(false); setEditingCompany(null) }} className="form-button">Mégse</button>
                <button onClick={handleSave} className="form-button-primary flex items-center gap-2"><Save size={16} />Mentés</button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr><th>Név</th><th>Adószám</th><th>Cégjegyzékszám</th><th>Email</th><th>Telefon</th><th>Státusz</th><th>Műveletek</th></tr>
          </thead>
          <tbody>
            {filteredCompanies.length === 0 ? (
              <tr><td colSpan={7} className="text-center text-gray-500 py-4">Nincs találat</td></tr>
            ) : (
              filteredCompanies.map((c) => (
                <tr key={c.id}>
                  <td>{c.name}</td>
                  <td>{c.taxNumber || '-'}</td>
                  <td>{c.registrationNumber || '-'}</td>
                  <td>{c.email || '-'}</td>
                  <td>{c.phone || '-'}</td>
                  <td><span className={`badge ${c.isActive ? 'badge-green' : 'badge-red'}`}>{c.isActive ? 'Aktív' : 'Inaktív'}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button onClick={() => handleEdit(c)} className="form-button text-xs"><Edit size={12} />Szerkesztés</button>
                      <button onClick={() => handleDelete(c.id)} className="form-button text-xs text-red-600"><Trash2 size={12} />Törlés</button>
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

