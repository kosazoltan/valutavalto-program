import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  Clock,
  Calendar,
  Users,
  RefreshCw,
  AlertTriangle,
  User,
  Building2,
  LogIn,
  LogOut,
} from 'lucide-react'
import {
  workerAttendanceApi,
  type WorkerAttendanceDto,
  calculateDuration,
  formatDuration,
} from '../../services/api/workerAttendance'
import { workerMasterApi, type WorkerMaster } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

type Tab = 'my' | 'team'

function isoDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('hu-HU', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export default function AttendancePage() {
  const { t } = useTranslation()
  const [tab, setTab] = useState<Tab>('my')

  // Default: last 7 days
  const defaultFrom = useMemo(() => {
    const d = new Date()
    d.setDate(d.getDate() - 6)
    return isoDate(d)
  }, [])
  const defaultTo = useMemo(() => isoDate(new Date()), [])

  const [dateFrom, setDateFrom] = useState<string>(defaultFrom)
  const [dateTo, setDateTo] = useState<string>(defaultTo)

  return (
    <div className="space-y-2">
      <div>
        <h1 className="text-base font-bold text-secondary-900 flex items-center gap-2">
          <Clock className="text-primary-600" size={18} />
          {t('attendance.munkaidoNyilvantartas')}
        </h1>
        <p className="text-xs text-secondary-500">
          {t('attendance.bejelentkezesiEsKijelentkezesiNaploSajatVagyCsapattag')}
        </p>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-secondary-200">
        <TabButton active={tab === 'my'} onClick={() => setTab('my')} icon={<User size={14} />}>
          {t('attendance.sajatNaplom')}
        </TabButton>
        <TabButton
          active={tab === 'team'}
          onClick={() => setTab('team')}
          icon={<Users size={14} />}
        >
          {t('attendance.csapattagSupervisor')}
        </TabButton>
      </div>

      {/* Date range */}
      <div className="form-panel p-4 flex items-center gap-3 flex-wrap">
        <Calendar size={16} className="text-secondary-400" />
        <input
          type="date"
          className="form-input h-9 text-xs"
          value={dateFrom}
          max={dateTo || isoDate(new Date())}
          onChange={(e) => setDateFrom(e.target.value)}
          aria-label="Kezdo datum"
        />
        <span className="text-secondary-400 text-xs">{i18n.t('literals.lit-15')}</span>
        <input
          type="date"
          className="form-input h-9 text-xs"
          value={dateTo}
          min={dateFrom}
          max={isoDate(new Date())}
          onChange={(e) => setDateTo(e.target.value)}
          aria-label="Veg datum"
        />
      </div>

      {tab === 'my' && <MyAttendanceTab from={dateFrom} to={dateTo} />}
      {tab === 'team' && <TeamAttendanceTab from={dateFrom} to={dateTo} />}
    </div>
  )
}

// ==================== MY TAB ====================

function MyAttendanceTab({ from, to }: { from: string; to: string }) {
  const [entries, setEntries] = useState<WorkerAttendanceDto[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState<string | null>(null)
  const [reloadTick, setReloadTick] = useState(0)
  const refresh = useCallback(() => setReloadTick((t) => t + 1), [])

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setErr(null)
    workerAttendanceApi
      .my(from, to, 0, 100)
      .then((r) => {
        if (!cancelled) setEntries(r.content)
      })
      .catch((e) => {
        if (!cancelled) {
          logger.error('Attendance', 'my err', e)
          setErr(e instanceof Error ? e.message : String(e))
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [from, to, reloadTick])

  const activeEntry = entries.find((e) => !e.logoutAt)

  const recordLogin = async () => {
    try {
      setSaving(true)
      setErr(null)
      await workerAttendanceApi.login()
      refresh()
    } catch (e) {
      logger.error('Attendance', 'login record err', e)
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setSaving(false)
    }
  }

  const recordLogout = async () => {
    if (!activeEntry) return
    try {
      setSaving(true)
      setErr(null)
      await workerAttendanceApi.logout(activeEntry.id)
      refresh()
    } catch (e) {
      logger.error('Attendance', 'logout record err', e)
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-3">
      <div className="form-panel p-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="text-sm font-semibold text-secondary-900">
            {i18n.t('literals.jelenleti-allapot')}
          </div>
          <div className="text-xs text-secondary-500">
            {activeEntry
              ? `Nyitott session: ${formatDateTime(activeEntry.loginAt)}`
              : 'Nincs nyitott jelenléti session'}
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            className="form-button-primary flex items-center gap-1"
            onClick={() => void recordLogin()}
            disabled={saving || loading || Boolean(activeEntry)}
          >
            <LogIn size={14} />
            {i18n.t('literals.bejelentkezes-rogzitese')}
          </button>
          <button
            type="button"
            className="form-button flex items-center gap-1"
            onClick={() => void recordLogout()}
            disabled={saving || loading || !activeEntry}
          >
            <LogOut size={14} />
            {i18n.t('literals.kijelentkezes-rogzitese')}
          </button>
        </div>
      </div>
      <AttendanceList
        entries={entries}
        loading={loading || saving}
        err={err}
        onRefresh={refresh}
        showWorkerName={false}
      />
    </div>
  )
}

// ==================== TEAM TAB ====================

function TeamAttendanceTab({ from, to }: { from: string; to: string }) {
  const { t } = useTranslation()
  const [workers, setWorkers] = useState<WorkerMaster[]>([])
  const [selectedWorkerId, setSelectedWorkerId] = useState<number | ''>('')
  const [entries, setEntries] = useState<WorkerAttendanceDto[]>([])
  const [loading, setLoading] = useState(false)
  const [err, setErr] = useState<string | null>(null)
  const [reloadTick, setReloadTick] = useState(0)
  const refresh = useCallback(() => setReloadTick((t) => t + 1), [])

  // Load workers once
  useEffect(() => {
    workerMasterApi
      .listActive()
      .then((data) => setWorkers(Array.isArray(data) ? data : []))
      .catch((e) => logger.error('Attendance', 'workers err', e))
  }, [])

  // Load attendance when worker or dates change
  useEffect(() => {
    if (!selectedWorkerId) {
      setEntries([])
      return
    }
    let cancelled = false
    setLoading(true)
    setErr(null)
    workerAttendanceApi
      .byWorker(selectedWorkerId, from, to, 0, 100)
      .then((r) => {
        if (!cancelled) setEntries(r.content)
      })
      .catch((e) => {
        if (!cancelled) {
          logger.error('Attendance', 'team err', e)
          setErr(e instanceof Error ? e.message : String(e))
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [selectedWorkerId, from, to, reloadTick])

  return (
    <div className="space-y-3">
      <div className="form-panel p-4">
        <label className="form-label">{t('attendance.csapattagKivalasztasa')}</label>
        <select
          className="form-input w-full"
          value={selectedWorkerId}
          onChange={(e) => setSelectedWorkerId(e.target.value ? Number(e.target.value) : '')}
        >
          <option value="">{t('attendance.valasszCsapattagot')}</option>
          {workers.map((w) => (
            <option key={w.id} value={w.id}>
              {w.fullName}
              {i18n.t('literals.lit')}
              {w.workerCode ?? `#${w.id}`}
              {i18n.t('literals.lit-2')}
            </option>
          ))}
        </select>
      </div>

      {selectedWorkerId && (
        <AttendanceList
          entries={entries}
          loading={loading}
          err={err}
          onRefresh={refresh}
          showWorkerName={true}
        />
      )}
    </div>
  )
}

// ==================== LIST + SUMMARY ====================

function AttendanceList({
  entries,
  loading,
  err,
  onRefresh,
  showWorkerName,
}: {
  entries: WorkerAttendanceDto[]
  loading: boolean
  err: string | null
  onRefresh: () => void
  showWorkerName: boolean
}) {
  const { t } = useTranslation()
  const totalMinutes = useMemo(() => {
    return entries.reduce((sum, e) => sum + calculateDuration(e), 0)
  }, [entries])

  const activeCount = entries.filter((e) => !e.logoutAt).length

  return (
    <div className="space-y-3">
      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-3">
        <SummaryCard
          icon={<LogIn className="text-blue-500" size={20} />}
          label="Bejelentkezesek"
          value={entries.length.toString()}
        />
        <SummaryCard
          icon={<LogOut className="text-green-500" size={20} />}
          label="Nyitott session"
          value={activeCount.toString()}
          danger={activeCount > 1}
        />
        <SummaryCard
          icon={<Clock className="text-purple-500" size={20} />}
          label="Össz. munkaidő"
          value={formatDuration(totalMinutes)}
        />
      </div>

      {err && (
        <div className="p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 flex items-center gap-2">
          <AlertTriangle size={18} />
          <span className="text-sm">{err}</span>
        </div>
      )}

      {/* Refresh */}
      <div className="flex justify-end">
        <button onClick={onRefresh} className="form-button text-xs">
          <RefreshCw size={12} className={loading ? 'animate-spin' : ''} />
          <span>{t('common.refresh')}</span>
        </button>
      </div>

      {/* Table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              {showWorkerName && <th>{t('components.penztaros')}</th>}
              <th>{t('auth.login')}</th>
              <th>{t('auth.logout')}</th>
              <th className="text-right">{t('attendance.idotartam')}</th>
              <th>{t('branch.branchName')}</th>
              <th>{i18n.t('literals.ip')}</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr>
                <td
                  colSpan={showWorkerName ? 6 : 5}
                  className="text-center py-8 text-secondary-400"
                >
                  {i18n.t('literals.betoltes-4')}
                </td>
              </tr>
            )}
            {!loading && entries.length === 0 && (
              <tr>
                <td
                  colSpan={showWorkerName ? 6 : 5}
                  className="text-center py-8 text-secondary-400"
                >
                  {t('attendance.nincsAdatAzIdotartomanyban')}
                </td>
              </tr>
            )}
            {!loading &&
              entries.map((e) => {
                const duration = calculateDuration(e)
                const isActive = !e.logoutAt
                return (
                  <tr key={e.id} className={isActive ? 'bg-green-50' : ''}>
                    {showWorkerName && (
                      <td className="font-semibold">{e.workerName ?? `#${e.workerId}`}</td>
                    )}
                    <td className="text-sm font-mono">{formatDateTime(e.loginAt)}</td>
                    <td className="text-sm font-mono">
                      {e.logoutAt ? (
                        formatDateTime(e.logoutAt)
                      ) : (
                        <span className="badge badge-green text-xs">
                          {i18n.t('literals.aktiv')}
                        </span>
                      )}
                    </td>
                    <td className="text-right text-sm">{formatDuration(duration)}</td>
                    <td className="text-sm">
                      {e.branchCode ? (
                        <span className="inline-flex items-center gap-1">
                          <Building2 size={12} className="text-secondary-400" />
                          {e.branchCode}
                        </span>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="text-xs text-secondary-500 font-mono">{e.ipAddress ?? '—'}</td>
                  </tr>
                )
              })}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function SummaryCard({
  icon,
  label,
  value,
  danger,
}: {
  icon: React.ReactNode
  label: string
  value: string
  danger?: boolean
}) {
  return (
    <div
      className={`p-4 rounded-lg border bg-white shadow-sm ${
        danger ? 'border-red-300' : 'border-secondary-200'
      }`}
    >
      <div className="flex items-center gap-2 mb-2">
        {icon}
        <span className="text-xs font-medium text-secondary-500 uppercase tracking-wide">
          {label}
        </span>
      </div>
      <div className={`text-xl font-bold ${danger ? 'text-red-600' : 'text-secondary-900'}`}>
        {value}
      </div>
    </div>
  )
}

function TabButton({
  active,
  onClick,
  icon,
  children,
}: {
  active: boolean
  onClick: () => void
  icon: React.ReactNode
  children: React.ReactNode
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`px-4 py-2 text-sm font-semibold border-b-2 flex items-center gap-2 transition-all ${
        active
          ? 'text-primary-600 border-primary-600'
          : 'text-secondary-500 border-transparent hover:text-secondary-800'
      }`}
    >
      {icon}
      {children}
    </button>
  )
}
