import { useState, useCallback } from 'react'
import { BarChart3, Calendar, RefreshCw, TrendingUp, TrendingDown, ArrowRightLeft } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAuthStore } from '../../stores/authStore'
import { turnoverApi } from '../../services/api/index'
import { useTranslation } from 'react-i18next'

interface TurnoverData {
  date: string
  branchName: string
  currencies: Array<{
    currency: string
    buyCount: number
    buyAmount: number
    sellCount: number
    sellAmount: number
    conversionCount: number
    conversionAmount: number
    netFlow: number
    profit: number
  }>
  totals: {
    totalTransactions: number
    totalBuyHuf: number
    totalSellHuf: number
    totalProfit: number
    totalHandlingFees: number
    totalCommissions: number
  }
}

type Period = 'daily' | 'weekly' | 'monthly' | 'yearly'

export default function DailyTurnoverPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [date, setDate] = useState(new Date().toISOString().slice(0, 10))
  const [period, setPeriod] = useState<Period>('daily')
  const [data, setData] = useState<TurnoverData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadTurnover = useCallback(async () => {
    if (!branchId) { toast.warning('Fiók szükséges'); return }
    try {
      setLoading(true)
      setError(null)
      const res = await turnoverApi.byPeriod(period, branchId, date)
      setData(res as TurnoverData)
    } catch (err) {
      logger.error('DailyTurnoverPage', 'Forgalom betöltési hiba:', err)
      setError(getErrorMessage(err))
      setData(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, date, period])

  const fmtNum = (n: number) => n.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  const fmtHuf = (n: number) => n.toLocaleString('hu-HU', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) + ' Ft'

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><BarChart3 />{t('reports.forgalomOsszesito')}</h1>

      {/* Szűrők */}
      <div className="form-panel flex gap-3 items-end flex-wrap">
        <div>
          <label className="form-label">{t('common.period')}</label>
          <select className="form-input" value={period} onChange={e => setPeriod(e.target.value as Period)}>
            <option value="daily">{t('reports.napi')}</option>
            <option value="weekly">{t('reports.heti')}</option>
            <option value="monthly">{t('reports.havi')}</option>
            <option value="yearly">{t('reports.eves')}</option>
          </select>
        </div>
        <div>
          <label className="form-label">{t('common.date')}</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input className="form-input" type="date" value={date} onChange={e => setDate(e.target.value)} />
          </div>
        </div>
        <button onClick={() => void loadTurnover()} disabled={loading} className="form-button-primary">
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />{t('reports.lekerdezes')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      {data && (
        <>
          {/* Összesítő kártyák */}
          <div className="grid grid-cols-3 gap-3">
            <div className="form-panel text-center bg-green-50">
              <TrendingUp size={24} className="mx-auto text-green-600 mb-1" />
              <div className="text-lg font-bold text-green-700">{fmtHuf(data.totals.totalBuyHuf)}</div>
              <div className="text-sm text-gray-500">{t('reports.osszesVetel')}</div>
            </div>
            <div className="form-panel text-center bg-blue-50">
              <TrendingDown size={24} className="mx-auto text-blue-600 mb-1" />
              <div className="text-lg font-bold text-blue-700">{fmtHuf(data.totals.totalSellHuf)}</div>
              <div className="text-sm text-gray-500">{t('reports.osszesEladas')}</div>
            </div>
            <div className="form-panel text-center bg-yellow-50">
              <ArrowRightLeft size={24} className="mx-auto text-yellow-600 mb-1" />
              <div className="text-lg font-bold text-yellow-700">{fmtHuf(data.totals.totalProfit)}</div>
              <div className="text-sm text-gray-500">{t('reports.profit')}</div>
            </div>
          </div>

          {/* Extra összesítők */}
          <div className="grid grid-cols-3 gap-3">
            <div className="form-panel text-center">
              <div className="text-lg font-bold">{data.totals.totalTransactions}</div>
              <div className="text-sm text-gray-500">{t('customers.osszesTranzakcio')}</div>
            </div>
            <div className="form-panel text-center">
              <div className="text-lg font-bold">{fmtHuf(data.totals.totalHandlingFees)}</div>
              <div className="text-sm text-gray-500">{t('reports.kezelesiDijak')}</div>
            </div>
            <div className="form-panel text-center">
              <div className="text-lg font-bold">{fmtHuf(data.totals.totalCommissions)}</div>
              <div className="text-sm text-gray-500">{t('reports.jutalekok')}</div>
            </div>
          </div>

          {/* Devizánkénti bontás */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">{t('reports.devizankentiForgalom')}{data.branchName} — {data.date}</h2>
            {(data.currencies || []).length === 0 ? (
              <div className="text-center text-gray-500 py-4">{t('reports.nincsForgalmiAdat')}</div>
            ) : (
              <table className="data-grid w-full text-sm">
                <thead>
                  <tr>
                    <th>{t('common.deviza')}</th>
                    <th className="text-right">{t('darius.vetelDb')}</th>
                    <th className="text-right">{t('reports.vetelOsszeg')}</th>
                    <th className="text-right">{t('darius.eladasDb')}</th>
                    <th className="text-right">{t('reports.eladasOsszeg')}</th>
                    <th className="text-right">{t('cashier.conversion')}</th>
                    <th className="text-right">{t('reports.nettoMozgas')}</th>
                    <th className="text-right">{t('reports.profit')}</th>
                  </tr>
                </thead>
                <tbody>
                  {data.currencies.map(c => (
                    <tr key={c.currency}>
                      <td className="font-mono font-bold">{c.currency}</td>
                      <td className="text-right">{c.buyCount}</td>
                      <td className="text-right font-mono">{fmtNum(c.buyAmount)}</td>
                      <td className="text-right">{c.sellCount}</td>
                      <td className="text-right font-mono">{fmtNum(c.sellAmount)}</td>
                      <td className="text-right">{c.conversionCount}</td>
                      <td className={`text-right font-mono ${c.netFlow > 0 ? 'text-green-600' : c.netFlow < 0 ? 'text-red-600' : ''}`}>
                        {fmtNum(c.netFlow)}
                      </td>
                      <td className="text-right font-mono text-yellow-600">{fmtHuf(c.profit)}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="font-bold bg-gray-50">
                    <td>{t('reports.osszesen')}</td>
                    <td className="text-right">{data.currencies.reduce((s, c) => s + c.buyCount, 0)}</td>
                    <td></td>
                    <td className="text-right">{data.currencies.reduce((s, c) => s + c.sellCount, 0)}</td>
                    <td></td>
                    <td className="text-right">{data.currencies.reduce((s, c) => s + c.conversionCount, 0)}</td>
                    <td></td>
                    <td className="text-right">{fmtHuf(data.currencies.reduce((s, c) => s + c.profit, 0))}</td>
                  </tr>
                </tfoot>
              </table>
            )}
          </div>
        </>
      )}
    </div>
  )
}
