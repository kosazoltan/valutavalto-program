import { useState, useEffect, useCallback } from 'react'
import { Printer, Search, RefreshCw, Plus, Edit2, AlertTriangle, Save, X, Eye } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface PrintTemplateItem {
  id: string | number
  name?: string
  templateType?: string
  content?: string
  isDefault?: boolean
  companyId?: number
}

interface PrintTemplateForm {
  id?: string | number
  name: string
  templateType: string
  content: string
  isDefault: boolean
}

export default function PrintTemplatePage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<PrintTemplateItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [previewing, setPreviewing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [form, setForm] = useState<PrintTemplateForm | null>(null)
  const [preview, setPreview] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<PrintTemplateItem[]>('/print-templates', {
        params: typeFilter.trim() ? { type: typeFilter.trim() } : undefined,
      })
      setItems(safeArray<PrintTemplateItem>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PrintTemplatePage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [typeFilter])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const openNewForm = () => {
    setForm({
      name: '',
      templateType: typeFilter.trim() || 'RECEIPT',
      content: '',
      isDefault: false,
    })
    setPreview(null)
    setMessage(null)
    setError(null)
  }

  const openEditForm = async (item: PrintTemplateItem) => {
    try {
      setError(null)
      setMessage(null)
      const response = await api.get<PrintTemplateItem>(`/print-templates/${item.id}`)
      const detail = response.data ?? item
      setForm({
        id: detail.id,
        name: detail.name ?? '',
        templateType: detail.templateType ?? '',
        content: detail.content ?? '',
        isDefault: detail.isDefault ?? false,
      })
      setPreview(null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PrintTemplatePage', 'Sablon reszlet betoltesi hiba:', err)
      setError(msg)
    }
  }

  const saveForm = async () => {
    if (!form) return
    if (!form.name.trim() || !form.templateType.trim() || !form.content.trim()) {
      setError('Név, típus és tartalom megadása kötelező.')
      return
    }

    const payload = {
      name: form.name.trim(),
      templateType: form.templateType.trim(),
      content: form.content,
      isDefault: form.isDefault,
    }

    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      if (form.id != null) {
        await api.put<PrintTemplateItem>(`/print-templates/${form.id}`, payload)
        setMessage('Sablon frissítve.')
      } else {
        const response = await api.post<PrintTemplateItem>('/print-templates', payload)
        const created = response.data
        setForm(
          created?.id
            ? {
                id: created.id,
                name: created.name ?? payload.name,
                templateType: created.templateType ?? payload.templateType,
                content: created.content ?? payload.content,
                isDefault: created.isDefault ?? payload.isDefault,
              }
            : form,
        )
        setMessage('Sablon létrehozva.')
      }
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PrintTemplatePage', 'Mentesi hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const previewForm = async () => {
    if (!form?.id) {
      setError('Előnézethez előbb mentsd a sablont.')
      return
    }
    try {
      setPreviewing(true)
      setError(null)
      const response = await api.post<string>(`/print-templates/${form.id}/preview`, {
        data: {
          ugyfelNev: 'Minta Ügyfél',
          valuta: 'EUR',
          osszeg: '100',
          datum: new Date().toLocaleDateString('hu-HU'),
        },
      })
      setPreview(response.data ?? '')
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PrintTemplatePage', 'Elonezet hiba:', err)
      setError(msg)
    } finally {
      setPreviewing(false)
    }
  }

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Printer className="h-6 w-6" />
          {t('print.nyomtatasiSablonok')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button onClick={openNewForm} className="form-button-primary flex items-center gap-1">
            <Plus className="h-4 w-4" />
            {t('common.new')}
          </button>
        </div>
      </div>

      <div className="grid gap-2 md:grid-cols-[1fr_220px]">
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
        <input
          type="text"
          placeholder="Típus szűrő, pl. RECEIPT"
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value.toUpperCase())}
          className="form-input w-full"
        />
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

      {form && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-base font-semibold">
              {form.id ? 'Sablon szerkesztése' : 'Új sablon'}
            </h2>
            <button
              type="button"
              className="form-button p-2"
              title="Bezárás"
              onClick={() => {
                setForm(null)
                setPreview(null)
              }}
            >
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="grid gap-3 md:grid-cols-3">
            <div>
              <label htmlFor="print-template-name" className="form-label">
                {i18n.t('literals.nev')}
              </label>
              <input
                id="print-template-name"
                value={form.name}
                onChange={(e) =>
                  setForm((current) => (current ? { ...current, name: e.target.value } : current))
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="print-template-type" className="form-label">
                {i18n.t('literals.tipus')}
              </label>
              <input
                id="print-template-type"
                value={form.templateType}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, templateType: e.target.value.toUpperCase() } : current,
                  )
                }
                className="form-input w-full font-mono"
              />
            </div>
            <label className="flex items-end gap-2 pb-2 text-sm">
              <input
                type="checkbox"
                checked={form.isDefault}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, isDefault: e.target.checked } : current,
                  )
                }
              />
              {i18n.t('literals.alapertelmezett')}
            </label>
          </div>
          <div>
            <label htmlFor="print-template-content" className="form-label">
              {i18n.t('literals.tartalom')}
            </label>
            <textarea
              id="print-template-content"
              value={form.content}
              onChange={(e) =>
                setForm((current) => (current ? { ...current, content: e.target.value } : current))
              }
              className="form-input h-40 w-full font-mono text-sm"
            />
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() => void saveForm()}
              disabled={saving}
              className="form-button-primary flex items-center gap-1"
            >
              <Save className="h-4 w-4" />
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button
              type="button"
              onClick={() => void previewForm()}
              disabled={previewing || !form.id}
              className="form-button flex items-center gap-1"
            >
              <Eye className="h-4 w-4" />
              {previewing ? 'Előnézet...' : 'Előnézet'}
            </button>
          </div>
          {preview != null && (
            <pre className="max-h-64 overflow-auto rounded border border-gray-200 bg-gray-50 p-3 text-sm whitespace-pre-wrap">
              {preview}
            </pre>
          )}
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
                {t('backup.tipus')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('print.alapertelmezett')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('competitors.muveletek')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.name ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.templateType ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.isDefault ? 'Igen' : 'Nem'}</td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => void openEditForm(item)}
                      className="form-button mr-2 p-1 text-blue-600"
                      title="Szerkesztés"
                    >
                      <Edit2 className="h-4 w-4" />
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
