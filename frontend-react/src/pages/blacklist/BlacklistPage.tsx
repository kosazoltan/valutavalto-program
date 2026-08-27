import { useState, useEffect, useCallback } from 'react'
import { Ban, Upload, Plus, Edit2, Trash2, Search, Shield, AlertTriangle } from 'lucide-react'
import { blacklistApi, ProhibitedPerson, ProhibitedCompany } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

type Tab = 'persons' | 'companies'

interface PersonForm {
  fullName: string
  documentNumber: string
  identityNumber: string
  passportNumber: string
  dateOfBirth: string
  nationality: string
  listType: string
  listSource: string
  reason: string
}

interface CompanyForm {
  companyName: string
  taxNumber: string
  registrationNumber: string
  listType: string
  listSource: string
  reason: string
}

const emptyPersonForm: PersonForm = {
  fullName: '',
  documentNumber: '',
  identityNumber: '',
  passportNumber: '',
  dateOfBirth: '',
  nationality: '',
  listType: 'INTERNAL',
  listSource: 'MANUAL',
  reason: '',
}
const emptyCompanyForm: CompanyForm = {
  companyName: '',
  taxNumber: '',
  registrationNumber: '',
  listType: 'INTERNAL',
  listSource: 'MANUAL',
  reason: '',
}

const LIST_TYPES = [
  { value: 'INTERNAL', label: 'Belső tiltólista' },
  { value: 'EU_SANCTIONS', label: 'EU szankciós lista' },
  { value: 'UN_SANCTIONS', label: 'ENSZ szankciós lista' },
  { value: 'OFAC', label: 'OFAC (USA)' },
  { value: 'NATIONAL', label: 'Nemzeti lista' },
  { value: 'OTHER', label: 'Egyéb' },
]

