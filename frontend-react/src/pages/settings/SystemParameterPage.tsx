import { useState, useEffect } from 'react'
import { Settings, Plus, Edit, Trash2, Search, X, Save } from 'lucide-react'
import { systemParameterApi, SystemParameter, SystemParameterCreateRequest } from '../../services/api'

export default function SystemParameterPage() {
  const [parameters, setParameters] = useState<SystemParameter[]>([])
  const [filteredParameters, setFilteredParameters] = useState<SystemParameter[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string>('')
  const [showForm, setShowForm] = useState(false)
  const [editingParameter, setEditingParameter] = useState<SystemParameter | null>(null)
  const [formData, setFormData] = useState<SystemParameterCreateRequest>({
    parameterKey: '',
    parameterValue: '',
    parameterType: 'STRING',
    category: '',
    description: '',
    isActive: true
  })

  const categories = Array.from(new Set(parameters.map(p => p.category))).sort()
  const parameterTypes = ['STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'JSON']

  useEffect(() => {
    void loadParameters()
  }, [])

  useEffect(() => {
    filterParameters()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [parameters, searchTerm, selectedCategory])

  const loadParameters = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await systemParameterApi.list()
      setParameters(data)
    } catch (err) {
      console.error('Paraméterek betöltési hiba:', err)
      setError('Hiba a paraméterek betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const filterParameters = () => {
    let filtered = parameters

    if (searchTerm) {
      filtered = filtered.filter(p =>
        p.parameterKey.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.parameterValue.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.description?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }

    if (selectedCategory) {
      filtered = filtered.filter(p => p.category === selectedCategory)
    }

    setFilteredParameters(filtered)
  }

  const handleCreate = () => {
    setEditingParameter(null)
    setFormData({
      parameterKey: '',
      parameterValue: '',
      parameterType: 'STRING',
      category: '',
      description: '',
      isActive: true
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
      isActive: parameter.isActive
    })
    setShowForm(true)
  }

  const handleSave = async () => {
    try {
      setError(null)
      if (editingParameter) {
        await systemParameterApi.update(editingParameter.id, formData)
      } else {
        await systemParameterApi.create(formData)
      }
      await loadParameters()
      setShowForm(false)
      setEditingParameter(null)
    } catch (err) {
      console.error('Mentési hiba:', err)
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
      console.error('Törlési hiba:', err)
      setError('Hiba történt a törlés során')
    }
  }

  const handleToggleActive = async (id: string) => {
    try {
      setError(null)
      await systemParameterApi.toggleActive(id)
      await loadParameters()
    } catch (err) {
      console.error('Állapotváltási hiba:', err)
      setError('Hiba történt az állapotváltás során')
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
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Settings />
          Rendszerparaméterek
        </h1>
        <button
          type="button"
          onClick={handleCreate}
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          Új paraméter
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
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="form-label">Keresés</label>
            <div className="relative">
              <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
              <input
                type="text"
                className="form-input pl-8"
                placeholder="Kulcs, érték vagy leírás..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          <div>
            <label className="form-label">Kategória</label>
            <select
              className="form-input"
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
            >
              <option value="">Összes kategória</option>
              {categories.map(cat => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
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
                <label className="form-label">Paraméter kulcs *</label>
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
                <label className="form-label">Paraméter érték *</label>
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
                  <label className="form-label">Típus *</label>
                  <select
                    className="form-input"
                    value={formData.parameterType}
                    onChange={(e) => setFormData({ ...formData, parameterType: e.target.value })}
                  >
                    {parameterTypes.map(type => (
                      <option key={type} value={type}>{type}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="form-label">Kategória *</label>
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
                <label className="form-label">Leírás</label>
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
                  <span>Aktív</span>
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
                  Mégse
                </button>
                <button
                  type="button"
                  onClick={handleSave}
                  className="form-button-primary flex items-center gap-2"
                >
                  <Save size={16} />
                  Mentés
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Parameters Table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Kulcs</th>
              <th>Érték</th>
              <th>Típus</th>
              <th>Kategória</th>
              <th>Leírás</th>
              <th>Státusz</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filteredParameters.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">
                  Nincs találat
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
                        Szerkesztés
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDelete(param.id)}
                        className="form-button text-sm text-red-600 flex items-center gap-1"
                      >
                        <Trash2 size={14} />
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
