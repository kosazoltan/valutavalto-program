import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, ArrowRight, Calendar, Landmark } from 'lucide-react'
import {
  receivedBankTurnoverApi,
  type ReceivedBankTurnover,
  type ReceivedBankTurnoverMissingDay,
} from '../../services/api/received-bank-turnover'
import { logger } from '../../utils/logger'
import { localIsoDate } from '../../utils/dateFormat'

const ALL_UNITS = '__ALL__'
const TERRITORY_PREFIX = 'territory:'
const BRANCH_PREFIX = 'branch:'

type UnitMode = 'company' | 'territory' | 'branch'

function previousDayIso() {
  const d = new Date()
  d.setDate(d.getDate() - 1)
  return localIsoDate(d)
}

function formatAmount(value: number | string | null | undefined) {
  if (value == null || value === '') return '-'
  const n = typeof value === 'number' ? value : Number(value)
  if (Number.isNaN(n)) return '-'
  return n.toLocaleString('hu-HU', { maximumFractionDigits: 2 })
}

function parseUnit(value: string): {
  mode: UnitMode
  branchId?: string
  vaultTerritoryId?: number
} {
  if (value.startsWith(TERRITORY_PREFIX)) {
    return { mode: 'territory', vaultTerritoryId: Number(value.slice(TERRITORY_PREFIX.length)) }
  }
  if (value.startsWith(BRANCH_PREFIX)) {
    return { mode: 'branch', branchId: value.slice(BRANCH_PREFIX.length) }
  }
  return { mode: 'company' }
}

/**
 * FK-114: period bank turnover ("Banki forgalmi adatok" tab).
 * Fetched on button press only — the hosting page never auto-queries this endpoint.
 */
