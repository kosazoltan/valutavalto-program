import { useState, useEffect, useCallback } from 'react'
import { Percent, Plus, Edit2, Trash2 } from 'lucide-react'
import { commissionRateApi, CommissionRate } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface RateForm {
  entityType: string
  entityName: string
  currencyCode: string
  rate: string
  validFrom: string
  validTo: string
}

const emptyForm: RateForm = {
  entityType: 'BRANCH',
  entityName: '',
  currencyCode: '',
  rate: '',
  validFrom: new Date().toISOString().slice(0, 10),
  validTo: '',
}

export default function CommissionRatePage() {
  const { t } = useTranslation()
  const [rates, setRates] = useState<CommissionRate[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editingLoadingId, setEditingLoadingId] = useState<string | null>(null)
  const [form, setForm] = useState<RateForm>(emptyForm)
  const [filter, setFilter] = useState({ entityType: '', currencyCode: '' })

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setRates(await commissionRateApi.list())
    } catch (err) {
      logger.error('CommissionRatePage', 'Hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleSave = async () => {
    if (!form.rate) {
      toast.warning('Mérték megadása kötelező')
      return
    }
    try {
      setError(null)
      const payload = { ...form, rate: parseFloat(form.rate) }
      if (editingId) {
        await commissionRateApi.update(editingId, payload)
        toast.success('Jutalék mérték frissítve')
      } else {
        await commissionRateApi.create(payload)
        toast.success('Jutalék mérték létrehozva')
      }
      setShowForm(false)
      setEditingId(null)
      setForm(emptyForm)
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const openEditForm = (r: CommissionRate) => {
    setForm({
      entityType: r.entityType,
      entityName: r.entityName || '',
      currencyCode: r.currencyCode || '',
      rate: String(r.rate),
      validFrom: r.validFrom || '',
      validTo: r.validTo || '',
    })
    setEditingId(r.id)
    setShowForm(true)
  }

  const handleEdit = async (r: CommissionRate) => {
    try {
      setError(null)
      setEditingLoadingId(r.id)
      const detail = await commissionRateApi.getById(r.id)
      openEditForm(detail)
    } catch (err) {
      logger.error('CommissionRatePage', 'Részletek betöltési hiba:', err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setEditingLoadingId(null)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli a jutalék mértéket?')) return
    try {
      await commissionRateApi.delete(id)
      toast.success('Jutalék mérték törölve')
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const filtered = safeArray<CommissionRate>(rates).filter((r) => {
    if (filter.entityType && r.entityType !== filter.entityType) return false
    if (filter.currencyCode && r.currencyCode !== filter.currencyCode) return false
    return true
  })

  const entityTypes = [...new Set(rates.map((r) => r.entityType))].sort()
  const currencies = [...new Set(rates.map((r) => r.currencyCode).filter(Boolean))].sort()

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Percent />
          {t('commissions.jutalekMertekek')}
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
          {t('commissions.ujMertek')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {showForm && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">
            {editingId ? 'Mérték szerkesztése' : 'Új jutalék mérték'}
          </h2>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="form-label">{t('commissions.entitasTipus')}</label>
              <select
                className="form-input"
                value={form.entityType}
                onChange={(e) => setForm({ ...form, entityType: e.target.value })}
              >
                <option value="BRANCH">{t('commissions.fiok')}</option>
                <option value="WORKER">{t('commissions.dolgozo')}</option>
                <option value="CUSTOMER">{t('common.customer')}</option>
                <option value="GLOBAL">{t('commissions.globalis')}</option>
              </select>
            </div>
            <div>
              <label className="form-label">{t('commissions.entitasNeve')}</label>
              <input
                className="form-input"
                value={form.entityName}
                onChange={(e) => setForm({ ...form, entityName: e.target.value })}
                placeholder="Üres = mindegyik"
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
              <label className="form-label">{t('commissions.mertek')}</label>
              <input
                className="form-input"
                type="number"
                step="0.01"
                value={form.rate}
                onChange={(e) => setForm({ ...form, rate: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('commissions.ervenyessegKezdete')}</label>
              <input
                className="form-input"
                type="date"
                value={form.validFrom}
                onChange={(e) => setForm({ ...form, validFrom: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('commissions.ervenyessegVege')}</label>
              <input
                className="form-input"
                type="date"
                value={form.validTo}
                onChange={(e) => setForm({ ...form, validTo: e.target.value })}
                placeholder="Üres = határozatlan"
              />
            </div>
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

      {/* Filters */}
      <div className="form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">{t('commissions.entitasTipus')}</label>
          <select
            className="form-input"
            value={filter.entityType}
            onChange={(e) => setFilter({ ...filter, entityType: e.target.value })}
          >
            <option value="">{t('common.all')}</option>
            {entityTypes.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="form-label">{t('common.currency')}</label>
          <select
            className="form-input"
            value={filter.currencyCode}
            onChange={(e) => setFilter({ ...filter, currencyCode: e.target.value })}
          >
            <option value="">{t('common.all')}</option>
            {currencies.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>
        <span className="text-sm text-gray-500">
          {filtered.length} {t('commissions.talalat')}
        </span>
      </div>

      <div className="form-panel">
        {loading ? (
          <div>{i18n.t('literals.betoltes')}</div>
        ) : filtered.length === 0 ? (
          <div className="text-center text-gray-500 py-4">
            {t('commissions.nincsJutalekMertek')}
          </div>
        ) : (
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('commissions.entitasTipus')}</th>
                <th>{t('archiving.entitas')}</th>
                <th>{t('common.currency')}</th>
                <th>{t('commissions.mertek2')}</th>
                <th>{t('commissions.ervenyesseg')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((r) => (
                <tr key={r.id}>
                  <td>{r.entityType}</td>
                  <td>{r.entityName || '— Mind —'}</td>
                  <td>{r.currencyCode || '— Mind —'}</td>
                  <td className="font-mono">
                    {r.rate}
                    {i18n.t('literals.lit-30')}
                  </td>
                  <td className="text-sm">
                    {r.validFrom}
                    {i18n.t('literals.lit-32')}
                    {r.validTo || 'határozatlan'}
                  </td>
                  <td>
                    <div className="flex gap-1">
                      <button
                        onClick={() => void handleEdit(r)}
                        className="form-button text-xs"
                        disabled={editingLoadingId === r.id}
                        title={t('common.edit')}
                        aria-label={t('common.edit')}
                      >
                        <Edit2
                          size={12}
                          className={editingLoadingId === r.id ? 'animate-pulse' : ''}
                        />
                      </button>
                      <button
                        onClick={() => void handleDelete(r.id)}
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
        )}
      </div>
    </div>
  )
}
