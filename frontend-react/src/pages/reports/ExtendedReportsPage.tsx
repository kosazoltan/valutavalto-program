import { useState } from 'react'
import { FileText, Calendar } from 'lucide-react'
import { reportExtendedApi } from '../../services/api'

export default function ExtendedReportsPage() {
  const [reportType, setReportType] = useState('transaction-list')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [year, setYear] = useState(new Date().getFullYear())
  const [month, setMonth] = useState(new Date().getMonth() + 1)
  const [branchId] = useState<string | undefined>(undefined)
  const [loading, setLoading] = useState(false)
  const [reportData, setReportData] = useState<Record<string, unknown> | null>(null)

  const handleGenerateReport = async () => {
    try {
      setLoading(true)
      let data
      switch (reportType) {
        case 'transaction-list':
          data = await reportExtendedApi.getTransactionList(branchId, startDate, endDate)
          break
        case 'receipt-list':
          data = await reportExtendedApi.getReceiptList(branchId, startDate, endDate)
          break
        case 'fee-summary':
          data = await reportExtendedApi.getFeeSummary(branchId, startDate, endDate)
          break
        case 'monthly-inventory':
          data = await reportExtendedApi.getMonthlyInventory(branchId, year, month)
          break
        case 'monthly-turnover':
          data = await reportExtendedApi.getMonthlyTurnover(branchId, year, month)
          break
        case 'monthly-transfers':
          data = await reportExtendedApi.getMonthlyTransfers(branchId, year, month)
          break
        case 'handling-cost':
          data = await reportExtendedApi.getHandlingCost(branchId, startDate, endDate)
          break
        case 'suspicious-transactions':
          data = await reportExtendedApi.getSuspiciousTransactions(branchId, startDate, endDate)
          break
        case 'card-transaction-fees':
          data = await reportExtendedApi.getCardTransactionFees(branchId, startDate, endDate)
          break
        default:
          return
      }
      setReportData(data as Record<string, unknown>)
    } catch (error) {
      console.error('Hiba a riport generálásánál:', error)
      alert('Hiba történt a riport generálása során')
    } finally {
      setLoading(false)
    }
  }

  const reportTypes = [
    { value: 'transaction-list', label: 'Tranzakció lista' },
    { value: 'receipt-list', label: 'Bizonylat lista' },
    { value: 'fee-summary', label: 'Díj összesítés' },
    { value: 'monthly-inventory', label: 'Havi készlet' },
    { value: 'monthly-turnover', label: 'Havi forgalom' },
    { value: 'monthly-transfers', label: 'Havi átutalások' },
    { value: 'handling-cost', label: 'Kezelési költség' },
    { value: 'suspicious-transactions', label: 'Gyanús tranzakciók' },
    { value: 'card-transaction-fees', label: 'Kártyás tranzakció díjak' }
  ]

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          Bővített Riportok
        </h1>
      </div>

      <div className="form-panel space-y-4">
        <div>
          <label className="form-label">Riport típus</label>
          <select className="form-input" value={reportType} onChange={(e) => setReportType(e.target.value)}>
            {reportTypes.map(rt => <option key={rt.value} value={rt.value}>{rt.label}</option>)}
          </select>
        </div>

        {(reportType === 'monthly-inventory' || reportType === 'monthly-turnover' || reportType === 'monthly-transfers') ? (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="form-label">Év</label>
              <input type="number" className="form-input" value={year} onChange={(e) => setYear(parseInt(e.target.value))} />
            </div>
            <div>
              <label className="form-label">Hónap</label>
              <input type="number" className="form-input" min="1" max="12" value={month} onChange={(e) => setMonth(parseInt(e.target.value))} />
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="form-label">Kezdő dátum</label>
              <input type="date" className="form-input" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
            </div>
            <div>
              <label className="form-label">Vég dátum</label>
              <input type="date" className="form-input" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
            </div>
          </div>
        )}

        <button onClick={handleGenerateReport} disabled={loading} className="form-button-primary flex items-center gap-2">
          <Calendar size={16} />
          {loading ? 'Generálás...' : 'Riport generálása'}
        </button>
      </div>

      {reportData && (
        <div className="form-panel">
          <h2 className="text-lg font-bold mb-4">Riport eredmények</h2>
          <pre className="bg-gray-50 p-4 rounded overflow-auto max-h-96">{JSON.stringify(reportData, null, 2)}</pre>
        </div>
      )}
    </div>
  )
}

