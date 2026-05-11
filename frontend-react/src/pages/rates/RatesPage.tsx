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

function formatHuf(amount: number): string {
  return amount.toLocaleString('hu-HU')
}

/** Check if ANY rate in the dataset has a given tier */
function anyHasTier(rates: RateRow[], tier: 1 | 2 | 3): boolean {
  return rates.some(r => {
    if (tier === 1) return r.limit1Amount != null && (r.limit1BuyRate != null || r.limit1SellRate != null)
    if (tier === 2) return r.limit2Amount != null && (r.limit2BuyRate != null || r.limit2SellRate != null)
    return r.limit3Amount != null && (r.limit3BuyRate != null || r.limit3SellRate != null)
  })
}

export default function RatesPage() {
  const { t } = useTranslation()
  const [rates, setRates] = useState<RateRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefresh, setLastRefresh] = useState<string>('')
  const [editingCode, setEditingCode] = useState<string | null>(null)
  const [editValues, setEditValues] = useState({ buyRate: 0, sellRate: 0 })

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

  // Determine which tiers to show (only show columns if any currency uses that tier)
  const showTier1 = anyHasTier(rates, 1)
  const showTier2 = anyHasTier(rates, 2)
  const showTier3 = anyHasTier(rates, 3)

  // Count dynamic tier column pairs for colSpan calculations
  const tierCount = (showTier1 ? 1 : 0) + (showTier2 ? 1 : 0) + (showTier3 ? 1 : 0)

  return (
    <div className="space-y-1">
      {/* Compact header */}
      <div className="flex justify-between items-center gap-2 flex-wrap">
        <h1 className="text-sm font-bold text-gray-800 flex items-center gap-1.5">
          <TrendingUp size={16} />
          {t('cashier.rates')}{!canEdit && <span className="text-[10px] text-gray-500 font-normal">{t('rates.nezet')}</span>}
          {!canEdit && (
            <span className="text-[10px] text-blue-700 font-normal flex items-center gap-0.5 ml-1">
              <Eye size={10} />{t('rates.csakFoertektarSzerkesztheti')}
            </span>
          )}
          {lastRefresh && (
            <span className="text-[10px] text-gray-500 font-normal flex items-center gap-0.5 ml-1">
              <Clock size={10} />{t('rates.utolsoFrissites')}{lastRefresh}{rates.length > 0 && ` · ${rates.length} valuta`}
            </span>
          )}
        </h1>
        <div className="flex gap-1.5">
          {canEdit && (
            <button className="form-button flex items-center gap-1 h-6 text-[10px] px-2">
              <Download size={12} />
              {t('rates.mnbLetoltes')}
            </button>
          )}
          <button
            className="form-button-primary flex items-center gap-1 h-6 text-[10px] px-2"
            onClick={() => void loadRates()}
            disabled={loading}
          >
            <RefreshCw size={12} className={loading ? 'animate-spin' : ''} />
            {t('common.refresh')}
          </button>
        </div>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200 text-red-700 px-2 py-1 text-xs rounded">
          {error}
        </div>
      )}

      {loading && rates.length === 0 && (
        <div className="flex items-center justify-center h-24">
          <RefreshCw className="animate-spin text-blue-600" size={28} />
        </div>
      )}

      {/* Dense table — all currencies + discount tiers as separate columns */}
      {rates.length > 0 && (
        <div className="form-panel p-0 overflow-x-auto">
          <table className="w-full border-collapse" style={{ fontSize: '11px' }}>
            {/* Two-row header: tier group names + buy/sell sub-headers */}
            <thead>
              {/* Row 1: grouped tier headers */}
              <tr className="bg-gray-100 border-b border-gray-300">
                <th rowSpan={2} className="px-1 py-0.5 text-left text-[10px] uppercase text-gray-500 border-r border-gray-200 w-10 font-semibold">
                  {t('common.code')}
                </th>
                <th colSpan={2} className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-blue-50 text-blue-800">
                  {t('rates.alap')}
                </th>
                {showTier1 && (
                  <th colSpan={2} className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-emerald-50 text-emerald-800">
                    {t('rates.sav1')}
                  </th>
                )}
                {showTier2 && (
                  <th colSpan={2} className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-amber-50 text-amber-800">
                    {t('rates.sav2')}
                  </th>
                )}
                {showTier3 && (
                  <th colSpan={2} className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-purple-50 text-purple-800">
                    {t('rates.sav3')}
                  </th>
                )}
                <th rowSpan={2} className="px-1 py-0.5 text-center text-[10px] uppercase text-gray-500 w-14 font-semibold">
                  MNB
                </th>
                {canEdit && (
                  <th rowSpan={2} className="px-0.5 py-0.5 text-center text-[10px] uppercase text-gray-500 w-10 font-semibold">
                    <Edit size={10} className="mx-auto" />
                  </th>
                )}
              </tr>
              {/* Row 2: buy/sell sub-headers */}
              <tr className="bg-gray-50 border-b border-gray-300">
                {/* Alap buy/sell */}
                <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-blue-50/50">
                  {t('rates.vetel')}
                </th>
                <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-blue-50/50">
                  {t('rates.eladas')}
                </th>
                {/* Tier 1 buy/sell */}
                {showTier1 && (
                  <>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-emerald-50/50">
                      {t('rates.vetel')}
                    </th>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-emerald-50/50">
                      {t('rates.eladas')}
                    </th>
                  </>
                )}
                {/* Tier 2 buy/sell */}
                {showTier2 && (
                  <>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-amber-50/50">
                      {t('rates.vetel')}
                    </th>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-amber-50/50">
                      {t('rates.eladas')}
                    </th>
                  </>
                )}
                {/* Tier 3 buy/sell */}
                {showTier3 && (
                  <>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-purple-50/50">
                      {t('rates.vetel')}
                    </th>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-purple-50/50">
                      {t('rates.eladas')}
                    </th>
                  </>
                )}
              </tr>
            </thead>
            <tbody>
              {rates.map((rate, idx) => (
                <tr
                  key={rate.id}
                  className={`${idx % 2 === 1 ? 'bg-gray-50/70' : ''} hover:bg-blue-50/60 border-b border-gray-100 last:border-0`}
                  title={`${rate.name} — Frissítve: ${rate.lastUpdate}`}
                >
                  {/* Currency code */}
                  <td className="px-1 py-px border-r border-gray-100">
                    <span className="font-mono font-bold text-blue-700 text-[11px]" title={rate.name}>
                      {rate.code}
                    </span>
                  </td>

                  {/* Base buy rate */}
                  <td className="px-1 py-px text-right border-r border-gray-100">
                    {editingCode === rate.code && canEdit ? (
                      <NumberInput
                        value={editValues.buyRate.toString().replace('.', ',')}
                        onChange={(val) => setEditValues({ ...editValues, buyRate: parseFloat(val.replace(',', '.')) || 0 })}
                        className="form-input w-16 text-right text-[11px] py-0 px-0.5"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                        disabled={!canEdit}
                      />
                    ) : (
                      <span className="font-mono text-green-700 font-semibold">{formatDecimal(rate.buyRate, 2, 2)}</span>
                    )}
                  </td>

                  {/* Base sell rate */}
                  <td className="px-1 py-px text-right border-r border-gray-200">
                    {editingCode === rate.code && canEdit ? (
                      <NumberInput
                        value={editValues.sellRate.toString().replace('.', ',')}
                        onChange={(val) => setEditValues({ ...editValues, sellRate: parseFloat(val.replace(',', '.')) || 0 })}
                        className="form-input w-16 text-right text-[11px] py-0 px-0.5"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                        disabled={!canEdit}
                      />
                    ) : (
                      <span className="font-mono text-red-700 font-semibold">{formatDecimal(rate.sellRate, 2, 2)}</span>
                    )}
                  </td>

                  {/* Tier 1 buy */}
                  {showTier1 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-100"
                      title={rate.limit1Amount != null ? `≥ ${formatHuf(rate.limit1Amount)} Ft` : ''}
                    >
                      {rate.limit1BuyRate != null ? (
                        <span className="text-green-600">{formatDecimal(rate.limit1BuyRate, 2, 2)}</span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}
                  {/* Tier 1 sell */}
                  {showTier1 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-200"
                      title={rate.limit1Amount != null ? `≥ ${formatHuf(rate.limit1Amount)} Ft` : ''}
                    >
                      {rate.limit1SellRate != null ? (
                        <span className="text-red-600">{formatDecimal(rate.limit1SellRate, 2, 2)}</span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}

                  {/* Tier 2 buy */}
                  {showTier2 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-100"
                      title={rate.limit2Amount != null ? `≥ ${formatHuf(rate.limit2Amount)} Ft` : ''}
                    >
                      {rate.limit2BuyRate != null ? (
                        <span className="text-green-600">{formatDecimal(rate.limit2BuyRate, 2, 2)}</span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}
                  {/* Tier 2 sell */}
                  {showTier2 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-200"
                      title={rate.limit2Amount != null ? `≥ ${formatHuf(rate.limit2Amount)} Ft` : ''}
                    >
                      {rate.limit2SellRate != null ? (
                        <span className="text-red-600">{formatDecimal(rate.limit2SellRate, 2, 2)}</span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}

                  {/* Tier 3 buy */}
                  {showTier3 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-100"
                      title={rate.limit3Amount != null ? `≥ ${formatHuf(rate.limit3Amount)} Ft` : ''}
                    >
                      {rate.limit3BuyRate != null ? (
                        <span className="text-green-600">{formatDecimal(rate.limit3BuyRate, 2, 2)}</span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}
                  {/* Tier 3 sell */}
                  {showTier3 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-200"
                      title={rate.limit3Amount != null ? `≥ ${formatHuf(rate.limit3Amount)} Ft` : ''}
                    >
                      {rate.limit3SellRate != null ? (
                        <span className="text-red-600">{formatDecimal(rate.limit3SellRate, 2, 2)}</span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}

                  {/* MNB official rate */}
                  <td className="px-1 py-px text-right font-mono text-gray-600 text-[10px]">
                    {rate.mnbRate > 0 ? formatDecimal(rate.mnbRate, 2, 2) : '—'}
                  </td>

                  {/* Edit button (only for foertektar/ugyvezeto) */}
                  {canEdit && (
                    <td className="px-0.5 py-px text-center">
                      {editingCode === rate.code ? (
                        <div className="flex gap-0.5 justify-center">
                          <button
                            onClick={() => void saveEdit(rate.code)}
                            className="toolbar-button text-green-600 p-0.5"
                            title="Mentés"
                          >
                            <Save size={10} />
                          </button>
                          <button
                            onClick={cancelEdit}
                            className="toolbar-button text-red-600 p-0.5"
                            title="Mégse"
                          >
                            <X size={10} />
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => startEdit(rate)}
                          className="toolbar-button p-0.5 mx-auto block"
                          title="Szerkesztés"
                        >
                          <Edit size={10} />
                        </button>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>

          {/* Tier threshold legend — compact, at bottom */}
          {tierCount > 0 && (
            <div className="px-2 py-1 bg-gray-50 border-t border-gray-200 text-[9px] text-gray-500 flex flex-wrap gap-x-4 gap-y-0.5">
              <span className="font-semibold uppercase">{t('rates.kedvezmenySavokMinOsszeg')}</span>
              {rates.filter(r => r.limit1Amount != null || r.limit2Amount != null || r.limit3Amount != null).map(r => (
                <span key={r.code} className="font-mono">
                  {r.code}:
                  {r.limit1Amount != null && <span className="text-emerald-700 ml-0.5">1.≥{formatHuf(r.limit1Amount)}</span>}
                  {r.limit2Amount != null && <span className="text-amber-700 ml-0.5">2.≥{formatHuf(r.limit2Amount)}</span>}
                  {r.limit3Amount != null && <span className="text-purple-700 ml-0.5">3.≥{formatHuf(r.limit3Amount)}</span>}
                </span>
              ))}
            </div>
          )}
        </div>
      )}

      {!loading && rates.length === 0 && !error && (
        <div className="form-panel text-center text-gray-500 py-6 text-xs">
          {t('rates.nincsenekElerhetoArfolyamokKerjukHozzonLetreArfolyamotAzArfolyamkeszitesOldalon')}
        </div>
      )}
    </div>
  )
}
