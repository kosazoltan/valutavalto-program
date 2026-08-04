import { useState, useEffect, useMemo } from 'react'
import {
  ArrowLeftRight,
  Users,
  TrendingUp,
  Wallet,
  FileText,
  AlertTriangle,
  ArrowUp,
  ArrowDown,
  Clock,
  Server,
} from 'lucide-react'
import { Link } from 'react-router-dom'
import { exchangeRateApi, type ExchangeRate } from '../services/api/exchange-rates'
import { api } from '../services/api/index'
import { useAuthStore } from '../stores/authStore'
import { useAppMode } from '../hooks/useAppMode'
import { formatMillions } from './treasury/treasuryUtils'
import { useTranslation } from 'react-i18next'

// 2026-04-29 E-B3 fix: a "Árfolyam módosítás" Gyorsművelet-csempe csak a
// foertektar/ugyvezeto szerepkörnek látható (mode='full'). Az értéktár (és
// pénztáros) csak nézheti az árfolyamokat — ld. legacy ARFOLYAM/Arfolyam.exe
// külön EXE szerepkör-szegregáció + B2 fix RatesPage.tsx-ben.
const RATE_EDITOR_ROLES = ['foertektar', 'ugyvezeto'] as const

interface DashboardStats {
  todayTransactions: number
  todayVolume: number
  activeBranches: number
  alertCount: number
  // 2026-04-29 v2.3.11 (E-B1): a comparison-mezők NULL-ok ha nincs tegnapi adat,
  // 0 ha pontosan ugyanannyi, és valódi % különbség egyébként. Korábban a delta
  // Ft került ide, amit a UI "%-ban" jelenített meg → 46870% bizarr érték.
  yesterdayComparison: {
    transactionsPct?: number | null
    volumePct?: number | null
  }
}

interface RecentTransaction {
  id: number
  time: string
  type: string
  currency: string
  amount: number
  huf: number
  cashier: string
  status: string
}

/**
 * FKH-028 Fázis 6: minden tranzakció-típus a SAJÁT, helyes feliratával jelenik meg —
 * a korábbi bináris ternary miatt minden nem-BUY tétel (így a Transfer-alapú is)
 * "Eladás"-ként látszott. TRANSFER_OUT → "Átadás", TRANSFER_IN → "Átvétel" (az
 * átadás-átvétel/Shipment felületek terminológiáját követve; a backend enum
 * "Átutalás" displayName-je tudatosan NEM változik — külön téma).
 */
const TRANSACTION_TYPE_LABELS: Record<string, string> = {
  BUY: 'Vétel',
  SELL: 'Eladás',
  REVERSAL: 'Sztornó',
  PARTIAL_REFUND: 'Részleges visszatérítés',
  CONVERSION: 'Konverzió',
  TRANSFER_OUT: 'Átadás',
  TRANSFER_IN: 'Átvétel',
  WESTERN_UNION_SEND: 'WU küldés',
  WESTERN_UNION_RECEIVE: 'WU fogadás',
  MONEYGRAM_SEND: 'MG küldés',
  MONEYGRAM_RECEIVE: 'MG fogadás',
  VIGNETTE: 'Autópálya matrica',
  PHONE_TOPUP: 'Telefon feltöltés',
  OTHER: 'Egyéb',
}

function transactionTypeLabel(type: string): string {
  return TRANSACTION_TYPE_LABELS[type] ?? (type || 'Egyéb')
}

/** A badge-szín is típus-alapú (a korábbi BUY-alapú ternary helyett). */
function transactionTypeBadge(type: string): string {
  switch (type) {
    case 'BUY':
      return 'badge-green'
    case 'SELL':
      return 'badge-blue'
    case 'REVERSAL':
    case 'PARTIAL_REFUND':
      return 'badge-red'
    case 'TRANSFER_OUT':
    case 'TRANSFER_IN':
      return 'badge-orange'
    default:
      return 'badge-gray'
  }
}

