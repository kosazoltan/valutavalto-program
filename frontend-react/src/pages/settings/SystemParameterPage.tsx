import { useState, useEffect, useMemo } from 'react'
import { Settings, Plus, Edit, Trash2, Search, X, Save, KeyRound } from 'lucide-react'
import {
  systemParameterApi,
  SystemParameter,
  SystemParameterCreateRequest,
} from '../../services/api/index'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function SystemParameterPage() {
  const { t } = useTranslation()
  const [parameters, setParameters] = useState<SystemParameter[]>([])
  const [allParameters, setAllParameters] = useState<SystemParameter[]>([])
  const [activeParameterCount, setActiveParameterCount] = useState(0)
  const [managedParameterCount, setManagedParameterCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string>('')
  const [lookupKey, setLookupKey] = useState('')
  const [lookupParameter, setLookupParameter] = useState<SystemParameter | null>(null)
  const [lookupValue, setLookupValue] = useState<string | null>(null)
  const [lookupLoading, setLookupLoading] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [editingParameter, setEditingParameter] = useState<SystemParameter | null>(null)
  const [formData, setFormData] = useState<SystemParameterCreateRequest>({
    parameterKey: '',
    parameterValue: '',
    parameterType: 'STRING',
    category: '',
    description: '',
    isActive: true,
  })

  const categories = Array.from(new Set(allParameters.map((p) => p.category))).sort()
  const parameterTypes = ['STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'JSON']

  const filteredParameters = useMemo(() => {
    let filtered = parameters
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      filtered = filtered.filter(
        (p) =>
          p.parameterKey.toLowerCase().includes(term) ||
          p.parameterValue.toLowerCase().includes(term) ||
          p.description?.toLowerCase().includes(term),
      )
    }
    return filtered
  }, [parameters, searchTerm])

  useEffect(() => {
    void loadParameters()
  }, [])

  const loadParameters = async () => {
    try {
      setLoading(true)
      setError(null)
      const [data, activeParameters, managedParameters] = await Promise.all([
        systemParameterApi.list(),
        systemParameterApi.getActive(),
        systemParameterApi.listManaged(),
      ])
      setParameters(data)
      setAllParameters(data)
      setActiveParameterCount(activeParameters.length)
      setManagedParameterCount(managedParameters.length)
    } catch (err) {
      logger.error('SystemParameterPage', 'Paraméterek betöltési hiba:', err)
      setError('Hiba a paraméterek betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleCategoryChange = async (category: string) => {
    try {
      setSelectedCategory(category)
      setLoading(true)
      setError(null)
      const data = category
        ? await systemParameterApi.getByCategory(category)
        : await systemParameterApi.list()
      setParameters(data)
      if (!category) {
        setAllParameters(data)
      }
    } catch (err) {
      logger.error('SystemParameterPage', 'Kategória szűrési hiba:', err)
      setError('Hiba a kategória szerinti paraméterek betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleLookup = async () => {
    const key = lookupKey.trim()
    if (!key) {
      return
    }

    try {
      setLookupLoading(true)
      setError(null)
      const [parameter, value] = await Promise.all([
        systemParameterApi.getByKey(key),
        systemParameterApi.getValue(key),
      ])
      setLookupParameter(parameter)
      setLookupValue(value)
    } catch (err) {
      logger.error('SystemParameterPage', 'Kulcs lekérdezési hiba:', err)
      setLookupParameter(null)
      setLookupValue(null)
      setError('Hiba a paraméter kulcs lekérdezésekor')
    } finally {
      setLookupLoading(false)
    }
  }

  const handleCreate = () => {
    setEditingParameter(null)
    setFormData({
      parameterKey: '',
      parameterValue: '',
      parameterType: 'STRING',
      category: '',
      description: '',
      isActive: true,
    })
    setShowForm(true)
  }

  const handleEdit = (parameter: SystemParameter) => {
    setEditingParameter(parameter)
    setFormData({
      parameterKey: parameter.parameterKey,
      parameterValue: parameter.parameterValue,
      parameterType: parameter.parameterType,
      category: parameter.category,
      description: parameter.description || '',
      isActive: parameter.isActive,
    })
    setShowForm(true)
  }

  const handleSave = async () => {
    try {
      setError(null)
      if (editingParameter) {
        await systemParameterApi.update(editingParameter.id, {
          parameterValue: formData.parameterValue,
          description: formData.description,
        })
      } else {
        await systemParameterApi.create(formData)
      }
      await loadParameters()
      setShowForm(false)
      setEditingParameter(null)
    } catch (err) {
      logger.error('SystemParameterPage', 'Mentési hiba:', err)
      setError('Hiba történt a mentés során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törölni szeretné ezt a paramétert?')) {
      return
    }

    try {
      setError(null)
      await systemParameterApi.delete(id)
      await loadParameters()
    } catch (err) {
      logger.error('SystemParameterPage', 'Törlési hiba:', err)
      setError('Hiba történt a törlés során')
    }
  }

  const handleToggleActive = async (id: string) => {
    try {
      setError(null)
      await systemParameterApi.toggleActive(id)
      await loadParameters()
    } catch (err) {
      logger.error('SystemParameterPage', 'Állapotváltási hiba:', err)
      setError('Hiba történt az állapotváltás során')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">{i18n.t('literals.betoltes')}</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Settings />
          {t('settings.rendszerparameterek')}
        </h1>
        <button
          type="button"
          onClick={handleCreate}
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          {t('organizations.ujParameter')}
        </button>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Filters */}
      <div className="form-panel">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label htmlFor="system-parameter-search" className="form-label">
              {t('common.search')}
            </label>
            <div className="relative">
              <Search
                className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={16}
              />
              <input
                id="system-parameter-search"
                type="text"
                className="form-input pl-8"
                placeholder="Kulcs, érték vagy leírás..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          <div>
            <label htmlFor="system-parameter-category" className="form-label">
              {t('common.category')}
            </label>
            <select
              id="system-parameter-category"
              className="form-input"
              value={selectedCategory}
              onChange={(e) => void handleCategoryChange(e.target.value)}
            >
              <option value="">{t('settings.osszesKategoria')}</option>
              {categories.map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      <div className="form-panel">
        <div className="grid grid-cols-1 lg:grid-cols-[1fr_2fr] gap-4">
          <div className="grid grid-cols-2 gap-3">
            <div className="border border-gray-200 rounded p-3">
              <div className="text-xs text-gray-500">{t('common.active')}</div>
              <div className="text-lg font-semibold">{activeParameterCount}</div>
            </div>
            <div className="border border-gray-200 rounded p-3">
              <div className="text-xs text-gray-500">{t('settings.menedzselt')}</div>
              <div className="text-lg font-semibold">{managedParameterCount}</div>
            </div>
          </div>
          <div>
            <label htmlFor="system-parameter-key-lookup" className="form-label">
              {t('settings.kulcsEllenorzes')}
            </label>
            <div className="flex flex-col sm:flex-row gap-2">
              <div className="relative flex-1">
                <KeyRound
                  className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                  size={16}
                />
                <input
                  id="system-parameter-key-lookup"
                  type="text"
                  className="form-input pl-8"
                  value={lookupKey}
                  onChange={(e) => setLookupKey(e.target.value)}
                  placeholder="pl: RATE_SPREAD_EUR"
                />
              </div>
              <button
                type="button"
                onClick={() => void handleLookup()}
                disabled={lookupLoading || !lookupKey.trim()}
                className="form-button flex items-center justify-center gap-2"
              >
                <Search size={16} />
                {t('settings.lekerdezes')}
              </button>
            </div>
            {lookupParameter && (
              <div className="mt-3 grid grid-cols-1 md:grid-cols-3 gap-2 text-sm">
                <div>
                  <span className="text-gray-500">
                    {t('organizations.kulcs2')}
                    {i18n.t('literals.lit-22')}
                  </span>
                  <span className="font-mono">{lookupParameter.parameterKey}</span>
                </div>
                <div>
                  <span className="text-gray-500">
                    {t('fees.ertek')}
                    {i18n.t('literals.lit-22')}
                  </span>
                  <span className="font-mono">{lookupValue ?? lookupParameter.parameterValue}</span>
                </div>
                <div>
                  <span className="text-gray-500">
                    {t('common.category')}
                    {i18n.t('literals.lit-22')}
                  </span>
                  <span>{lookupParameter.category}</span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">
                {editingParameter ? 'Paraméter szerkesztése' : 'Új paraméter'}
              </h2>
              <button
                type="button"
                onClick={() => {
                  setShowForm(false)
                  setEditingParameter(null)
                }}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="form-label">{t('settings.parameterKulcs')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.parameterKey}
                  onChange={(e) => setFormData({ ...formData, parameterKey: e.target.value })}
                  disabled={!!editingParameter}
                  placeholder="pl: system.max_transaction_amount"
                />
              </div>

              <div>
                <label className="form-label">{t('settings.parameterErtek')}</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.parameterValue}
                  onChange={(e) => setFormData({ ...formData, parameterValue: e.target.value })}
                  placeholder="pl: 1000000"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('circulars.tipus')}</label>
                  <select
                    className="form-input"
                    value={formData.parameterType}
                    onChange={(e) => setFormData({ ...formData, parameterType: e.target.value })}
                  >
                    {parameterTypes.map((type) => (
                      <option key={type} value={type}>
                        {type}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="form-label">{t('circulars.kategoria')}</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    placeholder="pl: TRANSACTION"
                  />
                </div>
              </div>

              <div>
                <label className="form-label">{t('common.description')}</label>
                <textarea
                  className="form-input"
                  rows={3}
                  value={formData.description || ''}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Paraméter leírása..."
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
                    setEditingParameter(null)
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

      {/* Parameters Table */}
      <div className="form-panel overflow-x-auto">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('organizations.kulcs2')}</th>
              <th>{t('fees.ertek')}</th>
              <th>{t('common.type')}</th>
              <th>{t('common.category')}</th>
              <th>{t('common.description')}</th>
              <th>{t('common.status')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredParameters.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filteredParameters.map((param) => (
                <tr key={param.id}>
                  <td className="font-mono text-sm">{param.parameterKey}</td>
                  <td className="font-mono text-sm max-w-xs truncate" title={param.parameterValue}>
                    {param.parameterValue}
                  </td>
                  <td>
                    <span className="badge badge-gray">{param.parameterType}</span>
                  </td>
                  <td>{param.category}</td>
                  <td className="max-w-xs truncate" title={param.description}>
                    {param.description || '-'}
                  </td>
                  <td>
                    <button
                      type="button"
                      onClick={() => handleToggleActive(param.id)}
                      className={`badge ${param.isActive ? 'badge-green' : 'badge-red'}`}
                    >
                      {param.isActive ? 'Aktív' : 'Inaktív'}
                    </button>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => handleEdit(param)}
                        className="form-button text-sm flex items-center gap-1"
                      >
                        <Edit size={14} />
                        {t('common.edit')}
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDelete(param.id)}
                        className="form-button text-sm text-red-600 flex items-center gap-1"
                      >
                        <Trash2 size={14} />
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
