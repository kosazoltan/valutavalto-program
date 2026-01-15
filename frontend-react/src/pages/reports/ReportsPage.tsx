import { useState } from 'react'
import { FileText, Download, Calendar, BarChart3, PieChart, TrendingUp, FileSpreadsheet, Printer } from 'lucide-react'

const reportTypes = [
  { id: 'daily', name: 'Napi jelentés', icon: Calendar, description: 'Napi tranzakciók és forgalom összesítése' },
  { id: 'monthly', name: 'Havi kimutatás', icon: BarChart3, description: 'Havi forgalmi adatok' },
  { id: 'currency', name: 'Valuta statisztika', icon: PieChart, description: 'Valutánkénti bontás' },
  { id: 'profit', name: 'Eredmény kimutatás', icon: TrendingUp, description: 'Profit és veszteség' },
  { id: 'customer', name: 'Ügyfél statisztika', icon: FileText, description: 'Ügyfélenkénti forgalom' },
  { id: 'mnb', name: 'MNB jelentés', icon: FileSpreadsheet, description: 'Hatósági jelentés' },
]

export default function ReportsPage() {
  const [selectedReport, setSelectedReport] = useState('daily')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          Riportok
        </h1>
      </div>

      <div className="grid grid-cols-4 gap-3">
        {/* Report Type Selection */}
        <div className="form-panel">
          <h2 className="section-title">Riport típusa</h2>
          <div className="space-y-1">
            {reportTypes.map((report) => {
              const Icon = report.icon
              return (
                <button
                  key={report.id}
                  onClick={() => setSelectedReport(report.id)}
                  className={`w-full text-left p-2 rounded flex items-center gap-2 transition-colors ${
                    selectedReport === report.id
                      ? 'bg-blue-100 text-blue-800 border border-blue-300'
                      : 'hover:bg-gray-100'
                  }`}
                >
                  <Icon size={16} />
                  <span className="text-sm font-medium">{report.name}</span>
                </button>
              )
            })}
          </div>
        </div>

        {/* Report Options & Preview */}
        <div className="col-span-3 space-y-3">
          {/* Date Range */}
          <div className="form-panel">
            <h2 className="section-title">Időszak</h2>
            <div className="flex gap-3 items-center">
              <div>
                <label className="form-label">Kezdő dátum</label>
                <input
                  type="date"
                  value={dateFrom}
                  onChange={(e) => setDateFrom(e.target.value)}
                  className="form-input"
                />
              </div>
              <div>
                <label className="form-label">Záró dátum</label>
                <input
                  type="date"
                  value={dateTo}
                  onChange={(e) => setDateTo(e.target.value)}
                  className="form-input"
                />
              </div>
              <div className="flex gap-2 pt-5">
                <button className="form-button text-sm" onClick={() => { 
                  const today = new Date().toISOString().split('T')[0]
                  setDateFrom(today || '')
                  setDateTo(today || '')
                }}>Ma</button>
                <button className="form-button text-sm" onClick={() => {
                  const today = new Date()
                  const firstDay = new Date(today.getFullYear(), today.getMonth(), 1)
                  setDateFrom(firstDay.toISOString().split('T')[0] || '')
                  setDateTo(today.toISOString().split('T')[0] || '')
                }}>Hónap</button>
                <button className="form-button text-sm" onClick={() => {
                  const today = new Date()
                  const firstDay = new Date(today.getFullYear(), 0, 1)
                  setDateFrom(firstDay.toISOString().split('T')[0] || '')
                  setDateTo(today.toISOString().split('T')[0] || '')
                }}>Év</button>
              </div>
            </div>
          </div>

          {/* Report Preview */}
          <div className="form-panel">
            <div className="flex justify-between items-center mb-3">
              <h2 className="section-title">
                {reportTypes.find(r => r.id === selectedReport)?.name}
              </h2>
              <div className="flex gap-2">
                <button className="form-button flex items-center gap-1">
                  <Printer size={16} />
                  Nyomtatás
                </button>
                <button className="form-button flex items-center gap-1">
                  <Download size={16} />
                  Excel
                </button>
                <button className="form-button-primary flex items-center gap-1">
                  <Download size={16} />
                  PDF
                </button>
              </div>
            </div>

            {/* Sample Report Content */}
            {selectedReport === 'daily' && (
              <div className="space-y-4">
                <div className="grid grid-cols-4 gap-3">
                  <div className="bg-blue-50 p-3 rounded">
                    <div className="text-sm text-blue-600">Tranzakciók</div>
                    <div className="text-2xl font-bold">45</div>
                  </div>
                  <div className="bg-green-50 p-3 rounded">
                    <div className="text-sm text-green-600">Vétel</div>
                    <div className="text-2xl font-bold">2.5M Ft</div>
                  </div>
                  <div className="bg-red-50 p-3 rounded">
                    <div className="text-sm text-red-600">Eladás</div>
                    <div className="text-2xl font-bold">1.8M Ft</div>
                  </div>
                  <div className="bg-purple-50 p-3 rounded">
                    <div className="text-sm text-purple-600">Eredmény</div>
                    <div className="text-2xl font-bold">125K Ft</div>
                  </div>
                </div>

                <table className="data-grid w-full">
                  <thead>
                    <tr>
                      <th>Valuta</th>
                      <th className="text-right">Vétel db</th>
                      <th className="text-right">Vétel összeg</th>
                      <th className="text-right">Eladás db</th>
                      <th className="text-right">Eladás összeg</th>
                      <th className="text-right">Eredmény</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td className="font-mono font-bold">EUR</td>
                      <td className="text-right">12</td>
                      <td className="text-right font-mono">4,500</td>
                      <td className="text-right">8</td>
                      <td className="text-right font-mono">3,200</td>
                      <td className="text-right font-mono text-green-600">+45,000 Ft</td>
                    </tr>
                    <tr>
                      <td className="font-mono font-bold">USD</td>
                      <td className="text-right">8</td>
                      <td className="text-right font-mono">3,200</td>
                      <td className="text-right">5</td>
                      <td className="text-right font-mono">2,100</td>
                      <td className="text-right font-mono text-green-600">+32,000 Ft</td>
                    </tr>
                    <tr>
                      <td className="font-mono font-bold">GBP</td>
                      <td className="text-right">4</td>
                      <td className="text-right font-mono">1,800</td>
                      <td className="text-right">3</td>
                      <td className="text-right font-mono">1,200</td>
                      <td className="text-right font-mono text-green-600">+28,000 Ft</td>
                    </tr>
                    <tr>
                      <td className="font-mono font-bold">CHF</td>
                      <td className="text-right">3</td>
                      <td className="text-right font-mono">900</td>
                      <td className="text-right">2</td>
                      <td className="text-right font-mono">600</td>
                      <td className="text-right font-mono text-green-600">+20,000 Ft</td>
                    </tr>
                  </tbody>
                  <tfoot>
                    <tr className="font-bold bg-gray-100">
                      <td>ÖSSZESEN</td>
                      <td className="text-right">27</td>
                      <td className="text-right font-mono">10,400</td>
                      <td className="text-right">18</td>
                      <td className="text-right font-mono">7,100</td>
                      <td className="text-right font-mono text-green-600">+125,000 Ft</td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            )}

            {selectedReport === 'currency' && (
              <div className="grid grid-cols-2 gap-4">
                <div className="h-64 bg-gray-100 rounded flex items-center justify-center">
                  <span className="text-gray-500">Kördiagram helye</span>
                </div>
                <div className="space-y-2">
                  {['EUR', 'USD', 'GBP', 'CHF', 'Egyéb'].map((currency, index) => (
                    <div key={currency} className="flex items-center gap-2">
                      <div 
                        className="w-4 h-4 rounded"
                        style={{ backgroundColor: ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'][index] }}
                      />
                      <span className="font-mono">{currency}</span>
                      <div className="flex-1 h-2 bg-gray-200 rounded">
                        <div 
                          className="h-full rounded"
                          style={{ 
                            width: ['45%', '25%', '15%', '10%', '5%'][index],
                            backgroundColor: ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'][index]
                          }}
                        />
                      </div>
                      <span className="text-sm text-gray-500">{['45%', '25%', '15%', '10%', '5%'][index]}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {(selectedReport !== 'daily' && selectedReport !== 'currency') && (
              <div className="h-64 bg-gray-50 rounded flex items-center justify-center">
                <span className="text-gray-500">Válasszon időszakot a riport megjelenítéséhez</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
