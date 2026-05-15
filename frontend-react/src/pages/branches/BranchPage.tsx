import { useState, useEffect, useMemo } from 'react'
import { Building2, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { api } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'

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
  /** v2.5.1-E B6: ÉRTÉKTÁRI fiók-e (admin/foertektar állítja be). */
  isVault?: boolean
  vaultTerritoryId?: number | null
  // 2026-05-15 HIBA #2: kotelezo szervezeti mezok
  bankCode?: string
  zipCode?: string
  branchTypeId?: string
  branchTypeCode?: string
  countryId?: string
  branchStatusId?: string
  openingDate?: string
}

interface BranchForm {
  code: string
  name: string
  city: string
  address: string
  phone: string
  email: string
  // 2026-05-15 HIBA #2: a CreateBranchDto kotelezo mezoi a frontend-form-bol hianyoztak
  bankCode: string
  zipCode: string
  branchTypeId: string
  countryId: string
  branchStatusId: string
  openingDate: string
}

interface DictionaryEntry { id: string; code: string; name: string; nameHu?: string }

const emptyForm: BranchForm = {
  code: '', name: '', city: '', address: '', phone: '', email: '',
  bankCode: '', zipCode: '', branchTypeId: '', countryId: '', branchStatusId: '',
  openingDate: new Date().toISOString().slice(0, 10),
}

