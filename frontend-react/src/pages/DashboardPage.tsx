import { useState, useEffect, useMemo } from 'react'
import { ArrowLeftRight, Users, TrendingUp, Wallet, FileText, AlertTriangle, ArrowUp, ArrowDown, Clock } from 'lucide-react'
import { Link } from 'react-router-dom'
import { exchangeRateApi, type ExchangeRate } from '../services/api/exchange-rates'
import { transactionApi, type DailyTurnoverSummary } from '../services/api/transactions'
import { useAuthStore } from '../stores/authStore'
import { useAppMode } from '../hooks/useAppMode'
import { formatMillions } from './treasury/treasuryUtils'

// 2026-04-29 E-B3 fix: a "Árfolyam módosítás" Gyorsművelet-csempe csak a
// foertektar/ugyvezeto szerepkörnek látható (mode='full'). Az értéktár (és
// pénztáros) csak nézheti az árfolyamokat — ld. legacy ARFOLYAM/Arfolyam.exe
// külön EXE szerepkör-szegregáció + B2 fix RatesPage.tsx-ben.
const RATE_EDITOR_ROLES = ['foertektar', 'ugyvezeto'] as const

interface DashboardStats {
  todayTransactions: number
  todayVolume: number
  activeCustomers: number
  pendingDeposits: number
  // 2026-04-29 v2.3.11 (E-B1): a comparison-mezők NULL-ok ha nincs tegnapi adat,
  // 0 ha pontosan ugyanannyi, és valódi % különbség egyébként. Korábban a delta
  // Ft került ide, amit a UI "%-ban" jelenített meg → 46870% bizarr érték.
  yesterdayComparison: {
    transactionsPct: number | null
    volumePct: number | null
  }
}

interface RecentTransaction {
  id: number
  time: string
  type: string
  currency: string
  amount: number
  huf: number
  customer: string
  status: string
}

// Fő devizák a dashboardra (top 4)
const DASHBOARD_CURRENCIES = ['EUR', 'USD', 'GBP', 'CHF']

