import { useState, useEffect, useCallback } from 'react'
import { FileCheck2, Search, RefreshCw, Plus, Link as LinkIcon, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface StampBatchItem {
  id: string
  branchId?: string
  serialPrefix?: string
  serialStart?: number
  serialEnd?: number
  totalCount?: number
  usedCount?: number
  receivedAt?: string
  receivedBy?: string
  note?: string
}

interface StampAssignmentItem {
  id: string
  batchId?: string
  serialNumber?: string
  transactionId?: number
  assignedAt?: string
  assignedBy?: string
}

interface BatchForm {
  serialPrefix: string
  serialStart: string
  serialEnd: string
  note: string
}

interface AssignForm {
  serialNumber: string
  transactionId: string
}

function fmtDate(value?: string): string {
  if (!value) return '-'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString('hu-HU')
}

export default function StampPage() {
  const { t } = useTranslation()
  const branchId = useAuthStore((state) => state.worker?.branchId ?? '')
  const [items, setItems] = useState<StampBatchItem[]>([])
  const [usedItems, setUsedItems] = useState<StampAssignmentItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [batchForm, setBatchForm] = useState<BatchForm | null>(null)
  const [assignForm, setAssignForm] = useState<AssignForm | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [inventoryResponse, usedResponse] = await Promise.all([
        api.get<StampBatchItem[]>('/stamps/inventory'),
        api.get<StampAssignmentItem[]>('/stamps/used'),
      ])
      setItems(safeArray<StampBatchItem>(inventoryResponse.data))
      setUsedItems(safeArray<StampAssignmentItem>(usedResponse.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('StampPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  const openBatchForm = () => {
    setBatchForm({ serialPrefix: '', serialStart: '', serialEnd: '', note: '' })
    setMessage(null)
    setError(null)
  }

  const openAssignForm = () => {
    setAssignForm({ serialNumber: '', transactionId: '' })
    setMessage(null)
    setError(null)
  }

  const saveBatch = async () => {
    if (!batchForm) return
    if (!branchId) {
      setError('Hiányzó iroda azonosító.')
      return
    }
    if (
      !batchForm.serialPrefix.trim() ||
      !batchForm.serialStart.trim() ||
      !batchForm.serialEnd.trim()
    ) {
      setError('Előtag, kezdő és záró sorszám megadása kötelező.')
      return
    }

    try {
      setSaving(true)
      setError(null)
      await api.post('/stamps/receive', {
        branchId,
        serialPrefix: batchForm.serialPrefix.trim().toUpperCase(),
        serialStart: Number(batchForm.serialStart),
        serialEnd: Number(batchForm.serialEnd),
        note: batchForm.note.trim() || undefined,
      })
      setMessage('Matrica batch felvéve.')
      setBatchForm(null)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('StampPage', 'Batch felvételi hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const assignStamp = async () => {
    if (!assignForm) return
    if (!assignForm.serialNumber.trim() || !assignForm.transactionId.trim()) {
      setError('Matrica sorszám és tranzakció ID megadása kötelező.')
      return
    }

    try {
      setSaving(true)
      setError(null)
      await api.post('/stamps/assign', {
        serialNumber: assignForm.serialNumber.trim(),
        transactionId: Number(assignForm.transactionId),
      })
      setMessage('Matrica hozzárendelve.')
      setAssignForm(null)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('StampPage', 'Hozzárendelési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileCheck2 className="h-6 w-6" />
          {t('stamps.belyegek')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button onClick={openAssignForm} className="form-button flex items-center gap-1">
            <LinkIcon className="h-4 w-4" />
            {i18n.t('literals.hozzarendeles')}
          </button>
          <button onClick={openBatchForm} className="form-button-primary flex items-center gap-1">
            <Plus className="h-4 w-4" />
            {i18n.t('literals.uj-batch')}
          </button>
        </div>
      </div>

      {batchForm && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">{i18n.t('literals.uj-matrica-batch')}</h2>
          <div className="grid gap-3 md:grid-cols-4">
            <div>
              <label htmlFor="stamp-prefix" className="form-label">
                {i18n.t('literals.elotag')}
              </label>
              <input
                id="stamp-prefix"
                value={batchForm.serialPrefix}
                onChange={(e) =>
                  setBatchForm((current) =>
                    current ? { ...current, serialPrefix: e.target.value } : current,
                  )
                }
                className="form-input w-full uppercase"
              />
            </div>
            <div>
              <label htmlFor="stamp-start" className="form-label">
                {i18n.t('literals.kezdo-sorszam')}
              </label>
              <input
                id="stamp-start"
                value={batchForm.serialStart}
                onChange={(e) =>
                  setBatchForm((current) =>
                    current ? { ...current, serialStart: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="numeric"
              />
            </div>
            <div>
              <label htmlFor="stamp-end" className="form-label">
                {i18n.t('literals.zaro-sorszam')}
              </label>
              <input
                id="stamp-end"
                value={batchForm.serialEnd}
                onChange={(e) =>
                  setBatchForm((current) =>
                    current ? { ...current, serialEnd: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="numeric"
              />
            </div>
            <div>
              <label htmlFor="stamp-note" className="form-label">
                {i18n.t('literals.megjegyzes')}
              </label>
              <input
                id="stamp-note"
                value={batchForm.note}
                onChange={(e) =>
                  setBatchForm((current) =>
                    current ? { ...current, note: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void saveBatch()}
              disabled={saving}
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button type="button" onClick={() => setBatchForm(null)} className="form-button">
              {i18n.t('literals.megse')}
            </button>
          </div>
        </div>
      )}

      {assignForm && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">
            {i18n.t('literals.matrica-hozzarendelese-tranzakciohoz')}
          </h2>
          <div className="grid gap-3 md:grid-cols-2">
            <div>
              <label htmlFor="stamp-serial" className="form-label">
                {i18n.t('literals.matrica-sorszam')}
              </label>
              <input
                id="stamp-serial"
                value={assignForm.serialNumber}
                onChange={(e) =>
                  setAssignForm((current) =>
                    current ? { ...current, serialNumber: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                placeholder="ABC-123"
              />
            </div>
            <div>
              <label htmlFor="stamp-transaction" className="form-label">
                {i18n.t('literals.tranzakcio-id')}
              </label>
              <input
                id="stamp-transaction"
                value={assignForm.transactionId}
                onChange={(e) =>
                  setAssignForm((current) =>
                    current ? { ...current, transactionId: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="numeric"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void assignStamp()}
              disabled={saving}
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button type="button" onClick={() => setAssignForm(null)} className="form-button">
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
                {i18n.t('literals.elotag')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.tartomany-2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.osszes')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('stamps.felhasznalva')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.felveve')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.megjegyzes')}
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
                  <td className="px-4 py-3 text-sm font-mono font-semibold">
                    {item.serialPrefix ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-sm font-mono">
                    {item.serialStart ?? '-'}
                    {i18n.t('literals.lit-17')}
                    {item.serialEnd ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.totalCount ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.usedCount ?? 0}</td>
                  <td className="px-4 py-3 text-sm">{fmtDate(item.receivedAt)}</td>
                  <td className="px-4 py-3 text-sm">{item.note ?? '-'}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="rounded border border-gray-200 bg-white p-3">
        <h2 className="mb-3 text-base font-semibold">{i18n.t('literals.felhasznalt-matricak')}</h2>
        <div className="data-grid overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                  {t('stamps.belyegSzam')}
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                  {i18n.t('literals.tranzakcio-id')}
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                  {i18n.t('literals.hozzarendelve')}
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                  {i18n.t('literals.felhasznalo-2')}
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {usedItems.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                    {t('common.noData')}
                  </td>
                </tr>
              ) : (
                usedItems.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-mono font-semibold">
                      {item.serialNumber ?? '-'}
                    </td>
                    <td className="px-4 py-3 text-sm">{item.transactionId ?? '-'}</td>
                    <td className="px-4 py-3 text-sm">{fmtDate(item.assignedAt)}</td>
                    <td className="px-4 py-3 text-sm">{item.assignedBy ?? '-'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
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