export default function BranchPage() {
  const { t } = useTranslation()
  const [branches, setBranches] = useState<Branch[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingBranch, setEditingBranch] = useState<Branch | null>(null)
  const [form, setForm] = useState<BranchForm>(emptyForm)
  const [saving, setSaving] = useState(false)
  // 2026-05-15 HIBA #2: dictionary dropdownok a DictionaryController-bol
  const [branchTypes, setBranchTypes] = useState<DictionaryEntry[]>([])
  const [countries, setCountries] = useState<DictionaryEntry[]>([])
  const [branchStatuses, setBranchStatuses] = useState<DictionaryEntry[]>([])

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
    // Dictionary dropdownok eloltese (HIBA #2 fix, 2026-05-15)
    void (async () => {
      try {
        const [types, ctry, status] = await Promise.all([
          api.get('/dictionaries/BRANCH_TYPE'),
          api.get('/dictionaries/COUNTRY'),
          api.get('/dictionaries/BRANCH_STATUS'),
        ])
        setBranchTypes(safeArray<DictionaryEntry>(types.data))
        setCountries(safeArray<DictionaryEntry>(ctry.data))
        setBranchStatuses(safeArray<DictionaryEntry>(status.data))
      } catch (err) {
        logger.warn('BranchPage', 'Dictionary load failed (form dropdowns may be empty)', err)
      }
    })()
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
      bankCode: b.bankCode ?? '',
      zipCode: b.zipCode ?? '',
      branchTypeId: b.branchTypeId ?? '',
      countryId: b.countryId ?? '',
      branchStatusId: b.branchStatusId ?? '',
      // Sourcery #611: NE alapertelmezzunk ma-i datumra szerkesztesnel, ha eredetileg
      // ures volt — kulonben silently felulirjuk a legacy/null DB-adatot.
      openingDate: b.openingDate ?? '',
    })
    setShowForm(true)
  }

  const handleSave = async () => {
    // 2026-05-15 HIBA #2: kotelezo mezok validalasa a CreateBranchDto szerint
    const missing: string[] = []
    if (!form.code.trim()) missing.push('Kód')
    if (!form.name.trim()) missing.push('Név')
    if (!form.bankCode.trim()) missing.push('Banki kód')
    if (!form.address.trim()) missing.push('Cím')
    if (!form.city.trim()) missing.push('Város')
    if (!/^\d{4}$/.test(form.zipCode)) missing.push('Irányítószám (4 számjegy)')
    if (!form.branchTypeId) missing.push('Iroda típusa')
    if (!form.countryId) missing.push('Ország')
    if (!form.branchStatusId) missing.push('Státusz')
    if (!form.openingDate) missing.push('Nyitás dátuma')
    if (missing.length > 0) {
      toast.warning('Hiányzó kötelező mezők', missing.join(', '))
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

  /**
   * v2.5.1-E B6: is_vault flag toggle.
   * Csak admin/foertektar/ugyvezeto használhatja (backend PreAuthorize).
   */
  const handleToggleVault = async (b: Branch) => {
    const next = !(b.isVault ?? false)
    try {
      await api.patch(`/branches/${b.id}/is-vault`, { isVault: next })
      toast.success(next ? `${b.code}: értéktárként megjelölve` : `${b.code}: pénztárként megjelölve`)
      await load()
    } catch (err) {
      toast.error('Hiba az is_vault frissítésekor', getErrorMessage(err))
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
          {t('branches.fiokok')}
        </h1>
        <button onClick={openCreate} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          {t('branches.ujFiok')}
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
          <div className="bg-white rounded-lg p-4 w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">{editingBranch ? 'Fiók szerkesztése' : 'Új fiók'}</h2>
              <button onClick={() => setShowForm(false)} className="text-gray-500 hover:text-gray-700">
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('common.codeRequired')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.code}
                    onChange={(e) => setForm({ ...form, code: e.target.value })}
                    disabled={!!editingBranch}
                  />
                </div>
                <div>
                  <label className="form-label">{t('common.nameRequired')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="form-label">{t('common.city')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={form.city}
                  onChange={(e) => setForm({ ...form, city: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">{t('common.address')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={form.address}
                  onChange={(e) => setForm({ ...form, address: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Irányítószám *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.zipCode}
                    pattern="\d{4}"
                    maxLength={4}
                    onChange={(e) => setForm({ ...form, zipCode: e.target.value.replace(/\D/g, '') })}
                  />
                </div>
                <div>
                  <label className="form-label">Banki kód *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.bankCode}
                    onChange={(e) => setForm({ ...form, bankCode: e.target.value })}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Iroda típusa *</label>
                  <select
                    className="form-input"
                    value={form.branchTypeId}
                    onChange={(e) => setForm({ ...form, branchTypeId: e.target.value })}
                  >
                    <option value="">— válassz —</option>
                    {branchTypes.map(t => (
                      <option key={t.id} value={t.id}>{t.nameHu || t.name} ({t.code})</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="form-label">Ország *</label>
                  <select
                    className="form-input"
                    value={form.countryId}
                    onChange={(e) => setForm({ ...form, countryId: e.target.value })}
                  >
                    <option value="">— válassz —</option>
                    {countries.map(c => (
                      <option key={c.id} value={c.id}>{c.nameHu || c.name}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Státusz *</label>
                  <select
                    className="form-input"
                    value={form.branchStatusId}
                    onChange={(e) => setForm({ ...form, branchStatusId: e.target.value })}
                  >
                    <option value="">— válassz —</option>
                    {branchStatuses.map(s => (
                      <option key={s.id} value={s.id}>{s.nameHu || s.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="form-label">Nyitás dátuma *</label>
                  <input
                    type="date"
                    className="form-input"
                    value={form.openingDate}
                    max={new Date().toISOString().slice(0, 10)}
                    onChange={(e) => setForm({ ...form, openingDate: e.target.value })}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('common.phone')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.phone}
                    onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">{t('common.email')}</label>
                  <input
                    type="email"
                    className="form-input"
                    value={form.email}
                    onChange={(e) => setForm({ ...form, email: e.target.value })}
                  />
                </div>
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button onClick={() => setShowForm(false)} className="form-button">{t('common.cancel')}</button>
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
              <th>{t('common.code')}</th>
              <th>{t('common.name')}</th>
              <th>{t('common.city')}</th>
              <th>{t('common.email')}</th>
              <th>{t('common.phone')}</th>
              <th>{t('common.status')}</th>
              <th>{t('branches.ertektar')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">{t('common.noResult')}</td>
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
                    <label className="inline-flex items-center gap-2 cursor-pointer" title="Értéktári fiók">
                      <input
                        type="checkbox"
                        checked={b.isVault ?? false}
                        onChange={() => void handleToggleVault(b)}
                        className="form-checkbox h-4 w-4"
                      />
                      <span className={`text-xs font-semibold ${b.isVault ? 'text-blue-700' : 'text-gray-400'}`}>
                        {b.isVault ? 'IGEN' : 'nem'}
                      </span>
                    </label>
                  </td>
                  <td>
                    <div className="flex gap-1 flex-wrap">
                      <button
                        onClick={() => openEdit(b)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Edit size={12} />
                        {t('common.edit')}
                      </button>
                      <button
                        onClick={() => handleDelete(b.id)}
                        className="form-button text-xs text-red-600 flex items-center gap-1"
                      >
                        <Trash2 size={12} />
                        {t('common.delete')}
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
