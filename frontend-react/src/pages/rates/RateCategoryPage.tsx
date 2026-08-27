import { useState, useEffect, useCallback } from 'react'
import { Bookmark, Search, RefreshCw, Plus, Edit2, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface RateCategoryItem {
  id: string | number
  branchId?: string
  currencyCode?: string
  category?: 'SMALL' | 'STANDARD' | 'LARGE' | string
  buyRate?: number | string
  sellRate?: number | string
  minAmount?: number | string | null
  maxAmount?: number | string | null
  validFrom?: string
  validTo?: string | null
}

interface RateCategoryForm {
  currencyCode: string
  category: 'SMALL' | 'STANDARD' | 'LARGE'
  buyRate: string
  sellRate: string
  minAmount: string
  maxAmount: string
}

function formatRateCategoryValue(value: RateCategoryItem[keyof RateCategoryItem]): string {
  if (value == null || value === '') return '-'
  return String(value).replace('.', ',')
}

function formatAmountRange(
  minAmount: RateCategoryItem['minAmount'],
  maxAmount: RateCategoryItem['maxAmount'],
): string {
  const min = formatRateCategoryValue(minAmount)
  const max = formatRateCategoryValue(maxAmount)
  if (min === '-' && max === '-') return '-'
  if (min === '-') return `≤ ${max}`
  if (max === '-') return `≥ ${min}`
  return `${min} - ${max}`
}

export default function RateCategoryPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<RateCategoryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [form, setForm] = useState<RateCategoryForm | null>(null)
  const [probeCurrency, setProbeCurrency] = useState('EUR')
  const [probeAmount, setProbeAmount] = useState('1000')
  const [probeResult, setProbeResult] = useState<RateCategoryItem | null>(null)
  const [probeLoading, setProbeLoading] = useState(false)

  // Fix 2026-04-24 (Issue #184): user.branchId-t kuldjuk + /all endpoint-ot
  const { user } = useAuthStore()
  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      if (!user?.branchId) {
        setItems([])
        return
      }
      const response = await api.get<RateCategoryItem[]>('/rate-categories/all', {
        params: { branchId: user.branchId },
      })
      setItems(safeArray<(typeof items)[0]>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateCategoryPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [user?.branchId])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const openForm = (item?: RateCategoryItem) => {
    setForm({
      currencyCode: item?.currencyCode ?? '',
      category:
        item?.category === 'SMALL' || item?.category === 'LARGE' ? item.category : 'STANDARD',
      buyRate: item?.buyRate != null ? String(item.buyRate) : '',
      sellRate: item?.sellRate != null ? String(item.sellRate) : '',
      minAmount: item?.minAmount != null ? String(item.minAmount) : '',
      maxAmount: item?.maxAmount != null ? String(item.maxAmount) : '',
    })
    setMessage(null)
    setError(null)
  }

  const saveCategory = async () => {
    if (!form || !user?.branchId) return
    if (!form.currencyCode.trim() || !form.buyRate.trim() || !form.sellRate.trim()) {
      setError('Valuta, vételi árfolyam és eladási árfolyam megadása kötelező.')
      return
    }

    try {
      setSaving(true)
      setError(null)
      await api.post('/rate-categories', {
        branchId: user.branchId,
        currencyCode: form.currencyCode.trim().toUpperCase(),
        category: form.category,
        buyRate: form.buyRate.trim(),
        sellRate: form.sellRate.trim(),
        minAmount: form.minAmount.trim() || undefined,
        maxAmount: form.maxAmount.trim() || undefined,
      })
      setMessage('Árfolyam kategória mentve.')
      setForm(null)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateCategoryPage', 'Mentési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const probeCategory = async () => {
    if (!user?.branchId) return
    if (!probeCurrency.trim() || !probeAmount.trim()) {
      setError('Valuta és összeg megadása kötelező a kategória próbához.')
      return
    }

    try {
      setProbeLoading(true)
      setError(null)
      const response = await api.get<RateCategoryItem>('/rate-categories', {
        params: {
          branchId: user.branchId,
          currency: probeCurrency.trim().toUpperCase(),
          amount: probeAmount.trim(),
        },
      })
      setProbeResult(response.data ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateCategoryPage', 'Kategória próba hiba:', err)
      setError(msg)
      setProbeResult(null)
    } finally {
      setProbeLoading(false)
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
          <Bookmark className="h-6 w-6" />
          {t('rates.arfolyamKategoriak')}
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
            {i18n.t('literals.arfolyam-kategoria-beallitasa')}
          </h2>
          <div className="grid gap-3 md:grid-cols-3 xl:grid-cols-6">
            <div>
              <label htmlFor="rate-category-currency" className="form-label">
                {i18n.t('literals.valuta')}
              </label>
              <input
                id="rate-category-currency"
                value={form.currencyCode}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, currencyCode: e.target.value } : current,
                  )
                }
                className="form-input w-full uppercase"
                maxLength={3}
                placeholder="EUR"
              />
            </div>
            <div>
              <label htmlFor="rate-category-kind" className="form-label">
                {i18n.t('literals.kategoria-2')}
              </label>
              <select
                id="rate-category-kind"
                value={form.category}
                onChange={(e) =>
                  setForm((current) =>
                    current
                      ? { ...current, category: e.target.value as RateCategoryForm['category'] }
                      : current,
                  )
                }
                className="form-input w-full"
              >
                <option value="SMALL">{i18n.t('literals.small')}</option>
                <option value="STANDARD">{i18n.t('literals.standard')}</option>
                <option value="LARGE">{i18n.t('literals.large')}</option>
              </select>
            </div>
            <div>
              <label htmlFor="rate-category-buy" className="form-label">
                {i18n.t('literals.veteli-arfolyam')}
              </label>
              <input
                id="rate-category-buy"
                value={form.buyRate}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, buyRate: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="decimal"
              />
            </div>
            <div>
              <label htmlFor="rate-category-sell" className="form-label">
                {i18n.t('literals.eladasi-arfolyam')}
              </label>
              <input
                id="rate-category-sell"
                value={form.sellRate}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, sellRate: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="decimal"
              />
            </div>
            <div>
              <label htmlFor="rate-category-min" className="form-label">
                {i18n.t('literals.minimum-osszeg')}
              </label>
              <input
                id="rate-category-min"
                value={form.minAmount}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, minAmount: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="decimal"
              />
            </div>
            <div>
              <label htmlFor="rate-category-max" className="form-label">
                {i18n.t('literals.maximum-osszeg')}
              </label>
              <input
                id="rate-category-max"
                value={form.maxAmount}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, maxAmount: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="decimal"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void saveCategory()}
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

      <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
        <h2 className="text-base font-semibold">{i18n.t('literals.kategoria-proba')}</h2>
        <div className="grid gap-3 md:grid-cols-[160px_180px_auto_1fr] md:items-end">
          <div>
            <label htmlFor="rate-category-probe-currency" className="form-label">
              {i18n.t('literals.valuta')}
            </label>
            <input
              id="rate-category-probe-currency"
              value={probeCurrency}
              onChange={(e) => setProbeCurrency(e.target.value)}
              className="form-input w-full uppercase"
              maxLength={3}
              placeholder="EUR"
            />
          </div>
          <div>
            <label htmlFor="rate-category-probe-amount" className="form-label">
              {i18n.t('literals.osszeg')}
            </label>
            <input
              id="rate-category-probe-amount"
              value={probeAmount}
              onChange={(e) => setProbeAmount(e.target.value)}
              className="form-input w-full"
              inputMode="decimal"
              placeholder="1000"
            />
          </div>
          <button
            type="button"
            onClick={() => void probeCategory()}
            disabled={probeLoading}
            className="form-button-primary"
          >
            {probeLoading ? 'Lekérdezés...' : 'Kategória próba'}
          </button>
          <div className="rounded border border-blue-100 bg-blue-50 px-3 py-2 text-sm text-blue-900">
            {probeResult ? (
              <div className="grid gap-1 sm:grid-cols-4">
                <span>
                  <b>{probeResult.currencyCode}</b>
                </span>
                <span>
                  {i18n.t('literals.kategoria-3')}
                  <b>{probeResult.category}</b>
                </span>
                <span>
                  {i18n.t('literals.vetel-2')}
                  <b>{formatRateCategoryValue(probeResult.buyRate)}</b>
                </span>
                <span>
                  {i18n.t('literals.eladas-5')}
                  <b>{formatRateCategoryValue(probeResult.sellRate)}</b>
                </span>
              </div>
            ) : (
              <span>{i18n.t('literals.adjon-meg-valutat-es-osszeget-az-alkalma')}</span>
            )}
          </div>
        </div>
      </div>

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

      <div className="grid gap-3 md:hidden">
        {loading ? (
          <div className="rounded border border-gray-200 bg-white p-4 text-center text-sm text-gray-500">
            {i18n.t('literals.betoltes')}
          </div>
        ) : filtered.length === 0 ? (
          <div className="rounded border border-gray-200 bg-white p-4 text-center text-sm text-gray-500">
            {t('common.noData')}
          </div>
        ) : (
          filtered.map((item) => (
            <div
              key={item.id}
              className="rounded border border-gray-200 bg-white p-3 shadow-sm"
              data-testid="rate-category-mobile-card"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <div className="font-mono text-sm font-semibold text-blue-700">
                    {item.currencyCode ?? '-'}
                  </div>
                  <div className="text-xs text-gray-500">{item.category ?? '-'}</div>
                </div>
                <button
                  onClick={() => openForm(item)}
                  className="form-button p-1 text-blue-600"
                  title="Szerkesztés"
                >
                  <Edit2 className="h-4 w-4" />
                </button>
              </div>
              <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
                <div className="rounded border border-gray-100 bg-gray-50 px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">
                    {i18n.t('literals.veteli')}
                  </div>
                  <div className="font-mono font-semibold">
                    {formatRateCategoryValue(item.buyRate)}
                  </div>
                </div>
                <div className="rounded border border-gray-100 bg-gray-50 px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">
                    {i18n.t('literals.eladasi')}
                  </div>
                  <div className="font-mono font-semibold">
                    {formatRateCategoryValue(item.sellRate)}
                  </div>
                </div>
                <div className="col-span-2 rounded border border-gray-100 bg-gray-50 px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">
                    {i18n.t('literals.sav')}
                  </div>
                  <div>{formatAmountRange(item.minAmount, item.maxAmount)}</div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      <div className="data-grid hidden overflow-x-auto md:block">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.currency')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.kategoria-2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.veteli')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.eladasi')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.sav')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('common.actions')}
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
                    {item.currencyCode ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.category ?? '-'}</td>
                  <td className="px-4 py-3 text-sm font-mono">
                    {formatRateCategoryValue(item.buyRate)}
                  </td>
                  <td className="px-4 py-3 text-sm font-mono">
                    {formatRateCategoryValue(item.sellRate)}
                  </td>
                  <td className="px-4 py-3 text-sm">
                    {formatAmountRange(item.minAmount, item.maxAmount)}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => openForm(item)}
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
