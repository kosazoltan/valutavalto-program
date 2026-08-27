import { useState, useEffect, useCallback } from 'react'
import { Shield, Search, RefreshCw, Plus, AlertTriangle, Eye, Play } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface PoliceRequestItem {
  id: string | number
  requestNumber?: string
  requestDate?: string
  status?: string
  requestedBy?: string
  customerName?: string | null
  documentNumber?: string | null
  dateRangeFrom?: string | null
  dateRangeTo?: string | null
  responseData?: string | null
  completedAt?: string | null
  createdByName?: string | null
}

interface PolicePageResponse {
  content?: PoliceRequestItem[]
}

interface PoliceFormState {
  requestNumber: string
  requestDate: string
  requestedBy: string
  customerName: string
  documentNumber: string
  dateRangeFrom: string
  dateRangeTo: string
}

export default function PoliceRequestPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<PoliceRequestItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [form, setForm] = useState<PoliceFormState | null>(null)
  const [details, setDetails] = useState<PoliceRequestItem | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<PoliceRequestItem[] | PolicePageResponse>('/police/requests')
      const payload = Array.isArray(response.data) ? response.data : response.data.content
      setItems(safeArray<(typeof items)[0]>(payload))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PoliceRequestPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const openNewForm = () => {
    setError(null)
    setMessage(null)
    setForm({
      requestNumber: '',
      requestDate: new Date().toISOString().slice(0, 10),
      requestedBy: '',
      customerName: '',
      documentNumber: '',
      dateRangeFrom: '',
      dateRangeTo: '',
    })
  }

  const createRequest = async () => {
    if (!form) return
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      await api.post('/police/requests', {
        requestNumber: form.requestNumber.trim(),
        requestDate: form.requestDate,
        requestedBy: form.requestedBy.trim(),
        customerName: form.customerName.trim() || null,
        documentNumber: form.documentNumber.trim() || null,
        dateRangeFrom: form.dateRangeFrom || null,
        dateRangeTo: form.dateRangeTo || null,
      })
      setForm(null)
      setMessage('Rendőrségi megkeresés rögzítve.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PoliceRequestPage', 'Létrehozási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const loadDetails = async (id: string | number) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const response = await api.get<PoliceRequestItem>(`/police/requests/${id}`)
      setDetails(response.data)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PoliceRequestPage', 'Részlet betöltési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const processRequest = async (id: string | number) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const response = await api.post<PoliceRequestItem>(`/police/requests/${id}/process`)
      setDetails(response.data)
      setMessage('Rendőrségi megkeresés feldolgozva.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('PoliceRequestPage', 'Feldolgozási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
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
          <Shield className="h-6 w-6" />
          {t('police.rendorsegiMegkeresesek')}
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

      {form && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">{i18n.t('literals.uj-rendorsegi-megkereses')}</h2>
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <div>
              <label htmlFor="police-request-number" className="form-label">
                {i18n.t('literals.iktatoszam')}
              </label>
              <input
                id="police-request-number"
                value={form.requestNumber}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, requestNumber: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="police-request-date" className="form-label">
                {i18n.t('literals.datum-2')}
              </label>
              <input
                id="police-request-date"
                type="date"
                value={form.requestDate}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, requestDate: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="police-requested-by" className="form-label">
                {i18n.t('literals.eloado')}
              </label>
              <input
                id="police-requested-by"
                value={form.requestedBy}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, requestedBy: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="police-customer-name" className="form-label">
                {i18n.t('literals.ugyfel-neve')}
              </label>
              <input
                id="police-customer-name"
                value={form.customerName}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, customerName: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="police-document-number" className="form-label">
                {i18n.t('literals.okmanyszam')}
              </label>
              <input
                id="police-document-number"
                value={form.documentNumber}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, documentNumber: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="police-date-from" className="form-label">
                {i18n.t('literals.idoszak-kezdete')}
              </label>
              <input
                id="police-date-from"
                type="date"
                value={form.dateRangeFrom}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, dateRangeFrom: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="police-date-to" className="form-label">
                {i18n.t('literals.idoszak-vege')}
              </label>
              <input
                id="police-date-to"
                type="date"
                value={form.dateRangeTo}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, dateRangeTo: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void createRequest()}
              disabled={
                saving ||
                !form.requestNumber.trim() ||
                !form.requestDate ||
                !form.requestedBy.trim()
              }
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

      {details && (
        <div className="rounded border border-gray-200 bg-white p-4 text-sm">
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-base font-semibold">
              {i18n.t('literals.megkereses-reszletei')}
              {details.requestNumber}
            </h2>
            <button type="button" onClick={() => setDetails(null)} className="form-button">
              {i18n.t('literals.bezaras')}
            </button>
          </div>
          <div className="grid gap-2 md:grid-cols-2 xl:grid-cols-4">
            <div>
              <span className="text-gray-500">{i18n.t('literals.eloado-2')}</span>{' '}
              {details.requestedBy ?? '-'}
            </div>
            <div>
              <span className="text-gray-500">{i18n.t('literals.ugyfel')}</span>{' '}
              {details.customerName ?? '-'}
            </div>
            <div>
              <span className="text-gray-500">{i18n.t('literals.okmanyszam-2')}</span>{' '}
              {details.documentNumber ?? '-'}
            </div>
            <div>
              <span className="text-gray-500">{i18n.t('literals.statusz-2')}</span>{' '}
              {details.status ?? '-'}
            </div>
            <div>
              <span className="text-gray-500">{i18n.t('literals.idoszak-3')}</span>{' '}
              {details.dateRangeFrom ?? '-'}
              {i18n.t('literals.lit-39')} {details.dateRangeTo ?? '-'}
            </div>
            <div>
              <span className="text-gray-500">{i18n.t('literals.rogzitette')}</span>{' '}
              {details.createdByName ?? '-'}
            </div>
            <div>
              <span className="text-gray-500">{i18n.t('literals.lezarva-2')}</span>{' '}
              {details.completedAt ? new Date(details.completedAt).toLocaleString('hu-HU') : '-'}
            </div>
          </div>
          {details.responseData && (
            <pre className="mt-3 max-h-48 overflow-auto rounded bg-gray-50 p-3 text-xs">
              {details.responseData}
            </pre>
          )}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('police.iktatoszam')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.date')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.status2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('police.eloado')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.ugyfel-2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.okmanyszam')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('common.actions')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.requestNumber ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.requestDate ? new Date(item.requestDate).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.requestedBy ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.customerName ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.documentNumber ?? '-'}</td>
                  <td className="px-4 py-3 text-right whitespace-nowrap">
                    <button
                      onClick={() => void loadDetails(item.id)}
                      disabled={saving}
                      className="form-button mr-2 p-1 text-blue-600"
                      title="Részletek"
                    >
                      <Eye className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => void processRequest(item.id)}
                      disabled={saving || !['RECEIVED', 'PROCESSING'].includes(item.status ?? '')}
                      className="form-button p-1 text-green-700"
                      title="Feldolgozás"
                    >
                      <Play className="h-4 w-4" />
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
