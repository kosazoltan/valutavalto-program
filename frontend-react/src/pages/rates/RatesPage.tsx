import { useState, useEffect, useCallback } from 'react'
import { TrendingUp, RefreshCw, Edit, Save, X, Clock, Download, Eye } from 'lucide-react'
import { exchangeRateApi, ExchangeRate } from '../../services/api/index'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'
import { recordLocalAuditEvent } from '../../utils/electronTransactions'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useAppMode } from '../../hooks/useAppMode'
import { useTranslation } from 'react-i18next'

// 2026-04-29 B2 fix: a /rates oldalt a penztaros (mode='penztar') NEM
// szerkesztheti — csak a foertektar/ugyvezeto az ARFOLYAM/Arfolyam.exe legacy
// szerepkor szerint. Ld. D:\valutavalto-vault\references\legacy-anti-system.md §2.3
const RATE_EDITOR_ROLES = ['foertektar', 'ugyvezeto'] as const

interface RateRow {
  id: number
  code: string
  name: string
  buyRate: number
  sellRate: number
  mnbRate: number
  lastUpdate: string
  currencyId: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
}

function mapExchangeRateToRow(rate: ExchangeRate): RateRow {
  return {
    id: rate.id,
    code: rate.currencyCode,
    name: rate.currencyName,
    buyRate: rate.baseBuyRate,
    sellRate: rate.baseSellRate,
    mnbRate: rate.officialRate ?? 0,
    lastUpdate: rate.validTime
      ? rate.validTime.substring(0, 5)
      : new Date(rate.createdAt).toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }),
    currencyId: rate.currencyId,
    limit1Amount: rate.limit1Amount ?? undefined,
    limit1BuyRate: rate.limit1BuyRate ?? undefined,
    limit1SellRate: rate.limit1SellRate ?? undefined,
    limit2Amount: rate.limit2Amount ?? undefined,
    limit2BuyRate: rate.limit2BuyRate ?? undefined,
    limit2SellRate: rate.limit2SellRate ?? undefined,
    limit3Amount: rate.limit3Amount ?? undefined,
    limit3BuyRate: rate.limit3BuyRate ?? undefined,
    limit3SellRate: rate.limit3SellRate ?? undefined,
  }
}

function hasLimits(rate: RateRow): boolean {
  return !!(rate.limit1Amount || rate.limit2Amount || rate.limit3Amount)
}

function formatHuf(amount: number): string {
  return amount.toLocaleString('hu-HU')
}

