import { useEffect, useState, useCallback } from 'react'
import { Map as MapIcon, RefreshCw, TrendingUp, TrendingDown } from 'lucide-react'
import { api } from '@/services/api/index'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'

interface RegionLine {
  regionCode: string
  buyCount: number
  sellCount: number
  buyHuf: number
  sellHuf: number
  totalTurnoverHuf: number
  distinctCustomers: number
  activeDays: number
  avgDailyTurnoverHuf: number
  previousTurnoverHuf: number
  trendPercent: number
}

interface RegionTurnoverReport {
  yearMonth: string
  previousYearMonth: string
  regions: RegionLine[]
  totalTurnoverHuf: number
  previousTotalTurnoverHuf: number
  totalTrendPercent: number
}

function currentMonth(): string {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

export default function RegionTurnoverReportPage() {
  const { t } = useTranslation()
  const [yearMonth, setYearMonth] = useState(currentMonth())
  const [data, setData] = useState<RegionTurnoverReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await api.get(`/reports/region-turnover?yearMonth=${yearMonth}`)
      setData((response?.data ?? null) as RegionTurnoverReport | null)
    } catch {
      setError(t('reports.koerzetRiportHiba'))
      setData(null)
    } finally {
      setLoading(false)
    }
  }, [yearMonth, t])

  useEffect(() => { void load() }, [load])

  const regions = safeArray<RegionLine>(data?.regions)
  const fmtHuf = (n: number) => n.toLocaleString('hu-HU', { maximumFractionDigits: 0 }) + ' Ft'
  const fmtPct = (n: number) => `${n > 0 ? '+' : ''}${n.toLocaleString('hu-HU', { maximumFractionDigits: 1 })}%`

  const TrendCell = ({ pct }: { pct: number }) => (
    <span className={`inline-flex items-center gap-1 font-mono ${pct > 0 ? 'text-green-600' : pct < 0 ? 'text-red-600' : 'text-gray-500'}`}>
      {pct > 0 ? <TrendingUp size={14} /> : pct < 0 ? <TrendingDown size={14} /> : null}
      {fmtPct(pct)}
    </span>
  )

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><MapIcon />{t('reports.koerzetForgalom')}</h1>

      <div className="form-panel flex gap-3 items-end flex-wrap">
        <div>
          <label className="form-label" htmlFor="region-turnover-month">{t('common.period')}</label>
          <input
            id="region-turnover-month"
            type="month"
            value={yearMonth}
            onChange={(e) => setYearMonth(e.target.value)}
            className="form-input"
          />
        </div>
        <button onClick={() => void load()} disabled={loading} className="form-button-primary">
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />{t('reports.lekerdezes')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      {loading ? (
        <div className="text-center py-8 text-gray-500">{t('common.loading')}</div>
      ) : data && regions.length > 0 ? (
        <div className="form-panel">
          <div className="flex justify-between items-center mb-2 text-sm text-gray-600">
            <span>{data.yearMonth} ({t('reports.elozoHonap')}: {data.previousYearMonth})</span>
            <span className="flex items-center gap-2">
              {t('reports.osszesen')}: <strong>{fmtHuf(data.totalTurnoverHuf)}</strong>
              <TrendCell pct={data.totalTrendPercent} />
            </span>
          </div>
          <table className="data-grid w-full text-sm">
            <thead>
              <tr>
                <th>{t('reports.koerzet')}</th>
                <th className="text-right">{t('darius.vetelDb')}</th>
                <th className="text-right">{t('darius.eladasDb')}</th>
                <th className="text-right">{t('reports.osszesForgalom')}</th>
                <th className="text-right">{t('reports.vevoSzam')}</th>
                <th className="text-right">{t('reports.aktivNapok')}</th>
                <th className="text-right">{t('reports.atlagNapiForgalom')}</th>
                <th className="text-right">{t('reports.trend')}</th>
              </tr>
            </thead>
            <tbody>
              {regions.map((r) => (
                <tr key={r.regionCode}>
                  <td className="font-mono font-bold">{r.regionCode}</td>
                  <td className="text-right">{r.buyCount}</td>
                  <td className="text-right">{r.sellCount}</td>
                  <td className="text-right font-mono">{fmtHuf(r.totalTurnoverHuf)}</td>
                  <td className="text-right">{r.distinctCustomers}</td>
                  <td className="text-right">{r.activeDays}</td>
                  <td className="text-right font-mono">{fmtHuf(r.avgDailyTurnoverHuf)}</td>
                  <td className="text-right"><TrendCell pct={r.trendPercent} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="text-center py-8 text-gray-500">{t('reports.nincsForgalmiAdat')}</div>
      )}
    </div>
  )
}
