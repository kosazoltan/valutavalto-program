import { useState, useEffect, useCallback } from 'react'
import { TrendingUp, RefreshCw, Edit, Save, X, Clock, Download } from 'lucide-react'
import { exchangeRateApi, ExchangeRate } from '../../services/api/index'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'
import { recordLocalAuditEvent } from '../../utils/electronTransactions'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'

interface RateRow {
  id: number
  code: string
  name: string
  buyRate: number
  sellRate: number
  mnbRate: number
  lastUpdate: string
  currencyId: number
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
  }
}

export default function RatesPage() {
  const [rates, setRates] = useState<RateRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefresh, setLastRefresh] = useState<string>('')
  const [editingCode, setEditingCode] = useState<string | null>(null)
  const [editValues, setEditValues] = useState({ buyRate: 0, sellRate: 0 })

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

  const getSpread = (buy: number, sell: number) => {
    if (buy === 0) return '0.00'
    return ((sell - buy) / buy * 100).toFixed(2)
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <TrendingUp />
          Árfolyamok
        </h1>
        <div className="flex gap-2">
          <button className="form-button flex items-center gap-1">
            <Download size={16} />
            MNB letöltés
          </button>
          <button
            className="form-button-primary flex items-center gap-1"
            onClick={() => void loadRates()}
            disabled={loading}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            Frissítés
          </button>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Info Banner */}
      <div className="form-panel bg-blue-50 border-blue-200 flex items-center gap-2">
        <Clock size={16} className="text-blue-600" />
        <span className="text-sm text-blue-800">
          {lastRefresh
            ? `Utolsó frissítés: ${lastRefresh}`
            : 'Betöltés...'}
          {rates.length > 0 && ` | ${rates.length} valuta`}
        </span>
      </div>

      {/* Loading State */}
      {loading && rates.length === 0 && (
        <div className="flex items-center justify-center h-32">
          <RefreshCw className="animate-spin text-blue-600" size={32} />
        </div>
      )}

      {/* Rates Table */}
      {rates.length > 0 && (
        <div className="form-panel p-0">
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th className="w-20">Kód</th>
                <th>Megnevezés</th>
                <th className="text-right w-28">Vételi ár</th>
                <th className="text-right w-28">Eladási ár</th>
                <th className="text-right w-28">MNB közép</th>
                <th className="text-right w-24">Spread %</th>
                <th className="w-20">Frissítve</th>
                <th className="w-24">Művelet</th>
              </tr>
            </thead>
            <tbody>
              {rates.map((rate) => (
                <tr key={rate.id}>
                  <td>
                    <span className="font-mono font-bold text-blue-600">{rate.code}</span>
                  </td>
                  <td>{rate.name}</td>
                  <td className="text-right">
                    {editingCode === rate.code ? (
                      <NumberInput
                        value={editValues.buyRate.toString().replace('.', ',')}
                        onChange={(val) => setEditValues({ ...editValues, buyRate: parseFloat(val.replace(',', '.')) || 0 })}
                        className="form-input w-24 text-right"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                      />
                    ) : (
                      <span className="font-mono text-green-600">{formatDecimal(rate.buyRate, 2, 2)}</span>
                    )}
                  </td>
                  <td className="text-right">
                    {editingCode === rate.code ? (
                      <NumberInput
                        value={editValues.sellRate.toString().replace('.', ',')}
                        onChange={(val) => setEditValues({ ...editValues, sellRate: parseFloat(val.replace(',', '.')) || 0 })}
                        className="form-input w-24 text-right"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                      />
                    ) : (
                      <span className="font-mono text-red-600">{formatDecimal(rate.sellRate, 2, 2)}</span>
                    )}
                  </td>
                  <td className="text-right font-mono text-gray-600">
                    {rate.mnbRate > 0 ? formatDecimal(rate.mnbRate, 2, 2) : '-'}
                  </td>
                  <td className="text-right">
                    <span className="text-xs font-mono bg-gray-100 px-2 py-0.5 rounded">
                      {formatDecimal(parseFloat(getSpread(rate.buyRate, rate.sellRate)), 2, 2)}%
                    </span>
                  </td>
                  <td className="text-center text-sm text-gray-500">{rate.lastUpdate}</td>
                  <td>
                    {editingCode === rate.code ? (
                      <div className="flex gap-1">
                        <button
                          onClick={() => void saveEdit(rate.code)}
                          className="toolbar-button text-green-600"
                          title="Mentés"
                        >
                          <Save size={14} />
                        </button>
                        <button
                          onClick={cancelEdit}
                          className="toolbar-button text-red-600"
                          title="Mégse"
                        >
                          <X size={14} />
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => startEdit(rate)}
                        className="toolbar-button"
                        title="Szerkesztés"
                      >
                        <Edit size={14} />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Empty State */}
      {!loading && rates.length === 0 && !error && (
        <div className="form-panel text-center text-gray-500 py-8">
          Nincsenek elérhető árfolyamok. Kérjük, hozzon létre árfolyamot az Árfolyamkészítés oldalon.
        </div>
      )}
    </div>
  )
}
