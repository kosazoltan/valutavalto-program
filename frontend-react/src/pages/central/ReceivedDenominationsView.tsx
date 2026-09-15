import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, ArrowRight, Calendar, Layers } from 'lucide-react'
import {
  receivedDenominationsApi,
  type ReceivedDenominationCurrencyRow,
  type ReceivedDenominations,
} from '../../services/api/received-denominations'
import { logger } from '../../utils/logger'
import { localIsoDate } from '../../utils/dateFormat'

const ALL_BRANCHES = '__ALL__'

/** Canonical face-value columns (FK-112). Backend also echoes this list. */
export const FIXED_FACE_VALUES = [
  20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1,
] as const

/** Previous day as a LOCAL ISO date — the closing snapshot of the last closed business day. */
function previousDayIso() {
  const d = new Date()
  d.setDate(d.getDate() - 1)
  return localIsoDate(d)
}

function formatNumber(value: number | null | undefined, fractionDigits = 0) {
  if (value == null) return '-'
  return value.toLocaleString('hu-HU', {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  })
}

/**
 * Face values are shown at their STORED precision. Rounding to whole units would hide the very
 * defect the red highlight reports (a legacy fractional 0.5 would read as "1", 0.2 as "0").
 */
function formatFaceValue(value: number | null | undefined) {
  if (value == null) return '-'
  return value.toLocaleString('hu-HU', { maximumFractionDigits: 20 })
}

function faceValuesOf(data: ReceivedDenominations | null): number[] {
  if (Array.isArray(data?.fixedFaceValues) && data.fixedFaceValues.length > 0) {
    return data.fixedFaceValues
  }
  return [...FIXED_FACE_VALUES]
}

function rateSourceLabel(
  t: ReturnType<typeof useTranslation>['t'],
  source: string | null | undefined,
) {
  if (source === 'MNB') return t('centralReceivedData.denominationsRateSourceMnb')
  if (source === 'MANUAL_SETTLEMENT') return t('centralReceivedData.denominationsRateSourceManual')
  return source ?? ''
}

/**
 * FK-111 / FK-112: closing-time denomination matrix ("Keszletek, cimletek" tab).
 *
 * The data is fetched on button press only — the hosting page never auto-queries.
 * Columns are the 14 catalog face values plus Egyeb; HUF conversion uses live rates
 * from the response (never stored on the snapshot).
 */