interface DashboardSummary {
  todayVolume?: number
  activeBranches?: number
  openTransactions?: number
  alertCount?: number
  currencyVolumes?: Record<string, number>
  recentTransactions?: Array<{
    id?: number
    receiptNumber?: string
    type?: string
    currencyCode?: string
    amount?: number
    hufAmount?: number
    cashierName?: string
    createdAt?: string
  }>
}

interface HealthResponse {
  status?: string
  timestamp?: string
  uptime?: string
  version?: string
  db?: string
  database?: {
    connected?: boolean
    responseTimeMs?: number
    activeConnections?: number
  }
  jvm?: {
    heapUsed?: number
    heapMax?: number
    threads?: number
    gcCount?: number
  }
  name?: string
  buildTime?: string
  gitCommit?: string
  environment?: string
  javaVersion?: string
}

interface SystemHealthPanelState {
  status: string
  db: string
  uptime: string
  version: string
  appName: string
  environment: string
  javaVersion: string
  dbResponseTimeMs?: number
  activeConnections?: number
  heapUsed?: number
  heapMax?: number
  threads?: number
}

// Fő devizák a dashboardra (top 4)
const DASHBOARD_CURRENCIES = ['EUR', 'USD', 'GBP', 'CHF']

function formatBytes(value?: number): string {
  if (value == null || !Number.isFinite(value) || value < 0) return '—'
  if (value < 1024 * 1024) return `${Math.round(value / 1024)} KB`
  return `${Math.round(value / 1024 / 1024)} MB`
}

