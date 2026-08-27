import { useState, useEffect, useCallback } from 'react'
import { Monitor, Search, RefreshCw, Edit2, AlertTriangle, Send } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface LedDisplayItem {
  branchId: string
  branchName?: string
  connected?: boolean
  lastRefresh?: string
  lastError?: string
  displayType?: string
  content?: string
  lastUpdated?: string
}

interface LedDisplayLine {
  currencyCode: string
  buyRate?: number
  sellRate?: number
  unit?: number
}

interface LedDisplayStatus {
  branchId: string
  branchName?: string
  connected?: boolean
  lastRefresh?: string
  lastError?: string
}

interface LedOperationalStatus {
  branchId: string
  displayType?: string
  content?: string
  lastUpdated?: string
}

interface LedConfigForm {
  branchId: string
  displayType: string
  connectionString: string
  isActive: boolean
  refreshIntervalSeconds: string
  displayedCurrencies: string
  serialDisplayType: string
  comPorts: string
  currencies: string
  showBankCard: boolean
  speedCommand: boolean
  speed: string
  endMarkers: string
  decimalSeparator: string
  customText: string
  displayIds: string
}

function fmtDate(value?: string): string {
  if (!value) return '-'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString('hu-HU')
}

export default function LedDisplayPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<LedDisplayItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [configForm, setConfigForm] = useState<LedConfigForm | null>(null)
  const [displayContent, setDisplayContent] = useState<Record<string, LedDisplayLine[]>>({})
  const [serialStatuses, setSerialStatuses] = useState<Record<string, LedDisplayStatus>>({})

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<LedDisplayItem[]>('/led-display/status')
      const serialItems = safeArray<LedDisplayItem>(response.data)
      const operationalStatuses = await Promise.all(
        serialItems.map(async (item) => {
          try {
            const status = await api.get<LedOperationalStatus[]>('/led/status', {
              params: { branchId: item.branchId },
            })
            return { branchId: item.branchId, rows: safeArray<LedOperationalStatus>(status.data) }
          } catch (statusErr) {
            logger.error('LedDisplayPage', 'LED árfolyamtábla státusz betöltési hiba:', statusErr)
            return { branchId: item.branchId, rows: [] }
          }
        }),
      )
      const operationalByBranch = new Map(
        operationalStatuses.map((entry) => [entry.branchId, entry.rows[0]]),
      )
      setItems(
        serialItems.map((item) => {
          const operational = operationalByBranch.get(item.branchId)
          return operational ? { ...item, ...operational } : item
        }),
      )
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LedDisplayPage', 'Betöltési hiba:', err)
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

  const refreshBranch = async (branchId: string) => {
    try {
      setError(null)
      await Promise.all([
        api.post(`/led/update/${branchId}`),
        api.post('/led/rate-board/update', null, { params: { branchId } }),
        api.post(`/led-display/refresh/${branchId}`),
      ])
      setMessage('LED kijelző frissítve.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LedDisplayPage', 'Branch frissítési hiba:', err)
      setError(msg)
    }
  }

  const refreshAll = async () => {
    try {
      setError(null)
      await api.post('/led-display/refresh-all')
      setMessage('Aktív LED kijelzők frissítése elindítva.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LedDisplayPage', 'Összes frissítési hiba:', err)
      setError(msg)
    }
  }

  const openConfig = async (branchId: string) => {
    try {
      setError(null)
      const [displayConfigResponse, serialConfigResponse, contentResponse, statusResponse] =
        await Promise.all([
          api.get<
            Partial<LedConfigForm> & {
              refreshIntervalSeconds?: number
              speed?: number
              decimalSeparator?: string
            }
          >(`/led/config/${branchId}`),
          api.get<
            Partial<LedConfigForm> & {
              refreshIntervalSeconds?: number
              speed?: number
              decimalSeparator?: string
            }
          >(`/led-display/config/${branchId}`),
          api.get<LedDisplayLine[]>(`/led/content/${branchId}`),
          api.get<LedDisplayStatus>(`/led-display/status/${branchId}`),
        ])
      const data = { ...(displayConfigResponse.data ?? {}), ...(serialConfigResponse.data ?? {}) }
      setDisplayContent((current) => ({
        ...current,
        [branchId]: safeArray<LedDisplayLine>(contentResponse.data),
      }))
      setSerialStatuses((current) => ({ ...current, [branchId]: statusResponse.data }))
      setConfigForm({
        branchId,
        displayType: data.displayType ?? 'NETWORK',
        connectionString: data.connectionString ?? '',
        isActive: data.isActive ?? true,
        refreshIntervalSeconds:
          data.refreshIntervalSeconds != null ? String(data.refreshIntervalSeconds) : '60',
        displayedCurrencies: data.displayedCurrencies ?? '',
        serialDisplayType: data.serialDisplayType ?? 'STANDARD',
        comPorts: data.comPorts ?? 'COM1',
        currencies: data.currencies ?? 'EUR,USD,GBP,CHF',
        showBankCard: data.showBankCard ?? false,
        speedCommand: data.speedCommand ?? true,
        speed: data.speed != null ? String(data.speed) : '5',
        endMarkers: data.endMarkers ?? '254',
        decimalSeparator: data.decimalSeparator ?? ',',
        customText: data.customText ?? '',
        displayIds: data.displayIds ?? '',
      })
      setMessage(null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LedDisplayPage', 'Konfiguráció betöltési hiba:', err)
      setError(msg)
    }
  }

  const renderSerialStatus = (branchId: string) => {
    const status = serialStatuses[branchId]
    if (!status) {
      return (
        <p className="text-sm text-gray-500">
          {i18n.t('literals.nincs-reszletes-fizikai-statusz')}
        </p>
      )
    }
    return (
      <dl
        className="grid gap-2 text-sm sm:grid-cols-2 lg:grid-cols-4"
        data-testid="led-serial-status-panel"
      >
        <div className="rounded border border-gray-100 bg-gray-50 px-3 py-2">
          <dt className="text-[10px] uppercase text-gray-500">{i18n.t('literals.telephely')}</dt>
          <dd className="break-words font-semibold text-gray-900">
            {status.branchName ?? status.branchId}
          </dd>
        </div>
        <div className="rounded border border-gray-100 bg-gray-50 px-3 py-2">
          <dt className="text-[10px] uppercase text-gray-500">{i18n.t('literals.kapcsolat')}</dt>
          <dd
            className={
              status.connected ? 'font-semibold text-green-700' : 'font-semibold text-gray-700'
            }
          >
            {status.connected ? 'Online' : 'Offline'}
          </dd>
        </div>
        <div className="rounded border border-gray-100 bg-gray-50 px-3 py-2">
          <dt className="text-[10px] uppercase text-gray-500">
            {i18n.t('literals.utolso-frissites-2')}
          </dt>
          <dd>{fmtDate(status.lastRefresh)}</dd>
        </div>
        <div className="rounded border border-gray-100 bg-gray-50 px-3 py-2">
          <dt className="text-[10px] uppercase text-gray-500">{i18n.t('literals.hiba-3')}</dt>
          <dd className="break-words">{status.lastError ?? '-'}</dd>
        </div>
      </dl>
    )
  }

  const renderContentPreview = (branchId: string) => {
    const lines = displayContent[branchId] ?? []
    if (lines.length === 0) {
      return (
        <p className="text-sm text-gray-500">
          {i18n.t('literals.nincs-kijelzo-tartalom-elonezet')}
        </p>
      )
    }
    return (
      <div className="overflow-x-auto rounded border border-gray-200">
        <table className="min-w-full divide-y divide-gray-200 text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-left font-medium text-gray-600">
                {i18n.t('literals.valuta')}
              </th>
              <th className="px-3 py-2 text-right font-medium text-gray-600">
                {i18n.t('literals.vetel')}
              </th>
              <th className="px-3 py-2 text-right font-medium text-gray-600">
                {i18n.t('literals.eladas')}
              </th>
              <th className="px-3 py-2 text-right font-medium text-gray-600">
                {i18n.t('literals.egyseg')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 bg-white">
            {lines.map((line) => (
              <tr key={line.currencyCode}>
                <td className="px-3 py-2 font-mono font-semibold">{line.currencyCode}</td>
                <td className="px-3 py-2 text-right">{line.buyRate ?? '-'}</td>
                <td className="px-3 py-2 text-right">{line.sellRate ?? '-'}</td>
                <td className="px-3 py-2 text-right">{line.unit ?? 1}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    )
  }

  const saveConfig = async () => {
    if (!configForm) return
    try {
      setSaving(true)
      setError(null)
      await Promise.all([
        api.put('/led/config', {
          branchId: configForm.branchId,
          displayType: configForm.displayType,
          connectionString: configForm.connectionString || null,
          isActive: configForm.isActive,
          refreshIntervalSeconds: Number(configForm.refreshIntervalSeconds),
          displayedCurrencies: configForm.displayedCurrencies || null,
        }),
        api.put(`/led-display/config/${configForm.branchId}`, {
          branchId: configForm.branchId,
          displayType: configForm.displayType,
          connectionString: configForm.connectionString || null,
          isActive: configForm.isActive,
          refreshIntervalSeconds: Number(configForm.refreshIntervalSeconds),
          displayedCurrencies: configForm.displayedCurrencies || null,
          serialDisplayType: configForm.serialDisplayType || null,
          comPorts: configForm.comPorts,
          currencies: configForm.currencies,
          showBankCard: configForm.showBankCard,
          speedCommand: configForm.speedCommand,
          speed: Number(configForm.speed),
          endMarkers: configForm.endMarkers,
          decimalSeparator: configForm.decimalSeparator || ',',
          customText: configForm.customText || null,
          displayIds: configForm.displayIds || null,
        }),
      ])
      setMessage('LED konfiguráció mentve.')
      setConfigForm(null)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LedDisplayPage', 'Konfiguráció mentési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const sendText = async () => {
    if (!configForm || !configForm.customText.trim()) {
      setError('Egyéni szöveg megadása kötelező.')
      return
    }
    try {
      setSaving(true)
      setError(null)
      const text = configForm.customText.trim()
      await Promise.all([
        api.post('/led/scrolling-text', { text }, { params: { branchId: configForm.branchId } }),
        api.post(`/led-display/text/${configForm.branchId}`, text, {
          headers: { 'Content-Type': 'text/plain' },
        }),
      ])
      setMessage('Egyéni LED szöveg elküldve.')
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LedDisplayPage', 'Egyéni szöveg küldési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Monitor className="h-6 w-6" />
          {t('led.ledKijelzo')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => void refreshAll()}
            className="form-button-primary flex items-center gap-1"
          >
            <RefreshCw className="h-4 w-4" />
            {i18n.t('literals.osszes-frissitese')}
          </button>
        </div>
      </div>

      {configForm && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">{i18n.t('literals.led-konfiguracio')}</h2>
          <div className="grid gap-3 md:grid-cols-3 xl:grid-cols-5">
            <div>
              <label htmlFor="led-display-type" className="form-label">
                {i18n.t('literals.kapcsolat-tipus')}
              </label>
              <select
                id="led-display-type"
                value={configForm.displayType}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, displayType: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              >
                <option value="NETWORK">{i18n.t('literals.network')}</option>
                <option value="SERIAL">{i18n.t('literals.serial')}</option>
                <option value="USB">{i18n.t('literals.usb')}</option>
              </select>
            </div>
            <div>
              <label htmlFor="led-connection" className="form-label">
                {i18n.t('literals.kapcsolat')}
              </label>
              <input
                id="led-connection"
                value={configForm.connectionString}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, connectionString: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="led-refresh-interval" className="form-label">
                {i18n.t('literals.frissites-mp')}
              </label>
              <input
                id="led-refresh-interval"
                value={configForm.refreshIntervalSeconds}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, refreshIntervalSeconds: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="numeric"
              />
            </div>
            <div>
              <label htmlFor="led-com-ports" className="form-label">
                {i18n.t('literals.com-portok')}
              </label>
              <input
                id="led-com-ports"
                value={configForm.comPorts}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, comPorts: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="led-currencies" className="form-label">
                {i18n.t('literals.valutak')}
              </label>
              <input
                id="led-currencies"
                value={configForm.currencies}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, currencies: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="led-speed" className="form-label">
                {i18n.t('literals.sebesseg')}
              </label>
              <input
                id="led-speed"
                value={configForm.speed}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, speed: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="numeric"
              />
            </div>
            <div>
              <label htmlFor="led-end-markers" className="form-label">
                {i18n.t('literals.zaro-bajtok')}
              </label>
              <input
                id="led-end-markers"
                value={configForm.endMarkers}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, endMarkers: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="led-decimal" className="form-label">
                {i18n.t('literals.tizedesjel')}
              </label>
              <input
                id="led-decimal"
                value={configForm.decimalSeparator}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current
                      ? { ...current, decimalSeparator: e.target.value.slice(0, 1) }
                      : current,
                  )
                }
                className="form-input w-full"
                maxLength={1}
              />
            </div>
            <div>
              <label htmlFor="led-display-ids" className="form-label">
                {i18n.t('literals.kijelzo-id-k')}
              </label>
              <input
                id="led-display-ids"
                value={configForm.displayIds}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, displayIds: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <label className="flex items-end gap-2 pb-2 text-sm">
              <input
                type="checkbox"
                checked={configForm.isActive}
                onChange={(e) =>
                  setConfigForm((current) =>
                    current ? { ...current, isActive: e.target.checked } : current,
                  )
                }
              />
              {i18n.t('literals.aktiv-2')}
            </label>
          </div>
          <div>
            <label htmlFor="led-custom-text" className="form-label">
              {i18n.t('literals.egyeni-szoveg')}
            </label>
            <textarea
              id="led-custom-text"
              value={configForm.customText}
              onChange={(e) =>
                setConfigForm((current) =>
                  current ? { ...current, customText: e.target.value } : current,
                )
              }
              className="form-input h-24 w-full"
              maxLength={1000}
            />
          </div>
          <div>
            <h3 className="mb-2 text-sm font-semibold text-gray-700">
              {i18n.t('literals.fizikai-statusz')}
            </h3>
            {renderSerialStatus(configForm.branchId)}
          </div>
          <div>
            <h3 className="mb-2 text-sm font-semibold text-gray-700">
              {i18n.t('literals.kijelzo-tartalom-elonezet')}
            </h3>
            {renderContentPreview(configForm.branchId)}
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void saveConfig()}
              disabled={saving}
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button
              type="button"
              onClick={() => void sendText()}
              disabled={saving}
              className="form-button flex items-center gap-1"
            >
              <Send className="h-4 w-4" />
              {i18n.t('literals.szoveg-kuldese')}
            </button>
            <button type="button" onClick={() => setConfigForm(null)} className="form-button">
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

      <div className="space-y-3 md:hidden">
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
            <article
              key={item.branchId}
              className="rounded border border-gray-200 bg-white p-3 shadow-sm"
            >
              <div className="mb-3 flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="break-words font-semibold text-gray-900">
                    {item.branchName ?? item.branchId}
                  </p>
                  <p className="font-mono text-xs text-gray-500">{item.branchId}</p>
                </div>
                <span className={`badge ${item.connected ? 'badge-green' : 'badge-gray'}`}>
                  {item.connected ? 'Online' : 'Offline'}
                </span>
              </div>
              <dl className="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
                <div>
                  <dt className="text-gray-500">{i18n.t('literals.utolso-frissites-2')}</dt>
                  <dd className="text-gray-900">{fmtDate(item.lastRefresh)}</dd>
                </div>
                <div>
                  <dt className="text-gray-500">{i18n.t('literals.hiba-3')}</dt>
                  <dd className="text-gray-900">{item.lastError ?? '-'}</dd>
                </div>
              </dl>
              <div className="mt-3 grid grid-cols-2 gap-2">
                <button
                  onClick={() => void refreshBranch(item.branchId)}
                  className="form-button justify-center text-xs"
                  title="Frissítés"
                >
                  <RefreshCw className="h-4 w-4" />
                </button>
                <button
                  onClick={() => void openConfig(item.branchId)}
                  className="form-button justify-center text-xs text-blue-600"
                  title="Szerkesztés"
                >
                  <Edit2 className="h-4 w-4" />
                </button>
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
                {t('led.penztar')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.online')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.utolso-frissites-2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.hiba-3')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('competitors.muveletek')}
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
                <tr key={item.branchId} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.branchName ?? item.branchId}</td>
                  <td className="px-4 py-3 text-sm">{item.connected ? 'Igen' : 'Nem'}</td>
                  <td className="px-4 py-3 text-sm">{fmtDate(item.lastRefresh)}</td>
                  <td className="px-4 py-3 text-sm">{item.lastError ?? '-'}</td>
                  <td className="px-4 py-3 text-right whitespace-nowrap">
                    <button
                      onClick={() => void refreshBranch(item.branchId)}
                      className="form-button mr-2 p-1"
                      title="Frissítés"
                    >
                      <RefreshCw className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => void openConfig(item.branchId)}
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
        {i18n.t('literals.osszesen-2')}
        {filtered.length}
        {i18n.t('literals.lit-10')}
        {items.length}
      </div>
    </div>
  )
}
