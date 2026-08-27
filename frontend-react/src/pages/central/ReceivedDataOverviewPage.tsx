import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import {
  AlertTriangle,
  ArrowRight,
  Calendar,
  CheckCircle2,
  ClipboardList,
  Clock,
  RefreshCw,
  Search,
  ShieldCheck,
} from 'lucide-react'
import { transferReconciliationApi, type TransferReconciliationResult } from '../../services/api'
import { logger } from '../../utils/logger'
import { localIsoDate } from '../../utils/dateFormat'
import { downloadBlob } from '../../utils/downloadBlob'
import i18n from '../../i18n'

const RECON_FILTERS = ['all', 'match', 'mismatch', 'pending'] as const
type ReconFilter = (typeof RECON_FILTERS)[number]

function isReconFilter(value: string): value is ReconFilter {
  return (RECON_FILTERS as readonly string[]).includes(value)
}

/** Előző nap LOKÁLIS dátumként (a másnap reggeli ellenőrzés alapértelmezett intervalluma). */
function previousDayIso() {
  const d = new Date()
  d.setDate(d.getDate() - 1)
  return localIsoDate(d)
}

function formatAmount(value?: number | null) {
  if (value == null) return '-'
  return value.toLocaleString('hu-HU')
}

type ReconPresentation = 'match' | 'mismatch' | 'pending'

function presentationOf(status: string): ReconPresentation {
  if (status === 'EGYEZIK') return 'match'
  if (status === 'ELTERES') return 'mismatch'
  // FOLYAMATBAN és ismeretlen státusz: soha ne essen ELTÉRÉS-nek (hamis piros).
  return 'pending'
}

