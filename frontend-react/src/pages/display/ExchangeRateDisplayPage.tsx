import React, { useState, useEffect, useCallback } from 'react'
import { Monitor, RefreshCw, Edit2, Power, PowerOff, Eye, Wifi, WifiOff } from 'lucide-react'
import {
  exchangeRateDisplayApi,
  type ExchangeRateDisplay,
  type ExchangeRateDisplayPreviewRow,
} from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface DisplayForm {
  displayName: string
  displayType: string
  connectionType: string
  comPort: string
  baudRate: number
  ipAddress: string
  port: number
  refreshInterval: number
  rowCount: number
  columnCount: number
  currencyIds: string
  showBuyRate: boolean
  showSellRate: boolean
  showMiddleRate: boolean
  showFlag: boolean
  brightness: number
}

const emptyForm: DisplayForm = {
  displayName: '',
  displayType: 'LED_MATRIX',
  connectionType: 'SERIAL',
  comPort: 'COM1',
  baudRate: 9600,
  ipAddress: '',
  port: 0,
  refreshInterval: 30,
  rowCount: 8,
  columnCount: 3,
  currencyIds: '1,2,3,4',
  showBuyRate: true,
  showSellRate: true,
  showMiddleRate: false,
  showFlag: true,
  brightness: 80,
}

const DISPLAY_TYPES = [
  { value: 'LED_MATRIX', label: 'LED mátrix' },
  { value: 'LED_SCROLL', label: 'LED gördülő' },
  { value: 'LCD', label: 'LCD kijelző' },
  { value: 'MONITOR', label: 'TV/Monitor' },
  { value: 'CUSTOM', label: 'Egyedi' },
]

const formatCurrencyIdsForForm = (value?: string | null): string => {
  const text = value?.trim() ?? ''
  if (!text) return ''
  if (text.startsWith('[') && text.endsWith(']')) {
    return text.slice(1, -1).trim()
  }
  return text
}

const serializeCurrencyIdsForBackend = (value: string): string => {
  const text = value.trim()
  if (!text) return '[]'
  if (text.startsWith('[') && text.endsWith(']')) return text
  return `[${text}]`
}

