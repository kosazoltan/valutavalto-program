import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  AlertTriangle,
  Calendar,
  CheckCircle2,
  Clock,
  Eye,
  RefreshCw,
  Search,
  Send,
  XCircle,
} from 'lucide-react'
import { closingControlApi, type ClosingControlStatus } from '../../services/api'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

type StatusFilter = 'all' | 'missing' | 'warning' | 'critical' | 'done'

function todayIso() {
  return new Date().toISOString().slice(0, 10)
}

function isDone(row: ClosingControlStatus) {
  const required = row.requiredCount ?? 3
  const completed = row.completedCount ?? Number(row.dailyClosingDone) + Number(row.eveningClosingDone) + Number(row.navClosingDone)
  return completed >= required
}

function alertLabel(level: string) {
  switch (level) {
    case 'CRITICAL':
      return 'kritikus'
    case 'WARNING':
      return 'figyelmeztetés'
    case 'NONE':
      return 'rendben'
    default:
      return level || 'ismeretlen'
  }
}

function alertClass(level: string) {
  switch (level) {
    case 'CRITICAL':
      return 'border-red-200 bg-red-50 text-red-700'
    case 'WARNING':
      return 'border-amber-200 bg-amber-50 text-amber-700'
    case 'NONE':
      return 'border-emerald-200 bg-emerald-50 text-emerald-700'
    default:
      return 'border-slate-200 bg-slate-50 text-slate-700'
  }
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

function checkCell(done: boolean, label: string) {
  return (
    <span className={`inline-flex min-w-[92px] items-center gap-1 rounded border px-2 py-1 text-xs font-medium ${done ? 'border-emerald-200 bg-emerald-50 text-emerald-700' : 'border-slate-200 bg-white text-slate-500'}`}>
      {done ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
      {label}
    </span>
  )
}

export default function ClosingControlPage() {
  const navigate = useNavigate()
  const [date, setDate] = useState(todayIso())
  const [rows, setRows] = useState<ClosingControlStatus[]>([])
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<StatusFilter>('all')
  const [loading, setLoading] = useState(false)
  const [alertingBranchId, setAlertingBranchId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await closingControlApi.list(date)
      setRows(data)
    } catch (err) {
      logger.error('ClosingControlPage', 'Zárás kontroll betöltési hiba:', err)
      setError(getErrorMessage(err))
      setRows([])
    } finally {
      setLoading(false)
    }
  }, [date])

  useEffect(() => {
    void load()
  }, [load])

  const summary = useMemo(() => {
    const total = rows.length
    const done = rows.filter(isDone).length
    const critical = rows.filter((row) => row.alertLevel === 'CRITICAL').length
    const warning = rows.filter((row) => row.alertLevel === 'WARNING').length
    const missing = rows.filter((row) => row.missingRecord).length
    return { total, done, critical, warning, missing }
  }, [rows])

  const filteredRows = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase()
    return rows.filter((row) => {
      const matchesQuery = !normalizedQuery || [
        row.branchCode,
        row.branchName,
        row.branchCity,
        row.notes,
      ].some((value) => value?.toLowerCase().includes(normalizedQuery))

      if (!matchesQuery) return false
      if (filter === 'all') return true
      if (filter === 'missing') return Boolean(row.missingRecord)
      if (filter === 'warning') return row.alertLevel === 'WARNING'
      if (filter === 'critical') return row.alertLevel === 'CRITICAL'
      if (filter === 'done') return isDone(row)
      return true
    })
  }, [filter, query, rows])

  const handleAlert = async (row: ClosingControlStatus) => {
    const branchLabel = row.branchCode ? `${row.branchCode} - ${row.branchName ?? row.branchId}` : row.branchName ?? row.branchId
    const message = `${date} napi zárási beérkezés hiányzik vagy nem teljes. Kérjük az iroda zárását és szinkronját ellenőrizni.`
    try {
      setAlertingBranchId(row.branchId)
      await closingControlApi.sendAlert({ branchId: row.branchId, message })
      toast.success('Figyelmeztetés elküldve', branchLabel)
      await load()
    } catch (err) {
      toast.error('Figyelmeztetés sikertelen', getErrorMessage(err))
    } finally {
      setAlertingBranchId(null)
    }
  }

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <Clock className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">Zárás beérkezés felügyelet</h1>
              <div className="text-xs text-slate-500">zarasctrl.dll, beerk.dll és missctrl.dll modern központi monitor</div>
            </div>
          </div>
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

      <div className="space-y-4 p-4">
        <div className="grid grid-cols-2 gap-2 md:grid-cols-5">
          <div className="rounded-md border border-slate-200 bg-white p-3">
            <div className="text-xs text-slate-500">Iroda</div>
            <div className="text-xl font-semibold text-slate-900">{summary.total}</div>
          </div>
          <div className="rounded-md border border-emerald-200 bg-emerald-50 p-3">
            <div className="text-xs text-emerald-700">Rendben</div>
            <div className="text-xl font-semibold text-emerald-800">{summary.done}</div>
          </div>
          <div className="rounded-md border border-red-200 bg-red-50 p-3">
            <div className="text-xs text-red-700">Kritikus</div>
            <div className="text-xl font-semibold text-red-800">{summary.critical}</div>
          </div>
          <div className="rounded-md border border-amber-200 bg-amber-50 p-3">
            <div className="text-xs text-amber-700">Figyelmeztetés</div>
            <div className="text-xl font-semibold text-amber-800">{summary.warning}</div>
          </div>
          <div className="rounded-md border border-slate-200 bg-white p-3">
            <div className="text-xs text-slate-500">Hiányzó rekord</div>
            <div className="text-xl font-semibold text-slate-900">{summary.missing}</div>
          </div>
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
                onChange={(event) => setFilter(event.target.value as StatusFilter)}
                className="rounded border border-slate-300 bg-white px-2 py-2 text-sm"
              >
                <option value="all">Összes</option>
                <option value="critical">Kritikus</option>
                <option value="warning">Figyelmeztetés</option>
                <option value="missing">Hiányzó rekord</option>
                <option value="done">Rendben</option>
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
                  <th className="px-3 py-2 text-left">Állapot</th>
                  <th className="px-3 py-2 text-left">Zárások</th>
                  <th className="px-3 py-2 text-left">Utolsó tranzakció</th>
                  <th className="px-3 py-2 text-left">Megjegyzés</th>
                  <th className="px-3 py-2 text-right">Művelet</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredRows.map((row) => (
                  <tr key={row.branchId} className={row.alertLevel === 'CRITICAL' ? 'bg-red-50/40' : undefined}>
                    <td className="px-3 py-2">
                      <div className="font-semibold text-slate-900">{row.branchCode ?? row.branchId.slice(0, 8)}</div>
                      <div className="text-xs text-slate-500">{row.branchName ?? 'Névtelen iroda'}{row.branchCity ? `, ${row.branchCity}` : ''}</div>
                    </td>
                    <td className="px-3 py-2">
                      <span className={`inline-flex items-center gap-1 rounded border px-2 py-1 text-xs font-semibold ${alertClass(row.alertLevel)}`}>
                        {row.alertLevel === 'CRITICAL' ? <AlertTriangle size={14} /> : row.alertLevel === 'NONE' ? <CheckCircle2 size={14} /> : <Clock size={14} />}
                        {alertLabel(row.alertLevel)}
                      </span>
                      {row.missingRecord && (
                        <span className="ml-2 inline-flex items-center rounded border border-slate-200 bg-slate-50 px-2 py-1 text-xs text-slate-600">
                          nincs rekord
                        </span>
                      )}
                    </td>
                    <td className="px-3 py-2">
                      <div className="flex flex-wrap gap-1">
                        {checkCell(row.dailyClosingDone, 'napi')}
                        {checkCell(row.eveningClosingDone, 'esti')}
                        {checkCell(row.navClosingDone, 'NAV')}
                      </div>
                      <div className="mt-1 text-xs text-slate-500">{row.completedCount ?? 0}/{row.requiredCount ?? 3}</div>
                    </td>
                    <td className="px-3 py-2 text-slate-700">{formatDateTime(row.lastTransactionAt)}</td>
                    <td className="max-w-[280px] px-3 py-2 text-xs text-slate-600">
                      {row.notes || '-'}
                    </td>
                    <td className="px-3 py-2 text-right">
                      <div className="flex justify-end gap-2">
                        <button
                          type="button"
                          onClick={() => navigate(`/daybook?branchId=${encodeURIComponent(row.branchId)}&date=${encodeURIComponent(date)}`)}
                          className="inline-flex items-center gap-1 rounded border border-slate-300 bg-white px-2 py-1 text-xs font-medium text-slate-700 hover:bg-slate-50"
                        >
                          <Eye size={14} />
                          Napló
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleAlert(row)}
                          disabled={isDone(row) || alertingBranchId === row.branchId}
                          className="inline-flex items-center gap-1 rounded border border-amber-300 bg-amber-50 px-2 py-1 text-xs font-medium text-amber-800 hover:bg-amber-100 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                          <Send size={14} />
                          {alertingBranchId === row.branchId ? 'Küldés' : 'Figyelmeztet'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!loading && filteredRows.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-3 py-8 text-center text-sm text-slate-500">
                      Nincs megjeleníthető záráskontroll sor.
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
