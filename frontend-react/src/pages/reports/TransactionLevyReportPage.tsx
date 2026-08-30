import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { transactionLevyApi } from '../../services/api/index'
import type {
  MonthlySummary,
  TransactionLevyReport,
  TransactionLevyRow,
  TypeGroup,
} from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * FK-099 FR-8/9/10/11/12/13/14 — Tranzakciós díjak jelentése.
 *
 * - hónap-választó; `from = ${month}-01`, `to = ${month}-${lastDay}` — string/
 *   szám-matematikával (soha `toISOString`, ami UTC+2-n hónapokat csúsztat, pitfall 8);
 * - fő-tábla: pénztár+nap sorok, Vétel / Eladás / Konverzió × 5 alkomponens
 *   + Nagy-alap + Tranz.díj;
 * - ÖSSZESEN sor a backend `totals`-ból — a kliens NEM számolja újra (FR-11);
 * - havi cég-szintű panel (konverzió SZÁNDÉKOSAN nincs — TBD-3 OUT);
 * - küszöb-badge a hatályos (legutolsó) ráta `thresholdHuf`-ból (FR-7 UI).
 */
export default function TransactionLevyReportPage() {
  const { t } = useTranslation()
  const fmt = useMemo(() => new Intl.NumberFormat('hu-HU'), [])

  const [month, setMonth] = useState(() => currentMonth())
  const [report, setReport] = useState<TransactionLevyReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // D2 (round-3): kérés-sorszám őrző (TransferPage idióma) — gyors hónapváltásnál
  // a későn érkező elavult válasz nem írhatja felül az újabbat, az elavult hiba
  // nem törölhet friss sikert, és az elavult `finally` nem ragaszthatja a loadingot.
  const requestSeqRef = useRef(0)

  const load = useCallback(async (selectedMonth: string) => {
    const { from, to } = monthRange(selectedMonth)
    const requestId = requestSeqRef.current + 1
    requestSeqRef.current = requestId
    setLoading(true)
    setError(null)
    try {
      const data = await transactionLevyApi.getReport(from, to)
      if (requestSeqRef.current === requestId) {
        setReport(data)
      }
    } catch (err) {
      if (requestSeqRef.current === requestId) {
        setReport(null)
        // D5 (round-3): repo-konvenció getErrorMessage — a szerver `response.data.message`
        // elsőbbsége megmarad (AxiosError-ág), a hálózati hibák humanizáltak.
        setError(getErrorMessage(err))
      }
    } finally {
      if (requestSeqRef.current === requestId) {
        setLoading(false)
      }
    }
  }, [])

  useEffect(() => {
    void load(month)
  }, [month, load])

  const onMonthChange = (value: string) => {
    setMonth(value)
  }

  const threshold = report?.appliedRates.at(-1)?.thresholdHuf ?? null

  return (
    <div className="mx-auto max-w-7xl p-6">
      <h1 className="mb-4 text-2xl font-bold">{t('reports.transactionLevy.title')}</h1>

      <div className="mb-4 flex items-end gap-4">
        <div>
          <label htmlFor="levy-month" className="mb-1 block text-sm font-medium">
            {t('reports.transactionLevy.month')}
          </label>
          <input
            id="levy-month"
            type="month"
            className="rounded border border-gray-300 px-3 py-2"
            value={month}
            onChange={(e) => onMonthChange(e.target.value)}
          />
        </div>
        {threshold !== null && (
          <span
            data-testid="threshold-badge"
            className="rounded-full bg-blue-100 px-3 py-1 text-sm text-blue-800"
          >
            {t('reports.transactionLevy.threshold')}: {fmt.format(threshold)} {t('components.ft')}
          </span>
        )}
        {(report?.appliedRates.length ?? 0) > 1 && (
          <span className="text-sm text-amber-700">
            {t('reports.transactionLevy.multiRateNote')}
          </span>
        )}
      </div>

      {loading && <p>{t('reports.transactionLevy.loading')}</p>}
      {error && (
        <div className="mb-4 rounded border border-red-300 bg-red-50 p-3 text-red-700">{error}</div>
      )}

      {!loading && !error && report && report.rows.length === 0 && (
        <p className="mb-4 text-gray-500">{t('reports.transactionLevy.emptyState')}</p>
      )}

      {!loading && !error && report && (
        <>
          {/* D4 (round-3): vízszintes scroll-konténer (ArchivingPage idióma) —
              a 19 oszlopos tábla keskeny nézetben nem tolja szét az oldalt. */}
          <div className="overflow-x-auto rounded border border-gray-200 bg-white">
            <table className="w-full min-w-[1200px] border-collapse text-sm">
              <thead>
                <tr>
                  <th rowSpan={2} className="border border-gray-300 px-2 py-1 text-left">
                    {t('reports.transactionLevy.table.date')}
                  </th>
                  <th rowSpan={2} className="border border-gray-300 px-2 py-1 text-left">
                    {t('reports.transactionLevy.table.branch')}
                  </th>
                  <GroupHeader label={t('reports.transactionLevy.table.buy')} />
                  <GroupHeader label={t('reports.transactionLevy.table.sell')} />
                  <GroupHeader label={t('reports.transactionLevy.table.conversion')} />
                  <th rowSpan={2} className="border border-gray-300 px-2 py-1 text-right">
                    {t('reports.transactionLevy.table.largeBase')}
                  </th>
                  <th rowSpan={2} className="border border-gray-300 px-2 py-1 text-right">
                    {t('reports.transactionLevy.table.levyTotal')}
                  </th>
                </tr>
                <tr>
                  <SubHeaders keyPrefix="buy" t={t} />
                  <SubHeaders keyPrefix="sell" t={t} />
                  <SubHeaders keyPrefix="conversion" t={t} />
                </tr>
              </thead>
              <tbody>
                {report.rows.map((row) => (
                  <RowCells key={`${row.date}-${row.branchId}`} row={row} fmt={fmt} />
                ))}
                <TotalsRow totals={report.totals} fmt={fmt} t={t} />
              </tbody>
            </table>
          </div>

          <MonthlyPanel summary={report.monthlySummary} fmt={fmt} t={t} />
        </>
      )}
    </div>
  )
}