export default function ReceivedDataOverviewPage() {
  const { t } = useTranslation()
  const yesterday = previousDayIso()
  const [startDate, setStartDate] = useState(yesterday)
  const [endDate, setEndDate] = useState(yesterday)
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<ReconFilter>('all')
  const [result, setResult] = useState<TransferReconciliationResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [reconciliationError, setReconciliationError] = useState(false)
  const [hasRun, setHasRun] = useState(false)

  // FK-003: az ellenőrzés NEM fut automatikusan — Kasza Helga manuálisan indítja.
  // FK-089: a daily_report alsó panel megszűnt, csak az egyeztetés marad.
  const runCheck = async () => {
    setLoading(true)
    setReconciliationError(false)
    try {
      const value = await transferReconciliationApi.run(startDate, endDate)
      setResult(value)
    } catch (reason) {
      logger.error('ReceivedDataOverviewPage', 'Egyeztetés futtatási hiba:', reason)
      setResult(null)
      setReconciliationError(true)
    }
    setHasRun(true)
    setLoading(false)
  }

  const filteredRows = useMemo(() => {
    const rows = result?.rows ?? []
    const q = query.trim().toLowerCase()
    return rows.filter((row) => {
      const matchesQuery =
        !q ||
        [
          row.fromBranchCode,
          row.fromBranchName,
          row.toBranchCode,
          row.toBranchName,
          row.currencyCode,
          row.transferNumber,
          row.discrepancyNote,
        ].some((value) => value?.toLowerCase().includes(q))
      if (!matchesQuery) return false
      const presentation = presentationOf(row.status)
      if (filter === 'match') return presentation === 'match'
      if (filter === 'mismatch') return presentation === 'mismatch'
      if (filter === 'pending') return presentation === 'pending'
      return true
    })
  }, [filter, query, result])

  const exportCsv = () => {
    const header = [
      'datum',
      'kuldo',
      'fogado',
      'valutanem',
      'kuldott',
      'fogadott',
      'statusz',
      'megjegyzes',
    ]
    const lines = filteredRows.map((row) =>
      [
        row.date,
        `${row.fromBranchCode ?? ''} ${row.fromBranchName ?? ''}`.trim(),
        `${row.toBranchCode ?? ''} ${row.toBranchName ?? ''}`.trim(),
        row.currencyCode,
        String(row.sentAmount ?? ''),
        String(row.receivedAmount ?? ''),
        row.status,
        row.discrepancyNote ?? '',
      ]
        .map((value) => `"${value.replace(/"/g, '""')}"`)
        .join(';'),
    )
    downloadBlob(
      [header.join(';'), ...lines].join('\n'),
      `egyeztetes-${startDate}_${endDate}.csv`,
      'text/csv;charset=utf-8',
    )
  }

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <ClipboardList className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">
                {i18n.t('literals.beerkezett-adatok-attekintese')}
              </h1>
              <div className="text-xs text-slate-500">
                {i18n.t('literals.beerkezett-napi-adatok-es-penztarak-kozo')}
              </div>
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={exportCsv}
              disabled={filteredRows.length === 0}
              className="rounded border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
            >
              {i18n.t('literals.csv')}
            </button>
            {hasRun && (
              <button
                type="button"
                onClick={() => void runCheck()}
                disabled={loading}
                className="inline-flex items-center gap-2 rounded border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
              >
                <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
                {i18n.t('literals.frissites')}
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="space-y-4 p-4">
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
          <Metric label="Összes mozgás" value={result?.totalRows ?? 0} />
          <Metric label="Egyezik" value={result?.matchedRows ?? 0} tone="green" />
          <Metric label="Eltérés" value={result?.discrepancyRows ?? 0} tone="red" />
          <Metric label="Értesített értéktár" value={result?.notifiedBranches ?? 0} tone="amber" />
        </div>

        {reconciliationError && (
          <div
            data-testid="received-data-recon-error"
            className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
          >
            {t('centralReceivedData.reconciliationError')}
          </div>
        )}

        <div className="rounded-md border border-slate-200 bg-white p-3">
          <div className="flex flex-wrap items-end gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-600">
                {i18n.t('literals.datum-tol')}
              </label>
              <div className="flex items-center gap-2">
                <Calendar size={16} className="text-slate-400" />
                <input
                  type="date"
                  value={startDate}
                  onChange={(event) => setStartDate(event.target.value)}
                  className="rounded border border-slate-300 px-2 py-2 text-sm"
                />
              </div>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-600">
                {i18n.t('literals.datum-ig')}
              </label>
              <div className="flex items-center gap-2">
                <Calendar size={16} className="text-slate-400" />
                <input
                  type="date"
                  value={endDate}
                  onChange={(event) => setEndDate(event.target.value)}
                  className="rounded border border-slate-300 px-2 py-2 text-sm"
                />
              </div>
            </div>
            <div className="min-w-[220px] flex-1">
              <label className="mb-1 block text-xs font-medium text-slate-600">
                {i18n.t('literals.kereses-2')}
              </label>
              <div className="flex items-center gap-2 rounded border border-slate-300 bg-white px-2">
                <Search size={16} className="text-slate-400" />
                <input
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  className="w-full py-2 text-sm outline-none"
                  placeholder="Iroda, kód, valuta, megjegyzés"
                />
              </div>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-600">
                {i18n.t('literals.szuro')}
              </label>
              <select
                value={filter}
                onChange={(event) => {
                  if (isReconFilter(event.target.value)) setFilter(event.target.value)
                }}
                className="rounded border border-slate-300 bg-white px-2 py-2 text-sm"
              >
                <option value="all">{t('centralReceivedData.filterAll')}</option>
                <option value="match">{t('centralReceivedData.statusMatch')}</option>
                <option value="mismatch">{t('centralReceivedData.statusMismatch')}</option>
                <option value="pending">{t('centralReceivedData.statusInProgress')}</option>
              </select>
            </div>
            <button
              type="button"
              onClick={() => void runCheck()}
              disabled={loading}
              className="inline-flex items-center gap-2 rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
            >
              <ShieldCheck size={16} />
              {i18n.t('literals.ellenorzes')}
            </button>
          </div>
        </div>

        <div className="overflow-hidden rounded-md border border-slate-200 bg-white">
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-3 py-2 text-left">{i18n.t('literals.datum-2')}</th>
                  <th className="px-3 py-2 text-left">{i18n.t('literals.kuldo')}</th>
                  <th className="px-3 py-2 text-left">{i18n.t('literals.fogado')}</th>
                  <th className="px-3 py-2 text-left">{i18n.t('literals.valutanem')}</th>
                  <th className="px-3 py-2 text-right">{i18n.t('literals.kuldott-osszeg')}</th>
                  <th className="px-3 py-2 text-right">{i18n.t('literals.fogadott-osszeg')}</th>
                  <th className="px-3 py-2 text-left">{i18n.t('literals.statusz')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredRows.map((row, index) => {
                  const presentation = presentationOf(row.status)
                  const rowClass =
                    presentation === 'mismatch'
                      ? 'bg-red-50'
                      : presentation === 'pending'
                        ? 'bg-slate-50'
                        : undefined
                  return (
                    <tr
                      key={`${row.transferId}-${row.currencyCode}-${index}`}
                      className={rowClass}
                      data-testid={`recon-row-${row.transferNumber}`}
                    >
                      <td className="px-3 py-2 text-slate-700">{row.date}</td>
                      <td className="px-3 py-2">
                        <div className="font-semibold text-slate-900">
                          {row.fromBranchCode ?? '-'}
                        </div>
                        <div className="text-xs text-slate-500">{row.fromBranchName ?? ''}</div>
                      </td>
                      <td className="px-3 py-2">
                        <div className="font-semibold text-slate-900">
                          {row.toBranchCode ?? '-'}
                        </div>
                        <div className="text-xs text-slate-500">{row.toBranchName ?? ''}</div>
                      </td>
                      <td className="px-3 py-2 font-mono text-slate-700">{row.currencyCode}</td>
                      <td className="px-3 py-2 text-right font-mono text-slate-700">
                        {formatAmount(row.sentAmount)}
                      </td>
                      <td className="px-3 py-2 text-right font-mono text-slate-700">
                        {formatAmount(row.receivedAmount)}
                      </td>
                      <td className="px-3 py-2">
                        {presentation === 'match' && (
                          <span
                            data-testid={`recon-status-match-${row.transferNumber}`}
                            className="inline-flex items-center gap-1 rounded border border-emerald-200 bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700"
                          >
                            <CheckCircle2 size={13} />
                            {t('centralReceivedData.statusMatch')}
                          </span>
                        )}
                        {presentation === 'pending' && (
                          <div>
                            <span
                              data-testid={`recon-status-pending-${row.transferNumber}`}
                              className="inline-flex items-center gap-1 rounded border border-slate-200 bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700"
                            >
                              <Clock size={13} />
                              {t('centralReceivedData.statusInProgress')}
                            </span>
                            {row.discrepancyNote && (
                              <div className="mt-1 text-xs text-slate-600">
                                {row.discrepancyNote}
                              </div>
                            )}
                          </div>
                        )}
                        {presentation === 'mismatch' && (
                          <div>
                            <span
                              data-testid={`recon-status-mismatch-${row.transferNumber}`}
                              className="inline-flex items-center gap-1 rounded border border-red-200 bg-red-100 px-2 py-1 text-xs font-semibold text-red-700"
                            >
                              <AlertTriangle size={13} />
                              {t('centralReceivedData.statusMismatch')}
                            </span>
                            {row.discrepancyNote && (
                              <div className="mt-1 text-xs text-red-600">{row.discrepancyNote}</div>
                            )}
                          </div>
                        )}
                      </td>
                    </tr>
                  )
                })}
                {!loading && hasRun && filteredRows.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-8 text-center text-sm text-slate-500">
                      {i18n.t('literals.nincs-egyeztetendo-penzmozgas-a-megadott')}
                    </td>
                  </tr>
                )}
                {!loading && !hasRun && (
                  <tr>
                    <td colSpan={7} className="px-3 py-8 text-center text-sm text-slate-500">
                      <div className="inline-flex items-center gap-2">
                        <ArrowRight size={15} className="text-slate-400" />
                        {i18n.t('literals.valasszon-intervallumot-majd-nyomja-meg')}
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          {loading && (
            <div className="border-t border-slate-100 px-3 py-3 text-sm text-slate-500">
              {i18n.t('literals.egyeztetes-folyamatban')}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function Metric({
  label,
  value,
  tone = 'slate',
}: {
  label: string
  value: number | string
  tone?: 'slate' | 'green' | 'red' | 'amber'
}) {
  const classes = {
    slate: 'border-slate-200 bg-white text-slate-900',
    green: 'border-emerald-200 bg-emerald-50 text-emerald-800',
    red: 'border-red-200 bg-red-50 text-red-800',
    amber: 'border-amber-200 bg-amber-50 text-amber-800',
  }
  return (
    <div className={`rounded-md border p-3 ${classes[tone]}`}>
      <div className="text-xs opacity-75">{label}</div>
      <div className="text-lg font-semibold">{value}</div>
    </div>
  )
}
