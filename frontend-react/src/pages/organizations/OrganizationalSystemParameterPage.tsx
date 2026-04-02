import { useState, useEffect, useCallback } from 'react'
import { Settings, Plus, Edit2, Trash2, Search } from 'lucide-react'
import { organizationalSystemParameterApi, OrganizationalSystemParameter } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'

interface ParamForm {
  organizationName: string
  parameterKey: string
  parameterValue: string
  currencyCode: string
  validFrom: string
  validTo: string
  description: string
}

const emptyForm: ParamForm = { organizationName: '', parameterKey: '', parameterValue: '', currencyCode: '', validFrom: new Date().toISOString().slice(0, 10), validTo: '', description: '' }

export default function OrganizationalSystemParameterPage() {
  const [params, setParams] = useState<OrganizationalSystemParameter[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [form, setForm] = useState<ParamForm>(emptyForm)
  const [search, setSearch] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setParams(await organizationalSystemParameterApi.list())
    } catch (err) {
      logger.error('OrganizationalSystemParameterPage', 'Hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void loadData() }, [loadData])

  const handleSave = async () => {
    if (!form.parameterKey || !form.parameterValue) { toast.warning('Kulcs és érték kötelező'); return }
    try {
      setError(null)
      if (editingId) {
        await organizationalSystemParameterApi.update(editingId, form)
        toast.success('Paraméter frissítve')
      } else {
        await organizationalSystemParameterApi.create(form)
        toast.success('Paraméter létrehozva')
      }
      setShowForm(false)
      setEditingId(null)
      setForm(emptyForm)
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleEdit = (p: OrganizationalSystemParameter) => {
    setForm({
      organizationName: p.organizationName || '',
      parameterKey: p.parameterKey,
      parameterValue: p.parameterValue,
      currencyCode: p.currencyCode || '',
      validFrom: p.validFrom || '',
      validTo: p.validTo || '',
      description: p.description || '',
    })
    setEditingId(p.id)
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli a paramétert?')) return
    try {
      await organizationalSystemParameterApi.delete(id)
      toast.success('Paraméter törölve')
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const filtered = safeArray<OrganizationalSystemParameter>(params).filter(p => {
    if (!search) return true
    const s = search.toLowerCase()
    return (p.parameterKey?.toLowerCase().includes(s) || p.parameterValue?.toLowerCase().includes(s) || p.organizationName?.toLowerCase().includes(s))
  })

  // Group by organization
  const orgs = [...new Set(filtered.map(p => p.organizationName || 'Globális'))].sort()

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><Settings />Szervezeti rendszerparaméterek</h1>
        <button onClick={() => { setShowForm(true); setEditingId(null); setForm(emptyForm) }} className="form-button-primary"><Plus size={16} /> Új paraméter</button>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>}

      {showForm && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{editingId ? 'Paraméter szerkesztése' : 'Új paraméter'}</h2>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="form-label">Szervezet</label>
              <input className="form-input" value={form.organizationName} onChange={e => setForm({ ...form, organizationName: e.target.value })} placeholder="Üres = globális" />
            </div>
            <div>
              <label className="form-label">Kulcs *</label>
              <input className="form-input font-mono" value={form.parameterKey} onChange={e => setForm({ ...form, parameterKey: e.target.value })} placeholder="pl. MAX_TRANSACTION_AMOUNT" />
            </div>
            <div>
              <label className="form-label">Érték *</label>
              <input className="form-input" value={form.parameterValue} onChange={e => setForm({ ...form, parameterValue: e.target.value })} />
            </div>
            <div>
              <label className="form-label">Valuta</label>
              <input className="form-input" value={form.currencyCode} onChange={e => setForm({ ...form, currencyCode: e.target.value })} placeholder="pl. EUR" />
            </div>
            <div>
              <label className="form-label">Érvényes ettől</label>
              <input className="form-input" type="date" value={form.validFrom} onChange={e => setForm({ ...form, validFrom: e.target.value })} />
            </div>
            <div>
              <label className="form-label">Érvényes eddig</label>
              <input className="form-input" type="date" value={form.validTo} onChange={e => setForm({ ...form, validTo: e.target.value })} />
            </div>
          </div>
          <div>
            <label className="form-label">Leírás</label>
            <textarea className="form-input" rows={2} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleSave()} className="form-button-primary">Mentés</button>
            <button onClick={() => { setShowForm(false); setEditingId(null) }} className="form-button">Mégse</button>
          </div>
        </div>
      )}

      {/* Search */}
      <div className="form-panel flex gap-3 items-end">
        <div className="flex-1">
          <label className="form-label">Keresés</label>
          <div className="flex items-center gap-1">
            <Search size={16} className="text-gray-400" />
            <input className="form-input flex-1" value={search} onChange={e => setSearch(e.target.value)} placeholder="Kulcs, érték vagy szervezet..." />
          </div>
        </div>
        <span className="text-sm text-gray-500">{filtered.length} paraméter</span>
      </div>

      {/* Grouped tables */}
      {loading ? <div>Betöltés...</div> : filtered.length === 0 ? (
        <div className="form-panel text-center text-gray-500 py-4">Nincs paraméter</div>
      ) : orgs.map(org => (
        <div key={org} className="form-panel">
          <h2 className="font-semibold mb-2">{org}</h2>
          <table className="data-grid w-full">
            <thead><tr><th>Kulcs</th><th>Érték</th><th>Valuta</th><th>Érvényesség</th><th>Műveletek</th></tr></thead>
            <tbody>
              {filtered.filter(p => (p.organizationName || 'Globális') === org).map(p => (
                <tr key={p.id}>
                  <td className="font-mono text-sm">{p.parameterKey}</td>
                  <td>{p.parameterValue}</td>
                  <td>{p.currencyCode || '-'}</td>
                  <td className="text-sm">{p.validFrom} – {p.validTo || 'határozatlan'}</td>
                  <td>
                    <div className="flex gap-1">
                      <button onClick={() => handleEdit(p)} className="form-button text-xs"><Edit2 size={12} /></button>
                      <button onClick={() => void handleDelete(p.id)} className="form-button text-xs text-red-600"><Trash2 size={12} /></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ))}
    </div>
  )
}
