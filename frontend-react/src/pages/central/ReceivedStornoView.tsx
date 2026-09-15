import { Fragment, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { ArrowRight, Calendar, ChevronDown, ChevronRight, RotateCcw } from 'lucide-react'
import {
  receivedStornoApi,
  type ReceivedStorno,
  type ReceivedStornoRow,
} from '../../services/api/received-storno'
import { logger } from '../../utils/logger'
import { localIsoDate } from '../../utils/dateFormat'

const ALL_UNITS = '__ALL__'
const TERRITORY_PREFIX = 'territory:'
const BRANCH_PREFIX = 'branch:'

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

function parseUnit(value: string): { branchId?: string; vaultTerritoryId?: number } {
  if (value.startsWith(TERRITORY_PREFIX)) {
    return { vaultTerritoryId: Number(value.slice(TERRITORY_PREFIX.length)) }
  }
  if (value.startsWith(BRANCH_PREFIX)) {
    return { branchId: value.slice(BRANCH_PREFIX.length) }
  }
  return {}
}

function documentLabel(row: ReceivedStornoRow) {
  return [row.originalDocumentNumber, row.stornoDocumentNumber].filter(Boolean).join(' → ')
}

/**
 * FK-115: cancelled sale/purchase + transfer list. Fetched on button press only.
 */
export default function ReceivedStornoView() {
  const { t } = useTranslation()
  const yesterday = previousDayIso()
  const [fromDate, setFromDate] = useState(yesterday)
  const [toDate, setToDate] = useState(yesterday)
  const [unit, setUnit] = useState(ALL_UNITS)
  const [data, setData] = useState<ReceivedStorno | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(false)
  const [forbidden, setForbidden] = useState(false)
  const [hasRun, setHasRun] = useState(false)
  const [openKey, setOpenKey] = useState<string | null>(null)

  const load = async () => {
    setLoading(true)
    setError(false)
    setForbidden(false)
    try {
      const parsed = parseUnit(unit)
      const value = await receivedStornoApi.load(fromDate, toDate, {
        branchId: parsed.branchId ?? null,
        vaultTerritoryId: parsed.vaultTerritoryId ?? null,
      })
      setData(value)
    } catch (reason) {
      logger.error('ReceivedStornoView', 'Sztornó-lista lekérdezési hiba:', reason)
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

  return (
    <div className="space-y-4" data-testid="received-storno-view">
      <div className="rounded-md border border-slate-200 bg-white p-3">
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <label htmlFor="storno-from" className="mb-1 block text-xs font-medium text-slate-600">
              {t('centralReceivedData.bankTurnoverFrom')}
            </label>
            <div className="flex items-center gap-2">
              <Calendar size={16} className="text-slate-400" />
              <input
                id="storno-from"
                type="date"
                value={fromDate}
                onChange={(event) => setFromDate(event.target.value)}
                className="rounded border border-slate-300 px-2 py-2 text-sm"
              />
            </div>
          </div>
          <div>
            <label htmlFor="storno-to" className="mb-1 block text-xs font-medium text-slate-600">
              {t('centralReceivedData.bankTurnoverTo')}
            </label>
            <div className="flex items-center gap-2">
              <Calendar size={16} className="text-slate-400" />
              <input
                id="storno-to"
                type="date"
                value={toDate}
                onChange={(event) => setToDate(event.target.value)}
                className="rounded border border-slate-300 px-2 py-2 text-sm"
              />
            </div>
          </div>
          <div className="min-w-[260px]">
            <label htmlFor="storno-unit" className="mb-1 block text-xs font-medium text-slate-600">
              {t('centralReceivedData.denominationsUnit')}
            </label>
            <select
              id="storno-unit"
              value={unit}
              onChange={(event) => setUnit(event.target.value)}
              data-testid="storno-unit-select"
              className="w-full rounded border border-slate-300 bg-white px-2 py-2 text-sm"
            >
              <option value={ALL_UNITS}>{t('centralReceivedData.bankTurnoverAllCompany')}</option>
              {territories.map((territory) => (
                <option key={`t-${territory.id}`} value={`${TERRITORY_PREFIX}${territory.id}`}>
                  {t('centralReceivedData.bankTurnoverTerritory', { name: territory.name })}
                </option>
              ))}
              {branches.map((branch) => (
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
            data-testid="storno-load-button"
            className="inline-flex items-center gap-2 rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
          >
            <RotateCcw size={16} />
            {t('centralReceivedData.denominationsLoad')}
          </button>
        </div>
      </div>

      {(error || forbidden) && (
        <div
          data-testid="received-storno-error"
          className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
        >
          {t(forbidden ? 'centralReceivedData.stornoForbidden' : 'centralReceivedData.stornoError')}
        </div>
      )}

      <div className="overflow-hidden rounded-md border border-slate-200 bg-white">
        <div className="overflow-x-auto">
          <table className="data-grid min-w-full text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="w-8 px-3 py-2" />
                <th className="px-3 py-2 text-left">{t('centralReceivedData.stornoOffice')}</th>
                <th className="px-3 py-2 text-left">{t('centralReceivedData.stornoDate')}</th>
                <th className="px-3 py-2 text-left">{t('centralReceivedData.stornoTime')}</th>
                <th className="px-3 py-2 text-left">{t('centralReceivedData.stornoDocument')}</th>
                <th className="px-3 py-2 text-left">{t('centralReceivedData.stornoWorker')}</th>
                <th className="px-3 py-2 text-left">{t('centralReceivedData.stornoReason')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {rows.map((row, index) => {
                const key = `${row.type}-${row.stornoDocumentNumber}-${index}`
                const open = openKey === key
                const lines = Array.isArray(row.lines) ? row.lines : []
                return (
                  <Fragment key={key}>
                    <tr data-testid={`storno-row-${row.stornoDocumentNumber ?? index}`}>
                      <td className="px-3 py-2">
                        <button
                          type="button"
                          data-testid={`storno-expand-${row.stornoDocumentNumber ?? index}`}
                          onClick={() => setOpenKey(open ? null : key)}
                          className="text-slate-500"
                          aria-expanded={open}
                        >
                          {open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                        </button>
                      </td>
                      <td className="px-3 py-2">
                        <div className="font-semibold text-slate-900">{row.officeCode ?? '-'}</div>
                        <div className="text-xs text-slate-500">{row.officeName ?? ''}</div>
                      </td>
                      <td className="px-3 py-2 text-slate-700">{row.date}</td>
                      <td className="px-3 py-2 text-slate-700">{row.time ?? '-'}</td>
                      <td className="px-3 py-2 font-mono text-slate-700">{documentLabel(row)}</td>
                      <td className="px-3 py-2 text-slate-700">{row.workerName ?? '-'}</td>
                      <td className="px-3 py-2 text-slate-700">{row.reason ?? '-'}</td>
                    </tr>
                    {open && (
                      <tr data-testid={`storno-lines-${row.stornoDocumentNumber ?? index}`}>
                        <td colSpan={7} className="bg-slate-50 px-6 py-3">
                          <table className="w-full text-sm">
                            <thead>
                              <tr className="text-xs uppercase text-slate-500">
                                <th className="py-1 text-left">
                                  {t('centralReceivedData.denominationsCurrency')}
                                </th>
                                <th className="py-1 text-right">
                                  {t('centralReceivedData.stornoAmount')}
                                </th>
                                <th className="py-1 text-right">
                                  {t('centralReceivedData.stornoHuf')}
                                </th>
                              </tr>
                            </thead>
                            <tbody>
                              {lines.map((line, lineIndex) => (
                                <tr key={`${key}-line-${lineIndex}`}>
                                  <td className="py-1 font-mono">{line.currencyCode}</td>
                                  <td className="py-1 text-right font-mono">
                                    {formatAmount(line.amount)}
                                  </td>
                                  <td className="py-1 text-right font-mono">
                                    {line.rateMissing
                                      ? t('centralReceivedData.denominationsRateMissing')
                                      : formatAmount(line.hufValue)}
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </td>
                      </tr>
                    )}
                  </Fragment>
                )
              })}
              {!loading && hasRun && rows.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-3 py-8 text-center text-sm text-slate-500">
                    {t('centralReceivedData.stornoEmpty')}
                  </td>
                </tr>
              )}
              {!loading && !hasRun && (
                <tr>
                  <td colSpan={7} className="px-3 py-8 text-center text-sm text-slate-500">
                    <div className="inline-flex items-center gap-2">
                      <ArrowRight size={15} className="text-slate-400" />
                      {t('centralReceivedData.stornoPrompt')}
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        {loading && (
          <div className="border-t border-slate-100 px-3 py-3 text-sm text-slate-500">
            {t('centralReceivedData.stornoLoading')}
          </div>
        )}
      </div>
    </div>
  )
}
