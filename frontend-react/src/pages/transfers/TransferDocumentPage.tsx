import { useCallback, useEffect, useMemo, useState } from 'react'
import { FileCheck2, Search, RefreshCw, AlertTriangle, Printer, Eye, PackageCheck, Truck, CheckCircle2, Plus } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { transferDocumentApi, type TransferDocument } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'

interface CreateFormState {
  currencyCode: string
  quantity: string
  sourceType: string
  sourceId: string
  destinationType: string
  destinationId: string
  courierPin: string
  notes: string
}

const emptyForm = (): CreateFormState => ({
  currencyCode: 'HUF',
  quantity: '',
  sourceType: 'BRANCH',
  sourceId: '',
  destinationType: 'BRANCH',
  destinationId: '',
  courierPin: '',
  notes: '',
})

export default function TransferDocumentPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const [items, setItems] = useState<TransferDocument[]>([])
  const [selectedItem, setSelectedItem] = useState<TransferDocument | null>(null)
  const [form, setForm] = useState<CreateFormState>(emptyForm)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [courierPin, setCourierPin] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setItems(safeArray<TransferDocument>(await transferDocumentApi.list({ status: statusFilter || undefined })))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('TransferDocumentPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [statusFilter])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = useMemo(() => items.filter(item => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some(v =>
      v != null && String(v).toLowerCase().includes(term)
    )
  }), [items, searchTerm])

  const openDetails = async (id: string | number) => {
    try {
      setSaving(true)
      setError(null)
      setSelectedItem(await transferDocumentApi.get(id))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('TransferDocumentPage', 'Részlet betöltési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const replaceItem = (updated: TransferDocument) => {
    setItems((current) => current.map((item) => String(item.id) === String(updated.id) ? updated : item))
    setSelectedItem(updated)
  }

  const createDocument = async () => {
    if (!worker?.id) {
      setError(t('transferReceipts.missingWorker'))
      return
    }

    try {
      setSaving(true)
      setError(null)
      const created = await transferDocumentApi.create({
        senderId: Number(worker.id),
        currencyCode: form.currencyCode.trim().toUpperCase(),
        quantity: Number(form.quantity),
        sourceType: form.sourceType.trim(),
        sourceId: form.sourceId.trim(),
        destinationType: form.destinationType.trim(),
        destinationId: form.destinationId.trim(),
        courierPin: form.courierPin,
        notes: form.notes,
      })
      setForm(emptyForm())
      setSelectedItem(created)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('TransferDocumentPage', 'Létrehozási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const pickup = async (item: TransferDocument) => {
    if (!worker?.id) {
      setError(t('transferReceipts.missingWorker'))
      return
    }

    try {
      setSaving(true)
      setError(null)
      replaceItem(await transferDocumentApi.pickup(item.id, Number(worker.id), courierPin))
      setCourierPin('')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('TransferDocumentPage', 'Átvételi hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const deliver = async (item: TransferDocument) => {
    try {
      setSaving(true)
      setError(null)
      replaceItem(await transferDocumentApi.deliver(item.id))
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('TransferDocumentPage', 'Leadási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const confirmReceipt = async (item: TransferDocument) => {
    if (!worker?.id) {
      setError(t('transferReceipts.missingWorker'))
      return
    }

    try {
      setSaving(true)
      setError(null)
      replaceItem(await transferDocumentApi.confirm(item.id, Number(worker.id)))
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('TransferDocumentPage', 'Megerősítési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileCheck2 className="h-6 w-6" />
          {t('transferReceipts.title')}
        </h1>
        <div className="no-print flex items-center gap-2">
          <button onClick={() => window.print()} className="form-button" title={t('common.print')}>
            <Printer className="h-4 w-4" /> {t('common.print')}
          </button>
          <button onClick={() => void loadData()} className="form-button p-2" title={t('common.refresh')}>
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="no-print grid gap-3 md:grid-cols-3">
        <div className="relative md:col-span-2">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder={t('common.searchPlaceholder')}
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
        <select className="form-input" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
          <option value="">{t('common.all')}</option>
          <option value="PENDING">PENDING</option>
          <option value="PICKED_UP">PICKED_UP</option>
          <option value="DELIVERED">DELIVERED</option>
          <option value="CONFIRMED">CONFIRMED</option>
        </select>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="rounded border border-gray-200 bg-gray-50 p-3">
        <h2 className="mb-3 flex items-center gap-2 text-base font-semibold">
          <Plus size={16} />
          {t('transferReceipts.newDocument')}
        </h2>
        <div className="grid gap-3 md:grid-cols-4">
          <input className="form-input" data-testid="td-currency" value={form.currencyCode} onChange={(event) => setForm({ ...form, currencyCode: event.target.value })} placeholder={t('transferReceipts.currencyCode')} />
          <input className="form-input" data-testid="td-quantity" type="number" min="1" value={form.quantity} onChange={(event) => setForm({ ...form, quantity: event.target.value })} placeholder={t('transferReceipts.quantity')} />
          <input className="form-input" data-testid="td-source-type" value={form.sourceType} onChange={(event) => setForm({ ...form, sourceType: event.target.value })} placeholder={t('transferReceipts.sourceType')} />
          <input className="form-input" data-testid="td-source-id" value={form.sourceId} onChange={(event) => setForm({ ...form, sourceId: event.target.value })} placeholder={t('transferReceipts.sourceId')} />
          <input className="form-input" data-testid="td-destination-type" value={form.destinationType} onChange={(event) => setForm({ ...form, destinationType: event.target.value })} placeholder={t('transferReceipts.destinationType')} />
          <input className="form-input" data-testid="td-destination-id" value={form.destinationId} onChange={(event) => setForm({ ...form, destinationId: event.target.value })} placeholder={t('transferReceipts.destinationId')} />
          <input className="form-input" data-testid="td-courier-pin" value={form.courierPin} onChange={(event) => setForm({ ...form, courierPin: event.target.value })} placeholder={t('transferReceipts.courierPin')} />
          <input className="form-input" data-testid="td-notes" value={form.notes} onChange={(event) => setForm({ ...form, notes: event.target.value })} placeholder={t('common.note')} />
        </div>
        <button
          className="form-button-primary mt-3"
          data-testid="td-create"
          type="button"
          onClick={() => void createDocument()}
          disabled={saving || !form.currencyCode || !form.quantity || !form.sourceType || !form.sourceId || !form.destinationType || !form.destinationId}
        >
          <Plus size={16} />
          {t('common.create')}
        </button>
      </div>

      {selectedItem && (
        <div className="rounded border border-blue-200 bg-blue-50 p-3" data-testid="td-detail-panel">
          <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
            <div>
              <h2 className="font-semibold text-blue-950">{selectedItem.documentNumber ?? selectedItem.id}</h2>
              <p className="text-sm text-blue-900">
                {selectedItem.sourceType}:{selectedItem.sourceId} → {selectedItem.destinationType}:{selectedItem.destinationId}
              </p>
              <p className="mt-1 text-sm text-blue-900">
                {selectedItem.quantity ?? '-'} {selectedItem.currencyCode ?? ''} · {selectedItem.status ?? '-'}
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              {selectedItem.status === 'PENDING' && (
                <>
                  <input
                    className="form-input w-28"
                    data-testid="td-pickup-pin"
                    value={courierPin}
                    onChange={(event) => setCourierPin(event.target.value)}
                    placeholder={t('transferReceipts.courierPin')}
                  />
                  <button className="form-button" data-testid="td-pickup" onClick={() => void pickup(selectedItem)} disabled={saving}>
                    <PackageCheck size={16} />
                    {t('transferReceipts.pickup')}
                  </button>
                </>
              )}
              {selectedItem.status === 'PICKED_UP' && (
                <button className="form-button" data-testid="td-deliver" onClick={() => void deliver(selectedItem)} disabled={saving}>
                  <Truck size={16} />
                  {t('transferReceipts.deliver')}
                </button>
              )}
              {selectedItem.status === 'DELIVERED' && (
                <button className="form-button" data-testid="td-confirm" onClick={() => void confirmReceipt(selectedItem)} disabled={saving}>
                  <CheckCircle2 size={16} />
                  {t('transferReceipts.confirm')}
                </button>
              )}
            </div>
          </div>
          {selectedItem.notes && <div className="mt-3 rounded bg-white px-3 py-2 text-sm">{selectedItem.notes}</div>}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('transferReceipts.documentNumber')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('transferReceipts.fromBranch')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('transferReceipts.toBranch')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('transferReceipts.amount')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('transferReceipts.status')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('transferReceipts.date')}</th>
              <th className="no-print px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.loading')}</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.noData')}</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.documentNumber ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{formatLocation(item.sourceType, item.sourceId)}</td>
                <td className="px-4 py-3 text-sm">{formatLocation(item.destinationType, item.destinationId)}</td>
                <td className="px-4 py-3 text-sm text-right font-mono">{formatAmount(item.quantity)} {item.currencyCode ?? ''}</td>
                <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.createdAt ? new Date(item.createdAt).toLocaleString('hu-HU') : '-'}</td>
                <td className="no-print px-4 py-3 text-sm">
                  <button className="toolbar-button" data-testid={`td-detail-${item.id}`} title={t('common.details')} onClick={() => void openDetails(item.id)} disabled={saving}>
                    <Eye size={14} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('common.total')}: {filtered.length} / {items.length}
      </div>
    </div>
  )
}

function formatAmount(value: string | number | undefined): string {
  if (typeof value === 'number') return value.toLocaleString('hu-HU')
  if (typeof value === 'string') return value
  return '-'
}

function formatLocation(type?: string, id?: string): string {
  if (!type && !id) return '-'
  return `${type ?? '-'}:${id ?? '-'}`
}
