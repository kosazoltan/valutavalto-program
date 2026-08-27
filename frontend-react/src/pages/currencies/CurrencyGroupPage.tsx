import { useState, useEffect, useCallback } from 'react'
import { Layers, Search, RefreshCw, Plus, Edit2, Trash2, AlertTriangle } from 'lucide-react'
import { currencyGroupApi } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface CurrencyGroupItem {
  id: string | number
  code?: string
  name?: string
  description?: string | null
  currencyIds?: string | null
  isActive?: boolean
}

interface CurrencyGroupForm {
  id?: string | number
  code: string
  name: string
  description: string
  currencyIds: string
  isActive: boolean
}

function currencyCount(currencyIds?: string | null): string | number {
  if (!currencyIds) return '-'
  try {
    return safeArray<unknown>(JSON.parse(currencyIds)).length
  } catch {
    return '-'
  }
}

export default function CurrencyGroupPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<CurrencyGroupItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [form, setForm] = useState<CurrencyGroupForm | null>(null)
  const [editingLoadingId, setEditingLoadingId] = useState<string | number | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await currencyGroupApi.list()
      setItems(safeArray<(typeof items)[0]>(data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('CurrencyGroupPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const fillForm = (item?: CurrencyGroupItem) => {
    setForm({
      id: item?.id,
      code: item?.code ?? '',
      name: item?.name ?? '',
      description: item?.description ?? '',
      currencyIds: item?.currencyIds ?? '',
      isActive: item?.isActive ?? true,
    })
    setMessage(null)
    setError(null)
  }

  const openForm = () => {
    fillForm()
  }

  const openEditForm = async (item: CurrencyGroupItem) => {
    try {
      setEditingLoadingId(item.id)
      setMessage(null)
      setError(null)
      const detail = await currencyGroupApi.getById(String(item.id))
      fillForm(detail)
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CurrencyGroupPage', 'Részletek betöltési hiba:', err)
    } finally {
      setEditingLoadingId(null)
    }
  }

  const saveGroup = async () => {
    if (!form) return
    if (!form.code.trim() || !form.name.trim()) {
      setError('Kód és név megadása kötelező.')
      return
    }

    const payload = {
      code: form.code.trim().toUpperCase(),
      name: form.name.trim(),
      description: form.description.trim() || null,
      currencyIds: form.currencyIds.trim() || null,
      isActive: form.isActive,
    }

    try {
      setSaving(true)
      setError(null)
      if (form.id) {
        await currencyGroupApi.update(form.id, payload)
        setMessage('Valutacsoport frissítve.')
      } else {
        await currencyGroupApi.create(payload)
        setMessage('Valutacsoport létrehozva.')
      }
      setForm(null)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CurrencyGroupPage', 'Mentési hiba:', err)
    } finally {
      setSaving(false)
    }
  }

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  const handleDelete = async (id: string | number) => {
    if (!confirm('Biztosan törli?')) return
    try {
      setError(null)
      await currencyGroupApi.remove(id)
      setMessage('Valutacsoport törölve.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CurrencyGroupPage', 'Törlési hiba:', err)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Layers className="h-6 w-6" />
          {t('currencies.valutacsoportok')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => openForm()}
            className="form-button-primary flex items-center gap-1"
          >
            <Plus className="h-4 w-4" />
            {t('common.new')}
          </button>
        </div>
      </div>

      {form && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">
            {form.id ? 'Valutacsoport szerkesztése' : 'Új valutacsoport'}
          </h2>
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
            <div>
              <label htmlFor="currency-group-code" className="form-label">
                {i18n.t('literals.kod-3')}
              </label>
              <input
                id="currency-group-code"
                value={form.code}
                onChange={(e) =>
                  setForm((current) => (current ? { ...current, code: e.target.value } : current))
                }
                className="form-input w-full uppercase"
                maxLength={20}
              />
            </div>
            <div>
              <label htmlFor="currency-group-name" className="form-label">
                {i18n.t('literals.nev')}
              </label>
              <input
                id="currency-group-name"
                value={form.name}
                onChange={(e) =>
                  setForm((current) => (current ? { ...current, name: e.target.value } : current))
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="currency-group-description" className="form-label">
                {i18n.t('literals.leiras')}
              </label>
              <input
                id="currency-group-description"
                value={form.description}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, description: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="currency-group-currency-ids" className="form-label">
                {i18n.t('literals.valuta-id-k-json')}
              </label>
              <input
                id="currency-group-currency-ids"
                value={form.currencyIds}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, currencyIds: e.target.value } : current,
                  )
                }
                className="form-input w-full font-mono"
                placeholder="[1,2,3]"
              />
            </div>
            <label className="flex items-end gap-2 pb-2 text-sm">
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, isActive: e.target.checked } : current,
                  )
                }
              />
              {i18n.t('literals.aktiv-2')}
            </label>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void saveGroup()}
              disabled={saving}
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button type="button" onClick={() => setForm(null)} className="form-button">
              {i18n.t('literals.megse')}
            </button>
          </div>
        </div>
      )}

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Keresés..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {message && (
        <div className="rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
          {message}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('competitors.nev')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.kod-3')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('currencies.leiras')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('currencies.valutakSzama')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.active')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('competitors.muveletek')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.name ?? '-'}</td>
                  <td className="px-4 py-3 text-sm font-mono font-semibold">{item.code ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.description ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{currencyCount(item.currencyIds)}</td>
                  <td className="px-4 py-3 text-sm">{item.isActive ? 'Igen' : 'Nem'}</td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => void openEditForm(item)}
                      className="form-button mr-2 p-1 text-blue-600"
                      title="Szerkesztés"
                      disabled={editingLoadingId === item.id}
                    >
                      <Edit2
                        className={`h-4 w-4 ${editingLoadingId === item.id ? 'animate-pulse' : ''}`}
                      />
                    </button>
                    <button
                      onClick={() => handleDelete(item.id)}
                      className="form-button p-1 text-red-600"
                      title="Törlés"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}
        {filtered.length}
        {i18n.t('literals.lit-10')}
        {items.length}
      </div>
    </div>
  )
}
