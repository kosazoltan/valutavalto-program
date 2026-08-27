import { useState, useEffect, useMemo } from 'react'
import { Archive, Building, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { organizationApi, Organization } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function OrganizationPage() {
  const { t } = useTranslation()
  const [organizations, setOrganizations] = useState<Organization[]>([])
  const [activeOrganizations, setActiveOrganizations] = useState<Organization[]>([])
  const [rootOrganizations, setRootOrganizations] = useState<Organization[]>([])
  const [loading, setLoading] = useState(true)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingOrg, setEditingOrg] = useState<Organization | null>(null)
  const [formData, setFormData] = useState<Partial<Organization>>({
    code: '',
    name: '',
    description: '',
    isActive: true,
  })

  const filteredOrganizations = useMemo(() => {
    if (!searchTerm) return organizations
    const term = searchTerm.toLowerCase()
    return organizations.filter(
      (o) => o.code?.toLowerCase().includes(term) || o.name?.toLowerCase().includes(term),
    )
  }, [organizations, searchTerm])

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      const [data, active, roots] = await Promise.all([
        organizationApi.list(),
        organizationApi.getActive(),
        organizationApi.getRoots(),
      ])
      setOrganizations(data)
      setActiveOrganizations(active)
      setRootOrganizations(roots)
    } catch (err) {
      logger.error('OrganizationPage', 'Szervezetek betöltési hiba:', err)
      setError('Hiba a szervezetek betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleCreate = () => {
    setEditingOrg(null)
    setFormData({ code: '', name: '', description: '', isActive: true })
    setShowForm(true)
  }

  const handleEdit = async (org: Organization) => {
    try {
      setError(null)
      setDetailLoadingId(org.id)
      const detailed = await organizationApi.getById(org.id)
      setEditingOrg(detailed)
      setFormData(detailed)
      setShowForm(true)
    } catch (err) {
      logger.error('OrganizationPage', 'Szervezet részletek betöltési hiba:', err)
      setError('Hiba a szervezet részleteinek betöltésekor')
    } finally {
      setDetailLoadingId(null)
    }
  }

  const handleSave = async () => {
    try {
      setError(null)
      if (editingOrg) {
        await organizationApi.update(editingOrg.id, formData)
      } else {
        await organizationApi.create(formData)
      }
      await loadData()
      setShowForm(false)
      setEditingOrg(null)
    } catch (err) {
      logger.error('OrganizationPage', 'Mentési hiba:', err)
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
      logger.error('OrganizationPage', 'Törlési hiba:', err)
      setError('Hiba történt a törlés során')
    }
  }

  const handleArchive = async (id: string) => {
    if (!confirm('Biztosan archiválni szeretné ezt a szervezetet?')) return
    try {
      setError(null)
      await organizationApi.archive(id)
      await loadData()
    } catch (err) {
      logger.error('OrganizationPage', 'Archiválási hiba:', err)
      setError('Hiba történt az archiválás során')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building />
          {t('organizations.szervezetek')}
        </h1>
        <button
          type="button"
          onClick={handleCreate}
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          {t('organizations.ujSzervezet')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
        <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
          <div className="rounded border border-gray-200 bg-white p-3">
            <div className="text-xs text-gray-500">{i18n.t('literals.osszes-szervezet')}</div>
            <div className="text-2xl font-semibold text-gray-900">{organizations.length}</div>
          </div>
          <div className="rounded border border-emerald-200 bg-emerald-50 p-3">
            <div className="text-xs text-emerald-700">{i18n.t('literals.aktiv-szervezet')}</div>
            <div className="text-2xl font-semibold text-emerald-800">
              {activeOrganizations.length}
            </div>
          </div>
          <div className="rounded border border-blue-200 bg-blue-50 p-3">
            <div className="text-xs text-blue-700">{i18n.t('literals.gyoker-szervezet')}</div>
            <div className="text-2xl font-semibold text-blue-800">{rootOrganizations.length}</div>
          </div>
        </div>
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
              placeholder="Kód vagy név..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingOrg ? 'Szervezet szerkesztése' : 'Új szervezet'}
              </h2>
              <button
                type="button"
                onClick={() => {
                  setShowForm(false)
                  setEditingOrg(null)
                }}
                className="text-gray-500"
              >
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="form-label">{t('common.codeRequired')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">{t('common.nameRequired')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">{t('common.description')}</label>
                <textarea
                  className="form-input"
                  rows={3}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
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
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button
                  type="button"
                  onClick={() => {
                    setShowForm(false)
                    setEditingOrg(null)
                  }}
                  className="form-button"
                >
                  {t('common.cancel')}
                </button>
                <button
                  type="button"
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

      <div className="form-panel overflow-x-auto">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.code')}</th>
              <th>{t('common.name')}</th>
              <th>{t('organizations.szulo')}</th>
              <th>{t('common.status')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredOrganizations.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filteredOrganizations.map((o) => (
                <tr key={o.id}>
                  <td className="font-mono text-sm">{o.code}</td>
                  <td>{o.name}</td>
                  <td>{o.parentName || '-'}</td>
                  <td>
                    <span className={`badge ${o.isActive ? 'badge-green' : 'badge-red'}`}>
                      {o.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => void handleEdit(o)}
                        disabled={detailLoadingId === o.id}
                        className="form-button text-xs disabled:opacity-50"
                      >
                        <Edit
                          size={12}
                          className={detailLoadingId === o.id ? 'animate-pulse' : ''}
                        />
                        {t('common.edit')}
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleArchive(o.id)}
                        className="form-button text-xs text-amber-700"
                      >
                        <Archive size={12} />
                        {t('archiving.archivalas')}
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDelete(o.id)}
                        className="form-button text-xs text-red-600"
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