export default function RatesPage() {
  const { t } = useTranslation()
  const [rates, setRates] = useState<RateRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefresh, setLastRefresh] = useState<string>('')
  const [editingCode, setEditingCode] = useState<string | null>(null)
  const [editValues, setEditValues] = useState({ buyRate: 0, sellRate: 0 })

  // B2: szerkesztes csak a foertektar/ugyvezeto-nek (legacy ARFOLYAM/Arfolyam.exe)
  // 2026-04-29 v2.3.10 (Sourcery PR #271): a NumberInput field-ek `editingCode` flag-szel
  // védettek — read-only módban (canEdit=false) az Edit gomb (Művelet oszlop) sem
  // látszik, tehát `setEditingCode()` sosem hívódhat meg, a NumberInput sosem renderel.
  // Defensive: a useEffect ki-resetli az editingCode-ot, ha canEdit kivilágosodik (pl.
  // role-change után login).
  const { mode: appMode } = useAppMode()
  const hasCanonicalRole = useAuthStore((state) => state.hasCanonicalRole)
  const canEdit = appMode === 'full' && hasCanonicalRole([...RATE_EDITOR_ROLES])

  useEffect(() => {
    if (!canEdit && editingCode !== null) {
      setEditingCode(null)
      setEditValues({ buyRate: 0, sellRate: 0 })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canEdit])

  const loadRates = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const dataRaw = await exchangeRateApi.list()
      const data = safeArray<ExchangeRate>(dataRaw)
      setRates(data.map(mapExchangeRateToRow))
      setLastRefresh(new Date().toLocaleString('hu-HU'))
    } catch (err) {
      logger.error('RatesPage', 'Árfolyamok betöltési hiba:', err)
      setError('Hiba az árfolyamok betöltésekor. Kérjük, próbálja újra!')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadRates()
  }, [loadRates])

  const startEdit = (rate: RateRow) => {
    setEditingCode(rate.code)
    setEditValues({ buyRate: rate.buyRate, sellRate: rate.sellRate })
  }

  const saveEdit = async (code: string) => {
    const rate = rates.find(r => r.code === code)
    if (!rate) return

    if (editValues.buyRate >= editValues.sellRate) {
      alert('A vételi árfolyamnak kisebbnek kell lennie az eladásinál!')
      return
    }

    try {
      await exchangeRateApi.create({
        currencyId: rate.currencyId,
        baseBuyRate: editValues.buyRate,
        baseSellRate: editValues.sellRate,
        officialRate: rate.mnbRate || undefined,
      })
      await recordLocalAuditEvent({
        entityType: 'EXCHANGE_RATE',
        eventType: 'UPDATE',
        entityId: String(rate.currencyId),
        referenceNumber: rate.code,
        payload: {
          currencyId: rate.currencyId,
          currencyCode: rate.code,
          baseBuyRate: editValues.buyRate,
          baseSellRate: editValues.sellRate,
          officialRate: rate.mnbRate || null,
        },
        rateSnapshot: {
          currencyCode: rate.code,
          buyRate: editValues.buyRate,
          sellRate: editValues.sellRate,
          officialRate: rate.mnbRate || null,
        },
        status: 'SERVER_FORWARDED',
      })
      setEditingCode(null)
      void loadRates()
    } catch (err) {
      logger.error('RatesPage', 'Árfolyam mentési hiba:', err)
      alert('Hiba az árfolyam mentésekor!')
    }
  }

  const cancelEdit = () => {
    setEditingCode(null)
  }

  return (
    <div className="space-y-2">
      {/* Compact header — minden info egy sorban */}
      <div className="flex justify-between items-center gap-3 flex-wrap">
        <h1 className="text-base font-bold text-gray-800 flex items-center gap-2">
          <TrendingUp size={18} />
          {t('cashier.rates')}{!canEdit && <span className="text-xs text-gray-500 font-normal">{t('rates.nezet')}</span>}
          {!canEdit && (
            <span className="text-xs text-blue-700 font-normal flex items-center gap-1 ml-2">
              <Eye size={12} />{t('rates.csakFoertektarSzerkesztheti')}
            </span>
          )}
          {lastRefresh && (
            <span className="text-xs text-gray-500 font-normal flex items-center gap-1 ml-2">
              <Clock size={12} />{t('rates.utolsoFrissites')}{lastRefresh}{rates.length > 0 && ` · ${rates.length} valuta`}
            </span>
          )}
        </h1>
        <div className="flex gap-2">
          {canEdit && (
            <button className="form-button flex items-center gap-1 h-7 text-xs">
              <Download size={14} />
              {t('rates.mnbLetoltes')}
            </button>
          )}
          <button
            className="form-button-primary flex items-center gap-1 h-7 text-xs"
            onClick={() => void loadRates()}
            disabled={loading}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            {t('common.refresh')}
          </button>
        </div>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200 text-red-700 px-3 py-2 text-sm rounded">
          {error}
        </div>
      )}

      {loading && rates.length === 0 && (
        <div className="flex items-center justify-center h-32">
          <RefreshCw className="animate-spin text-blue-600" size={32} />
        </div>
      )}

      {/* Compact dense table — minden valuta + sávok egy sorban */}
      {rates.length > 0 && (
        <div className="form-panel p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr className="text-xs uppercase text-gray-500">
                <th className="px-1.5 py-1 text-left w-12">{t('common.code')}</th>
                <th className="px-1 py-1 text-left">{t('display.megnevezes')}</th>
                <th className="px-1 py-1 text-right">{t('rates.veteli')}</th>
                <th className="px-1 py-1 text-right">{t('rates.eladasi')}</th>
                <th className="px-1 py-1 text-right w-16">MNB</th>
                <th className="px-1 py-1 text-center w-12">{t('stockSnapshot.lastUpdated')}</th>
                {canEdit && <th className="px-1 py-1 text-center w-16">{t('common.operation')}</th>}
              </tr>
            </thead>
            <tbody>
              {rates.map((rate, idx) => (
                <tr key={rate.id} className={`${idx % 2 === 1 ? 'bg-gray-50' : ''} hover:bg-blue-50 border-b border-gray-100 last:border-0`}>
                  <td className="px-1.5 py-0.5">
                    <span className="font-mono font-bold text-blue-600 text-xs">{rate.code}</span>
                  </td>
                  <td className="px-1 py-0.5 text-xs truncate max-w-[100px]">{rate.name}</td>
                  <td className="px-1 py-0.5 text-right">
                    {editingCode === rate.code && canEdit ? (
                      <NumberInput
                        value={editValues.buyRate.toString().replace('.', ',')}
                        onChange={(val) => setEditValues({ ...editValues, buyRate: parseFloat(val.replace(',', '.')) || 0 })}
                        className="form-input w-20 text-right text-sm py-0.5"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                        disabled={!canEdit}
                      />
                    ) : (
                      <div>
                        <span className="font-mono text-green-600">{formatDecimal(rate.buyRate, 2, 2)}</span>
                        {hasLimits(rate) && (
                          <div className="flex gap-1.5 justify-end mt-0.5">
                            {rate.limit1Amount != null && rate.limit1BuyRate != null && (
                              <span className="text-[10px] font-mono text-green-500" title={`≥${formatHuf(rate.limit1Amount)} Ft`}>
                                {formatHuf(rate.limit1Amount)}:{formatDecimal(rate.limit1BuyRate, 2, 2)}
                              </span>
                            )}
                            {rate.limit2Amount != null && rate.limit2BuyRate != null && (
                              <span className="text-[10px] font-mono text-green-500" title={`≥${formatHuf(rate.limit2Amount)} Ft`}>
                                {formatHuf(rate.limit2Amount)}:{formatDecimal(rate.limit2BuyRate, 2, 2)}
                              </span>
                            )}
                            {rate.limit3Amount != null && rate.limit3BuyRate != null && (
                              <span className="text-[10px] font-mono text-green-500" title={`≥${formatHuf(rate.limit3Amount)} Ft`}>
                                {formatHuf(rate.limit3Amount)}:{formatDecimal(rate.limit3BuyRate, 2, 2)}
                              </span>
                            )}
                          </div>
                        )}
                      </div>
                    )}
                  </td>
                  <td className="px-1 py-0.5 text-right">
                    {editingCode === rate.code && canEdit ? (
                      <NumberInput
                        value={editValues.sellRate.toString().replace('.', ',')}
                        onChange={(val) => setEditValues({ ...editValues, sellRate: parseFloat(val.replace(',', '.')) || 0 })}
                        className="form-input w-20 text-right text-sm py-0.5"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                        disabled={!canEdit}
                      />
                    ) : (
                      <div>
                        <span className="font-mono text-red-600">{formatDecimal(rate.sellRate, 2, 2)}</span>
                        {hasLimits(rate) && (
                          <div className="flex gap-1.5 justify-end mt-0.5">
                            {rate.limit1Amount != null && rate.limit1SellRate != null && (
                              <span className="text-[10px] font-mono text-red-400" title={`≥${formatHuf(rate.limit1Amount)} Ft`}>
                                {formatHuf(rate.limit1Amount)}:{formatDecimal(rate.limit1SellRate, 2, 2)}
                              </span>
                            )}
                            {rate.limit2Amount != null && rate.limit2SellRate != null && (
                              <span className="text-[10px] font-mono text-red-400" title={`≥${formatHuf(rate.limit2Amount)} Ft`}>
                                {formatHuf(rate.limit2Amount)}:{formatDecimal(rate.limit2SellRate, 2, 2)}
                              </span>
                            )}
                            {rate.limit3Amount != null && rate.limit3SellRate != null && (
                              <span className="text-[10px] font-mono text-red-400" title={`≥${formatHuf(rate.limit3Amount)} Ft`}>
                                {formatHuf(rate.limit3Amount)}:{formatDecimal(rate.limit3SellRate, 2, 2)}
                              </span>
                            )}
                          </div>
                        )}
                      </div>
                    )}
                  </td>
                  <td className="px-1 py-0.5 text-right font-mono text-gray-600 text-xs">
                    {rate.mnbRate > 0 ? formatDecimal(rate.mnbRate, 2, 2) : '-'}
                  </td>
                  <td className="px-1 py-0.5 text-center text-[10px] text-gray-500">{rate.lastUpdate}</td>
                  {canEdit && (
                    <td className="px-1 py-0.5">
                      {editingCode === rate.code ? (
                        <div className="flex gap-0.5 justify-center">
                          <button
                            onClick={() => void saveEdit(rate.code)}
                            className="toolbar-button text-green-600 p-1"
                            title="Mentés"
                          >
                            <Save size={12} />
                          </button>
                          <button
                            onClick={cancelEdit}
                            className="toolbar-button text-red-600 p-1"
                            title="Mégse"
                          >
                            <X size={12} />
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => startEdit(rate)}
                          className="toolbar-button p-1 mx-auto block"
                          title="Szerkesztés"
                        >
                          <Edit size={12} />
                        </button>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {!loading && rates.length === 0 && !error && (
        <div className="form-panel text-center text-gray-500 py-8">
          {t('rates.nincsenekElerhetoArfolyamokKerjukHozzonLetreArfolyamotAzArfolyamkeszitesOldalon')}
        </div>
      )}
    </div>
  )
}
