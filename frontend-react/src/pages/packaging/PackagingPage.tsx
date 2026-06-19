import { useCallback, useEffect, useMemo, useState } from 'react'
import { Package, Plus, RefreshCw, Trash2, AlertCircle } from 'lucide-react'
import { branchApi, currencyApi, packagingApi, type BranchInfo, type Currency, type PackagingRecord } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'

interface PackagingFormState {
  currencyCode: string
  packagingDate: string
  bundleCount: string
  denomination: string
  bundleSize: string
  notes: string
}

const emptyForm = (): PackagingFormState => ({
  currencyCode: '',
  packagingDate: new Date().toISOString().slice(0, 10),
  bundleCount: '1',
  denomination: '',
  bundleSize: '100',
  notes: '',
})

export default function PackagingPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [records, setRecords] = useState<PackagingRecord[]>([])
  const [selectedBranchId, setSelectedBranchId] = useState(worker?.branchId || '')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [form, setForm] = useState<PackagingFormState>(emptyForm)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const selectedBranch = useMemo(
    () => branches.find((branch) => branch.id === selectedBranchId),
    [branches, selectedBranchId],
  )

  const loadReferenceData = useCallback(async () => {
    try {
      setError(null)
      const [branchData, currencyData] = await Promise.all([
        branchApi.listActive(),
        currencyApi.getActive(),
      ])
      const safeBranches = safeArray<BranchInfo>(branchData)
      const safeCurrencies = safeArray<Currency>(currencyData)
      setBranches(safeBranches)
      setCurrencies(safeCurrencies)
      setSelectedBranchId((current) => current || safeBranches[0]?.id || '')
      setForm((current) => ({
        ...current,
        currencyCode: current.currencyCode || safeCurrencies[0]?.code || '',
      }))
    } catch (err) {
      const message = getErrorMessage(err)
      logger.error('PackagingPage', 'Referenciaadat betöltési hiba:', err)
      setError(message)
    }
  }, [])

  const loadRecords = useCallback(async () => {
    if (!selectedBranchId) {
      setRecords([])
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      setError(null)
      setRecords(safeArray<PackagingRecord>(await packagingApi.list(selectedBranchId, fromDate, toDate)))
    } catch (err) {
      const message = getErrorMessage(err)
      logger.error('PackagingPage', 'Göngyöleg lista betöltési hiba:', err)
      setError(message)
      setRecords([])
    } finally {
      setLoading(false)
    }
  }, [selectedBranchId, fromDate, toDate])

  useEffect(() => {
    void loadReferenceData()
  }, [loadReferenceData])

  useEffect(() => {
    void loadRecords()
  }, [loadRecords])

  const handleCreate = async () => {
    if (!selectedBranchId) {
      setError(t('packaging.selectBranch'))
      return
    }

    try {
      setSaving(true)
      setError(null)
      await packagingApi.create({
        branchId: selectedBranchId,
        currencyCode: form.currencyCode,
        packagingDate: form.packagingDate,
        bundleCount: Number(form.bundleCount),
        denomination: Number(form.denomination),
        bundleSize: Number(form.bundleSize) || undefined,
        notes: form.notes,
      })
      setForm((current) => ({
        ...emptyForm(),
        currencyCode: current.currencyCode,
        packagingDate: current.packagingDate,
      }))
      await loadRecords()
    } catch (err) {
      const message = getErrorMessage(err)
      logger.error('PackagingPage', 'Göngyöleg rögzítési hiba:', err)
      setError(message)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (record: PackagingRecord) => {
    if (!confirm(t('packaging.confirmDelete'))) return

    try {
      setSaving(true)
      setError(null)
      await packagingApi.delete(record.id)
      await loadRecords()
    } catch (err) {
      const message = getErrorMessage(err)
      logger.error('PackagingPage', 'Göngyöleg törlési hiba:', err)
      setError(message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <h1 className="flex items-center gap-2 text-xl font-bold text-gray-800">
          <Package />
          {t('packaging.title')}
        </h1>
        <button type="button" className="form-button" onClick={() => void loadRecords()} disabled={loading}>
          <RefreshCw size={16} />
          {t('common.refresh')}
        </button>
      </div>

      {error && (
        <div className="form-panel border-red-200 bg-red-50 text-red-700">
          <div className="flex items-center gap-2">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      <div className="form-panel">
        <div className="grid gap-3 md:grid-cols-4">
          <label className="form-label">
            {t('packaging.branch')}
            <select
              className="form-input mt-1"
              value={selectedBranchId}
              data-testid="packaging-branch"
              onChange={(event) => setSelectedBranchId(event.target.value)}
            >
              {!selectedBranchId && <option value="">{t('packaging.selectBranch')}</option>}
              {branches.map((branch) => (
                <option key={branch.id} value={branch.id}>
                  {branch.code ? `${branch.code} - ${branch.name}` : branch.name}
                </option>
              ))}
            </select>
          </label>
          <label className="form-label">
            {t('packaging.dateFrom')}
            <input className="form-input mt-1" type="date" value={fromDate} onChange={(event) => setFromDate(event.target.value)} />
          </label>
          <label className="form-label">
            {t('packaging.dateTo')}
            <input className="form-input mt-1" type="date" value={toDate} onChange={(event) => setToDate(event.target.value)} />
          </label>
          <div className="text-sm text-gray-600 md:self-end">
            {selectedBranch ? selectedBranch.name : t('packaging.noSelectedBranch')}
          </div>
        </div>
      </div>

      <div className="form-panel">
        <h2 className="mb-3 flex items-center gap-2 text-base font-semibold">
          <Plus size={16} />
          {t('packaging.newRecord')}
        </h2>
        <div className="grid gap-3 md:grid-cols-6">
          <label className="form-label">
            {t('common.currency')}
            <select
              className="form-input mt-1"
              value={form.currencyCode}
              data-testid="packaging-currency"
              onChange={(event) => setForm({ ...form, currencyCode: event.target.value })}
            >
              {currencies.map((currency) => (
                <option key={currency.code} value={currency.code}>
                  {currency.code}
                </option>
              ))}
            </select>
          </label>
          <label className="form-label">
            {t('packaging.packagingDate')}
            <input
              className="form-input mt-1"
              type="date"
              value={form.packagingDate}
              data-testid="packaging-date"
              onChange={(event) => setForm({ ...form, packagingDate: event.target.value })}
            />
          </label>
          <label className="form-label">
            {t('packaging.denomination')}
            <input
              className="form-input mt-1"
              type="number"
              min="1"
              value={form.denomination}
              data-testid="packaging-denomination"
              onChange={(event) => setForm({ ...form, denomination: event.target.value })}
            />
          </label>
          <label className="form-label">
            {t('packaging.bundleCount')}
            <input
              className="form-input mt-1"
              type="number"
              min="1"
              value={form.bundleCount}
              data-testid="packaging-bundle-count"
              onChange={(event) => setForm({ ...form, bundleCount: event.target.value })}
            />
          </label>
          <label className="form-label">
            {t('packaging.bundleSize')}
            <input
              className="form-input mt-1"
              type="number"
              min="1"
              value={form.bundleSize}
              data-testid="packaging-bundle-size"
              onChange={(event) => setForm({ ...form, bundleSize: event.target.value })}
            />
          </label>
          <label className="form-label">
            {t('common.note')}
            <input
              className="form-input mt-1"
              value={form.notes}
              data-testid="packaging-notes"
              onChange={(event) => setForm({ ...form, notes: event.target.value })}
            />
          </label>
        </div>
        <div className="mt-3">
          <button
            type="button"
            className="form-button-primary"
            data-testid="packaging-create"
            onClick={() => void handleCreate()}
            disabled={saving || !selectedBranchId || !form.currencyCode || !form.packagingDate || !form.denomination || !form.bundleCount}
          >
            <Plus size={16} />
            {t('packaging.create')}
          </button>
        </div>
      </div>

      <div className="form-panel p-0">
        {loading ? (
          <div className="p-6 text-center text-gray-500">{t('common.loading')}</div>
        ) : records.length === 0 ? (
          <div className="p-6 text-center text-gray-500">{t('packaging.noRecords')}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('common.date')}</th>
                  <th>{t('common.currency')}</th>
                  <th className="text-right">{t('packaging.denomination')}</th>
                  <th className="text-right">{t('packaging.bundle')}</th>
                  <th className="text-right">{t('packaging.size')}</th>
                  <th>{t('common.note')}</th>
                  <th className="no-print w-20">{t('common.operation')}</th>
                </tr>
              </thead>
              <tbody>
                {records.map((record) => (
                  <tr key={record.id}>
                    <td>{formatDate(record.packagingDate)}</td>
                    <td className="font-semibold">{record.currencyCode}</td>
                    <td className="text-right">{record.denomination.toLocaleString('hu-HU')}</td>
                    <td className="text-right">{record.bundleCount.toLocaleString('hu-HU')}</td>
                    <td className="text-right">{(record.bundleSize ?? 100).toLocaleString('hu-HU')}</td>
                    <td>{record.notes || '-'}</td>
                    <td className="no-print">
                      <button
                        type="button"
                        className="toolbar-button text-red-700"
                        title={t('common.delete')}
                        onClick={() => void handleDelete(record)}
                        disabled={saving}
                      >
                        <Trash2 size={14} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

function formatDate(value: string): string {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleDateString('hu-HU')
}