export default function BlacklistPage() {
  const { t } = useTranslation()
  const [activeTab, setActiveTab] = useState<Tab>('persons')
  const [persons, setPersons] = useState<ProhibitedPerson[]>([])
  const [companies, setCompanies] = useState<ProhibitedCompany[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showPersonForm, setShowPersonForm] = useState(false)
  const [showCompanyForm, setShowCompanyForm] = useState(false)
  const [editingPersonId, setEditingPersonId] = useState<string | null>(null)
  const [editingCompanyId, setEditingCompanyId] = useState<string | null>(null)
  const [personForm, setPersonForm] = useState<PersonForm>(emptyPersonForm)
  const [companyForm, setCompanyForm] = useState<CompanyForm>(emptyCompanyForm)
  const [saving, setSaving] = useState(false)
  const [stats, setStats] = useState({
    totalPersons: 0,
    totalCompanies: 0,
    activePersons: 0,
    activeCompanies: 0,
  })

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [p, c] = await Promise.all([
        blacklistApi.getPersons().catch(() => [] as ProhibitedPerson[]),
        blacklistApi.getCompanies().catch(() => [] as ProhibitedCompany[]),
      ])
      setPersons(p)
      setCompanies(c)
      setStats({
        totalPersons: p.length,
        totalCompanies: c.length,
        activePersons: p.filter((x) => x.isActive).length,
        activeCompanies: c.filter((x) => x.isActive).length,
      })
    } catch (err) {
      logger.error('BlacklistPage', 'Tiltólista betöltési hiba:', err)
      setError('Hiba a tiltólista betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  // --- Person CRUD ---
  const handleSavePerson = async () => {
    if (!personForm.fullName) {
      toast.warning('Hiányzó adat', 'Név megadása kötelező')
      return
    }
    try {
      setSaving(true)
      setError(null)
      if (editingPersonId) {
        await blacklistApi.updatePerson(editingPersonId, personForm)
        toast.success('Személy frissítve')
      } else {
        await blacklistApi.createPerson(personForm)
        toast.success('Személy hozzáadva a tiltólistához')
      }
      setShowPersonForm(false)
      setEditingPersonId(null)
      setPersonForm(emptyPersonForm)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      toast.error('Hiba', msg)
    } finally {
      setSaving(false)
    }
  }

  const handleEditPerson = (person: ProhibitedPerson) => {
    setEditingPersonId(person.id)
    setPersonForm({
      fullName: person.fullName,
      documentNumber: person.documentNumber || '',
      identityNumber: person.identityNumber || '',
      passportNumber: person.passportNumber || '',
      dateOfBirth: person.dateOfBirth || '',
      nationality: person.nationality || '',
      listType: person.listType,
      listSource: person.listSource,
      reason: person.reason || '',
    })
    setShowPersonForm(true)
  }

  const handleDeletePerson = async (id: string) => {
    if (!confirm('Biztosan törli ezt a személyt a tiltólistáról?')) return
    try {
      setError(null)
      await blacklistApi.deletePerson(id)
      toast.success('Személy törölve')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  // --- Company CRUD ---
  const handleSaveCompany = async () => {
    if (!companyForm.companyName) {
      toast.warning('Hiányzó adat', 'Cégnév megadása kötelező')
      return
    }
    try {
      setSaving(true)
      setError(null)
      if (editingCompanyId) {
        await blacklistApi.updateCompany(editingCompanyId, companyForm)
        toast.success('Cég frissítve')
      } else {
        await blacklistApi.createCompany(companyForm)
        toast.success('Cég hozzáadva a tiltólistához')
      }
      setShowCompanyForm(false)
      setEditingCompanyId(null)
      setCompanyForm(emptyCompanyForm)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      toast.error('Hiba', msg)
    } finally {
      setSaving(false)
    }
  }

  const handleEditCompany = (company: ProhibitedCompany) => {
    setEditingCompanyId(company.id)
    setCompanyForm({
      companyName: company.companyName,
      taxNumber: company.taxNumber || '',
      registrationNumber: company.registrationNumber || '',
      listType: company.listType,
      listSource: company.listSource,
      reason: company.reason || '',
    })
    setShowCompanyForm(true)
  }

  const handleDeleteCompany = async (id: string) => {
    if (!confirm('Biztosan törli ezt a céget a tiltólistáról?')) return
    try {
      setError(null)
      await blacklistApi.deleteCompany(id)
      toast.success('Cég törölve')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  // --- Import ---
  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    try {
      setError(null)
      if (activeTab === 'persons') {
        await blacklistApi.importPersons(file)
      } else {
        await blacklistApi.importCompanies(file)
      }
      await loadData()
      toast.success('Importálás sikeres')
    } catch (err) {
      logger.error('BlacklistPage', 'Importálási hiba:', err)
      setError('Hiba az importálásnál. Kérjük ellenőrizze a fájl formátumát.')
    }
    e.target.value = ''
  }

  // --- Filter ---
  const filteredPersons = persons.filter(
    (p) =>
      !searchTerm ||
      p.fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (p.documentNumber || '').toLowerCase().includes(searchTerm.toLowerCase()),
  )
  const filteredCompanies = companies.filter(
    (c) =>
      !searchTerm ||
      c.companyName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (c.taxNumber || '').toLowerCase().includes(searchTerm.toLowerCase()),
  )

  return (
    <div className="space-y-4">
      {/* Header + stat */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Ban />
          {t('blacklist.tiltolista')}
        </h1>
        <div className="flex gap-2">
          <label className="form-button cursor-pointer">
            <Upload size={16} />
            {t('blacklist.importalas')}
            <input
              type="file"
              className="hidden"
              accept=".csv,.xlsx,.xls"
              onChange={handleImport}
            />
          </label>
          {activeTab === 'persons' ? (
            <button
              onClick={() => {
                setShowPersonForm(true)
                setEditingPersonId(null)
                setPersonForm(emptyPersonForm)
              }}
              className="form-button-primary"
            >
              <Plus size={16} />
              {t('blacklist.szemelyHozzaadasa')}
            </button>
          ) : (
            <button
              onClick={() => {
                setShowCompanyForm(true)
                setEditingCompanyId(null)
                setCompanyForm(emptyCompanyForm)
              }}
              className="form-button-primary"
            >
              <Plus size={16} />
              {t('blacklist.cegHozzaadasa')}
            </button>
          )}
        </div>
      </div>

      {/* Statisztika */}
      <div className="grid grid-cols-4 gap-3">
        <div className="form-panel text-center">
          <div className="text-lg font-bold text-red-600">{stats.activePersons}</div>
          <div className="text-sm text-gray-500">{t('blacklist.aktivSzemely')}</div>
        </div>
        <div className="form-panel text-center">
          <div className="text-lg font-bold">{stats.totalPersons}</div>
          <div className="text-sm text-gray-500">{t('blacklist.osszesSzemely')}</div>
        </div>
        <div className="form-panel text-center">
          <div className="text-lg font-bold text-red-600">{stats.activeCompanies}</div>
          <div className="text-sm text-gray-500">{t('blacklist.aktivCeg')}</div>
        </div>
        <div className="form-panel text-center">
          <div className="text-lg font-bold">{stats.totalCompanies}</div>
          <div className="text-sm text-gray-500">{t('blacklist.osszesCeg')}</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 border-b">
        <button
          onClick={() => setActiveTab('persons')}
          className={`px-4 py-2 font-medium ${activeTab === 'persons' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500'}`}
        >
          <Shield size={14} className="inline mr-1" />
          {t('blacklist.szemelyek')}
          {filteredPersons.length}
          {i18n.t('literals.lit-2')}
        </button>
        <button
          onClick={() => setActiveTab('companies')}
          className={`px-4 py-2 font-medium ${activeTab === 'companies' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500'}`}
        >
          <AlertTriangle size={14} className="inline mr-1" />
          {t('blacklist.cegek')}
          {filteredCompanies.length}
          {i18n.t('literals.lit-2')}
        </button>
      </div>

      {/* Keresés */}
      <div className="flex gap-2 items-center">
        <Search size={16} className="text-gray-400" />
        <input
          className="form-input flex-1"
          placeholder="Keresés név, okmányszám, adószám alapján..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Person form */}
      {showPersonForm && (
        <div className="form-panel space-y-3 border-2 border-red-200">
          <h2 className="font-semibold">
            {editingPersonId ? 'Személy szerkesztése' : 'Új személy a tiltólistán'}
          </h2>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="form-label">{t('blacklist.teljesNev')}</label>
              <input
                className="form-input"
                value={personForm.fullName}
                onChange={(e) => setPersonForm({ ...personForm, fullName: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.documentNumber')}</label>
              <input
                className="form-input"
                value={personForm.documentNumber}
                onChange={(e) => setPersonForm({ ...personForm, documentNumber: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('blacklist.szemelyiSzam')}</label>
              <input
                className="form-input"
                value={personForm.identityNumber}
                onChange={(e) => setPersonForm({ ...personForm, identityNumber: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('blacklist.utlevelszam')}</label>
              <input
                className="form-input"
                value={personForm.passportNumber}
                onChange={(e) => setPersonForm({ ...personForm, passportNumber: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.birthDate')}</label>
              <input
                className="form-input"
                type="date"
                value={personForm.dateOfBirth}
                onChange={(e) => setPersonForm({ ...personForm, dateOfBirth: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.nationality')}</label>
              <input
                className="form-input"
                value={personForm.nationality}
                onChange={(e) => setPersonForm({ ...personForm, nationality: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('blacklist.listaTipus')}</label>
              <select
                className="form-input"
                value={personForm.listType}
                onChange={(e) => setPersonForm({ ...personForm, listType: e.target.value })}
              >
                {LIST_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="col-span-2">
              <label className="form-label">{t('blacklist.indoklas')}</label>
              <input
                className="form-input"
                value={personForm.reason}
                onChange={(e) => setPersonForm({ ...personForm, reason: e.target.value })}
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={handleSavePerson} disabled={saving} className="form-button-primary">
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button
              onClick={() => {
                setShowPersonForm(false)
                setEditingPersonId(null)
              }}
              className="form-button"
            >
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Company form */}
      {showCompanyForm && (
        <div className="form-panel space-y-3 border-2 border-red-200">
          <h2 className="font-semibold">
            {editingCompanyId ? 'Cég szerkesztése' : 'Új cég a tiltólistán'}
          </h2>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="form-label">{t('blacklist.cegnev')}</label>
              <input
                className="form-input"
                value={companyForm.companyName}
                onChange={(e) => setCompanyForm({ ...companyForm, companyName: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.taxNumber')}</label>
              <input
                className="form-input"
                value={companyForm.taxNumber}
                onChange={(e) => setCompanyForm({ ...companyForm, taxNumber: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.companyRegNumber')}</label>
              <input
                className="form-input"
                value={companyForm.registrationNumber}
                onChange={(e) =>
                  setCompanyForm({ ...companyForm, registrationNumber: e.target.value })
                }
              />
            </div>
            <div>
              <label className="form-label">{t('blacklist.listaTipus')}</label>
              <select
                className="form-input"
                value={companyForm.listType}
                onChange={(e) => setCompanyForm({ ...companyForm, listType: e.target.value })}
              >
                {LIST_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="col-span-2">
              <label className="form-label">{t('blacklist.indoklas')}</label>
              <input
                className="form-input"
                value={companyForm.reason}
                onChange={(e) => setCompanyForm({ ...companyForm, reason: e.target.value })}
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={handleSaveCompany} disabled={saving} className="form-button-primary">
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button
              onClick={() => {
                setShowCompanyForm(false)
                setEditingCompanyId(null)
              }}
              className="form-button"
            >
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Table */}
      {loading ? (
        <div>{i18n.t('literals.betoltes')}</div>
      ) : (
        <div className="form-panel">
          {activeTab === 'persons' ? (
            filteredPersons.length === 0 ? (
              <div className="text-center text-gray-500 py-8">
                {t('blacklist.nincsSzemelyATiltolistan')}
              </div>
            ) : (
              <table className="data-grid w-full">
                <thead>
                  <tr>
                    <th>{t('common.name')}</th>
                    <th>{t('common.documentNumber')}</th>
                    <th>{t('common.birthDate')}</th>
                    <th>{t('common.nationality')}</th>
                    <th>{t('blacklist.listaTipus')}</th>
                    <th>{t('blacklist.forras')}</th>
                    <th>{t('common.status')}</th>
                    <th>{t('common.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredPersons.map((p) => (
                    <tr key={p.id}>
                      <td className="font-medium">{p.fullName}</td>
                      <td className="font-mono text-sm">{p.documentNumber || '-'}</td>
                      <td>{p.dateOfBirth || '-'}</td>
                      <td>{p.nationality || '-'}</td>
                      <td>
                        <span className="badge badge-red">
                          {LIST_TYPES.find((t) => t.value === p.listType)?.label || p.listType}
                        </span>
                      </td>
                      <td className="text-sm">{p.listSource}</td>
                      <td>
                        <span className={`badge ${p.isActive ? 'badge-red' : 'badge-gray'}`}>
                          {p.isActive ? 'Aktív' : 'Inaktív'}
                        </span>
                      </td>
                      <td>
                        <div className="flex gap-1">
                          <button
                            onClick={() => handleEditPerson(p)}
                            className="form-button text-xs"
                            title="Szerkesztés"
                          >
                            <Edit2 size={12} />
                          </button>
                          <button
                            onClick={() => handleDeletePerson(p.id)}
                            className="form-button text-xs text-red-600"
                            title="Törlés"
                          >
                            <Trash2 size={12} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )
          ) : filteredCompanies.length === 0 ? (
            <div className="text-center text-gray-500 py-8">
              {t('blacklist.nincsCegATiltolistan')}
            </div>
          ) : (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('blacklist.cegnev2')}</th>
                  <th>{t('common.taxNumber')}</th>
                  <th>{t('common.companyRegNumber')}</th>
                  <th>{t('blacklist.listaTipus')}</th>
                  <th>{t('blacklist.forras')}</th>
                  <th>{t('common.status')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredCompanies.map((c) => (
                  <tr key={c.id}>
                    <td className="font-medium">{c.companyName}</td>
                    <td className="font-mono text-sm">{c.taxNumber || '-'}</td>
                    <td className="text-sm">{c.registrationNumber || '-'}</td>
                    <td>
                      <span className="badge badge-red">
                        {LIST_TYPES.find((t) => t.value === c.listType)?.label || c.listType}
                      </span>
                    </td>
                    <td className="text-sm">{c.listSource}</td>
                    <td>
                      <span className={`badge ${c.isActive ? 'badge-red' : 'badge-gray'}`}>
                        {c.isActive ? 'Aktív' : 'Inaktív'}
                      </span>
                    </td>
                    <td>
                      <div className="flex gap-1">
                        <button
                          onClick={() => handleEditCompany(c)}
                          className="form-button text-xs"
                          title="Szerkesztés"
                        >
                          <Edit2 size={12} />
                        </button>
                        <button
                          onClick={() => handleDeleteCompany(c.id)}
                          className="form-button text-xs text-red-600"
                          title="Törlés"
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
