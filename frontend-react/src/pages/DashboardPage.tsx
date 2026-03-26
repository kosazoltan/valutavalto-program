import { useState, useEffect } from 'react'
import { ArrowLeftRight, Users, TrendingUp, Wallet, FileText, AlertTriangle, ArrowUp, ArrowDown, Clock } from 'lucide-react'
import { Link } from 'react-router-dom'
import { exchangeRateApi, type ExchangeRate } from '../services/api/exchange-rates'

// Mock data - replace with API calls (stats & transactions still mock)
const mockStats = {
  todayTransactions: 47,
  todayVolume: 12500000,
  activeCustomers: 23,
  pendingDeposits: 3,
  yesterdayComparison: {
    transactions: 12, // +12%
    volume: -5.2, // -5.2%
  }
}

const mockRecentTransactions = [
  { id: 1, time: '10:45', type: 'BUY', currency: 'EUR', amount: 500, huf: 195750, customer: 'Kiss János', status: 'completed' },
  { id: 2, time: '10:32', type: 'SELL', currency: 'USD', amount: 1000, huf: 358200, customer: 'Nagy Péter', status: 'completed' },
  { id: 3, time: '10:15', type: 'BUY', currency: 'GBP', amount: 200, huf: 91000, customer: 'Szabó Anna', status: 'completed' },
  { id: 4, time: '09:58', type: 'SELL', currency: 'CHF', amount: 350, huf: 140875, customer: 'Kovács Béla', status: 'pending' },
]

// Fő devizák a dashboardra (top 4)
const DASHBOARD_CURRENCIES = ['EUR', 'USD', 'GBP', 'CHF']

export default function DashboardPage() {
  const [liveRates, setLiveRates] = useState<ExchangeRate[]>([])
  const [ratesLoading, setRatesLoading] = useState(true)

  useEffect(() => {
    const fetchRates = async () => {
      try {
        const allRates = await exchangeRateApi.list()
        // Szűrés: csak aktív + dashboard devizák
        const filtered = allRates
          .filter(r => r.active && DASHBOARD_CURRENCIES.includes(r.currencyCode))
          .sort((a, b) => DASHBOARD_CURRENCIES.indexOf(a.currencyCode) - DASHBOARD_CURRENCIES.indexOf(b.currencyCode))
        setLiveRates(filtered)
      } catch {
        // Ha API nem elérhető, üres marad
        setLiveRates([])
      } finally {
        setRatesLoading(false)
      }
    }
    fetchRates()
  }, [])
  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-secondary-900">Irányítópult</h1>
          <p className="text-sm text-secondary-500 mt-1">Áttekintés és gyorsműveletek</p>
        </div>
        <div className="flex items-center gap-2 text-sm text-secondary-600">
          <Clock size={16} />
          <span>Utolsó frissítés: {new Date().toLocaleTimeString('hu-HU')}</span>
        </div>
      </div>

      {/* MODERN KPI Cards - Bento Grid Style */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard
          icon={ArrowLeftRight}
          label="Mai tranzakciók"
          value={mockStats.todayTransactions}
          change={mockStats.yesterdayComparison.transactions}
          color="primary"
        />
        <StatCard
          icon={Wallet}
          label="Mai forgalom"
          value={`${(mockStats.todayVolume / 1000000).toFixed(1)}M Ft`}
          change={mockStats.yesterdayComparison.volume}
          color="success"
        />
        <StatCard
          icon={Users}
          label="Aktív ügyfelek"
          value={mockStats.activeCustomers}
          color="info"
        />
        <StatCard
          icon={AlertTriangle}
          label="Függő foglalók"
          value={mockStats.pendingDeposits}
          color="warning"
          urgent={mockStats.pendingDeposits > 0}
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-3 gap-6">
        {/* Current rates - Spans 2 columns */}
        <div className="col-span-2 form-panel">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-secondary-900 flex items-center gap-2">
              <TrendingUp size={20} className="text-success-600" />
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
          <h2 className="text-lg font-bold text-secondary-900 mb-4">Gyorsműveletek</h2>
          <div className="flex flex-col gap-2">
            <Link to="/transactions/new" className="form-button-primary justify-start">
              <ArrowLeftRight size={18} />
              <span>Új tranzakció</span>
            </Link>
            <Link to="/customers/new" className="form-button justify-start">
              <Users size={18} />
              <span>Új ügyfél</span>
            </Link>
            <Link to="/rates" className="form-button justify-start">
              <TrendingUp size={18} />
              <span>Árfolyam módosítás</span>
            </Link>
            <Link to="/cashdesk" className="form-button justify-start">
              <Wallet size={18} />
              <span>Napi zárás</span>
            </Link>
          </div>
        </div>
      </div>

      {/* Recent transactions - Full width */}
      <div className="form-panel">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-bold text-secondary-900 flex items-center gap-2">
            <FileText size={20} className="text-primary-600" />
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
            {mockRecentTransactions.map((tx) => (
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
  change?: number
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
      <div className="flex items-center gap-2 mb-1">
        <Icon size={18} />
        <span className="text-sm">{label}</span>
      </div>
      <div className="text-2xl font-bold">{value}</div>
      {change !== undefined && (
        <div className={`text-xs mt-1 flex items-center gap-1 ${change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          {change >= 0 ? <ArrowUp size={12} /> : <ArrowDown size={12} />}
          <span>{Math.abs(change)}% tegnaphoz képest</span>
        </div>
      )}
    </div>
  )
}