export default function DashboardPage() {
  const [liveRates, setLiveRates] = useState<ExchangeRate[]>([])
  const [ratesLoading, setRatesLoading] = useState(true)
  const [stats, setStats] = useState<DashboardStats>({
    todayTransactions: 0,
    todayVolume: 0,
    activeCustomers: 0,
    pendingDeposits: 0,
    yesterdayComparison: { transactionsPct: null, volumePct: null }
  })
  const [recentTransactions, setRecentTransactions] = useState<RecentTransaction[]>([])

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
          .filter(r => r.active && DASHBOARD_CURRENCIES.includes(r.currencyCode))
          .sort((a, b) => DASHBOARD_CURRENCIES.indexOf(a.currencyCode) - DASHBOARD_CURRENCIES.indexOf(b.currencyCode))
        setLiveRates(filtered)
      } catch {
        setLiveRates([])
      } finally {
        setRatesLoading(false)
      }
    }

    const fetchDashboardData = async () => {
      try {
        // Valódi napi forgalom az API-ból
        const turnover: DailyTurnoverSummary = await transactionApi.getDailyTurnover()
        const totalTx = (turnover.totalBuyCount || 0) + (turnover.totalSellCount || 0)
        const totalVol = (turnover.totalBuyHuf || 0) + (turnover.totalSellHuf || 0)

        // Tegnapi adatok az összehasonlításhoz
        const yesterday = new Date()
        yesterday.setDate(yesterday.getDate() - 1)
        const yStr = yesterday.toISOString().split('T')[0]
        let yTx = 0, yVol = 0
        try {
          const yTurnover = await transactionApi.getDailyTurnover(yStr)
          yTx = (yTurnover.totalBuyCount || 0) + (yTurnover.totalSellCount || 0)
          yVol = (yTurnover.totalBuyHuf || 0) + (yTurnover.totalSellHuf || 0)
        } catch { /* tegnapi adat nem elérhető — 0 marad */ }

        // 2026-04-29 v2.3.11 (E-B1): valódi %-különbség számítás NaN/Infinity guard-dal.
        // - yesterdayValue = 0 + todayValue = 0  → 0% (nincs változás)
        // - yesterdayValue = 0 + todayValue > 0 → null (nincs alap, "—" megjelenítés)
        // - yesterdayValue > 0                  → ((today - yesterday) / yesterday) * 100
        const computePct = (today: number, yesterday: number): number | null => {
          if (yesterday === 0) return today === 0 ? 0 : null
          return Math.round(((today - yesterday) / yesterday) * 100)
        }

        setStats({
          todayTransactions: totalTx,
          todayVolume: totalVol,
          activeCustomers: totalTx > 0 ? Math.ceil(totalTx * 0.7) : 0, // Becsült egyedi ügyfelek (tranzakciók 70%-a)
          pendingDeposits: turnover.totalReversalCount || 0,
          yesterdayComparison: {
            transactionsPct: computePct(totalTx, yTx),
            volumePct: computePct(totalVol, yVol)
          }
        })
      } catch {
        // API hiba esetén 0 értékek maradnak
      }

      try {
        // Legutóbbi tranzakciók az API-ból
        const page = await transactionApi.list({ size: 5 })
        const txList = (page.content || []).map((tx, idx) => ({
          id: idx + 1,
          time: tx.transactionTime ? tx.transactionTime.substring(0, 5) : '',
          type: tx.transactionType || '',
          currency: tx.currencyCode || '',
          amount: tx.currencyAmount || 0,
          huf: tx.hufAmount || 0,
          customer: tx.workerName || '',
          status: (tx.status || 'COMPLETED').toLowerCase()
        }))
        setRecentTransactions(txList)
      } catch {
        setRecentTransactions([])
      }
    }

    fetchRates()
    fetchDashboardData()
  }, [])
  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-lg font-bold text-secondary-900">Irányítópult</h1>
          <p className="text-xs text-secondary-500">Áttekintés és gyorsműveletek</p>
        </div>
        <div className="flex items-center gap-1.5 text-xs text-secondary-600">
          <Clock size={14} />
          <span>{new Date().toLocaleTimeString('hu-HU')}</span>
        </div>
      </div>

      {/* MODERN KPI Cards - Compact */}
      <div className="grid grid-cols-4 gap-2">
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
        <StatCard
          icon={Users}
          label="Aktív ügyfelek"
          value={stats.activeCustomers}
          color="info"
        />
        <StatCard
          icon={AlertTriangle}
          label="Függő foglalók"
          value={stats.pendingDeposits}
          color="warning"
          urgent={stats.pendingDeposits > 0}
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-3 gap-3">
        {/* Current rates - Spans 2 columns */}
        <div className="col-span-2 form-panel">
          <div className="flex justify-between items-center mb-2">
            <h2 className="text-sm font-bold text-secondary-900 flex items-center gap-1.5">
              <TrendingUp size={16} className="text-success-600" />
              Aktuális árfolyamok
            </h2>
            <Link to="/rates" className="text-sm font-medium text-primary-600 hover:text-primary-700 flex items-center gap-1">
              Részletek →
            </Link>
          </div>
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>Deviza</th>
                <th className="text-right">Vétel (HUF)</th>
                <th className="text-right">Eladás (HUF)</th>
                <th className="text-right">Változás</th>
              </tr>
            </thead>
            <tbody>
              {ratesLoading ? (
                <tr><td colSpan={4} className="text-center py-4 text-secondary-400">Betöltés...</td></tr>
              ) : liveRates.length === 0 ? (
                <tr><td colSpan={4} className="text-center py-4 text-secondary-400">Nincs elérhető árfolyam</td></tr>
              ) : (
                liveRates.map((rate) => (
                  <tr key={rate.currencyCode}>
                    <td>
                      <div className="flex items-center gap-2">
                        <span className={`font-bold text-currency-${rate.currencyCode.toLowerCase()}`}>{rate.currencyCode}</span>
                        <span className="text-secondary-500 text-xs">{rate.currencyName}</span>
                      </div>
                    </td>
                    <td className="text-right font-mono font-semibold">{rate.baseBuyRate.toFixed(2)}</td>
                    <td className="text-right font-mono font-semibold">{rate.baseSellRate.toFixed(2)}</td>
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

        {/* Quick actions - Compact card */}
        <div className="form-panel">
          <h2 className="text-sm font-bold text-secondary-900 mb-2">Gyorsműveletek</h2>
          <div className="flex flex-col gap-1.5">
            <Link to="/transactions/new" className="form-button-primary justify-start">
              <ArrowLeftRight size={18} />
              <span>Új tranzakció</span>
            </Link>
            <Link to="/customers/new" className="form-button justify-start">
              <Users size={18} />
              <span>Új ügyfél</span>
            </Link>
            {/* E-B3 fix: Árfolyam módosítás csak foertektar/ugyvezeto-nek (mode='full').
                Értéktár/pénztár módban csak a /rates "(nézet)" elérhető read-only. */}
            {canEditRates ? (
              <Link to="/rates/creation" className="form-button justify-start">
                <TrendingUp size={18} />
                <span>Árfolyam módosítás</span>
              </Link>
            ) : (
              <Link to="/rates" className="form-button justify-start">
                <TrendingUp size={18} />
                <span>Árfolyamok megtekintése</span>
              </Link>
            )}
            <Link to="/cashdesk" className="form-button justify-start">
              <Wallet size={18} />
              <span>Napi zárás</span>
            </Link>
          </div>
        </div>
      </div>

      {/* Recent transactions - Full width */}
      <div className="form-panel">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-sm font-bold text-secondary-900 flex items-center gap-1.5">
            <FileText size={16} className="text-primary-600" />
            Legutóbbi tranzakciók
          </h2>
          <Link to="/transactions" className="text-sm font-medium text-primary-600 hover:text-primary-700 flex items-center gap-1">
            Összes →
          </Link>
        </div>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Idő</th>
              <th>Típus</th>
              <th>Deviza</th>
              <th className="text-right">Összeg</th>
              <th className="text-right">HUF érték</th>
              <th>Ügyfél</th>
              <th>Státusz</th>
            </tr>
          </thead>
          <tbody>
            {recentTransactions.map((tx) => (
              <tr key={tx.id}>
                <td className="font-mono text-sm">{tx.time}</td>
                <td>
                  <span className={`badge ${
                    tx.type === 'BUY' ? 'badge-green' : 'badge-blue'
                  }`}>
                    {tx.type === 'BUY' ? 'Vétel' : 'Eladás'}
                  </span>
                </td>
                <td>
                  <span className={`font-bold text-currency-${tx.currency.toLowerCase()}`}>{tx.currency}</span>
                </td>
                <td className="text-right font-mono font-semibold">{tx.amount.toLocaleString()}</td>
                <td className="text-right font-mono">{tx.huf.toLocaleString()} Ft</td>
                <td className="text-secondary-700">{tx.customer}</td>
                <td>
                  <span className={`badge ${
                    tx.status === 'completed' ? 'badge-green' : 'badge-yellow'
                  }`}>
                    {tx.status === 'completed' ? 'Befejezve' : 'Folyamatban'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function StatCard({
  icon: Icon,
  label,
  value,
  change,
  color,
  urgent
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
  const colorClasses = {
    primary: 'bg-primary-50 border-primary-200 text-primary-700',
    success: 'bg-green-50 border-green-200 text-green-700',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-700',
    info: 'bg-blue-50 border-blue-200 text-blue-700',
  }

  return (
    <div className={`form-panel border ${colorClasses[color]} ${urgent ? 'ring-2 ring-yellow-400 animate-pulse' : ''}`}>
      <div className="flex items-center gap-1.5 mb-0.5">
        <Icon size={14} />
        <span className="text-xs">{label}</span>
      </div>
      <div className="text-lg font-bold leading-tight">{value}</div>
      {change === null && (
        <div className="text-[10px] mt-0.5 text-gray-500">
          — nincs tegnapi adat
        </div>
      )}
      {change !== undefined && change !== null && (
        <div className={`text-[10px] mt-0.5 flex items-center gap-0.5 ${change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          {change >= 0 ? <ArrowUp size={10} /> : <ArrowDown size={10} />}
          <span>{Math.abs(change)}% tegnap</span>
        </div>
      )}
    </div>
  )
}

