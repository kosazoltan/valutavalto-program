import { useState, useEffect, useCallback } from 'react'
import { TrendingUp, RefreshCw, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

/**
 * ProfitReport shape (backend: ProfitCalculationService.ProfitReport)
 * - revenue, expenses, grossProfit, netProfit (BigDecimal -> number/string)
 * - totalTransactions (int)
 * - profitByCurrency: [{ currency, buyCount, sellCount, buyHuf, sellHuf, fees, profit }]
 *
 * Codex PR #144 P1 fix: GET /api/v1/profit/company EGY ProfitReport objektumot
 * ad vissza, NEM array-t. A korabbi safeArray<ProfitItem[]> mindig uresre esett.
 */
interface CurrencyProfitRow {
  currency?: string
  currencyCode?: string
  buyCount?: number
  sellCount?: number
  buyHuf?: number | string
  sellHuf?: number | string
  fees?: number | string
  profit?: number | string
}

interface ProfitReport {
  revenue?: number | string
  expenses?: number | string
  grossProfit?: number | string
  netProfit?: number | string
  totalTransactions?: number
  profitByCurrency?: CurrencyProfitRow[]
}

interface WacProfitSummary {
  totalProfit?: number | string
  transactionCount?: number
  sellCount?: number
  buyCount?: number
  profitByCurrency?: Record<string, number | string>
}

type ReportMode =
  | 'company-monthly'
  | 'branch-daily'
  | 'branch-monthly'
  | 'wac-company'
  | 'wac-branch'
  | 'wac-territory'

type LoadedReport =
  | { kind: 'classic'; data: ProfitReport }
  | { kind: 'wac'; data: WacProfitSummary }

const reportModeLabels: Record<ReportMode, string> = {
  'company-monthly': 'Cég havi',
  'branch-daily': 'Fiók napi',
  'branch-monthly': 'Fiók havi',
  'wac-company': 'WAC cég',
  'wac-branch': 'WAC fiók',
  'wac-territory': 'WAC terület',
}

function todayInput(): string {
  const d = new Date()
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

function formatHuf(v: number | string | undefined): string {
  if (v == null) return '-'
  const n = typeof v === 'string' ? Number(v) : v
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString('hu-HU')
}

export default function ProfitPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const currentDay = todayInput()
  const currentMonth = currentDay.slice(0, 7)
  const [report, setReport] = useState<LoadedReport | null>(null)
  const [mode, setMode] = useState<ReportMode>('company-monthly')
  const [date, setDate] = useState(currentDay)
  const [month, setMonth] = useState(currentMonth)
  const [from, setFrom] = useState(`${currentMonth}-01`)
  const [to, setTo] = useState(currentDay)
  const [territoryId, setTerritoryId] = useState('1')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    const branchId = worker?.branchId
    const needsBranch =
      mode === 'branch-daily' || mode === 'branch-monthly' || mode === 'wac-branch'
    if (needsBranch && !branchId) {
      setError('Nincs bejelentkezett fiók (branchId hiányzik) - a fiók riport nem tölthető.')
      setLoading(false)
      setReport(null)
      return
    }
    if (mode === 'wac-territory' && !territoryId.trim()) {
      setError('Terület azonosító szükséges a WAC területi riporthoz.')
      setLoading(false)
      setReport(null)
      return
    }

    try {
      setLoading(true)
      setError(null)
      if (mode === 'branch-daily') {
        const response = await api.get<ProfitReport>('/profit/daily', {
          params: { branchId, date },
        })
        setReport({ kind: 'classic', data: response.data ?? {} })
      } else if (mode === 'branch-monthly') {
        const response = await api.get<ProfitReport>('/profit/monthly', {
          params: { branchId, month },
        })
        setReport({ kind: 'classic', data: response.data ?? {} })
      } else if (mode === 'wac-company') {
        const response = await api.get<WacProfitSummary>('/profit/summary', {
          params: { from, to },
        })
        setReport({ kind: 'wac', data: response.data ?? {} })
      } else if (mode === 'wac-branch') {
        const response = await api.get<WacProfitSummary>(`/profit/branch/${branchId}`, {
          params: { from, to },
        })
        setReport({ kind: 'wac', data: response.data ?? {} })
      } else if (mode === 'wac-territory') {
        const response = await api.get<WacProfitSummary>(
          `/profit/territory/${territoryId.trim()}`,
          { params: { from, to } },
        )
        setReport({ kind: 'wac', data: response.data ?? {} })
      } else {
        const response = await api.get<ProfitReport>('/profit/company', { params: { month } })
        setReport({ kind: 'classic', data: response.data ?? {} })
      }
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('ProfitPage', 'Betoltesi hiba:', err)
      setError(msg)
      setReport(null)
    } finally {
      setLoading(false)
    }
  }, [date, from, mode, month, territoryId, to, worker?.branchId])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const classicReport = report?.kind === 'classic' ? report.data : null
  const wacReport = report?.kind === 'wac' ? report.data : null
  const rows: CurrencyProfitRow[] = classicReport?.profitByCurrency ?? []
  const wacRows = Object.entries(wacReport?.profitByCurrency ?? {})

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <TrendingUp className="h-6 w-6" />
          {t('profit.haszonKimutatas')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissites">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="rounded border border-gray-200 bg-white p-3">
        <div className="grid gap-3 lg:grid-cols-[minmax(220px,1fr)_2fr]">
          <div>
            <label htmlFor="profit-mode" className="form-label">
              {i18n.t('literals.riport-tipusa')}
            </label>
            <select
              id="profit-mode"
              value={mode}
              onChange={(event) => setMode(event.target.value as ReportMode)}
              className="form-input w-full"
            >
              {Object.entries(reportModeLabels).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {(mode === 'company-monthly' || mode === 'branch-monthly') && (
              <div>
                <label htmlFor="profit-month" className="form-label">
                  {i18n.t('literals.honap')}
                </label>
                <input
                  id="profit-month"
                  type="month"
                  value={month}
                  onChange={(event) => setMonth(event.target.value)}
                  className="form-input w-full"
                />
              </div>
            )}
            {mode === 'branch-daily' && (
              <div>
                <label htmlFor="profit-date" className="form-label">
                  {i18n.t('literals.nap')}
                </label>
                <input
                  id="profit-date"
                  type="date"
                  value={date}
                  onChange={(event) => setDate(event.target.value)}
                  className="form-input w-full"
                />
              </div>
            )}
            {(mode === 'wac-company' || mode === 'wac-branch' || mode === 'wac-territory') && (
              <>
                <div>
                  <label htmlFor="profit-from" className="form-label">
                    {i18n.t('literals.kezdete')}
                  </label>
                  <input
                    id="profit-from"
                    type="date"
                    value={from}
                    onChange={(event) => setFrom(event.target.value)}
                    className="form-input w-full"
                  />
                </div>
                <div>
                  <label htmlFor="profit-to" className="form-label">
                    {i18n.t('literals.vege')}
                  </label>
                  <input
                    id="profit-to"
                    type="date"
                    value={to}
                    onChange={(event) => setTo(event.target.value)}
                    className="form-input w-full"
                  />
                </div>
              </>
            )}
            {mode === 'wac-territory' && (
              <div>
                <label htmlFor="profit-territory" className="form-label">
                  {i18n.t('literals.terulet-id')}
                </label>
                <input
                  id="profit-territory"
                  type="number"
                  min="1"
                  value={territoryId}
                  onChange={(event) => setTerritoryId(event.target.value)}
                  className="form-input w-full"
                />
              </div>
            )}
          </div>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {/* Osszesitett sor */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">{t('profit.bevetel')}</div>
          <div className="text-xl font-mono">{formatHuf(classicReport?.revenue)}</div>
        </div>
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">{t('profit.koltsegek')}</div>
          <div className="text-xl font-mono">{formatHuf(classicReport?.expenses)}</div>
        </div>
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">{t('profit.bruttoHaszon')}</div>
          <div className="text-xl font-mono">{formatHuf(classicReport?.grossProfit)}</div>
        </div>
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">
            {wacReport ? 'WAC összhaszon' : t('profit.nettoHaszon')}
          </div>
          <div className="text-xl font-mono">
            {formatHuf(wacReport?.totalProfit ?? classicReport?.netProfit)}
          </div>
        </div>
      </div>

      {wacReport && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div className="bg-white rounded shadow p-3">
            <div className="text-xs text-gray-500">{i18n.t('literals.tranzakciok')}</div>
            <div className="text-xl font-mono">{wacReport.transactionCount ?? 0}</div>
          </div>
          <div className="bg-white rounded shadow p-3">
            <div className="text-xs text-gray-500">{t('darius.vetelDb')}</div>
            <div className="text-xl font-mono">{wacReport.buyCount ?? 0}</div>
          </div>
          <div className="bg-white rounded shadow p-3">
            <div className="text-xs text-gray-500">{t('darius.eladasDb')}</div>
            <div className="text-xl font-mono">{wacReport.sellCount ?? 0}</div>
          </div>
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            {wacReport ? (
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                  {t('common.deviza')}
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                  {t('profit.haszon')}
                </th>
              </tr>
            ) : (
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                  {t('common.deviza')}
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                  {t('darius.vetelDb')}
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                  {t('darius.eladasDb')}
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                  {t('profit.vetelHuf')}
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                  {t('profit.eladasHuf')}
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                  {t('profit.haszon')}
                </th>
              </tr>
            )}
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td
                  colSpan={wacReport ? 2 : 6}
                  className="px-4 py-8 text-center text-sm text-gray-500"
                >
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : wacReport ? (
              wacRows.length === 0 ? (
                <tr>
                  <td colSpan={2} className="px-4 py-8 text-center text-sm text-gray-500">
                    {t('common.noData')}
                  </td>
                </tr>
              ) : (
                wacRows.map(([currency, profit]) => (
                  <tr key={currency} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm">{currency}</td>
                    <td className="px-4 py-3 text-right text-sm font-mono">{formatHuf(profit)}</td>
                  </tr>
                ))
              )
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              rows.map((r, i) => (
                <tr
                  key={`${r.currencyCode ?? r.currency ?? 'idx'}-${i}`}
                  className="hover:bg-gray-50"
                >
                  <td className="px-4 py-3 text-sm">{r.currencyCode ?? r.currency ?? '-'}</td>
                  <td className="px-4 py-3 text-right text-sm font-mono">{r.buyCount ?? '-'}</td>
                  <td className="px-4 py-3 text-right text-sm font-mono">{r.sellCount ?? '-'}</td>
                  <td className="px-4 py-3 text-right text-sm font-mono">{formatHuf(r.buyHuf)}</td>
                  <td className="px-4 py-3 text-right text-sm font-mono">{formatHuf(r.sellHuf)}</td>
                  <td className="px-4 py-3 text-right text-sm font-mono">{formatHuf(r.profit)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('decade.tranzakciok')}
        {classicReport?.totalTransactions ?? wacReport?.transactionCount ?? 0}
      </div>
    </div>
  )
}
