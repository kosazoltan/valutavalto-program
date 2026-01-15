import { useState, useEffect } from 'react'
import { Users, Search, Calendar, Download } from 'lucide-react'
import { workerCommissionApi, WorkerCommission } from '../../services/api'
import { formatInteger, formatDecimal } from '../../utils/numberFormat'

export default function WorkerCommissionPage() {
  const [commissions, setCommissions] = useState<WorkerCommission[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [filteredCommissions, setFilteredCommissions] = useState<WorkerCommission[]>([])
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')

  useEffect(() => {
    void loadData()
  }, [])

  useEffect(() => {
    filterCommissions()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [commissions, searchTerm])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await workerCommissionApi.list()
      setCommissions(data)
    } catch (err) {
      console.error('Jutalékok betöltési hiba:', err)
      setError('Hiba a jutalékok betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const filterCommissions = () => {
    let filtered = commissions
    if (searchTerm) {
      filtered = filtered.filter(c =>
        c.workerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.branchName?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }
    setFilteredCommissions(filtered)
  }

  const handleFilterByPeriod = async () => {
    if (!startDate || !endDate) {
      alert('Kérjük, adja meg az időszakot')
      return
    }
    try {
      setError(null)
      const data = await workerCommissionApi.getByPeriod(startDate, endDate)
      setCommissions(data)
    } catch (err) {
      console.error('Szűrési hiba:', err)
      setError('Hiba történt az időszak szűrése során')
    }
  }

  const handleExportAccountingList = async () => {
    if (!startDate || !endDate) {
      alert('Kérjük, adja meg az időszakot')
      return
    }
    try {
      setError(null)
      await workerCommissionApi.getAccountingList(startDate, endDate)
      // TODO: Implement CSV export
    } catch (err) {
      console.error('Export hiba:', err)
      setError('Hiba történt az export során')
    }
  }

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Users />
          Dolgozói Jutalékok
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel space-y-4">
        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="form-label">Kezdő dátum</label>
            <input
              type="date"
              className="form-input"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label">Vég dátum</label>
            <input
              type="date"
              className="form-input"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
            />
          </div>
          <div className="flex items-end gap-2">
            <button
              onClick={handleFilterByPeriod}
              className="form-button-primary flex items-center gap-2"
            >
              <Calendar size={16} />
              Szűrés
            </button>
            <button
              onClick={handleExportAccountingList}
              className="form-button flex items-center gap-2"
            >
              <Download size={16} />
              Export
            </button>
          </div>
          <div>
            <label className="form-label">Keresés</label>
            <div className="relative">
              <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
              <input
                type="text"
                className="form-input pl-8"
                placeholder="Dolgozó vagy fiók..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Dolgozó</th>
              <th>Fők</th>
              <th>Időszak</th>
              <th>Tranzakciók</th>
              <th>Összeg</th>
              <th>Jutalék %</th>
              <th>Jutalék összeg</th>
              <th>Státusz</th>
            </tr>
          </thead>
          <tbody>
            {filteredCommissions.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">Nincs találat</td>
              </tr>
            ) : (
              filteredCommissions.map((c) => (
                <tr key={c.id}>
                  <td>{c.workerName}</td>
                  <td>{c.branchName || '-'}</td>
                  <td>{c.periodStart} - {c.periodEnd}</td>
                  <td>{c.transactionCount || 0}</td>
                  <td className="font-mono">{c.totalTransactionAmount ? formatInteger(c.totalTransactionAmount) : '0'} {c.currencyCode}</td>
                  <td className="font-mono">{c.commissionRate ? `${formatDecimal(c.commissionRate * 100, 2, 2)}%` : '-'}</td>
                  <td className="font-bold font-mono">{c.commissionAmount ? formatInteger(c.commissionAmount) : '0'} {c.currencyCode}</td>
                  <td>
                    <span className={`badge ${c.statusName === 'Jóváhagyva' ? 'badge-green' : 'badge-yellow'}`}>
                      {c.statusName}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