export default function ExchangeRateDisplayPage() {
  const { t } = useTranslation()
  const [displays, setDisplays] = useState<ExchangeRateDisplay[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [form, setForm] = useState<DisplayForm>(emptyForm)
  const [saving, setSaving] = useState(false)
  const [previewId, setPreviewId] = useState<string | null>(null)
  const [previewData, setPreviewData] = useState<ExchangeRateDisplayPreviewRow[]>([])
  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setDisplays(await exchangeRateDisplayApi.list())
    } catch (err) {
      logger.error('ExchangeRateDisplayPage', 'Kijelzők betöltési hiba:', err)
      setError('Hiba a kijelzők betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleSave = async () => {
    if (!form.displayName) {
      toast.warning('Hiányzó adat', 'Kijelző neve kötelező')
      return
    }
    try {
      setSaving(true)
      setError(null)
      if (!editingId) return
      const payload: Partial<ExchangeRateDisplay> = {
        displayName: form.displayName,
        currencyIds: serializeCurrencyIdsForBackend(form.currencyIds),
        refreshInterval: form.refreshInterval,
      }
      await exchangeRateDisplayApi.updateDisplay(editingId, payload)
      toast.success('Kijelző frissítve')
      setShowForm(false)
      setEditingId(null)
      setForm(emptyForm)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      toast.error('Hiba', msg)
    } finally {
      setSaving(false)
    }
  }

  const handleEdit = (display: ExchangeRateDisplay) => {
    setEditingId(display.id)
    setForm({
      displayName: display.displayName,
      displayType: display.displayType || 'LED_MATRIX',
      connectionType: display.connectionType || 'SERIAL',
      comPort: display.comPort || 'COM1',
      baudRate: display.baudRate || 9600,
      ipAddress: display.ipAddress || '',
      port: display.port || 0,
      refreshInterval: display.refreshInterval || 30,
      rowCount: display.rowCount || 8,
      columnCount: display.columnCount || 3,
      currencyIds: formatCurrencyIdsForForm(display.currencyIds) || '1,2,3,4',
      showBuyRate: display.showBuyRate !== false,
      showSellRate: display.showSellRate !== false,
      showMiddleRate: display.showMiddleRate || false,
      showFlag: display.showFlag !== false,
      brightness: display.brightness || 80,
    })
    setShowForm(true)
  }

  const handleToggleActive = async (display: ExchangeRateDisplay) => {
    try {
      setError(null)
      await exchangeRateDisplayApi.updateDisplay(display.id, { isActive: !display.isActive })
      toast.success(display.isActive ? 'Kijelző leállítva' : 'Kijelző elindítva')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleRefresh = async (id: string) => {
    try {
      setError(null)
      await exchangeRateDisplayApi.updateDisplay(id, {})
      toast.success('Kijelző frissítve')
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handlePreview = async (display: ExchangeRateDisplay) => {
    if (previewId === display.id) {
      setPreviewId(null)
      setPreviewData([])
      return
    }
    try {
      setPreviewData(await exchangeRateDisplayApi.getCurrentRates(display.id))
      setPreviewId(display.id)
    } catch (err) {
      logger.error('ExchangeRateDisplayPage', 'Előnézet hiba:', err)
      toast.error('Előnézet hiba', getErrorMessage(err))
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Monitor />
          {t('display.arfolyamKijelzok')}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Form */}
      {showForm && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{i18n.t('literals.kijelzo-szerkesztese')}</h2>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="form-label">{t('display.kijelzoNeve')}</label>
              <input
                className="form-input"
                value={form.displayName}
                onChange={(e) => setForm({ ...form, displayName: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.type')}</label>
              <select
                className="form-input"
                value={form.displayType}
                onChange={(e) => setForm({ ...form, displayType: e.target.value })}
              >
                {DISPLAY_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="form-label">{t('display.kapcsolat')}</label>
              <select
                className="form-input"
                value={form.connectionType}
                onChange={(e) => setForm({ ...form, connectionType: e.target.value })}
              >
                <option value="SERIAL">{t('display.sorosPort')}</option>
                <option value="TCP">{t('display.tcpIp')}</option>
                <option value="USB">{i18n.t('literals.usb')}</option>
              </select>
            </div>
            {form.connectionType === 'SERIAL' && (
              <>
                <div>
                  <label className="form-label">{t('display.comPort')}</label>
                  <select
                    className="form-input"
                    value={form.comPort}
                    onChange={(e) => setForm({ ...form, comPort: e.target.value })}
                  >
                    {['COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8'].map((p) => (
                      <option key={p} value={p}>
                        {p}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="form-label">{t('display.baudRate')}</label>
                  <select
                    className="form-input"
                    value={form.baudRate}
                    onChange={(e) => setForm({ ...form, baudRate: Number(e.target.value) })}
                  >
                    {[9600, 19200, 38400, 57600, 115200].map((b) => (
                      <option key={b} value={b}>
                        {b}
                      </option>
                    ))}
                  </select>
                </div>
              </>
            )}
            {form.connectionType === 'TCP' && (
              <>
                <div>
                  <label className="form-label">{t('common.ipAddress')}</label>
                  <input
                    className="form-input"
                    value={form.ipAddress}
                    onChange={(e) => setForm({ ...form, ipAddress: e.target.value })}
                  />
                </div>
                <div>
                  <label className="form-label">{t('display.port')}</label>
                  <input
                    className="form-input"
                    type="number"
                    value={form.port}
                    onChange={(e) => setForm({ ...form, port: Number(e.target.value) })}
                  />
                </div>
              </>
            )}
            <div>
              <label className="form-label">{t('display.frissitesiIdoMp')}</label>
              <input
                className="form-input"
                type="number"
                min={5}
                max={3600}
                value={form.refreshInterval}
                onChange={(e) => setForm({ ...form, refreshInterval: Number(e.target.value) })}
              />
            </div>
            <div>
              <label className="form-label">{t('display.sorokSzama')}</label>
              <input
                className="form-input"
                type="number"
                min={1}
                max={20}
                value={form.rowCount}
                onChange={(e) => setForm({ ...form, rowCount: Number(e.target.value) })}
              />
            </div>
            <div>
              <label className="form-label">{t('display.oszlopokSzama')}</label>
              <input
                className="form-input"
                type="number"
                min={2}
                max={6}
                value={form.columnCount}
                onChange={(e) => setForm({ ...form, columnCount: Number(e.target.value) })}
              />
            </div>
            <div className="col-span-2">
              <label className="form-label">{t('display.devizakVesszovelElvalasztva')}</label>
              <input
                className="form-input"
                value={form.currencyIds}
                onChange={(e) => setForm({ ...form, currencyIds: e.target.value })}
                placeholder="1,2,3,4"
              />
            </div>
            <div>
              <label className="form-label">{t('display.fenyero')}</label>
              <input
                className="form-input"
                type="range"
                min={0}
                max={100}
                value={form.brightness}
                onChange={(e) => setForm({ ...form, brightness: Number(e.target.value) })}
              />
              <span className="text-sm ml-2">
                {form.brightness}
                {i18n.t('literals.lit-30')}
              </span>
            </div>
            <div className="col-span-3 flex gap-4">
              <label className="flex items-center gap-1">
                <input
                  type="checkbox"
                  checked={form.showBuyRate}
                  onChange={(e) => setForm({ ...form, showBuyRate: e.target.checked })}
                />
                {t('cashier.buy')}
              </label>
              <label className="flex items-center gap-1">
                <input
                  type="checkbox"
                  checked={form.showSellRate}
                  onChange={(e) => setForm({ ...form, showSellRate: e.target.checked })}
                />
                {t('cashier.sell')}
              </label>
              <label className="flex items-center gap-1">
                <input
                  type="checkbox"
                  checked={form.showMiddleRate}
                  onChange={(e) => setForm({ ...form, showMiddleRate: e.target.checked })}
                />
                {t('display.kozep')}
              </label>
              <label className="flex items-center gap-1">
                <input
                  type="checkbox"
                  checked={form.showFlag}
                  onChange={(e) => setForm({ ...form, showFlag: e.target.checked })}
                />
                {t('display.zaszloIkon')}
              </label>
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={handleSave} disabled={saving} className="form-button-primary">
              {saving ? 'Mentés...' : 'Mentés'}
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

      {/* Table */}
      {loading ? (
        <div>{i18n.t('literals.betoltes')}</div>
      ) : (
        <div className="form-panel">
          {safeArray(displays).length === 0 ? (
            <div className="text-center text-gray-500 py-8">
              {t('display.nincsKijelzoKonfiguralva')}
            </div>
          ) : (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('display.megnevezes')}</th>
                  <th>{t('common.type')}</th>
                  <th>{t('display.kapcsolat')}</th>
                  <th>{t('common.refresh')}</th>
                  <th>{t('common.status')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {safeArray<ExchangeRateDisplay>(displays).map((d) => (
                  <React.Fragment key={d.id}>
                    <tr>
                      <td className="font-medium">{d.displayName}</td>
                      <td>
                        {DISPLAY_TYPES.find((t) => t.value === d.displayType)?.label ||
                          d.displayType ||
                          '-'}
                      </td>
                      <td className="text-sm">
                        {d.connectionType || 'SERIAL'} {d.comPort || d.ipAddress || ''}
                      </td>
                      { }
                      <td>
                        {d.refreshInterval}
                        {i18n.t('literals.s')}
                      </td>
                      <td>
                        <span className={`badge ${d.isActive ? 'badge-green' : 'badge-gray'}`}>
                          {d.isActive ? (
                            <>
                              <Wifi size={10} className="inline" /> {t('display.online')}
                            </>
                          ) : (
                            <>
                              <WifiOff size={10} className="inline" /> {t('display.offline')}
                            </>
                          )}
                        </span>
                      </td>
                      <td>
                        <div className="flex gap-1">
                          <button
                            onClick={() => handleEdit(d)}
                            className="form-button text-xs"
                            title="Szerkesztés"
                          >
                            <Edit2 size={12} />
                          </button>
                          <button
                            onClick={() => handleToggleActive(d)}
                            className="form-button text-xs"
                            title={d.isActive ? 'Leállítás' : 'Indítás'}
                          >
                            {d.isActive ? <PowerOff size={12} /> : <Power size={12} />}
                          </button>
                          <button
                            onClick={() => handleRefresh(d.id)}
                            className="form-button text-xs"
                            title="Azonnali frissítés"
                          >
                            <RefreshCw size={12} />
                          </button>
                          <button
                            onClick={() => void handlePreview(d)}
                            className="form-button text-xs"
                            title="Előnézet"
                          >
                            <Eye size={12} />
                          </button>
                        </div>
                      </td>
                    </tr>
                    {previewId === d.id && previewData.length > 0 && (
                      <tr key={`preview-${d.id}`}>
                        <td colSpan={6}>
                          <div className="bg-black text-green-400 font-mono text-sm p-3 rounded">
                            <div className="text-center mb-1 text-yellow-300">
                              {t('display.kijelzoElonezet')}
                            </div>
                            <div className="grid grid-cols-3 gap-2 text-center">
                              <div className="font-bold">{t('common.deviza')}</div>
                              <div className="font-bold">{t('cashier.buy')}</div>
                              <div className="font-bold">{t('cashier.sell')}</div>
                              {previewData.map((r) => (
                                <React.Fragment key={r.currency}>
                                  <div>{r.currency}</div>
                                  <div>{r.buyRate}</div>
                                  <div>{r.sellRate}</div>
                                </React.Fragment>
                              ))}
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
