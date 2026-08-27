import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Calendar,
  CheckCircle2,
  Clock,
  Eye,
  Info,
  RefreshCw,
  Search,
  Send,
  XCircle,
} from 'lucide-react'
import { closingControlApi, type ClosingControlStatus } from '../../services/api'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import {
  type ClosingViewFilter,
  isClosingDone,
  computeClosingSummary,
  sortByBranchCode,
  matchesClosingFilter,
} from './closingControlView'
import { excludeBankPartners } from '../../utils/bankPartners'
import { localIsoDate } from '../../utils/dateFormat'
import i18n from '../../i18n'

// Codex P2 #560 fix: NEM toISOString().slice(0, 10), mert az UTC zónát ad vissza.
// A lokális dátumot a közös localIsoDate util adja (utils/dateFormat).

export default function ClosingControlPage() {
  const navigate = useNavigate()
  const [date, setDate] = useState(localIsoDate())
  const [rows, setRows] = useState<ClosingControlStatus[]>([])
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<ClosingViewFilter>('all')
  const [loading, setLoading] = useState(false)
  const [alertingBranchId, setAlertingBranchId] = useState<string | null>(null)
  const [detailLoadingBranchId, setDetailLoadingBranchId] = useState<string | null>(null)
  const [selectedBranchStatus, setSelectedBranchStatus] = useState<ClosingControlStatus | null>(
    null,
  )
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await closingControlApi.list(date)
      // FK-014: banki/speciális partnerek (VAULT_COUNTERPARTY) kiszűrése — csak a 65 pénztár
      // és 8 értéktár végez napi zárást. Fetch után szűrünk, hogy a 3-kockás összesítő is helyes legyen.
      setRows(excludeBankPartners(data))
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

  // FK-003 1. pont: 3-kockás összesítő (Iroda / Rendben / Hiányzó rekord).
  const summary = useMemo(() => computeClosingSummary(rows), [rows])

  // FK-003 2. pont: pénztárszám szerint rendezett, szűrt kártyák.
  const cards = useMemo(
    () => sortByBranchCode(rows.filter((row) => matchesClosingFilter(row, filter, query))),
    [rows, filter, query],
  )

  const handleAlert = async (row: ClosingControlStatus) => {
    const branchLabel = row.branchCode
      ? `${row.branchCode} - ${row.branchName ?? row.branchId}`
      : (row.branchName ?? row.branchId)
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

  const handleViewBranchStatus = async (row: ClosingControlStatus) => {
    try {
      setError(null)
      setDetailLoadingBranchId(row.branchId)
      setSelectedBranchStatus(await closingControlApi.getBranch(row.branchId, date))
    } catch (err) {
      logger.error('ClosingControlPage', 'Iroda zárási részletek betöltési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setDetailLoadingBranchId(null)
    }
  }

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <Clock className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">
                {i18n.t('literals.zaras-beerkezes-felugyelet')}
              </h1>
              <div className="text-xs text-slate-500">
                {i18n.t('literals.napi-zarasok-es-nyitasok-beerkezesenek-v')}
              </div>
            </div>
          </div>
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex items-center gap-2 rounded border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            {i18n.t('literals.frissites')}
          </button>
        </div>
      </div>

      <div className="space-y-4 p-4">
        {/* FK-003 1. pont: 3 kocka — Iroda / Rendben / Hiányzó rekord */}
        <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
          <div className="rounded-md border border-slate-200 bg-white p-3">
            <div className="text-xs text-slate-500">{i18n.t('literals.iroda')}</div>
            <div className="text-2xl font-semibold text-slate-900">{summary.total}</div>
          </div>
          <div className="rounded-md border border-emerald-200 bg-emerald-50 p-3">
            <div className="text-xs text-emerald-700">{i18n.t('literals.rendben')}</div>
            <div className="text-2xl font-semibold text-emerald-800">{summary.done}</div>
          </div>
          <div className="rounded-md border border-red-200 bg-red-50 p-3">
            <div className="text-xs text-red-700">{i18n.t('literals.hianyzo-rekord')}</div>
            <div className="text-2xl font-semibold text-red-800">{summary.notArrived}</div>
          </div>
        </div>

        {/* Megtartandó: dátum + keresés + szűrő */}
        <div className="rounded-md border border-slate-200 bg-white p-3">
          <div className="flex flex-wrap items-end gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-600">
                {i18n.t('literals.datum-2')}
              </label>
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
              <label className="mb-1 block text-xs font-medium text-slate-600">
                {i18n.t('literals.kereses-2')}
              </label>
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
              <label className="mb-1 block text-xs font-medium text-slate-600">
                {i18n.t('literals.szuro')}
              </label>
              <select
                value={filter}
                onChange={(event) => setFilter(event.target.value as ClosingViewFilter)}
                className="rounded border border-slate-300 bg-white px-2 py-2 text-sm"
              >
                <option value="all">{i18n.t('literals.osszes')}</option>
                <option value="done">{i18n.t('literals.rendben')}</option>
                <option value="notArrived">{i18n.t('literals.hianyzo-rekord')}</option>
              </select>
            </div>
          </div>
        </div>

        {error && (
          <div className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        )}

        {selectedBranchStatus && (
          <div className="rounded-md border border-sky-200 bg-sky-50 px-4 py-3 text-sm text-sky-950">
            <div className="mb-3 flex flex-wrap items-start justify-between gap-2">
              <div>
                <div className="font-semibold">
                  {selectedBranchStatus.branchCode ?? selectedBranchStatus.branchId.slice(0, 8)}
                </div>
                <div className="text-xs text-sky-700">
                  {selectedBranchStatus.branchName ?? 'Névtelen iroda'}
                  {selectedBranchStatus.branchCity ? `, ${selectedBranchStatus.branchCity}` : ''}
                </div>
              </div>
              <div className="text-xs text-sky-700">{selectedBranchStatus.controlDate}</div>
            </div>
            <div className="grid gap-2 text-xs sm:grid-cols-3">
              <div
                className={`rounded px-2 py-1.5 font-semibold ${selectedBranchStatus.dailyClosingDone ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'}`}
              >
                {i18n.t('literals.napi-zaras')}
                {selectedBranchStatus.dailyClosingDone ? 'rendben' : 'hiányzik'}
              </div>
              <div
                className={`rounded px-2 py-1.5 font-semibold ${selectedBranchStatus.eveningClosingDone ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'}`}
              >
                {i18n.t('literals.esti-zaras')}
                {selectedBranchStatus.eveningClosingDone ? 'rendben' : 'hiányzik'}
              </div>
              <div
                className={`rounded px-2 py-1.5 font-semibold ${selectedBranchStatus.navClosingDone ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'}`}
              >
                {i18n.t('literals.nav-zaras')}
                {selectedBranchStatus.navClosingDone ? 'rendben' : 'hiányzik'}
              </div>
            </div>
            {(selectedBranchStatus.lastTransactionAt || selectedBranchStatus.notes) && (
              <div className="mt-2 grid gap-2 text-xs sm:grid-cols-2">
                {selectedBranchStatus.lastTransactionAt && (
                  <div>
                    <span className="font-semibold">{i18n.t('literals.utolso-tranzakcio')}</span>{' '}
                    {selectedBranchStatus.lastTransactionAt}
                  </div>
                )}
                {selectedBranchStatus.notes && (
                  <div>
                    <span className="font-semibold">{i18n.t('literals.megjegyzes-2')}</span>{' '}
                    {selectedBranchStatus.notes}
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* FK-003 2. pont: kártyás/rácsos nézet — pénztárszám + név + összesített státusz */}
        {!loading && cards.length === 0 ? (
          <div className="rounded-md border border-slate-200 bg-white px-3 py-8 text-center text-sm text-slate-500">
            {i18n.t('literals.nincs-megjelenitheto-iroda')}
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
            {cards.map((row) => {
              const done = isClosingDone(row)
              return (
                <div
                  key={row.branchId}
                  className={`rounded-md border bg-white p-3 ${done ? 'border-emerald-200' : 'border-red-200'}`}
                >
                  <div className="mb-2 flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <div className="font-semibold text-slate-900">
                        {row.branchCode ?? row.branchId.slice(0, 8)}
                      </div>
                      <div className="truncate text-xs text-slate-500" title={row.branchName ?? ''}>
                        {row.branchName ?? 'Névtelen iroda'}
                        {row.branchCity ? `, ${row.branchCity}` : ''}
                      </div>
                    </div>
                    <div className="flex shrink-0 gap-1">
                      <button
                        type="button"
                        title="Részletek"
                        aria-label={`Részletek lekérése — ${row.branchCode ?? row.branchName ?? row.branchId}`}
                        onClick={() => void handleViewBranchStatus(row)}
                        disabled={detailLoadingBranchId === row.branchId}
                        className="rounded border border-sky-300 bg-sky-50 p-1.5 text-sky-800 hover:bg-sky-100 disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        <Info
                          size={14}
                          className={detailLoadingBranchId === row.branchId ? 'animate-pulse' : ''}
                        />
                      </button>
                      <button
                        type="button"
                        title="Napló"
                        aria-label={`Napló megnyitása — ${row.branchCode ?? row.branchName ?? row.branchId}`}
                        onClick={() =>
                          navigate(
                            `/daybook?branchId=${encodeURIComponent(row.branchId)}&date=${encodeURIComponent(date)}`,
                          )
                        }
                        className="rounded border border-slate-300 bg-white p-1.5 text-slate-600 hover:bg-slate-50"
                      >
                        <Eye size={14} />
                      </button>
                      <button
                        type="button"
                        title="Figyelmeztet"
                        aria-label={`Figyelmeztetés küldése — ${row.branchCode ?? row.branchName ?? row.branchId}`}
                        onClick={() => void handleAlert(row)}
                        disabled={done || alertingBranchId === row.branchId}
                        className="rounded border border-amber-300 bg-amber-50 p-1.5 text-amber-800 hover:bg-amber-100 disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        <Send size={14} />
                      </button>
                    </div>
                  </div>
                  <div
                    className={`flex items-center gap-1.5 rounded px-2 py-1.5 text-xs font-semibold ${
                      done ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'
                    }`}
                  >
                    {done ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                    {done ? 'Zárás bejött' : 'Zárás nem érkezett be'}
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {loading && (
          <div className="rounded-md border border-slate-200 bg-white px-3 py-3 text-sm text-slate-500">
            {i18n.t('literals.betoltes')}
          </div>
        )}
      </div>
    </div>
  )
}
