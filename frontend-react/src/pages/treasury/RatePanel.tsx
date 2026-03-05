import { useState, useEffect, useCallback } from 'react'
import {
  RefreshCw,
  ArrowUp,
  ArrowDown,
  Edit2,
  Save,
  Server,
  X,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { exchangeRateApi, currencyApi } from '../../services/api'
import type { ExchangeRate, Currency, CreateExchangeRateRequest } from '../../services/api'
import { formatAmount, currencyColorClass } from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'

interface RateRow {
  currency: Currency
  rate: ExchangeRate | null
  buyTrend: 'up' | 'down' | 'flat'
  sellTrend: 'up' | 'down' | 'flat'
  changePercent: number
}

export default function RatePanel() {
  const [loading, setLoading] = useState(true)
  const [rateRows, setRateRows] = useState<RateRow[]>([])
  const [lastPoll, setLastPoll] = useState<string>('')
  const [showManualModal, setShowManualModal] = useState(false)
  const [showSpreadEditor, setShowSpreadEditor] = useState(false)
  const [editCurrency, setEditCurrency] = useState<string>('')

  // Manual rate form
  const [manualCurrencyId, setManualCurrencyId] = useState<number>(0)
  const [manualBuyRate, setManualBuyRate] = useState('')
  const [manualSellRate, setManualSellRate] = useState('')

  const fetchData = useCallback(async () => {
    try {
      const [rates, currencies] = await Promise.all([
        exchangeRateApi.list().catch(() => [] as ExchangeRate[]),
        currencyApi.list().catch(() => [] as Currency[]),
      ])

      const rateMap = new Map<number, ExchangeRate>()
      for (const r of rates) {
        rateMap.set(r.currencyId, r)
      }

      const rows: RateRow[] = currencies
        .filter((c) => c.active)
        .map((c) => {
          const rate = rateMap.get(c.id) ?? null
          return {
            currency: c,
            rate,
            buyTrend: 'flat' as const,
            sellTrend: 'flat' as const,
            changePercent: 0,
          }
        })

      setRateRows(rows)
      setLastPoll(new Date().toLocaleTimeString('hu-HU'))
    } catch (err) {
      console.error('RatePanel fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void fetchData()
  }, [fetchData])

  // Hotkeys
  useHotkeys('r', () => void fetchData(), { enableOnFormTags: false })
  useHotkeys('m', () => setShowManualModal(true), { enableOnFormTags: false })
  useHotkeys('s', () => setShowSpreadEditor(true), { enableOnFormTags: false })
  useHotkeys('escape', () => {
    setShowManualModal(false)
    setShowSpreadEditor(false)
    setEditCurrency('')
  }, { enableOnFormTags: true })

  const handleManualRateSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()
    if (!manualCurrencyId || !manualBuyRate || !manualSellRate) return
    try {
      const request: CreateExchangeRateRequest = {
        currencyId: manualCurrencyId,
        baseBuyRate: parseFloat(manualBuyRate),
        baseSellRate: parseFloat(manualSellRate),
      }
      await exchangeRateApi.create(request)
      setShowManualModal(false)
      setManualBuyRate('')
      setManualSellRate('')
      setManualCurrencyId(0)
      void fetchData()
    } catch (err) {
      console.error('Manual rate submit error:', err)
    }
  }, [manualCurrencyId, manualBuyRate, manualSellRate, fetchData])

  const handleEditRate = useCallback((code: string) => {
    setEditCurrency(code)
    const row = rateRows.find((r) => r.currency.code === code)
    if (row?.rate) {
      setManualCurrencyId(row.currency.id)
      setManualBuyRate(String(row.rate.baseBuyRate))
      setManualSellRate(String(row.rate.baseSellRate))
    }
    setShowManualModal(true)
  }, [rateRows])

  if (loading) return <TableSkeleton rows={10} cols={7} />

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-secondary-900">Árfolyam Kezelő</h1>
          <div className="flex items-center gap-2 text-sm text-secondary-600">
            <RefreshCw size={16} />
            <span>
              Utolsó frissítés: <strong>{lastPoll}</strong>
            </span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
            <span>Frissítés most</span>
          </button>
          <button onClick={() => setShowManualModal(true)} className="form-button h-8 text-xs">
            <Edit2 size={14} />
            <span>Manuális bevitel</span>
          </button>
          <button onClick={() => setShowSpreadEditor(true)} className="form-button h-8 text-xs">
            <Server size={14} />
            <span>Spread editor</span>
          </button>
        </div>
      </div>

      {/* Rate table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th className="w-24">Valuta</th>
              <th className="text-right w-28">MNB / Alap</th>
              <th className="text-right w-28">Vétel</th>
              <th className="text-right w-28">Eladás</th>
              <th className="text-right w-32">Spread</th>
              <th className="text-right w-24">Δ%</th>
              <th className="w-16"></th>
            </tr>
          </thead>
          <tbody>
            {rateRows.length === 0 && (
              <tr>
                <td colSpan={7} className="text-center text-sm text-secondary-400 py-8">
                  Nincs árfolyam adat
                </td>
              </tr>
            )}
            {rateRows.map((row) => {
              const buyRate = row.rate?.baseBuyRate ?? 0
              const sellRate = row.rate?.baseSellRate ?? 0
              const officialRate = row.rate?.officialRate ?? 0
              const spread = sellRate - buyRate
              const spreadPercent = buyRate > 0 ? (spread / buyRate) * 100 : 0

              return (
                <tr key={row.currency.code} className="hover:bg-primary-50">
                  <td>
                    <span className={`font-bold ${currencyColorClass(row.currency.code)}`}>
                      {row.currency.code}
                    </span>
                  </td>
                  <td className="text-right font-mono">
                    {officialRate > 0 ? formatAmount(officialRate) : '—'}
                  </td>
                  <td className="text-right font-mono font-semibold">
                    {buyRate > 0 ? formatAmount(buyRate) : '—'}
                    {row.buyTrend === 'up' && (
                      <ArrowUp size={12} className="inline ml-1 text-success-600" />
                    )}
                    {row.buyTrend === 'down' && (
                      <ArrowDown size={12} className="inline ml-1 text-danger-600" />
                    )}
                  </td>
                  <td className="text-right font-mono font-semibold">
                    {sellRate > 0 ? formatAmount(sellRate) : '—'}
                    {row.sellTrend === 'up' && (
                      <ArrowUp size={12} className="inline ml-1 text-success-600" />
                    )}
                    {row.sellTrend === 'down' && (
                      <ArrowDown size={12} className="inline ml-1 text-danger-600" />
                    )}
                  </td>
                  <td className="text-right font-mono text-xs text-secondary-600">
                    {spread > 0 ? `${formatAmount(spread)} (${spreadPercent.toFixed(1)}%)` : '—'}
                  </td>
                  <td className="text-right">
                    {row.changePercent !== 0 ? (
                      <span
                        className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold ${
                          row.changePercent > 0
                            ? 'bg-success-100 text-success-700'
                            : 'bg-danger-100 text-danger-700'
                        }`}
                      >
                        {row.changePercent > 0 ? '🟢+' : '🔴'}
                        {row.changePercent.toFixed(1)}%
                      </span>
                    ) : (
                      <span className="text-xs text-secondary-400">—</span>
                    )}
                  </td>
                  <td className="text-center">
                    <button
                      className="text-primary-600 hover:text-primary-700"
                      onClick={() => handleEditRate(row.currency.code)}
                    >
                      <Edit2 size={16} />
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* MNB Polling Status */}
      <div className="form-panel">
        <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
          <Server size={20} className="text-primary-600" />
          MNB Polling Státusz
        </h2>
        <div className="grid grid-cols-4 gap-4">
          <div className="p-4 bg-success-50 border border-success-200 rounded-lg">
            <div className="text-xs text-secondary-600 mb-1">Utolsó sikeres frissítés</div>
            <div className="text-sm font-bold text-secondary-900">{lastPoll || '—'}</div>
            <div className="text-xs text-success-700 mt-1">✅ Elérhető</div>
          </div>
          <div className="p-4 bg-primary-50 border border-primary-200 rounded-lg">
            <div className="text-xs text-secondary-600 mb-1">Következő frissítés</div>
            <div className="text-sm font-bold text-secondary-900">Manuális</div>
            <div className="text-xs text-secondary-500 mt-1">R billentyű</div>
          </div>
          <div className="p-4 bg-secondary-50 border border-secondary-200 rounded-lg">
            <div className="text-xs text-secondary-600 mb-1">Aktív valuták</div>
            <div className="text-sm font-bold text-secondary-900">{rateRows.length}</div>
            <div className="text-xs text-secondary-500 mt-1">valuta beállítva</div>
          </div>
          <div className="p-4 bg-secondary-50 border border-secondary-200 rounded-lg">
            <div className="text-xs text-secondary-600 mb-1">Hibák (ma)</div>
            <div className="text-sm font-bold text-secondary-900">0</div>
            <div className="text-xs text-secondary-500 mt-1">0 hiba</div>
          </div>
        </div>
      </div>

      {/* Manual Rate Modal */}
      {showManualModal && (
        <ModalOverlay onClose={() => setShowManualModal(false)}>
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full mx-4">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-secondary-900">
                {editCurrency ? `${editCurrency} árfolyam szerkesztés` : 'Manuális árfolyam bevitel'}
              </h2>
              <button onClick={() => setShowManualModal(false)} className="text-secondary-400 hover:text-secondary-600">
                <X size={20} />
              </button>
            </div>
            <form onSubmit={(e) => void handleManualRateSubmit(e)} className="space-y-4">
              {!editCurrency && (
                <div>
                  <label className="form-label">Valuta</label>
                  <select
                    className="form-input w-full"
                    value={manualCurrencyId}
                    onChange={(e) => setManualCurrencyId(Number(e.target.value))}
                  >
                    <option value={0}>Válassz valutát</option>
                    {rateRows.map((r) => (
                      <option key={r.currency.id} value={r.currency.id}>
                        {r.currency.code} — {r.currency.name}
                      </option>
                    ))}
                  </select>
                </div>
              )}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Vétel árfolyam</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-input w-full font-mono"
                    placeholder="0.00"
                    value={manualBuyRate}
                    onChange={(e) => setManualBuyRate(e.target.value)}
                  />
                </div>
                <div>
                  <label className="form-label">Eladás árfolyam</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-input w-full font-mono"
                    placeholder="0.00"
                    value={manualSellRate}
                    onChange={(e) => setManualSellRate(e.target.value)}
                  />
                </div>
              </div>
              <div className="p-3 bg-warning-50 border border-warning-200 rounded-lg">
                <div className="text-xs text-warning-800">
                  <strong>Figyelem:</strong> Manuális bevitel felülírja az aktuális árfolyamot.
                </div>
              </div>
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-secondary-200">
                <button
                  type="button"
                  className="form-button"
                  onClick={() => setShowManualModal(false)}
                >
                  Mégse
                </button>
                <button type="submit" className="form-button-primary">
                  <Save size={18} />
                  <span>Mentés</span>
                </button>
              </div>
            </form>
          </div>
        </ModalOverlay>
      )}

      {/* Spread Editor Modal */}
      {showSpreadEditor && (
        <ModalOverlay onClose={() => setShowSpreadEditor(false)}>
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-3xl w-full mx-4">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-secondary-900">Spread szerkesztő</h2>
              <button onClick={() => setShowSpreadEditor(false)} className="text-secondary-400 hover:text-secondary-600">
                <X size={20} />
              </button>
            </div>
            <div className="p-3 bg-primary-50 border border-primary-200 rounded-lg text-sm text-secondary-700 mb-4">
              A spread (árfolyam margin) = eladási árfolyam − vételi árfolyam. A táblázat csak olvasható
              áttekintés — az egyes valuták szerkesztéséhez kattints a ceruza ikonra.
            </div>
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th className="w-24">Valuta</th>
                  <th className="text-right w-28">MNB / Alap</th>
                  <th className="text-right w-28">Vétel</th>
                  <th className="text-right w-28">Eladás</th>
                  <th className="text-right w-28">Spread Ft</th>
                  <th className="text-right w-24">Spread %</th>
                </tr>
              </thead>
              <tbody>
                {rateRows
                  .filter((r) => r.rate)
                  .map((row) => {
                    const buyRate = row.rate?.baseBuyRate ?? 0
                    const sellRate = row.rate?.baseSellRate ?? 0
                    const spread = sellRate - buyRate
                    const spreadPct = buyRate > 0 ? (spread / buyRate) * 100 : 0
                    return (
                      <tr key={row.currency.code}>
                        <td className={`font-bold ${currencyColorClass(row.currency.code)}`}>
                          {row.currency.code}
                        </td>
                        <td className="text-right font-mono">
                          {row.rate?.officialRate ? formatAmount(row.rate.officialRate) : '—'}
                        </td>
                        <td className="text-right font-mono">{formatAmount(buyRate)}</td>
                        <td className="text-right font-mono">{formatAmount(sellRate)}</td>
                        <td className="text-right font-mono">{formatAmount(spread)}</td>
                        <td className="text-right font-mono text-xs">{spreadPct.toFixed(1)}%</td>
                      </tr>
                    )
                  })}
              </tbody>
            </table>
            <div className="flex justify-end mt-6">
              <button onClick={() => setShowSpreadEditor(false)} className="form-button-primary">
                Bezárás
              </button>
            </div>
          </div>
        </ModalOverlay>
      )}
    </div>
  )
}

// ---- Helper ----

function ModalOverlay({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}>{children}</div>
    </div>
  )
}
