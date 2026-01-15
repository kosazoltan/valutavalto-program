import { ArrowLeftRight, Users, TrendingUp, Wallet, FileText, AlertTriangle } from 'lucide-react'
import { Link } from 'react-router-dom'

// Mock data - replace with API calls
const mockStats = {
  todayTransactions: 47,
  todayVolume: 12500000,
  activeCustomers: 23,
  pendingDeposits: 3,
}

const mockRates = [
  { code: 'EUR', name: 'Euró', buy: 391.50, sell: 398.50, change: 0.5 },
  { code: 'USD', name: 'US Dollár', buy: 358.20, sell: 365.80, change: -0.3 },
  { code: 'GBP', name: 'Angol Font', buy: 455.00, sell: 468.00, change: 0.8 },
  { code: 'CHF', name: 'Svájci Frank', buy: 402.50, sell: 412.50, change: 0.1 },
]

const mockRecentTransactions = [
  { id: 1, time: '10:45', type: 'BUY', currency: 'EUR', amount: 500, huf: 195750, customer: 'Kiss János' },
  { id: 2, time: '10:32', type: 'SELL', currency: 'USD', amount: 1000, huf: 358200, customer: 'Nagy Péter' },
  { id: 3, time: '10:15', type: 'BUY', currency: 'GBP', amount: 200, huf: 91000, customer: 'Szabó Anna' },
]

export default function DashboardPage() {
  return (
    <div className="space-y-4">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800">Főoldal</h1>
        <div className="text-sm text-gray-600">
          Utolsó frissítés: {new Date().toLocaleTimeString('hu-HU')}
        </div>
      </div>

      {/* Quick stats */}
      <div className="grid grid-cols-4 gap-3">
        <StatCard
          icon={ArrowLeftRight}
          label="Mai tranzakciók"
          value={mockStats.todayTransactions}
          color="primary"
        />
        <StatCard
          icon={Wallet}
          label="Mai forgalom"
          value={`${(mockStats.todayVolume / 1000000).toFixed(1)}M Ft`}
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
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        {/* Current rates */}
        <div className="form-panel">
          <div className="flex justify-between items-center mb-2">
            <h2 className="font-semibold flex items-center gap-2">
              <TrendingUp size={18} />
              Aktuális árfolyamok
            </h2>
            <Link to="/rates" className="text-sm text-primary hover:underline">
              Részletek →
            </Link>
          </div>
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>Deviza</th>
                <th className="text-right">Vétel</th>
                <th className="text-right">Eladás</th>
                <th className="text-right">Változás</th>
              </tr>
            </thead>
            <tbody>
              {mockRates.map((rate) => (
                <tr key={rate.code}>
                  <td>
                    <span className="font-semibold">{rate.code}</span>
                    <span className="text-gray-500 ml-1 text-xs">{rate.name}</span>
                  </td>
                  <td className="text-right font-mono">{rate.buy.toFixed(2)}</td>
                  <td className="text-right font-mono">{rate.sell.toFixed(2)}</td>
                  <td className={`text-right ${rate.change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {rate.change >= 0 ? '+' : ''}{rate.change.toFixed(1)}%
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Recent transactions */}
        <div className="form-panel">
          <div className="flex justify-between items-center mb-2">
            <h2 className="font-semibold flex items-center gap-2">
              <FileText size={18} />
              Legutóbbi tranzakciók
            </h2>
            <Link to="/transactions" className="text-sm text-primary hover:underline">
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
                <th>Ügyfél</th>
              </tr>
            </thead>
            <tbody>
              {mockRecentTransactions.map((tx) => (
                <tr key={tx.id}>
                  <td>{tx.time}</td>
                  <td>
                    <span className={`px-1 py-0.5 text-xs rounded ${
                      tx.type === 'BUY' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'
                    }`}>
                      {tx.type === 'BUY' ? 'Vétel' : 'Eladás'}
                    </span>
                  </td>
                  <td className="font-semibold">{tx.currency}</td>
                  <td className="text-right font-mono">{tx.amount.toLocaleString()}</td>
                  <td className="text-gray-600">{tx.customer}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Quick actions */}
      <div className="form-panel">
        <h2 className="font-semibold mb-2">Gyorsműveletek</h2>
        <div className="flex gap-2">
          <Link to="/transactions/new" className="form-button-primary flex items-center gap-1">
            <ArrowLeftRight size={16} />
            Új tranzakció
          </Link>
          <Link to="/customers/new" className="form-button flex items-center gap-1">
            <Users size={16} />
            Új ügyfél
          </Link>
          <Link to="/rates" className="form-button flex items-center gap-1">
            <TrendingUp size={16} />
            Árfolyam módosítás
          </Link>
          <Link to="/cashdesk" className="form-button flex items-center gap-1">
            <Wallet size={16} />
            Pénztár zárás
          </Link>
        </div>
      </div>
    </div>
  )
}

function StatCard({ 
  icon: Icon, 
  label, 
  value, 
  color 
}: { 
  icon: React.ElementType
  label: string
  value: string | number
  color: 'primary' | 'success' | 'warning' | 'info'
}) {
  const colorClasses = {
    primary: 'bg-primary-50 border-primary-200 text-primary-700',
    success: 'bg-green-50 border-green-200 text-green-700',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-700',
    info: 'bg-blue-50 border-blue-200 text-blue-700',
  }

  return (
    <div className={`form-panel border ${colorClasses[color]}`}>
      <div className="flex items-center gap-2 mb-1">
        <Icon size={18} />
        <span className="text-sm">{label}</span>
      </div>
      <div className="text-2xl font-bold">{value}</div>
    </div>
  )
}