export default function ReceivedBankTurnoverView() {
  const { t } = useTranslation()
  const yesterday = previousDayIso()
  const [fromDate, setFromDate] = useState(yesterday)
  const [toDate, setToDate] = useState(yesterday)
  const [unit, setUnit] = useState(ALL_UNITS)
  const [data, setData] = useState<ReceivedBankTurnover | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(false)
  const [forbidden, setForbidden] = useState(false)
  const [hasRun, setHasRun] = useState(false)

  const load = async () => {
    setLoading(true)
    setError(false)
    setForbidden(false)
    try {
      const parsed = parseUnit(unit)
      const value = await receivedBankTurnoverApi.load(fromDate, toDate, {
        branchId: parsed.branchId ?? null,
        vaultTerritoryId: parsed.vaultTerritoryId ?? null,
      })
      setData(value)
    } catch (reason) {
      logger.error('ReceivedBankTurnoverView', 'Banki forgalom lekérdezési hiba:', reason)
      setData(null)
      const status = (reason as { response?: { status?: number } })?.response?.status
      if (status === 403) {
        setForbidden(true)
      } else {
        setError(true)
      }
    }
    setHasRun(true)
    setLoading(false)
  }

  const rows = Array.isArray(data?.rows) ? data.rows : []
  const missing = Array.isArray(data?.missingClosingDays) ? data.missingClosingDays : []
  const branches = useMemo(
    () => (Array.isArray(data?.branches) ? data.branches : []),
    [data?.branches],
  )
  const territories = useMemo(() => {
    if (Array.isArray(data?.territories) && data.territories.length > 0) {
      return data.territories
    }
    const map = new Map<number, string>()
    for (const branch of branches) {
      if (branch.vaultTerritoryId != null && !map.has(branch.vaultTerritoryId)) {
        map.set(branch.vaultTerritoryId, branch.region || `Terület ${branch.vaultTerritoryId}`)
      }
    }
    return Array.from(map.entries())
      .map(([id, name]) => ({ id, name }))
      .sort((a, b) => a.name.localeCompare(b.name, 'hu'))
  }, [branches, data?.territories])
  const vaultBranches = branches.filter((b) => b.isVault)

  return (
    <div className="space-y-4" data-testid="received-bank-turnover-view">
      <div className="rounded-md border border-slate-200 bg-white p-3">
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <label
              htmlFor="bank-turnover-from"
              className="mb-1 block text-xs font-medium text-slate-600"
            >
              {t('centralReceivedData.bankTurnoverFrom')}
            </label>
            <div className="flex items-center gap-2">
              <Calendar size={16} className="text-slate-400" />
              <input
                id="bank-turnover-from"
                type="date"
                value={fromDate}
                max={yesterday}
                onChange={(event) => setFromDate(event.target.value)}
                className="rounded border border-slate-300 px-2 py-2 text-sm"
              />
            </div>
          </div>
          <div>
            <label
              htmlFor="bank-turnover-to"
              className="mb-1 block text-xs font-medium text-slate-600"
            >
              {t('centralReceivedData.bankTurnoverTo')}
            </label>
            <div className="flex items-center gap-2">
              <Calendar size={16} className="text-slate-400" />
              <input
                id="bank-turnover-to"
                type="date"
                value={toDate}
                max={yesterday}
                onChange={(event) => setToDate(event.target.value)}
                className="rounded border border-slate-300 px-2 py-2 text-sm"
              />
            </div>
          </div>
          <div className="min-w-[260px]">
            <label
              htmlFor="bank-turnover-unit"
              className="mb-1 block text-xs font-medium text-slate-600"
            >
              {t('centralReceivedData.denominationsUnit')}
            </label>
            <select
              id="bank-turnover-unit"
              value={unit}
              onChange={(event) => setUnit(event.target.value)}
              data-testid="bank-turnover-unit-select"
              className="w-full rounded border border-slate-300 bg-white px-2 py-2 text-sm"
            >
              <option value={ALL_UNITS}>{t('centralReceivedData.bankTurnoverAllCompany')}</option>
              {territories.map((territory) => (
                <option key={`t-${territory.id}`} value={`${TERRITORY_PREFIX}${territory.id}`}>
                  {t('centralReceivedData.bankTurnoverTerritory', { name: territory.name })}
                </option>
              ))}
              {vaultBranches.map((branch) => (
                <option key={branch.id} value={`${BRANCH_PREFIX}${branch.id}`}>
                  {[branch.code, branch.name].filter(Boolean).join(' — ')}
                </option>
              ))}
            </select>
          </div>
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            data-testid="bank-turnover-load-button"
            className="inline-flex items-center gap-2 rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
          >
            <Landmark size={16} />
            {t('centralReceivedData.denominationsLoad')}
          </button>
        </div>
      </div>

      {(error || forbidden) && (
        <div
          data-testid="received-bank-turnover-error"
          className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
        >
          {t(
            forbidden
              ? 'centralReceivedData.bankTurnoverForbidden'
              : 'centralReceivedData.bankTurnoverError',
          )}
        </div>
      )}

      {missing.length > 0 && (
        <div
          data-testid="bank-turnover-missing-days"
          className="rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900"
        >
          <div className="mb-1 inline-flex items-center gap-2 font-semibold">
            <AlertTriangle size={16} />
            {t('centralReceivedData.bankTurnoverMissingTitle', { count: missing.length })}
          </div>
          <ul className="list-disc pl-5">
            {missing.map((day: ReceivedBankTurnoverMissingDay) => (
              <li key={`${day.branchId}-${day.date}`}>
                {day.date} — {[day.branchCode, day.branchName].filter(Boolean).join(' ')}
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="overflow-hidden rounded-md border border-slate-200 bg-white">
        <div className="overflow-x-auto">
          <table className="data-grid min-w-full text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-3 py-2 text-left">
                  {t('centralReceivedData.denominationsCurrency')}
                </th>
                <th className="px-3 py-2 text-right">
                  {t('centralReceivedData.bankTurnoverBankIn')}
                </th>
                <th className="px-3 py-2 text-right">
                  {t('centralReceivedData.bankTurnoverBankOut')}
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {rows.map((row) => (
                <tr key={row.currencyCode} data-testid={`bank-turnover-row-${row.currencyCode}`}>
                  <td className="px-3 py-2 font-mono text-slate-700">{row.currencyCode}</td>
                  <td className="px-3 py-2 text-right font-mono text-slate-700">
                    {formatAmount(row.bankIn)}
                  </td>
                  <td className="px-3 py-2 text-right font-mono text-slate-700">
                    {formatAmount(row.bankOut)}
                  </td>
                </tr>
              ))}
              {!loading && hasRun && rows.length === 0 && (
                <tr>
                  <td colSpan={3} className="px-3 py-8 text-center text-sm text-slate-500">
                    {t('centralReceivedData.bankTurnoverEmpty')}
                  </td>
                </tr>
              )}
              {!loading && !hasRun && (
                <tr>
                  <td colSpan={3} className="px-3 py-8 text-center text-sm text-slate-500">
                    <div className="inline-flex items-center gap-2">
                      <ArrowRight size={15} className="text-slate-400" />
                      {t('centralReceivedData.bankTurnoverPrompt')}
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        {loading && (
          <div className="border-t border-slate-100 px-3 py-3 text-sm text-slate-500">
            {t('centralReceivedData.bankTurnoverLoading')}
          </div>
        )}
      </div>
    </div>
  )
}