export default function DashboardPage() {
  const { t } = useTranslation()
  const [liveRates, setLiveRates] = useState<ExchangeRate[]>([])
  const [ratesLoading, setRatesLoading] = useState(true)
  const [stats, setStats] = useState<DashboardStats>({
    todayTransactions: 0,
    todayVolume: 0,
    activeBranches: 0,
    alertCount: 0,
    yesterdayComparison: {},
  })
  const [recentTransactions, setRecentTransactions] = useState<RecentTransaction[]>([])
  const [systemHealth, setSystemHealth] = useState<SystemHealthPanelState | null>(null)
  const [systemHealthError, setSystemHealthError] = useState<string | null>(null)

  // E-B3: árfolyam módosítás csak foertektar/ugyvezeto-nek (mode='full')
  // A `roles` selector dependency triggereli a re-render-t login/role-change után.
  const { mode: appMode } = useAppMode()
  const roles = useAuthStore((state) => state.roles)
  const hasCanonicalRole = useAuthStore((state) => state.hasCanonicalRole)
  const canEditRates = useMemo(
    () => appMode === 'full' && hasCanonicalRole([...RATE_EDITOR_ROLES]),
    // eslint-disable-next-line react-hooks/exhaustive-deps -- belt+suspenders: roles szándékos extra trigger login/role-change-kor
    [appMode, roles, hasCanonicalRole],
  )

  useEffect(() => {
    const fetchRates = async () => {
      try {
        const allRates = await exchangeRateApi.list()
        const filtered = allRates
          .filter((r) => r.active && DASHBOARD_CURRENCIES.includes(r.currencyCode))
          .sort(
            (a, b) =>
              DASHBOARD_CURRENCIES.indexOf(a.currencyCode) -
              DASHBOARD_CURRENCIES.indexOf(b.currencyCode),
          )
        setLiveRates(filtered)
      } catch {
        setLiveRates([])
      } finally {
        setRatesLoading(false)
      }
    }

    const fetchDashboardData = async () => {
      try {
        const response = await api.get<DashboardSummary>('/dashboard/summary')
        const summary = response.data ?? {}

        setStats({
          todayTransactions: summary.openTransactions ?? 0,
          todayVolume: summary.todayVolume ?? 0,
          activeBranches: summary.activeBranches ?? 0,
          alertCount: summary.alertCount ?? 0,
          yesterdayComparison: {},
        })
        const txList = (summary.recentTransactions ?? []).slice(0, 5).map((tx, idx) => ({
          id: idx + 1,
          time: tx.createdAt ? tx.createdAt.replace('T', ' ').slice(5, 16) : '',
          type: tx.type || '',
          currency: tx.currencyCode || '',
          amount: tx.amount || 0,
          huf: tx.hufAmount || 0,
          cashier: tx.cashierName || '',
          status: 'completed',
        }))
        setRecentTransactions(txList)
      } catch {
        setStats({
          todayTransactions: 0,
          todayVolume: 0,
          activeBranches: 0,
          alertCount: 0,
          yesterdayComparison: {},
        })
        setRecentTransactions([])
      }
    }

    const fetchSystemHealth = async () => {
      try {
        const [healthResponse, detailedResponse, infoResponse] = await Promise.all([
          api.get<HealthResponse>('/health'),
          api.get<HealthResponse>('/health/detailed'),
          api.get<HealthResponse>('/health/info'),
        ])
        const health = healthResponse.data ?? {}
        const detailed = detailedResponse.data ?? {}
        const info = infoResponse.data ?? {}
        setSystemHealth({
          status: health.status ?? detailed.status ?? 'UNKNOWN',
          db: health.db ?? (detailed.database?.connected ? 'connected' : 'disconnected'),
          uptime: health.uptime ?? detailed.uptime ?? '—',
          version: info.version ?? health.version ?? detailed.version ?? '—',
          appName: info.name ?? 'valuta-backend',
          environment: info.environment ?? 'default',
          javaVersion: info.javaVersion ?? '—',
          dbResponseTimeMs: detailed.database?.responseTimeMs,
          activeConnections: detailed.database?.activeConnections,
          heapUsed: detailed.jvm?.heapUsed,
          heapMax: detailed.jvm?.heapMax,
          threads: detailed.jvm?.threads,
        })
        setSystemHealthError(null)
      } catch {
        setSystemHealth(null)
        setSystemHealthError('Nem elérhető')
      }
    }

    fetchRates()
    fetchDashboardData()
    fetchSystemHealth()
  }, [])
  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-lg font-bold text-secondary-900">{t('misc.iranyitopult')}</h1>
          <p className="text-xs text-secondary-500">{t('misc.attekintesEsGyorsmuveletek')}</p>
        </div>
        <div className="flex items-center gap-1.5 text-xs text-secondary-600">
          <Clock size={14} />
          <span>{new Date().toLocaleTimeString('hu-HU')}</span>
        </div>
      </div>

      {/* MODERN KPI Cards - Compact */}
      <div className="grid grid-cols-2 gap-2 lg:grid-cols-4">
        <StatCard
          icon={ArrowLeftRight}
          label="Mai tranzakciók"
          value={stats.todayTransactions}
          change={stats.yesterdayComparison.transactionsPct}
          color="primary"
        />
        <StatCard
          icon={Wallet}
          label="Mai forgalom"
          value={formatMillions(stats.todayVolume)}
          change={stats.yesterdayComparison.volumePct}
          color="success"
        />
        <StatCard icon={Users} label="Aktív irodák" value={stats.activeBranches} color="info" />
        <StatCard
          icon={AlertTriangle}
          label="Riasztások"
          value={stats.alertCount}
          color="warning"
          urgent={stats.alertCount > 0}
        />
      </div>

      <div className="form-panel">
        <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
          <h2 className="flex items-center gap-1.5 text-sm font-bold text-secondary-900">
            <Server size={16} className="text-blue-600" />
            Rendszerállapot
          </h2>
          <span
            className={`rounded border px-2 py-1 text-xs font-semibold ${
              systemHealth?.status === 'UP'
                ? 'border-emerald-200 bg-emerald-50 text-emerald-700'
                : 'border-amber-200 bg-amber-50 text-amber-700'
            }`}
          >
            {systemHealth?.status ?? systemHealthError ?? 'Betöltés...'}
          </span>
        </div>
        <div className="grid gap-2 text-xs sm:grid-cols-2 lg:grid-cols-4">
          <HealthInfo
            label="Backend"
            value={systemHealth?.appName ?? '—'}
            detail={`v${systemHealth?.version ?? '—'}`}
          />
          <HealthInfo
            label="Adatbázis"
            value={systemHealth?.db ?? '—'}
            detail={
              systemHealth?.dbResponseTimeMs != null ? `${systemHealth.dbResponseTimeMs} ms` : '—'
            }
          />
          <HealthInfo
            label="JVM"
            value={formatBytes(systemHealth?.heapUsed)}
            detail={`${formatBytes(systemHealth?.heapMax)} max · ${systemHealth?.threads ?? '—'} szál`}
          />
          <HealthInfo
            label="Környezet"
            value={systemHealth?.environment ?? '—'}
            detail={`Java ${systemHealth?.javaVersion ?? '—'} · ${systemHealth?.uptime ?? '—'}`}
          />
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid gap-3 lg:grid-cols-3">
        {/* Current rates - Spans 2 columns */}
        <div className="form-panel lg:col-span-2">
          <div className="flex justify-between items-center mb-2">
            <h2 className="text-sm font-bold text-secondary-900 flex items-center gap-1.5">
              <TrendingUp size={16} className="text-success-600" />
              {t('misc.aktualisArfolyamok')}
            </h2>
            <Link
              to="/rates"
              className="text-sm font-medium text-primary-600 hover:text-primary-700 flex items-center gap-1"
            >
              {t('misc.reszletek')}
            </Link>
          </div>
          <div className="overflow-x-auto">
            <table className="data-grid w-full min-w-[560px]">
              <thead>
                <tr>
                  <th>{t('common.deviza')}</th>
                  <th className="text-right">{t('misc.vetelHuf')}</th>
                  <th className="text-right">{t('misc.eladasHuf')}</th>
                  <th className="text-right">{t('misc.valtozas')}</th>
                </tr>
              </thead>
              <tbody>
                {ratesLoading ? (
                  <tr>
                    <td colSpan={4} className="text-center py-4 text-secondary-400">
                      Betöltés...
                    </td>
                  </tr>
                ) : liveRates.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="text-center py-4 text-secondary-400">
                      {t('misc.nincsElerhetoArfolyam')}
                    </td>
                  </tr>
                ) : (
                  liveRates.map((rate) => (
                    <tr key={rate.currencyCode}>
                      <td>
                        <div className="flex items-center gap-2">
                          <span
                            className={`font-bold text-currency-${rate.currencyCode.toLowerCase()}`}
                          >
                            {rate.currencyCode}
                          </span>
                          <span className="text-secondary-500 text-xs">{rate.currencyName}</span>
                        </div>
                      </td>
                      <td className="text-right font-mono font-semibold">
                        {rate.baseBuyRate.toFixed(2)}
                      </td>
                      <td className="text-right font-mono font-semibold">
                        {rate.baseSellRate.toFixed(2)}
                      </td>
                      <td className="text-right">
                        <div className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold bg-secondary-100 text-secondary-600">
                          {rate.officialRate ? `MNB: ${rate.officialRate.toFixed(2)}` : '—'}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Quick actions - Compact card */}
        <div className="form-panel">
          <h2 className="text-sm font-bold text-secondary-900 mb-2">{t('misc.gyorsmuveletek')}</h2>
          <div className="flex flex-col gap-1.5">
            <Link to="/transactions/new" className="form-button-primary justify-start">
              <ArrowLeftRight size={18} />
              <span>{t('misc.ujTranzakcio')}</span>
            </Link>
            <Link to="/customers/new" className="form-button justify-start">
              <Users size={18} />
              <span>{t('misc.ujUgyfel')}</span>
            </Link>
            {/* E-B3 fix: Árfolyam módosítás csak foertektar/ugyvezeto-nek (mode='full').
                Értéktár/pénztár módban csak a /rates "(nézet)" elérhető read-only. */}
            {canEditRates ? (
              <Link to="/rates/creation" className="form-button justify-start">
                <TrendingUp size={18} />
                <span>{t('misc.arfolyamModositas')}</span>
              </Link>
            ) : (
              <Link to="/rates" className="form-button justify-start">
                <TrendingUp size={18} />
                <span>{t('misc.arfolyamokMegtekintese')}</span>
              </Link>
            )}
            <Link to="/cashdesk" className="form-button justify-start">
              <Wallet size={18} />
              <span>{t('misc.napiZaras')}</span>
            </Link>
          </div>
        </div>
      </div>

      {/* Recent transactions - Full width */}
      <div className="form-panel">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-sm font-bold text-secondary-900 flex items-center gap-1.5">
            <FileText size={16} className="text-primary-600" />
            {t('misc.legutobbiTranzakciok')}
          </h2>
          <Link
            to="/transactions"
            className="text-sm font-medium text-primary-600 hover:text-primary-700 flex items-center gap-1"
          >
            {t('misc.osszes')}
          </Link>
        </div>
        <div className="overflow-x-auto">
          <table className="data-grid w-full min-w-[720px]">
            <thead>
              <tr>
                <th>{t('misc.ido')}</th>
                <th>{t('common.type')}</th>
                <th>{t('common.deviza')}</th>
                <th className="text-right">{t('common.amount')}</th>
                <th className="text-right">{t('stockSnapshot.hufValue')}</th>
                <th>Pénztáros</th>
                <th>{t('common.status')}</th>
              </tr>
            </thead>
            <tbody>
              {recentTransactions.map((tx) => (
                <tr key={tx.id}>
                  <td className="font-mono text-sm">{tx.time}</td>
                  <td>
                    <span className={`badge ${transactionTypeBadge(tx.type)}`}>
                      {transactionTypeLabel(tx.type)}
                    </span>
                  </td>
                  <td>
                    <span className={`font-bold text-currency-${tx.currency.toLowerCase()}`}>
                      {tx.currency}
                    </span>
                  </td>
                  <td className="text-right font-mono font-semibold">
                    {tx.amount.toLocaleString()}
                  </td>
                  <td className="text-right font-mono">
                    {tx.huf.toLocaleString()} {t('components.ft')}
                  </td>
                  <td className="text-secondary-700">{tx.cashier}</td>
                  <td>
                    <span
                      className={`badge ${
                        tx.status === 'completed' ? 'badge-green' : 'badge-yellow'
                      }`}
                    >
                      {tx.status === 'completed' ? 'Befejezve' : 'Folyamatban'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

function HealthInfo({ label, value, detail }: { label: string; value: string; detail: string }) {
  return (
    <div className="rounded border border-gray-200 bg-white px-3 py-2">
      <div className="text-[11px] font-semibold uppercase text-secondary-500">{label}</div>
      <div className="mt-0.5 truncate font-semibold text-secondary-900">{value}</div>
      <div className="mt-0.5 truncate text-secondary-500">{detail}</div>
    </div>
  )
}

function StatCard({
  icon: Icon,
  label,
  value,
  change,
  color,
  urgent,
}: {
  icon: React.ElementType
  label: string
  value: string | number
  // 2026-04-29 v2.3.11 (E-B1): `change` most a százalékos változás (NEM delta Ft).
  // null = nincs alap (tegnap=0, ma>0). undefined = nincs comparison szükséges.
  change?: number | null
  color: 'primary' | 'success' | 'warning' | 'info'
  urgent?: boolean
}) {
  const { t } = useTranslation()
  const colorClasses = {
    primary: 'bg-primary-50 border-primary-200 text-primary-700',
    success: 'bg-green-50 border-green-200 text-green-700',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-700',
    info: 'bg-blue-50 border-blue-200 text-blue-700',
  }

  return (
    <div
      className={`form-panel border ${colorClasses[color]} ${urgent ? 'ring-2 ring-yellow-400 animate-pulse' : ''}`}
    >
      <div className="flex items-center gap-1.5 mb-0.5">
        <Icon size={14} />
        <span className="text-xs">{label}</span>
      </div>
      <div className="text-lg font-bold leading-tight">{value}</div>
      {change === null && (
        <div className="text-[10px] mt-0.5 text-gray-500">{t('misc.NincsTegnapiAdat')}</div>
      )}
      {change !== undefined && change !== null && (
        <div
          className={`text-[10px] mt-0.5 flex items-center gap-0.5 ${change >= 0 ? 'text-green-600' : 'text-red-600'}`}
        >
          {change >= 0 ? <ArrowUp size={10} /> : <ArrowDown size={10} />}
          <span>
            {Math.abs(change)}
            {t('misc.szazalekTegnap')}
          </span>
        </div>
      )}
    </div>
  )
}