/** Aktuális hónap `YYYY-MM` — lokális idő szerint, UTC-eltolás nélkül. */
function currentMonth(): string {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

/**
 * Hónap → inclusive [from, to]. A hónap utolsó napja `new Date(y, m, 0).getDate()`
 * — soha `toISOString` (pitfall 8).
 */
function monthRange(month: string): { from: string; to: string } {
  const [yearStr, monthStr] = month.split('-')
  const year = Number(yearStr)
  const monthIndex = Number(monthStr)
  const lastDay = new Date(year, monthIndex, 0).getDate()
  return { from: `${month}-01`, to: `${month}-${String(lastDay).padStart(2, '0')}` }
}

function GroupHeader({ label }: { label: string }) {
  return (
    <th colSpan={5} className="border border-gray-300 px-2 py-1 text-center">
      {label}
    </th>
  )
}

function SubHeaders({ keyPrefix, t }: { keyPrefix: string; t: (k: string) => string }) {
  return (
    <>
      <th key={`${keyPrefix}-normalBase`} className="border border-gray-300 px-2 py-1 text-right">
        {t('reports.transactionLevy.table.normalBase')}
      </th>
      <th
        key={`${keyPrefix}-normalSupplement`}
        className="border border-gray-300 px-2 py-1 text-right"
      >
        {t('reports.transactionLevy.table.normalSupplement')}
      </th>
      <th key={`${keyPrefix}-aboveCount`} className="border border-gray-300 px-2 py-1 text-right">
        {t('reports.transactionLevy.table.aboveCount')}
      </th>
      <th key={`${keyPrefix}-aboveBase`} className="border border-gray-300 px-2 py-1 text-right">
        {t('reports.transactionLevy.table.aboveBase')}
      </th>
      <th
        key={`${keyPrefix}-aboveSupplement`}
        className="border border-gray-300 px-2 py-1 text-right"
      >
        {t('reports.transactionLevy.table.aboveSupplement')}
      </th>
    </>
  )
}

function RowCells({ row, fmt }: { row: TransactionLevyRow; fmt: Intl.NumberFormat }) {
  return (
    <tr>
      <td className="border border-gray-300 px-2 py-1">{row.date}</td>
      <td className="border border-gray-300 px-2 py-1">
        {row.branchCode}
        {row.branchName ? ` – ${row.branchName}` : ''}
      </td>
      <GroupCells group={row.buy} fmt={fmt} />
      <GroupCells group={row.sell} fmt={fmt} />
      <GroupCells group={row.conversion} fmt={fmt} />
      <td className="border border-gray-300 px-2 py-1 text-right">
        {fmt.format(row.largeBaseHuf)}
      </td>
      <td className="border border-gray-300 px-2 py-1 text-right font-semibold">
        {fmt.format(row.levyTotal)}
      </td>
    </tr>
  )
}

function GroupCells({ group, fmt }: { group: TypeGroup; fmt: Intl.NumberFormat }) {
  return (
    <>
      <td className="border border-gray-300 px-2 py-1 text-right">
        {fmt.format(group.normalBaseLevy)}
      </td>
      <td className="border border-gray-300 px-2 py-1 text-right">
        {fmt.format(group.normalSupplementLevy)}
      </td>
      <td className="border border-gray-300 px-2 py-1 text-right">{group.aboveThresholdCount}</td>
      <td className="border border-gray-300 px-2 py-1 text-right">
        {fmt.format(group.aboveThresholdBaseLevy)}
      </td>
      <td className="border border-gray-300 px-2 py-1 text-right">
        {fmt.format(group.aboveThresholdSupplementLevy)}
      </td>
    </>
  )
}

/** FR-11: az ÖSSZESEN sor a backend `totals`-át veszi át, ÚJRASZÁMÍTÁS NÉLKÜL. */
function TotalsRow({
  totals,
  fmt,
  t,
}: {
  totals: TransactionLevyRow
  fmt: Intl.NumberFormat
  t: (k: string) => string
}) {
  return (
    <tr className="font-semibold">
      <td colSpan={2} className="border border-gray-300 px-2 py-1">
        {t('reports.transactionLevy.totalRow')}
      </td>
      <GroupCells group={totals.buy} fmt={fmt} />
      <GroupCells group={totals.sell} fmt={fmt} />
      <GroupCells group={totals.conversion} fmt={fmt} />
      <td className="border border-gray-300 px-2 py-1 text-right">
        {fmt.format(totals.largeBaseHuf)}
      </td>
      <td className="border border-gray-300 px-2 py-1 text-right">
        {fmt.format(totals.levyTotal)}
      </td>
    </tr>
  )
}

/** FR-12/13/14: havi cég-szintű panel — konverziós adat SZÁNDÉKOSAN nincs (TBD-3 OUT). */
function MonthlyPanel({
  summary,
  fmt,
  t,
}: {
  summary: MonthlySummary
  fmt: Intl.NumberFormat
  t: (k: string) => string
}) {
  return (
    <section className="mt-6 rounded border border-gray-200 bg-gray-50 p-4">
      <h2 className="mb-3 text-lg font-semibold">{t('reports.transactionLevy.monthly.title')}</h2>
      <dl className="grid grid-cols-2 gap-x-8 gap-y-1 text-sm md:grid-cols-3">
        <Metric
          label={t('reports.transactionLevy.monthly.buyCount')}
          value={fmt.format(summary.buyCount)}
        />
        <Metric
          label={t('reports.transactionLevy.monthly.sellCount')}
          value={fmt.format(summary.sellCount)}
        />
        <Metric
          label={t('reports.transactionLevy.monthly.customerCount')}
          value={fmt.format(summary.customerCount)}
        />
        <Metric
          label={t('reports.transactionLevy.monthly.belowBuy')}
          value={`${fmt.format(summary.belowThresholdBuyHuf)} Ft`}
        />
        <Metric
          label={t('reports.transactionLevy.monthly.belowSell')}
          value={`${fmt.format(summary.belowThresholdSellHuf)} Ft`}
        />
        <Metric
          label={t('reports.transactionLevy.monthly.aboveBuy')}
          value={`${fmt.format(summary.aboveThresholdBuyHuf)} Ft`}
        />
        <Metric
          label={t('reports.transactionLevy.monthly.aboveSell')}
          value={`${fmt.format(summary.aboveThresholdSellHuf)} Ft`}
        />
      </dl>
    </section>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  // D3 (round-3): HTML5-valid `dl > div > dt + dd` — a dt/dd PÁR egy wrapperben
  // kerül a rácsba (fragment-ként a md:grid-cols-3 rács celláira szóródna).
  return (
    <div className="grid grid-cols-[auto_1fr] gap-x-2">
      <dt className="text-gray-600">{label}</dt>
      <dd className="font-medium">{value}</dd>
    </div>
  )
}
