import { useState, useEffect, useCallback } from 'react'
import { AlertTriangle, CalendarClock, Clock, RefreshCw, Search } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { exchangeRateApi, type ExchangeRate } from '../../services/api/exchange-rates'
import i18n from '../../i18n'

interface RateHistoryItem {
  id: string | number
  currencyCode?: string
  buyRate?: string
  sellRate?: string
  mnbRate?: string
  spread?: string
  category?: string
  effectiveFrom?: string
  effectiveTo?: string
  validFrom?: string
  createdByName?: string
}

const getCurrentLocalDateTimeValue = (): string => {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day}T${hours}:${minutes}`
}

export default function RateHistoryPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<RateHistoryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [atDateCurrency, setAtDateCurrency] = useState('EUR')
  const [atDateValue, setAtDateValue] = useState(getCurrentLocalDateTimeValue)
  const [atDateResult, setAtDateResult] = useState<RateHistoryItem | null>(null)
  const [atDateLoading, setAtDateLoading] = useState(false)
  const [atDateError, setAtDateError] = useState<string | null>(null)
  const [canonicalCurrencyCode, setCanonicalCurrencyCode] = useState('EUR')
  const [canonicalHufAmount, setCanonicalHufAmount] = useState('100000')
  const [canonicalRate, setCanonicalRate] = useState<ExchangeRate | null>(null)
  const [canonicalBuyRate, setCanonicalBuyRate] = useState<number | null>(null)
  const [canonicalSellRate, setCanonicalSellRate] = useState<number | null>(null)
  const [canonicalHistory, setCanonicalHistory] = useState<ExchangeRate[]>([])
  const [canonicalLoading, setCanonicalLoading] = useState(false)
  const [canonicalError, setCanonicalError] = useState<string | null>(null)

  // Fix 2026-04-24 (Issue #184): default utolso 30 nap + from/to parameter
  // A backend uj opcionalis currency paramot tamogat, ha nincs -> minden valuta
  // AI review fix (Sourcery + Codex PR #185 P2): local date komponenseket hasznaljuk,
  // NEM toISOString() (UTC-t adna, es CET/CEST este off-by-one hiba lehet)
  const formatLocalDate = (d: Date): string => {
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  const formatDateTimeDisplay = (value?: string): string =>
    value ? new Date(value).toLocaleString('hu-HU') : '-'

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const today = new Date()
      const defaultFrom = new Date(today)
      defaultFrom.setDate(today.getDate() - 30)
      const fromStr = dateFrom || formatLocalDate(defaultFrom)
      const toStr = dateTo || formatLocalDate(today)
      const response = await api.get<RateHistoryItem[]>('/rate-history', {
        params: { from: fromStr, to: toStr },
      })
      setItems(safeArray<(typeof items)[0]>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateHistoryPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [dateFrom, dateTo])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const loadAtDateRate = async () => {
    const currency = atDateCurrency.trim().toUpperCase()
    if (!currency || !atDateValue) {
      setAtDateError('Valuta és időpont megadása kötelező.')
      return
    }

    try {
      setAtDateLoading(true)
      setAtDateError(null)
      const response = await api.get<RateHistoryItem>('/rate-history/at-date', {
        params: { currency, date: atDateValue },
      })
      setAtDateResult(response.data)
      setAtDateCurrency(currency)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateHistoryPage', 'Adott időpont árfolyam lekérdezési hiba:', err)
      setAtDateError(msg)
      setAtDateResult(null)
    } finally {
      setAtDateLoading(false)
    }
  }

  const loadCanonicalExchangeRate = async () => {
    const currencyCode = canonicalCurrencyCode.trim().toUpperCase()
    const hufAmount = Number(canonicalHufAmount)
    const today = new Date()
    const defaultFrom = new Date(today)
    defaultFrom.setDate(today.getDate() - 30)
    const startDate = dateFrom || formatLocalDate(defaultFrom)
    const endDate = dateTo || formatLocalDate(today)

    if (!currencyCode || !Number.isFinite(hufAmount) || hufAmount <= 0) {
      setCanonicalError('Valuta és pozitív HUF összeg megadása kötelező.')
      return
    }

    try {
      setCanonicalLoading(true)
      setCanonicalError(null)
      const currentRate = await exchangeRateApi.getByCurrencyCode(currencyCode)
      const [buyRate, sellRate, history] = await Promise.all([
        exchangeRateApi.getBuyRateForAmount(currentRate.currencyId, hufAmount),
        exchangeRateApi.getSellRateForAmount(currentRate.currencyId, hufAmount),
        exchangeRateApi.getHistoryByCode(currencyCode, startDate, endDate),
      ])
      setCanonicalRate(currentRate)
      setCanonicalBuyRate(buyRate)
      setCanonicalSellRate(sellRate)
      setCanonicalHistory(history)
      setCanonicalCurrencyCode(currencyCode)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('RateHistoryPage', 'Canonical árfolyam lekérdezési hiba:', err)
      setCanonicalError(msg)
      setCanonicalRate(null)
      setCanonicalBuyRate(null)
      setCanonicalSellRate(null)
      setCanonicalHistory([])
    } finally {
      setCanonicalLoading(false)
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
          <Clock className="h-6 w-6" />
          {t('rates.arfolyamTortenelem')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="flex flex-col gap-2 md:flex-row md:items-center">
        <div className="grid grid-cols-2 gap-2 md:flex">
          <input
            aria-label="Kezdő dátum"
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="form-input min-w-0 px-2 py-1"
          />
          <input
            aria-label="Záró dátum"
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="form-input min-w-0 px-2 py-1"
          />
        </div>
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

      <section className="rounded-lg border border-blue-100 bg-blue-50/70 p-3">
        <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-blue-900">
          <CalendarClock className="h-4 w-4" />
          {t('rates.adottIdopontbanErvenyesArfolyam')}
        </div>
        <div className="grid gap-2 md:grid-cols-[120px_minmax(220px,1fr)_auto]">
          <input
            aria-label="Adott időpont valuta"
            value={atDateCurrency}
            onChange={(e) => setAtDateCurrency(e.target.value.toUpperCase())}
            className="form-input min-w-0 px-2 py-1"
            maxLength={3}
          />
          <input
            aria-label="Adott időpont"
            type="datetime-local"
            value={atDateValue}
            onChange={(e) => setAtDateValue(e.target.value)}
            className="form-input min-w-0 px-2 py-1"
          />
          <button
            type="button"
            onClick={() => void loadAtDateRate()}
            disabled={atDateLoading}
            className="form-button whitespace-nowrap px-3 py-2"
          >
            {t('rates.lekerdezes')}
          </button>
        </div>
        {atDateError && (
          <div className="mt-2 flex items-center gap-2 text-sm text-red-700">
            <AlertTriangle className="h-4 w-4" />
            {atDateError}
          </div>
        )}
        {atDateResult && (
          <div className="mt-3 grid gap-2 rounded-md bg-white p-3 text-sm shadow-sm md:grid-cols-4">
            <div>
              <div className="text-xs uppercase text-gray-500">{t('common.currency')}</div>
              <div className="font-semibold text-gray-900">
                {atDateResult.currencyCode ?? atDateCurrency}
              </div>
            </div>
            <div>
              <div className="text-xs uppercase text-gray-500">{t('rates.veteliArf')}</div>
              <div className="font-semibold text-gray-900">{atDateResult.buyRate ?? '-'}</div>
            </div>
            <div>
              <div className="text-xs uppercase text-gray-500">{t('rates.eladasiArf')}</div>
              <div className="font-semibold text-gray-900">{atDateResult.sellRate ?? '-'}</div>
            </div>
            <div>
              <div className="text-xs uppercase text-gray-500">{t('rates.ervenyes')}</div>
              <div className="font-semibold text-gray-900">
                {formatDateTimeDisplay(atDateResult.effectiveFrom ?? atDateResult.validFrom)}
              </div>
            </div>
          </div>
        )}
      </section>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <section className="rounded-lg border border-emerald-100 bg-emerald-50/70 p-3">
        <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-emerald-900">
          <Search className="h-4 w-4" />
          {t('rates.canonicalArfolyamEllenorzes')}
        </div>
        <div className="grid gap-2 md:grid-cols-[120px_minmax(160px,1fr)_auto]">
          <input
            aria-label="Árfolyam ellenőrzés valuta"
            value={canonicalCurrencyCode}
            onChange={(e) => setCanonicalCurrencyCode(e.target.value.toUpperCase())}
            className="form-input min-w-0 px-2 py-1"
            maxLength={3}
          />
          <input
            aria-label="Árfolyam ellenőrzés HUF összeg"
            type="number"
            min="1"
            value={canonicalHufAmount}
            onChange={(e) => setCanonicalHufAmount(e.target.value)}
            className="form-input min-w-0 px-2 py-1"
          />
          <button
            type="button"
            onClick={() => void loadCanonicalExchangeRate()}
            disabled={canonicalLoading}
            className="form-button whitespace-nowrap px-3 py-2"
          >
            {canonicalLoading ? 'Betöltés...' : 'Árfolyam ellenőrzés'}
          </button>
        </div>
        {canonicalError && (
          <div className="mt-2 flex items-center gap-2 text-sm text-red-700">
            <AlertTriangle className="h-4 w-4" />
            {canonicalError}
          </div>
        )}
        {canonicalRate && (
          <div className="mt-3 grid gap-2 rounded-md bg-white p-3 text-sm shadow-sm md:grid-cols-5">
            <div>
              <div className="text-xs uppercase text-gray-500">{t('common.currency')}</div>
              <div className="font-semibold text-gray-900">{canonicalRate.currencyCode}</div>
            </div>
            <div>
              <div className="text-xs uppercase text-gray-500">{t('rates.veteliArf')}</div>
              <div className="font-semibold text-gray-900">{canonicalRate.baseBuyRate}</div>
            </div>
            <div>
              <div className="text-xs uppercase text-gray-500">{t('rates.eladasiArf')}</div>
              <div className="font-semibold text-gray-900">{canonicalRate.baseSellRate}</div>
            </div>
            <div>
              <div className="text-xs uppercase text-gray-500">{t('rates.hufVetel')}</div>
              <div className="font-semibold text-gray-900">{canonicalBuyRate ?? '-'}</div>
            </div>
            <div>
              <div className="text-xs uppercase text-gray-500">{t('rates.hufEladas')}</div>
              <div className="font-semibold text-gray-900">{canonicalSellRate ?? '-'}</div>
            </div>
          </div>
        )}
        {canonicalHistory.length > 0 && (
          <div className="mt-2 text-xs text-emerald-900">
            {t('rates.canonicalHistoryTalalatok')}
            {i18n.t('literals.lit-22')}
            {canonicalHistory.length}
          </div>
        )}
      </section>

      <div className="space-y-2 md:hidden">
        {loading ? (
          <div className="rounded-md border border-gray-200 bg-white px-4 py-8 text-center text-sm text-gray-500">
            {i18n.t('literals.betoltes')}
          </div>
        ) : filtered.length === 0 ? (
          <div className="rounded-md border border-gray-200 bg-white px-4 py-8 text-center text-sm text-gray-500">
            {t('common.noData')}
          </div>
        ) : (
          filtered.map((item) => (
            <article
              key={item.id}
              className="rounded-md border border-gray-200 bg-white p-3 shadow-sm"
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="text-xs uppercase text-gray-500">{t('common.currency')}</div>
                  <div className="text-base font-semibold text-gray-900">
                    {item.currencyCode ?? '-'}
                  </div>
                </div>
                <div className="text-right text-xs text-gray-500">
                  {formatDateTimeDisplay(item.effectiveFrom ?? item.validFrom)}
                </div>
              </div>
              <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <div className="text-xs uppercase text-gray-500">{t('rates.veteliArf')}</div>
                  <div className="font-semibold text-gray-900">{item.buyRate ?? '-'}</div>
                </div>
                <div>
                  <div className="text-xs uppercase text-gray-500">{t('rates.eladasiArf')}</div>
                  <div className="font-semibold text-gray-900">{item.sellRate ?? '-'}</div>
                </div>
              </div>
            </article>
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
                {t('rates.veteliArf')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('rates.eladasiArf')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('rates.ervenyes')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('rates.modositotta')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.currencyCode ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.buyRate ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.sellRate ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {formatDateTimeDisplay(item.effectiveFrom ?? item.validFrom)}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.createdByName ?? '-'}</td>
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
