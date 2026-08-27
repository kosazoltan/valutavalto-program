import { useState, useEffect, useMemo } from 'react'
import { Building, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import {
  adminCompanyApi,
  ownCompanyApi,
  AdminCompanyDetails,
  OwnCompany,
} from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

const toAdminCompanyUpdate = (data: Partial<OwnCompany>) => ({
  name: data.name,
  taxNumber: data.taxNumber,
  registrationNumber: data.registrationNumber,
  address: data.address,
  phone: data.phone,
  email: data.email,
})

export default function OwnCompanyPage() {
  const { t } = useTranslation()
  const [companies, setCompanies] = useState<OwnCompany[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingCompany, setEditingCompany] = useState<OwnCompany | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [adminDetails, setAdminDetails] = useState<Record<string, AdminCompanyDetails>>({})
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
    isActive: true,
  })

  const filteredCompanies = useMemo(() => {
    if (!searchTerm) return companies
    const term = searchTerm.toLowerCase()
    return companies.filter(
      (c) => c.name?.toLowerCase().includes(term) || c.taxNumber?.toLowerCase().includes(term),
    )
  }, [companies, searchTerm])

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      const data = await ownCompanyApi.list()
      setCompanies(data)
      const details = await Promise.all(
        data.map(async (company) => {
          try {
            return [company.id, await adminCompanyApi.getDetails(company.id)] as const
          } catch (error) {
            logger.warn('OwnCompanyPage', `Admin cég részlet nem elérhető: ${company.id}`, error)
            return null
          }
        }),
      )
      setAdminDetails(
        Object.fromEntries(
          details.filter((item): item is readonly [string, AdminCompanyDetails] => item !== null),
        ),
      )
    } catch (error) {
      logger.error('OwnCompanyPage', 'Hiba az adatok betöltésekor:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreate = () => {
    setEditingCompany(null)
    setFormData({
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
      isActive: true,
    })
    setShowForm(true)
  }

  const handleEdit = async (company: OwnCompany) => {
    setDetailLoadingId(company.id)
    try {
      const detail = await ownCompanyApi.getById(company.id)
      setEditingCompany(detail)
      setFormData(detail)
      setShowForm(true)
    } catch (error) {
      logger.error('OwnCompanyPage', 'Hiba a cég részlet betöltésekor:', error)
      toast.error('Betöltési hiba', 'Hiba történt a cég részleteinek betöltése során')
    } finally {
      setDetailLoadingId(null)
    }
  }

  const handleSave = async () => {
    try {
      if (editingCompany) {
        await ownCompanyApi.update(editingCompany.id, formData)
        if (adminDetails[editingCompany.id]) {
          await adminCompanyApi.updateCompany(editingCompany.id, toAdminCompanyUpdate(formData))
        }
      } else {
        await ownCompanyApi.create(formData)
      }
      await loadData()
      setShowForm(false)
      setEditingCompany(null)
    } catch (error) {
      logger.error('OwnCompanyPage', 'Hiba a mentéskor:', error)
      toast.error('Mentési hiba', 'Hiba történt a mentés során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törölni szeretné ezt a céget?')) return
    try {
      await ownCompanyApi.delete(id)
      await loadData()
    } catch (error) {
      logger.error('OwnCompanyPage', 'Hiba a törléskor:', error)
      toast.error('Törlési hiba', 'Hiba történt a törlés során')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building />
          {t('company.sajatCegek')}
        </h1>
        <button
          onClick={handleCreate}
          className="form-button-primary flex items-center justify-center gap-2"
        >
          <Plus size={16} />
          {t('company.ujCeg')}
        </button>
      </div>

      <div className="form-panel">
        <div>
          <label className="form-label">{t('common.search')}</label>
          <div className="relative">
            <Search
              className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
              size={16}
            />
            <input
              type="text"
              className="form-input pl-8"
              placeholder="Név vagy adószám..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-3">
          <div className="bg-white rounded-lg p-4 w-full max-w-3xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingCompany ? 'Cég szerkesztése' : 'Új cég'}
              </h2>
              <button
                onClick={() => {
                  setShowForm(false)
                  setEditingCompany(null)
                }}
                className="text-gray-500"
              >
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="form-label">{t('common.nameRequired')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="form-label">{t('common.taxNumber')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.taxNumber || ''}
                    onChange={(e) => setFormData({ ...formData, taxNumber: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">{t('common.companyRegNumber')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.registrationNumber || ''}
                    onChange={(e) =>
                      setFormData({ ...formData, registrationNumber: e.target.value })
                    }
                  />
                </div>
              </div>
              <div>
                <label className="form-label">{t('common.address')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.address || ''}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="form-label">{t('common.phone')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.phone || ''}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">{t('common.email')}</label>
                  <input
                    type="email"
                    className="form-input"
                    value={formData.email || ''}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="form-label">{t('company.szamlaszam')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.bankAccountNumber || ''}
                  onChange={(e) => setFormData({ ...formData, bankAccountNumber: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="form-label">{i18n.t('literals.iban')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.iban || ''}
                    onChange={(e) => setFormData({ ...formData, iban: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">{i18n.t('literals.swift')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.swift || ''}
                    onChange={(e) => setFormData({ ...formData, swift: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="form-label">{t('company.engedelySzam')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.licenseNumber || ''}
                  onChange={(e) => setFormData({ ...formData, licenseNumber: e.target.value })}
                />
              </div>
              <div>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    className="rounded"
                    checked={formData.isActive ?? true}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  />
                  <span>{t('common.active')}</span>
                </label>
              </div>
              <div className="flex flex-col gap-2 pt-4 border-t sm:flex-row sm:justify-end">
                <button
                  onClick={() => {
                    setShowForm(false)
                    setEditingCompany(null)
                  }}
                  className="form-button"
                >
                  {t('common.cancel')}
                </button>
                <button
                  onClick={handleSave}
                  className="form-button-primary flex items-center gap-2"
                >
                  <Save size={16} />
                  {t('common.save')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="form-panel hidden overflow-x-auto md:block">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.name')}</th>
              <th>{t('common.taxNumber')}</th>
              <th>{t('common.companyRegNumber')}</th>
              <th>{i18n.t('literals.admin-statisztika')}</th>
              <th>{t('common.email')}</th>
              <th>{t('common.phone')}</th>
              <th>{t('common.status')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredCompanies.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filteredCompanies.map((c) => {
                const details = adminDetails[c.id]
                return (
                  <tr key={c.id}>
                    <td>{c.name}</td>
                    <td>{c.taxNumber || '-'}</td>
                    <td>{c.registrationNumber || '-'}</td>
                    <td>
                      {details ? (
                        <div
                          className="text-xs text-gray-700"
                          data-testid={`company-admin-stats-${c.id}`}
                        >
                          <div>
                            {details.activeBranchCount}
                            {i18n.t('literals.aktiv-fiok')}
                          </div>
                          <div>
                            {details.totalWorkerCount}
                            {i18n.t('literals.dolgozo')}
                          </div>
                          <div>
                            {details.dailyTurnoverHuf.toLocaleString('hu-HU')}
                            {i18n.t('literals.huf-ma')}
                          </div>
                        </div>
                      ) : (
                        <span className="text-xs text-gray-400">
                          {i18n.t('literals.nincs-admin-adat')}
                        </span>
                      )}
                    </td>
                    <td>{c.email || '-'}</td>
                    <td>{c.phone || '-'}</td>
                    <td>
                      <span className={`badge ${c.isActive ? 'badge-green' : 'badge-red'}`}>
                        {c.isActive ? 'Aktív' : 'Inaktív'}
                      </span>
                    </td>
                    <td>
                      <div className="flex gap-2">
                        <button
                          onClick={() => void handleEdit(c)}
                          disabled={detailLoadingId === c.id}
                          className="form-button text-xs disabled:opacity-50"
                        >
                          <Edit size={12} />
                          {detailLoadingId === c.id ? 'Betöltés...' : t('common.edit')}
                        </button>
                        <button
                          onClick={() => handleDelete(c.id)}
                          className="form-button text-xs text-red-600"
                        >
                          <Trash2 size={12} />
                          {t('common.delete')}
                        </button>
                      </div>
                    </td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>

      <div className="space-y-3 md:hidden">
        {filteredCompanies.length === 0 ? (
          <div className="form-panel text-center text-gray-500">{t('common.noResult')}</div>
        ) : (
          filteredCompanies.map((company) => {
            const details = adminDetails[company.id]
            return (
              <div key={company.id} className="form-panel space-y-3">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="font-semibold text-gray-900">{company.name}</div>
                    <div className="text-xs text-gray-500">{company.taxNumber || '-'}</div>
                  </div>
                  <span className={`badge ${company.isActive ? 'badge-green' : 'badge-red'}`}>
                    {company.isActive ? 'Aktív' : 'Inaktív'}
                  </span>
                </div>
                <div className="grid grid-cols-1 gap-2 text-sm">
                  <div>
                    <span className="text-gray-500">
                      {t('common.companyRegNumber')}
                      {i18n.t('literals.lit-7')}
                    </span>{' '}
                    {company.registrationNumber || '-'}
                  </div>
                  <div>
                    <span className="text-gray-500">
                      {t('common.email')}
                      {i18n.t('literals.lit-7')}
                    </span>{' '}
                    {company.email || '-'}
                  </div>
                  <div>
                    <span className="text-gray-500">
                      {t('common.phone')}
                      {i18n.t('literals.lit-7')}
                    </span>{' '}
                    {company.phone || '-'}
                  </div>
                </div>
                {details && (
                  <div
                    className="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900"
                    data-testid={`company-admin-stats-mobile-${company.id}`}
                  >
                    <div className="font-semibold">{i18n.t('literals.admin-statisztika')}</div>
                    <div className="mt-1 grid grid-cols-1 gap-1">
                      <span>
                        {details.activeBranchCount}
                        {i18n.t('literals.aktiv-fiok')}
                      </span>
                      <span>
                        {details.totalWorkerCount}
                        {i18n.t('literals.dolgozo')}
                      </span>
                      <span>
                        {details.dailyTurnoverHuf.toLocaleString('hu-HU')}
                        {i18n.t('literals.huf-ma')}
                      </span>
                    </div>
                    {details.branches?.length > 0 && (
                      <div className="mt-2 text-xs">
                        {i18n.t('literals.fiokok')}{' '}
                        {details.branches
                          .slice(0, 3)
                          .map((branch) => branch.code || branch.name)
                          .join(', ')}
                      </div>
                    )}
                  </div>
                )}
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => void handleEdit(company)}
                    disabled={detailLoadingId === company.id}
                    className="form-button justify-center text-xs disabled:opacity-50"
                  >
                    <Edit size={12} />
                    {detailLoadingId === company.id ? 'Betöltés...' : t('common.edit')}
                  </button>
                  <button
                    onClick={() => handleDelete(company.id)}
                    className="form-button justify-center text-xs text-red-600"
                  >
                    <Trash2 size={12} />
                    {t('common.delete')}
                  </button>
                </div>
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}
