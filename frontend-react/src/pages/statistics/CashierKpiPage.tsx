import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  Users,
  TrendingUp,
  TrendingDown,
  RefreshCw,
  AlertTriangle,
  Award,
  Calendar,
  DollarSign,
} from 'lucide-react'
import { cashierKpiApi, type CashierKpiSummary } from '../../services/api/cashierKpi'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

type QuickRange = 'today' | 'week' | 'month' | 'custom'

function formatInt(n: number | undefined | null): string {
  if (n == null) return '0'
  return Math.round(n).toLocaleString('hu-HU')
}

function formatHuf(n: number | undefined | null): string {
  return `${formatInt(n)} Ft`
}

function formatPct(n: number | undefined | null): string {
  if (n == null) return '0%'
  return `${Number(n).toFixed(1)}%`
}

function isoDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function rangeFor(quick: QuickRange): { from: string; to: string } {
  const today = new Date()
  const to = isoDate(today)
  if (quick === 'today') return { from: to, to }
  if (quick === 'week') {
    const w = new Date(today)
    w.setDate(w.getDate() - 6)
    return { from: isoDate(w), to }
  }
  if (quick === 'month') {
    const first = new Date(today.getFullYear(), today.getMonth(), 1)
    return { from: isoDate(first), to }
  }
  return { from: to, to }
}

