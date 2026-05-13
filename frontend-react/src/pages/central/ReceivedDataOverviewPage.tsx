import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  AlertTriangle,
  Calendar,
  CheckCircle2,
  ClipboardList,
  Clock,
  Eye,
  RefreshCw,
  Search,
  XCircle,
} from 'lucide-react'
import {
  centralReceivedDataApi,
  type CentralReceivedDataOverview,
  type CentralReceivedDataRow,
} from '../../services/api'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

type DataFilter = 'all' | 'critical' | 'missing' | 'received' | 'submitted' | 'waiting'

function todayIso() {
  return new Date().toISOString().slice(0, 10)
}

function formatHuf(value?: number) {
  return `${Math.round(value ?? 0).toLocaleString('hu-HU')} Ft`
}

function formatDateTime(value?: string | null) {
  if (!value) return '-'
  return new Date(value).toLocaleString('hu-HU', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function statusLabel(status: string) {
  switch (status) {
    case 'SUBMITTED':
      return 'beküldve'
    case 'RECEIVED':
      return 'beérkezett'
    case 'MISSING':
      return 'hiányzik'
    case 'WAITING':
      return 'várható'
    case 'CRITICAL':
      return 'kritikus'
    default:
      return status || 'ismeretlen'
  }
}

function statusClass(status: string) {
  switch (status) {
    case 'SUBMITTED':
      return 'border-emerald-200 bg-emerald-50 text-emerald-700'
    case 'RECEIVED':
      return 'border-blue-200 bg-blue-50 text-blue-700'
    case 'MISSING':
    case 'CRITICAL':
      return 'border-red-200 bg-red-50 text-red-700'
    case 'WAITING':
      return 'border-amber-200 bg-amber-50 text-amber-700'
    default:
      return 'border-slate-200 bg-slate-50 text-slate-700'
  }
}

function statusIcon(status: string) {
  if (status === 'SUBMITTED' || status === 'RECEIVED') return <CheckCircle2 size={14} />
  if (status === 'MISSING' || status === 'CRITICAL') return <AlertTriangle size={14} />
  return <Clock size={14} />
}

function closingPill(done: boolean, label: string) {
  return (
    <span className={`inline-flex items-center gap-1 rounded border px-2 py-1 text-xs ${done ? 'border-emerald-200 bg-emerald-50 text-emerald-700' : 'border-slate-200 bg-white text-slate-500'}`}>
      {done ? <CheckCircle2 size={13} /> : <XCircle size={13} />}
      {label}
    </span>
  )
}

export default function ReceivedDataOverviewPage() {
  const navigate = useNavigate()
  const [date, setDate] = useState(todayIso())
  const [overview, setOverview] = useState<CentralReceivedDataOverview | null>(null)
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<DataFilter>('all')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await centralReceivedDataApi.status(date)
      setOverview(data)
    } catch (err) {
      logger.error('ReceivedDataOverviewPage', 'Beérkezett adatok betöltési hiba:', err)
      setError(getErrorMessage(err))
      setOverview(null)
    } finally {
      setLoading(false)
    }
  }, [date])

  useEffect(() => {
    void load()
  }, [load])

  const rows = overview?.rows ?? []
  const filteredRows = useMemo(() => {
    const q = query.trim().toLowerCase()
    return rows.filter((row) => {
      const matchesQuery = !q || [
        row.branchCode,
        row.branchName,
        row.branchCity,
        row.notes,
      ].some((value) => value?.toLowerCase().includes(q))
      if (!matchesQuery) return false
      if (filter === 'all') return true
      if (filter === 'critical') return row.dataStatus === 'CRITICAL'
      if (filter === 'missing') return row.dataStatus === 'MISSING' || !row.reportReceived
      if (filter === 'received') return row.dataStatus === 'RECEIVED'
      if (filter === 'submitted') return row.dataStatus === 'SUBMITTED'
      if (filter === 'waiting') return row.dataStatus === 'WAITING'
      return true
    })
  }, [filter, query, rows])

  const exportCsv = () => {
    const header = [
      'branchCode',
      'branchName',
      'reportDate',
      'dataStatus',
      'reportReceived',
      'reportSubmitted',
      'transactionCount',
      'totalBuyHuf',
      'totalSellHuf',
      'totalFeeHuf',
      'closingAlertLevel',
    ]
    const lines = filteredRows.map((row) => [
      row.branchCode ?? '',
      row.branchName ?? '',
      row.reportDate,
      row.dataStatus,
      String(row.reportReceived),
      String(row.reportSubmitted),
      String(row.transactionCount ?? 0),
      String(row.totalBuyHuf ?? 0),
      String(row.totalSellHuf ?? 0),
      String(row.totalFeeHuf ?? 0),
      row.closingAlertLevel,
    ].map((value) => `"${value.replace(/"/g, '""')}"`).join(';'))
    const blob = new Blob([[header.join(';'), ...lines].join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `beerkezett-adatok-${date}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  const openDaybook = (row: CentralReceivedDataRow) => {
    navigate(`/daybook?branchId=${encodeURIComponent(row.branchId)}&date=${encodeURIComponent(date)}`)
  }

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <ClipboardList className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">Beérkezett adatok áttekintése</h1>
              <div className="text-xs text-slate-500">beerk.dll, datadisp.dll és getdisp.dll modern központi nézete</div>
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
            <button
              type="button"
              onClick={() => void load()}
              disabled={loading}
              className="inline-flex items-center gap-2 rounded border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
            >
              <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
              Frissítés
            </button>
          </div>
        </div>
      </div>

      <div className="space-y-4 p-4">
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4 xl:grid-cols-8">
          <Metric label="Iroda" value={overview?.totalBranches ?? 0} />
          <Metric label="Beérkezett" value={overview?.receivedReports ?? 0} tone="blue" />
          <Metric label="Beküldött" value={overview?.submittedReports ?? 0} tone="green" />
          <Metric label="Hiányzik" value={overview?.missingReports ?? 0} tone="red" />
          <Metric label="Kritikus zárás" value={overview?.criticalClosings ?? 0} tone="red" />
          <Metric label="Tranzakció" value={overview?.totalTransactions ?? 0} />
          <Metric label="Vétel" value={formatHuf(overview?.totalBuyHuf)} />
          <Metric label="Eladás" value={formatHuf(overview?.totalSellHuf)} />
        </div>

        <div className="rounded-md border border-slate-200 bg-white p-3">
          <div className="flex flex-wrap items-end gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-600">Dátum</label>
              <div className="flex items-center gap-2">
                <Calendar size={16} className="text-slate-400" />
                <input
                  type="date"
                  value={date}
                  onChange={(event) => setDate(event.target.value)}
                  className="rounded border border-slate-300 px-2 py-2 text-sm"
                />
              </div>
            </div>
            <div className="min-w-[240px] flex-1">
              <label className="mb-1 block text-xs font-medium text-slate-600">Keresés</label>
              <div className="flex items-center gap-2 rounded border border-slate-300 bg-white px-2">
                <Search size={16} className="text-slate-400" />
                <input
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  className="w-full py-2 text-sm outline-none"
                  placeholder="Iroda, kód, város, megjegyzés"
                />
              </div>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-600">Szűrő</label>
              <select
                value={filter}
                onChange={(event) => setFilter(event.target.value as DataFilter)}
                className="rounded border border-slate-300 bg-white px-2 py-2 text-sm"
              >
                <option value="all">Összes</option>
                <option value="critical">Kritikus</option>
                <option value="missing">Hiányzó</option>
                <option value="waiting">Várható</option>
                <option value="received">Beérkezett</option>
                <option value="submitted">Beküldött</option>
              </select>
            </div>
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
                  <th className="px-3 py-2 text-left">Iroda</th>
                  <th className="px-3 py-2 text-left">Adatcsomag</th>
                  <th className="px-3 py-2 text-left">Záráskontroll</th>
                  <th className="px-3 py-2 text-right">Forgalom</th>
                  <th className="px-3 py-2 text-right">Díj / profit</th>
                  <th className="px-3 py-2 text-left">Időpont</th>
                  <th className="px-3 py-2 text-right">Művelet</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredRows.map((row) => (
                  <tr key={row.branchId} className={row.dataStatus === 'CRITICAL' ? 'bg-red-50/40' : undefined}>
                    <td className="px-3 py-2">
                      <div className="font-semibold text-slate-900">{row.branchCode ?? row.branchId.slice(0, 8)}</div>
                      <div className="text-xs text-slate-500">{row.branchName ?? 'Névtelen iroda'}{row.branchCity ? `, ${row.branchCity}` : ''}</div>
                    </td>
                    <td className="px-3 py-2">
                      <span className={`inline-flex items-center gap-1 rounded border px-2 py-1 text-xs font-semibold ${statusClass(row.dataStatus)}`}>
                        {statusIcon(row.dataStatus)}
                        {statusLabel(row.dataStatus)}
                      </span>
                      <div className="mt-1 text-xs text-slate-500">{row.transactionCount ?? 0} tranzakció</div>
                    </td>
                    <td className="px-3 py-2">
                      <div className="flex flex-wrap gap-1">
                        {closingPill(row.dailyClosingDone, 'napi')}
                        {closingPill(row.eveningClosingDone, 'esti')}
                        {closingPill(row.navClosingDone, 'NAV')}
                      </div>
                      {row.closingControlMissing && <div className="mt-1 text-xs text-red-600">nincs kontrollrekord</div>}
                    </td>
                    <td className="px-3 py-2 text-right">
                      <div className="font-mono text-xs text-slate-700">V {formatHuf(row.totalBuyHuf)}</div>
                      <div className="font-mono text-xs text-slate-700">E {formatHuf(row.totalSellHuf)}</div>
                    </td>
                    <td className="px-3 py-2 text-right">
                      <div className="font-mono text-xs text-slate-700">{formatHuf(row.totalFeeHuf)}</div>
                      <div className="font-mono text-xs text-slate-500">{formatHuf(row.totalProfit)}</div>
                    </td>
                    <td className="px-3 py-2 text-xs text-slate-600">
                      <div>létrehozva: {formatDateTime(row.reportCreatedAt)}</div>
                      <div>beküldve: {formatDateTime(row.submittedAt)}</div>
                    </td>
                    <td className="px-3 py-2 text-right">
                      <button
                        type="button"
                        onClick={() => openDaybook(row)}
                        className="inline-flex items-center gap-1 rounded border border-slate-300 bg-white px-2 py-1 text-xs font-medium text-slate-700 hover:bg-slate-50"
                      >
                        <Eye size={14} />
                        Napló
                      </button>
                    </td>
                  </tr>
                ))}
                {!loading && filteredRows.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-8 text-center text-sm text-slate-500">
                      Nincs megjeleníthető beérkezett adat.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          {loading && (
            <div className="border-t border-slate-100 px-3 py-3 text-sm text-slate-500">Betöltés...</div>
          )}
        </div>
      </div>
    </div>
  )
}

function Metric({ label, value, tone = 'slate' }: { label: string; value: number | string; tone?: 'slate' | 'green' | 'blue' | 'red' }) {
  const classes = {
    slate: 'border-slate-200 bg-white text-slate-900',
    green: 'border-emerald-200 bg-emerald-50 text-emerald-800',
    blue: 'border-blue-200 bg-blue-50 text-blue-800',
    red: 'border-red-200 bg-red-50 text-red-800',
  }
  return (
    <div className={`rounded-md border p-3 ${classes[tone]}`}>
      <div className="text-xs opacity-75">{label}</div>
      <div className="text-lg font-semibold">{value}</div>
    </div>
  )
}