export default function ReceivedDenominationsView() {
  const { t } = useTranslation()
  const [date, setDate] = useState(previousDayIso())
  const [unit, setUnit] = useState<string>(ALL_BRANCHES)
  const [data, setData] = useState<ReceivedDenominations | null>(null)
  const [branchOptions, setBranchOptions] = useState<ReceivedDenominations['branches']>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(false)
  const [forbidden, setForbidden] = useState(false)
  const [hasRun, setHasRun] = useState(false)

  const load = async () => {
    setLoading(true)
    setError(false)
    setForbidden(false)
    try {
      const value = await receivedDenominationsApi.load(date, unit === ALL_BRANCHES ? null : unit)
      setData(value)
      setBranchOptions(value.branches ?? [])
    } catch (reason) {
      logger.error('ReceivedDenominationsView', 'Készletadat lekérdezési hiba:', reason)
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
  const columns = faceValuesOf(data)
  const colCount = columns.length + 3

  return (
    <div className="space-y-4" data-testid="received-denominations-view">
      <div className="rounded-md border border-slate-200 bg-white p-3">
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <label
              htmlFor="denominations-date"
              className="mb-1 block text-xs font-medium text-slate-600"
            >
              {t('centralReceivedData.denominationsTitle')}
            </label>
            <div className="flex items-center gap-2">
              <Calendar size={16} className="text-slate-400" />
              <input
                id="denominations-date"
                type="date"
                value={date}
                onChange={(event) => setDate(event.target.value)}
                className="rounded border border-slate-300 px-2 py-2 text-sm"
              />
            </div>
          </div>
          <div className="min-w-[240px]">
            <label
              htmlFor="denominations-unit"
              className="mb-1 block text-xs font-medium text-slate-600"
            >
              {t('centralReceivedData.denominationsUnit')}
            </label>
            <select
              id="denominations-unit"
              value={unit}
              onChange={(event) => setUnit(event.target.value)}
              data-testid="denominations-unit-select"
              className="w-full rounded border border-slate-300 bg-white px-2 py-2 text-sm"
            >
              <option value={ALL_BRANCHES}>
                {t('centralReceivedData.denominationsAllBranches')}
              </option>
              {branchOptions.map((branch) => (
                <option key={branch.id} value={branch.id}>
                  {[branch.code, branch.name].filter(Boolean).join(' — ')}
                </option>
              ))}
            </select>
          </div>
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            data-testid="denominations-load-button"
            className="inline-flex items-center gap-2 rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
          >
            <Layers size={16} />
            {t('centralReceivedData.denominationsLoad')}
          </button>
        </div>
      </div>

      {(error || forbidden) && (
        <div
          data-testid="received-denominations-error"
          className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
        >
          {t(
            forbidden
              ? 'centralReceivedData.denominationsForbidden'
              : 'centralReceivedData.denominationsError',
          )}
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
                  {t('centralReceivedData.denominationsStockTotal')}
                </th>
                {columns.map((faceValue) => (
                  <th
                    key={faceValue}
                    data-testid={`denom-header-${faceValue}`}
                    className="px-3 py-2 text-right"
                  >
                    {formatNumber(faceValue)}
                  </th>
                ))}
                <th data-testid="denom-header-other" className="px-3 py-2 text-right">
                  {t('centralReceivedData.denominationsOther')}
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {rows.map((row) => (
                <CurrencyRow key={row.currencyCode} row={row} columns={columns} t={t} />
              ))}
              {!loading && hasRun && rows.length === 0 && (
                <tr>
                  <td colSpan={colCount} className="px-3 py-8 text-center text-sm text-slate-500">
                    {t('centralReceivedData.denominationsEmpty')}
                  </td>
                </tr>
              )}
              {!loading && !hasRun && (
                <tr>
                  <td colSpan={2} className="px-3 py-8 text-center text-sm text-slate-500">
                    <div className="inline-flex items-center gap-2">
                      <ArrowRight size={15} className="text-slate-400" />
                      {t('centralReceivedData.denominationsPrompt')}
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        {loading && (
          <div className="border-t border-slate-100 px-3 py-3 text-sm text-slate-500">
            {t('centralReceivedData.denominationsLoading')}
          </div>
        )}
      </div>

      {data && (
        <div
          data-testid="denominations-summary"
          className="rounded-md border border-slate-200 bg-white p-3"
        >
          <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
            <SummaryItem
              testId="denominations-summary-currency-value"
              label={t('centralReceivedData.denominationsCurrencyValue')}
              value={formatNumber(data.currencyValueHuf, 2)}
            />
            <SummaryItem
              testId="denominations-summary-huf-value"
              label={t('centralReceivedData.denominationsHufValue')}
              value={formatNumber(data.hufTotalValue, 2)}
            />
            <SummaryItem
              testId="denominations-summary-grand-total"
              label={t('centralReceivedData.denominationsGrandTotal')}
              value={formatNumber(data.grandTotalHuf, 2)}
            />
          </div>
          {data.dataQualityIssueCount > 0 && (
            <div data-testid="denominations-issue-hint" className="mt-2 text-xs text-red-600">
              {t('centralReceivedData.denominationsIssueCount')}: {data.dataQualityIssueCount} —{' '}
              {t('centralReceivedData.denominationsIssueHint')}
            </div>
          )}
        </div>
      )}
    </div>
  )
}

function CurrencyRow({
  row,
  columns,
  t,
}: {
  row: ReceivedDenominationCurrencyRow
  columns: number[]
  t: ReturnType<typeof useTranslation>['t']
}) {
  const otherCells = Array.isArray(row.otherCells)
    ? row.otherCells
    : (row.cells ?? []).filter(
        (cell) => !FIXED_FACE_VALUES.includes(cell.faceValue as (typeof FIXED_FACE_VALUES)[number]),
      )
  const otherFlagged = otherCells.some((cell) => cell.dataQualityFlag !== 'OK')

  return (
    <tr key={row.currencyCode} data-testid={`denom-row-${row.currencyCode}`}>
      <td className="px-3 py-2 font-mono font-semibold text-slate-900">
        <div>{row.currencyCode}</div>
        {row.currencyCode !== 'HUF' && (
          <div
            data-testid={`denom-rate-${row.currencyCode}`}
            className={`text-[11px] font-normal ${row.rateMissing ? 'text-amber-700' : 'text-slate-500'}`}
          >
            {row.rateMissing
              ? t('centralReceivedData.denominationsRateMissing')
              : `${rateSourceLabel(t, row.rateSource)}${row.rateDate ? ` · ${row.rateDate}` : ''}`}
          </div>
        )}
      </td>
      <td className="px-3 py-2 text-right font-mono text-slate-700">
        {formatNumber(row.totalValue, 2)}
      </td>
      {columns.map((faceValue) => {
        const column = row.fixedColumns?.find((item) => Number(item.faceValue) === faceValue)
        const quantity = column?.quantity
        const flagged = Boolean(column?.dataQualityFlag && column.dataQualityFlag !== 'OK')
        return (
          <td
            key={faceValue}
            data-testid={`denom-cell-${row.currencyCode}-${faceValue}`}
            title={flagged ? (column?.dataQualityFlag ?? undefined) : undefined}
            className={`px-3 py-2 text-right font-mono ${
              flagged ? 'bg-red-50 text-red-700' : 'text-slate-700'
            }`}
          >
            {quantity == null ? (
              <span className="text-slate-300">–</span>
            ) : (
              <div className="flex items-center justify-end gap-1">
                {flagged && <AlertTriangle size={12} />}
                {formatNumber(quantity)}
              </div>
            )}
          </td>
        )
      })}
      <td
        data-testid={`denom-cell-${row.currencyCode}-other`}
        className={`px-3 py-2 text-right font-mono ${
          otherFlagged ? 'bg-red-50 text-red-700' : 'text-slate-700'
        }`}
      >
        {otherCells.length === 0 ? (
          <span className="text-slate-300">–</span>
        ) : (
          otherCells.map((cell) => (
            <div
              key={`${cell.faceValue}-${cell.denominationType}`}
              data-testid={`denom-cell-${row.currencyCode}-${cell.faceValue}`}
              title={cell.dataQualityFlag !== 'OK' ? cell.dataQualityFlag : undefined}
            >
              <div className="text-[11px] text-slate-500">{formatFaceValue(cell.faceValue)}</div>
              <div className="flex items-center justify-end gap-1">
                {cell.dataQualityFlag !== 'OK' && <AlertTriangle size={12} />}
                {formatNumber(cell.quantity)}
              </div>
            </div>
          ))
        )}
      </td>
    </tr>
  )
}

function SummaryItem({ label, value, testId }: { label: string; value: string; testId?: string }) {
  return (
    <div className="rounded border border-slate-200 p-3" data-testid={testId}>
      <div className="text-xs text-slate-500">{label}</div>
      <div className="text-lg font-semibold text-slate-900">{value}</div>
    </div>
  )
}