export default function CashierKpiPage() {
  const { t } = useTranslation()
  const [quick, setQuick] = useState<QuickRange>('month')
  const initialRange = useMemo(() => rangeFor('month'), [])
  const [dateFrom, setDateFrom] = useState<string>(initialRange.from)
  const [dateTo, setDateTo] = useState<string>(initialRange.to)
  const [data, setData] = useState<CashierKpiSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [err, setErr] = useState<string | null>(null)
  const [sortBy, setSortBy] = useState<'name' | 'totalHuf' | 'txCount' | 'reversalRatio'>(
    'totalHuf',
  )

  const [reloadTick, setReloadTick] = useState(0)
  const load = useCallback(() => setReloadTick((t) => t + 1), [])

  useEffect(() => {
    // Race condition safety: ha a deps gyorsan valtoznak, a regi fetch elvesz
    let cancelled = false
    setLoading(true)
    setErr(null)
    cashierKpiApi
      .get(dateFrom, dateTo)
      .then((res) => {
        if (!cancelled) setData(res)
      })
      .catch((e) => {
        if (!cancelled) {
          logger.error('CashierKpi', 'load err', e)
          setErr(e instanceof Error ? e.message : String(e))
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [dateFrom, dateTo, reloadTick])

  const handleQuick = (q: QuickRange) => {
    setQuick(q)
    if (q !== 'custom') {
      const r = rangeFor(q)
      setDateFrom(r.from)
      setDateTo(r.to)
    }
  }

  const sortedRows = useMemo(() => {
    if (!data) return []
    const rows = [...data.rows]
    if (sortBy === 'name') rows.sort((a, b) => a.workerName.localeCompare(b.workerName, 'hu'))
    else if (sortBy === 'totalHuf') rows.sort((a, b) => b.totalHuf - a.totalHuf)
    else if (sortBy === 'txCount') rows.sort((a, b) => b.txCount - a.txCount)
    else if (sortBy === 'reversalRatio') rows.sort((a, b) => b.reversalRatio - a.reversalRatio)
    return rows
  }, [data, sortBy])

  // Codex P2 fix: a top performer MINDIG a legnagyobb forgalmu — fuggetlen a sortBy-tol
  const topWorkerByTurnover = useMemo(() => {
    if (!data || data.rows.length === 0) return null
    const first = data.rows[0]
    if (!first) return null
    return data.rows.reduce((max, r) => (r.totalHuf > max.totalHuf ? r : max), first)
  }, [data])

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-base font-bold text-secondary-900 flex items-center gap-2">
            <Users className="text-primary-600" size={18} />
            {t('statistics.penztarosKpiDashboard')}
          </h1>
          <p className="text-xs text-secondary-500">
            {t('statistics.forgalomTranzakcioszamEsSztornoAranyPenztarosonkent')}
          </p>
        </div>
        <button
          type="button"
          onClick={() => void load()}
          disabled={loading}
          className="form-button"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          <span>{t('common.refresh')}</span>
        </button>
      </div>

      {/* Date range selector */}
      <div className="form-panel p-4 flex flex-wrap items-end gap-3">
        <div className="flex gap-1">
          {(['today', 'week', 'month', 'custom'] as QuickRange[]).map((q) => (
            <button
              key={q}
              type="button"
              onClick={() => handleQuick(q)}
              className={`px-3 py-2 text-xs font-semibold rounded border transition-all ${
                quick === q
                  ? 'bg-primary-600 text-white border-primary-700'
                  : 'bg-white text-secondary-700 border-secondary-200 hover:border-primary-400'
              }`}
            >
              {q === 'today'
                ? 'Ma'
                : q === 'week'
                  ? 'Utolsó 7 nap'
                  : q === 'month'
                    ? 'Ez a hónap'
                    : 'Egyéni'}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2 ml-2">
          <Calendar size={16} className="text-secondary-400" />
          <input
            type="date"
            className="form-input h-9 text-xs"
            value={dateFrom}
            max={dateTo || isoDate(new Date())}
            onChange={(e) => {
              setDateFrom(e.target.value)
              setQuick('custom')
            }}
            aria-label="Kezdo datum"
          />
          <span className="text-secondary-400 text-xs">{i18n.t('literals.lit-15')}</span>
          <input
            type="date"
            className="form-input h-9 text-xs"
            value={dateTo}
            min={dateFrom}
            max={isoDate(new Date())}
            onChange={(e) => {
              setDateTo(e.target.value)
              setQuick('custom')
            }}
            aria-label="Veg datum"
          />
        </div>
      </div>

      {/* Error */}
      {err && (
        <div className="p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 flex items-center gap-2">
          <AlertTriangle size={18} />
          <span className="text-sm">{err}</span>
        </div>
      )}

      {/* Summary cards */}
      {data && !loading && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <KpiCard
            icon={<DollarSign className="text-blue-500" size={20} />}
            label="Összforgalom"
            value={formatHuf(data.totalHuf)}
            sub={`${formatInt(data.totalTxCount)} tranzakció`}
          />
          <KpiCard
            icon={<TrendingUp className="text-green-500" size={20} />}
            label="Vétel / Eladás"
            value={`${formatInt(data.totalBuyCount)} / ${formatInt(data.totalSellCount)}`}
            sub="aktív tranzakciók"
          />
          <KpiCard
            icon={<TrendingDown className="text-orange-500" size={20} />}
            label="Sztornó arány"
            value={formatPct(data.reversalRatio)}
            sub={`${formatInt(data.totalReversalCount)} db`}
            danger={data.reversalRatio > 5}
          />
          <KpiCard
            icon={<Users className="text-purple-500" size={20} />}
            label="Aktív pénztárosok"
            value={formatInt(data.activeWorkerCount)}
            sub={`${formatInt(data.totalCustomerCount)} egyedi ügyfél`}
          />
        </div>
      )}

      {/* Top performer highlight */}
      {topWorkerByTurnover && !loading && (
        <div className="form-panel p-4 flex items-center gap-4 bg-gradient-to-r from-yellow-50 to-amber-50 border-yellow-200">
          <Award className="text-yellow-600" size={32} />
          <div>
            <div className="text-xs text-secondary-500 uppercase tracking-wide">
              {t('statistics.legnagyobbForgalom')}
            </div>
            <div className="text-xl font-bold text-secondary-900">
              {topWorkerByTurnover.workerName}
            </div>
            <div className="text-sm text-secondary-600">
              {formatHuf(topWorkerByTurnover.totalHuf)}
              {i18n.t('literals.lit-17')}
              {formatInt(topWorkerByTurnover.txCount)} {t('statistics.tranzakcioAtlag')}{' '}
              {formatHuf(topWorkerByTurnover.avgTxHuf)}
            </div>
          </div>
        </div>
      )}

      {/* Worker table */}
      <div className="form-panel">
        <div className="px-4 py-3 border-b border-secondary-200 flex items-center justify-between">
          <h2 className="font-semibold text-secondary-900">{t('statistics.penztarosokBontasa')}</h2>
          <div className="flex items-center gap-2">
            <span className="text-xs text-secondary-500">{t('statistics.rendezes')}</span>
            <select
              className="form-input h-8 text-xs w-40"
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
            >
              <option value="totalHuf">{t('statistics.forgalomCsokkeno')}</option>
              <option value="txCount">{t('statistics.tranzakcioSzam')}</option>
              <option value="reversalRatio">{t('statistics.sztorno')}</option>
              <option value="name">{t('common.name')}</option>
            </select>
          </div>
        </div>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('components.penztaros2')}</th>
              <th className="text-right">{t('closing.tranzakcio')}</th>
              <th className="text-right">{t('cashier.buy')}</th>
              <th className="text-right">{t('cashier.sell')}</th>
              <th className="text-right">{t('cashier.storno')}</th>
              <th className="text-right">{t('statistics.sztorno')}</th>
              <th className="text-right">{t('cashier.turnover')}</th>
              <th className="text-right">{t('statistics.atlagTx')}</th>
              <th className="text-right">{t('cashier.handlingFee')}</th>
              <th className="text-right">{t('common.customer')}</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr>
                <td colSpan={10} className="text-center text-sm text-secondary-400 py-8">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            )}
            {!loading && sortedRows.length === 0 && (
              <tr>
                <td colSpan={10} className="text-center text-sm text-secondary-400 py-8">
                  {t('statistics.nincsTranzakcioEbbenAzIdoszakban')}
                </td>
              </tr>
            )}
            {!loading &&
              sortedRows.map((r) => (
                <tr key={r.workerId}>
                  <td className="font-semibold">{r.workerName}</td>
                  <td className="text-right font-mono">{formatInt(r.txCount)}</td>
                  <td className="text-right font-mono text-blue-700">{formatInt(r.buyCount)}</td>
                  <td className="text-right font-mono text-orange-700">{formatInt(r.sellCount)}</td>
                  <td className="text-right font-mono text-red-700">
                    {formatInt(r.reversalCount)}
                  </td>
                  <td
                    className={`text-right font-mono text-xs ${r.reversalRatio > 5 ? 'text-red-600 font-bold' : 'text-secondary-600'}`}
                  >
                    {formatPct(r.reversalRatio)}
                  </td>
                  <td className="text-right font-mono font-semibold">{formatHuf(r.totalHuf)}</td>
                  <td className="text-right font-mono text-xs text-secondary-600">
                    {formatHuf(r.avgTxHuf)}
                  </td>
                  <td className="text-right font-mono text-xs">{formatHuf(r.totalFees)}</td>
                  <td className="text-right font-mono text-xs">{formatInt(r.customerCount)}</td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function KpiCard({
  icon,
  label,
  value,
  sub,
  danger,
}: {
  icon: React.ReactNode
  label: string
  value: string
  sub?: string
  danger?: boolean
}) {
  return (
    <div
      className={`p-4 rounded-lg border bg-white shadow-sm ${
        danger ? 'border-red-300' : 'border-secondary-200'
      }`}
    >
      <div className="flex items-center gap-2 mb-2">
        {icon}
        <span className="text-xs font-medium text-secondary-500 uppercase tracking-wide">
          {label}
        </span>
      </div>
      <div className={`text-2xl font-bold ${danger ? 'text-red-600' : 'text-secondary-900'}`}>
        {value}
      </div>
      {sub && <div className="text-xs text-secondary-500 mt-1">{sub}</div>}
    </div>
  )
}
