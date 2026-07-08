import { useMemo, useState } from 'react'
import {
  AlertTriangle,
  ArrowRight,
  Calendar,
  CheckCircle2,
  ClipboardList,
  RefreshCw,
  Search,
  ShieldCheck,
} from 'lucide-react'
import {
  centralReceivedDataApi,
  transferReconciliationApi,
  type CentralReceivedDataOverview,
  type TransferReconciliationResult,
} from '../../services/api'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'

type ReconFilter = 'all' | 'match' | 'mismatch'

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

function isMatch(status: string) {
  return status === 'EGYEZIK'
}

export default function ReceivedDataOverviewPage() {
  const yesterday = previousDayIso()
  const [startDate, setStartDate] = useState(yesterday)
  const [endDate, setEndDate] = useState(yesterday)
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<ReconFilter>('all')
  const [result, setResult] = useState<TransferReconciliationResult | null>(null)
  const [receivedDataOverview, setReceivedDataOverview] =
    useState<CentralReceivedDataOverview | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [hasRun, setHasRun] = useState(false)

  // FK-003: az ellenőrzés NEM fut automatikusan — Kasza Helga manuálisan indítja.
  const runCheck = async () => {
    try {
      setLoading(true)
      setError(null)
      const [reconciliation, receivedData] = await Promise.all([
        transferReconciliationApi.run(startDate, endDate),
        centralReceivedDataApi.status(startDate),
      ])
      setResult(reconciliation)
      setReceivedDataOverview(receivedData)
      setHasRun(true)
    } catch (err) {
      logger.error('ReceivedDataOverviewPage', 'Egyeztetés futtatási hiba:', err)
      setError(getErrorMessage(err))
      setResult(null)
      setReceivedDataOverview(null)
    } finally {
      setLoading(false)
    }
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
      if (filter === 'match') return isMatch(row.status)
      if (filter === 'mismatch') return !isMatch(row.status)
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
    const blob = new Blob([[header.join(';'), ...lines].join('\n')], {
      type: 'text/csv;charset=utf-8',
    })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `egyeztetes-${startDate}_${endDate}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <ClipboardList className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">
                Beérkezett adatok áttekintése
              </h1>
              <div className="text-xs text-slate-500">
                Beérkezett napi adatok és pénztárak közötti pénzmozgások — egyeztetés
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
              CSV
            </button>
            {hasRun && (
              <button
                type="button"
                onClick={() => void runCheck()}
                disabled={loading}
                className="inline-flex items-center gap-2 rounded border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
              >
                <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
                Frissítés
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

        <div
          className="grid grid-cols-2 gap-2 md:grid-cols-4"
          data-testid="central-received-data-status"
        >
          <Metric label="Irodák" value={receivedDataOverview?.totalBranches ?? 0} />
          <Metric
            label="Beérkezett jelentés"
            value={receivedDataOverview?.receivedReports ?? 0}
            tone="green"
          />
          <Metric
            label="Hiányzó jelentés"
            value={receivedDataOverview?.missingReports ?? 0}
            tone="red"
          />
          <Metric
            label="Kritikus zárás"
            value={receivedDataOverview?.criticalClosings ?? 0}
            tone="amber"
          />
        </div>

        <div className="rounded-md border border-slate-200 bg-white p-3">
          <div className="flex flex-wrap items-end gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-600">Dátum -tól</label>
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
              <label className="mb-1 block text-xs font-medium text-slate-600">Dátum -ig</label>
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
              <label className="mb-1 block text-xs font-medium text-slate-600">Keresés</label>
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
              <label className="mb-1 block text-xs font-medium text-slate-600">Szűrő</label>
              <select
                value={filter}
                onChange={(event) => setFilter(event.target.value as ReconFilter)}
                className="rounded border border-slate-300 bg-white px-2 py-2 text-sm"
              >
                <option value="all">Összes</option>
                <option value="match">Egyezik</option>
                <option value="mismatch">Eltérés</option>
              </select>
            </div>
            <button
              type="button"
              onClick={() => void runCheck()}
              disabled={loading}
              className="inline-flex items-center gap-2 rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
            >
              <ShieldCheck size={16} />
              Ellenőrzés
            </button>
          </div>
        </div>

        {error && (
          <div className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        )}

        <div className="overflow-hidden rounded-md border border-slate-200 bg-white">
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-3 py-2 text-left">Dátum</th>
                  <th className="px-3 py-2 text-left">Küldő</th>
                  <th className="px-3 py-2 text-left">Fogadó</th>
                  <th className="px-3 py-2 text-left">Valutanem</th>
                  <th className="px-3 py-2 text-right">Küldött összeg</th>
                  <th className="px-3 py-2 text-right">Fogadott összeg</th>
                  <th className="px-3 py-2 text-left">Státusz</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredRows.map((row, index) => (
                  <tr
                    key={`${row.transferId}-${row.currencyCode}-${index}`}
                    className={isMatch(row.status) ? undefined : 'bg-red-50'}
                  >
                    <td className="px-3 py-2 text-slate-700">{row.date}</td>
                    <td className="px-3 py-2">
                      <div className="font-semibold text-slate-900">
                        {row.fromBranchCode ?? '-'}
                      </div>
                      <div className="text-xs text-slate-500">{row.fromBranchName ?? ''}</div>
                    </td>
                    <td className="px-3 py-2">
                      <div className="font-semibold text-slate-900">{row.toBranchCode ?? '-'}</div>
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
                      {isMatch(row.status) ? (
                        <span className="inline-flex items-center gap-1 rounded border border-emerald-200 bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                          <CheckCircle2 size={13} />
                          EGYEZIK
                        </span>
                      ) : (
                        <div>
                          <span className="inline-flex items-center gap-1 rounded border border-red-200 bg-red-100 px-2 py-1 text-xs font-semibold text-red-700">
                            <AlertTriangle size={13} />
                            ELTÉRÉS
                          </span>
                          {row.discrepancyNote && (
                            <div className="mt-1 text-xs text-red-600">{row.discrepancyNote}</div>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
                {!loading && hasRun && filteredRows.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-8 text-center text-sm text-slate-500">
                      Nincs egyeztetendő pénzmozgás a megadott intervallumban.
                    </td>
                  </tr>
                )}
                {!loading && !hasRun && (
                  <tr>
                    <td colSpan={7} className="px-3 py-8 text-center text-sm text-slate-500">
                      <div className="inline-flex items-center gap-2">
                        <ArrowRight size={15} className="text-slate-400" />
                        Válasszon intervallumot, majd nyomja meg az „Ellenőrzés" gombot.
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          {loading && (
            <div className="border-t border-slate-100 px-3 py-3 text-sm text-slate-500">
              Egyeztetés folyamatban...
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
