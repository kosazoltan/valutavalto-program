import { useState, useEffect, useCallback } from 'react'
import { Settings, Plus, Edit2, Trash2, Search } from 'lucide-react'
import {
  organizationalSystemParameterApi,
  OrganizationalSystemParameter,
} from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface ParamForm {
  organizationName: string
  parameterKey: string
  parameterValue: string
  currencyCode: string
  validFrom: string
  validTo: string
  description: string
}

const emptyForm: ParamForm = {
  organizationName: '',
  parameterKey: '',
  parameterValue: '',
  currencyCode: '',
  validFrom: new Date().toISOString().slice(0, 10),
  validTo: '',
  description: '',
}

export default function OrganizationalSystemParameterPage() {
  const { t } = useTranslation()
  const [params, setParams] = useState<OrganizationalSystemParameter[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
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

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleSave = async () => {
    if (!form.parameterKey || !form.parameterValue) {
      toast.warning('Kulcs és érték kötelező')
      return
    }
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

  const handleEdit = async (p: OrganizationalSystemParameter) => {
    try {
      setDetailLoadingId(p.id)
      setError(null)
      const detailed = await organizationalSystemParameterApi.getById(p.id)
      setForm({
        organizationName: detailed.organizationName || '',
        parameterKey: detailed.parameterKey,
        parameterValue: detailed.parameterValue,
        currencyCode: detailed.currencyCode || '',
        validFrom: detailed.validFrom || '',
        validTo: detailed.validTo || '',
        description: detailed.description || '',
      })
      setEditingId(detailed.id)
      setShowForm(true)
    } catch (err) {
      logger.error('OrganizationalSystemParameterPage', 'Részlet betöltési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setDetailLoadingId(null)
    }
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

  const filtered = safeArray<OrganizationalSystemParameter>(params).filter((p) => {
    if (!search) return true
    const s = search.toLowerCase()
    return (
      p.parameterKey?.toLowerCase().includes(s) ||
      p.parameterValue?.toLowerCase().includes(s) ||
      p.organizationName?.toLowerCase().includes(s)
    )
  })

  // Group by organization
  const orgs = [...new Set(filtered.map((p) => p.organizationName || 'Globális'))].sort()

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Settings />
          {t('organizations.szervezetiRendszerparameterek')}
        </h1>
        <button
          onClick={() => {
            setShowForm(true)
            setEditingId(null)
            setForm(emptyForm)
          }}
          className="form-button-primary"
        >
          <Plus size={16} />
          {t('organizations.ujParameter')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {showForm && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{editingId ? 'Paraméter szerkesztése' : 'Új paraméter'}</h2>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="form-label">{t('organizations.szervezet')}</label>
              <input
                className="form-input"
                value={form.organizationName}
                onChange={(e) => setForm({ ...form, organizationName: e.target.value })}
                placeholder="Üres = globális"
              />
            </div>
            <div>
              <label className="form-label">{t('organizations.kulcs')}</label>
              <input
                className="form-input font-mono"
                value={form.parameterKey}
                onChange={(e) => setForm({ ...form, parameterKey: e.target.value })}
                placeholder="pl. MAX_TRANSACTION_AMOUNT"
              />
            </div>
            <div>
              <label className="form-label">{t('organizations.ertek')}</label>
              <input
                className="form-input"
                value={form.parameterValue}
                onChange={(e) => setForm({ ...form, parameterValue: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.currency')}</label>
              <input
                className="form-input"
                value={form.currencyCode}
                onChange={(e) => setForm({ ...form, currencyCode: e.target.value })}
                placeholder="pl. EUR"
              />
            </div>
            <div>
              <label className="form-label">{t('organizations.ervenyesEttol')}</label>
              <input
                className="form-input"
                type="date"
                value={form.validFrom}
                onChange={(e) => setForm({ ...form, validFrom: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('organizations.ervenyesEddig')}</label>
              <input
                className="form-input"
                type="date"
                value={form.validTo}
                onChange={(e) => setForm({ ...form, validTo: e.target.value })}
              />
            </div>
          </div>
          <div>
            <label className="form-label">{t('common.description')}</label>
            <textarea
              className="form-input"
              rows={2}
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleSave()} className="form-button-primary">
              {t('common.save')}
            </button>
            <button
              onClick={() => {
                setShowForm(false)
                setEditingId(null)
              }}
              className="form-button"
            >
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Search */}
      <div className="form-panel flex gap-3 items-end">
        <div className="flex-1">
          <label className="form-label">{t('common.search')}</label>
          <div className="flex items-center gap-1">
            <Search size={16} className="text-gray-400" />
            <input
              className="form-input flex-1"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Kulcs, érték vagy szervezet..."
            />
          </div>
        </div>
        <span className="text-sm text-gray-500">
          {filtered.length} {t('organizations.parameter')}
        </span>
      </div>

      {/* Grouped tables */}
      {loading ? (
        <div>{i18n.t('literals.betoltes')}</div>
      ) : filtered.length === 0 ? (
        <div className="form-panel text-center text-gray-500 py-4">
          {t('organizations.nincsParameter')}
        </div>
      ) : (
        orgs.map((org) => (
          <div key={org} className="form-panel overflow-x-auto">
            <h2 className="font-semibold mb-2">{org}</h2>
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('organizations.kulcs2')}</th>
                  <th>{t('fees.ertek')}</th>
                  <th>{t('common.currency')}</th>
                  <th>{t('commissions.ervenyesseg')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered
                  .filter((p) => (p.organizationName || 'Globális') === org)
                  .map((p) => (
                    <tr key={p.id}>
                      <td className="font-mono text-sm">{p.parameterKey}</td>
                      <td>{p.parameterValue}</td>
                      <td>{p.currencyCode || '-'}</td>
                      <td className="text-sm">
                        {p.validFrom}
                        {i18n.t('literals.lit-32')}
                        {p.validTo || 'határozatlan'}
                      </td>
                      <td>
                        <div className="flex gap-1">
                          <button
                            type="button"
                            aria-label="Szerkesztés"
                            onClick={() => void handleEdit(p)}
                            disabled={detailLoadingId === p.id}
                            className="form-button text-xs disabled:opacity-50"
                          >
                            <Edit2
                              size={12}
                              className={detailLoadingId === p.id ? 'animate-pulse' : ''}
                            />
                          </button>
                          <button
                            type="button"
                            aria-label="Törlés"
                            onClick={() => void handleDelete(p.id)}
                            className="form-button text-xs text-red-600"
                          >
                            <Trash2 size={12} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        ))
      )}
    </div>
  )
}
