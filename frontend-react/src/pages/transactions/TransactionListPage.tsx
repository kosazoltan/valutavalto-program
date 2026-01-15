import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Search, Plus, FileText, Printer, Eye, XCircle } from 'lucide-react'

const mockTransactions = [
  { id: '1', date: '2024-11-26 10:45', type: 'BUY', currency: 'EUR', foreignAmount: 500, hufAmount: 195750, rate: 391.50, customer: 'Kiss János', status: 'COMPLETED' },
  { id: '2', date: '2024-11-26 10:32', type: 'SELL', currency: 'USD', foreignAmount: 1000, hufAmount: 358200, rate: 358.20, customer: 'Nagy Péter', status: 'COMPLETED' },
  { id: '3', date: '2024-11-26 10:15', type: 'BUY', currency: 'GBP', foreignAmount: 200, hufAmount: 91000, rate: 455.00, customer: 'Szabó Anna', status: 'COMPLETED' },
  { id: '4', date: '2024-11-26 09:55', type: 'SELL', currency: 'CHF', foreignAmount: 300, hufAmount: 120750, rate: 402.50, customer: null, status: 'COMPLETED' },
  { id: '5', date: '2024-11-26 09:30', type: 'BUY', currency: 'EUR', foreignAmount: 1500, hufAmount: 587250, rate: 391.50, customer: 'Tóth Béla', status: 'CANCELLED' },
]

export default function TransactionListPage() {
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [typeFilter, setTypeFilter] = useState<string>('')
  const [currencyFilter, setCurrencyFilter] = useState<string>('')

  const filteredTransactions = mockTransactions.filter(tx => {
    if (search && !tx.customer?.toLowerCase().includes(search.toLowerCase())) return false
    if (typeFilter && tx.type !== typeFilter) return false
    if (currencyFilter && tx.currency !== currencyFilter) return false
    return true
  })

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          Tranzakciók
        </h1>
        <Link to="/transactions/new" className="form-button-primary flex items-center gap-1">
          <Plus size={16} />
          Új tranzakció
        </Link>
      </div>

      {/* Filters */}
      <div className="form-panel">
        <div className="flex gap-3 items-end">
          <div className="flex-1">
            <label className="form-label">Keresés</label>
            <div className="flex gap-1">
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="form-input flex-1"
                placeholder="Ügyfél neve..."
              />
              <button className="form-button">
                <Search size={16} />
              </button>
            </div>
          </div>
          <div>
            <label className="form-label">Dátum -tól</label>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="form-input"
            />
          </div>
          <div>
            <label className="form-label">Dátum -ig</label>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="form-input"
            />
          </div>
          <div>
            <label className="form-label">Típus</label>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="form-input"
            >
              <option value="">Mind</option>
              <option value="BUY">Vétel</option>
              <option value="SELL">Eladás</option>
            </select>
          </div>
          <div>
            <label className="form-label">Deviza</label>
            <select
              value={currencyFilter}
              onChange={(e) => setCurrencyFilter(e.target.value)}
              className="form-input"
            >
              <option value="">Mind</option>
              <option value="EUR">EUR</option>
              <option value="USD">USD</option>
              <option value="GBP">GBP</option>
              <option value="CHF">CHF</option>
            </select>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="form-panel p-0">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Dátum/Idő</th>
              <th>Típus</th>
              <th>Deviza</th>
              <th className="text-right">Deviza összeg</th>
              <th className="text-right">Árfolyam</th>
              <th className="text-right">HUF összeg</th>
              <th>Ügyfél</th>
              <th>Státusz</th>
              <th className="w-24">Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filteredTransactions.map((tx) => (
              <tr key={tx.id} className={tx.status === 'CANCELLED' ? 'opacity-50' : ''}>
                <td className="font-mono text-sm">{tx.date}</td>
                <td>
                  <span className={`px-1.5 py-0.5 text-xs rounded ${
                    tx.type === 'BUY' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'
                  }`}>
                    {tx.type === 'BUY' ? 'Vétel' : 'Eladás'}
                  </span>
                </td>
                <td className="font-bold">{tx.currency}</td>
                <td className="text-right font-mono">{tx.foreignAmount.toLocaleString('hu-HU', { minimumFractionDigits: 2 })}</td>
                <td className="text-right font-mono text-gray-600">{tx.rate.toFixed(2)}</td>
                <td className="text-right font-mono font-semibold">{tx.hufAmount.toLocaleString('hu-HU')} Ft</td>
                <td>{tx.customer || <span className="text-gray-400 italic">Névtelen</span>}</td>
                <td>
                  <span className={`px-1.5 py-0.5 text-xs rounded ${
                    tx.status === 'COMPLETED' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {tx.status === 'COMPLETED' ? 'Teljesítve' : 'Sztornózva'}
                  </span>
                </td>
                <td>
                  <div className="flex gap-1">
                    <button 
                      className="toolbar-button" 
                      title="Megtekintés"
                      onClick={() => navigate(`/transactions/${tx.id}`)}
                    >
                      <Eye size={14} />
                    </button>
                    <button 
                      className="toolbar-button" 
                      title="Nyomtatás"
                    >
                      <Printer size={14} />
                    </button>
                    {tx.status === 'COMPLETED' && (
                      <button 
                        className="toolbar-button text-red-600 hover:text-red-700" 
                        title="Sztornó"
                        onClick={() => navigate(`/transactions/${tx.id}/storno`)}
                      >
                        <XCircle size={14} />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Summary */}
      <div className="form-panel">
        <div className="flex justify-between text-sm">
          <span>{filteredTransactions.length} tranzakció</span>
          <span>
            Összesen: <strong className="font-mono">{filteredTransactions.reduce((sum, tx) => sum + tx.hufAmount, 0).toLocaleString('hu-HU')} Ft</strong>
          </span>
        </div>
      </div>
    </div>
  )
}
