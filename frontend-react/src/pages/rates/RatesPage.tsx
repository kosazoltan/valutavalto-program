import { useState } from 'react'
import { TrendingUp, RefreshCw, Edit, Save, X, Clock, Download, Upload } from 'lucide-react'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'

const mockRates = [
  { code: 'EUR', name: 'Euró', buyRate: 392.50, sellRate: 398.50, mnbRate: 395.80, lastUpdate: '10:30' },
  { code: 'USD', name: 'USA Dollár', buyRate: 358.20, sellRate: 365.80, mnbRate: 362.15, lastUpdate: '10:30' },
  { code: 'GBP', name: 'Angol Font', buyRate: 456.80, sellRate: 468.20, mnbRate: 462.50, lastUpdate: '10:30' },
  { code: 'CHF', name: 'Svájci Frank', buyRate: 408.50, sellRate: 418.50, mnbRate: 413.25, lastUpdate: '10:30' },
  { code: 'CZK', name: 'Cseh Korona', buyRate: 15.80, sellRate: 16.40, mnbRate: 16.10, lastUpdate: '10:30' },
  { code: 'PLN', name: 'Lengyel Zloty', buyRate: 92.50, sellRate: 96.50, mnbRate: 94.30, lastUpdate: '10:30' },
  { code: 'RON', name: 'Román Lej', buyRate: 78.50, sellRate: 82.50, mnbRate: 80.20, lastUpdate: '10:30' },
  { code: 'HRK', name: 'Horvát Kuna', buyRate: 52.20, sellRate: 54.80, mnbRate: 53.45, lastUpdate: '10:30' },
  { code: 'RSD', name: 'Szerb Dinár', buyRate: 3.35, sellRate: 3.55, mnbRate: 3.45, lastUpdate: '10:30' },
  { code: 'UAH', name: 'Ukrán Hrivnya', buyRate: 8.80, sellRate: 9.40, mnbRate: 9.10, lastUpdate: '10:30' },
]

export default function RatesPage() {
  const [rates, setRates] = useState(mockRates)
  const [editingCode, setEditingCode] = useState<string | null>(null)
  const [editValues, setEditValues] = useState({ buyRate: 0, sellRate: 0 })

  const startEdit = (rate: typeof mockRates[0]) => {
    setEditingCode(rate.code)
    setEditValues({ buyRate: rate.buyRate, sellRate: rate.sellRate })
  }

  const saveEdit = (code: string) => {
    setRates(rates.map(r => 
      r.code === code 
        ? { ...r, buyRate: editValues.buyRate, sellRate: editValues.sellRate, lastUpdate: new Date().toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }) }
        : r
    ))
    setEditingCode(null)
  }

  const cancelEdit = () => {
    setEditingCode(null)
  }

  const getSpread = (buy: number, sell: number) => {
    return ((sell - buy) / buy * 100).toFixed(2)
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <TrendingUp />
          Árfolyamok
        </h1>
        <div className="flex gap-2">
          <button className="form-button flex items-center gap-1">
            <Download size={16} />
            MNB letöltés
          </button>
          <button className="form-button flex items-center gap-1">
            <Upload size={16} />
            Import
          </button>
          <button className="form-button-primary flex items-center gap-1">
            <RefreshCw size={16} />
            Frissítés
          </button>
        </div>
      </div>

      {/* Info Banner */}
      <div className="form-panel bg-blue-50 border-blue-200 flex items-center gap-2">
        <Clock size={16} className="text-blue-600" />
        <span className="text-sm text-blue-800">
          Utolsó frissítés: 2024-05-20 10:30:00 | MNB árfolyam dátuma: 2024-05-20
        </span>
      </div>

      {/* Rates Table */}
      <div className="form-panel p-0">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th className="w-20">Kód</th>
              <th>Megnevezés</th>
              <th className="text-right w-28">Vételi ár</th>
              <th className="text-right w-28">Eladási ár</th>
              <th className="text-right w-28">MNB közép</th>
              <th className="text-right w-24">Spread %</th>
              <th className="w-20">Frissítve</th>
              <th className="w-24">Művelet</th>
            </tr>
          </thead>
          <tbody>
            {rates.map((rate) => (
              <tr key={rate.code}>
                <td>
                  <span className="font-mono font-bold text-blue-600">{rate.code}</span>
                </td>
                <td>{rate.name}</td>
                <td className="text-right">
                  {editingCode === rate.code ? (
                    <NumberInput
                      value={editValues.buyRate.toString().replace('.', ',')}
                      onChange={(val) => setEditValues({ ...editValues, buyRate: parseFloat(val.replace(',', '.')) || 0 })}
                      className="form-input w-24 text-right"
                      allowDecimals={true}
                      allowNegative={false}
                      step="0.01"
                    />
                  ) : (
                    <span className="font-mono text-green-600">{formatDecimal(rate.buyRate, 2, 2)}</span>
                  )}
                </td>
                <td className="text-right">
                  {editingCode === rate.code ? (
                    <NumberInput
                      value={editValues.sellRate.toString().replace('.', ',')}
                      onChange={(val) => setEditValues({ ...editValues, sellRate: parseFloat(val.replace(',', '.')) || 0 })}
                      className="form-input w-24 text-right"
                      allowDecimals={true}
                      allowNegative={false}
                      step="0.01"
                    />
                  ) : (
                    <span className="font-mono text-red-600">{formatDecimal(rate.sellRate, 2, 2)}</span>
                  )}
                </td>
                <td className="text-right font-mono text-gray-600">{formatDecimal(rate.mnbRate, 2, 2)}</td>
                <td className="text-right">
                  <span className="text-xs font-mono bg-gray-100 px-2 py-0.5 rounded">
                    {formatDecimal(parseFloat(getSpread(rate.buyRate, rate.sellRate)), 2, 2)}%
                  </span>
                </td>
                <td className="text-center text-sm text-gray-500">{rate.lastUpdate}</td>
                <td>
                  {editingCode === rate.code ? (
                    <div className="flex gap-1">
                      <button 
                        onClick={() => saveEdit(rate.code)} 
                        className="toolbar-button text-green-600"
                        title="Mentés"
                      >
                        <Save size={14} />
                      </button>
                      <button 
                        onClick={cancelEdit} 
                        className="toolbar-button text-red-600"
                        title="Mégse"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ) : (
                    <button 
                      onClick={() => startEdit(rate)} 
                      className="toolbar-button"
                      title="Szerkesztés"
                    >
                      <Edit size={14} />
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-3 gap-3">
        <div className="form-panel">
          <h3 className="font-semibold mb-2">Gyors árfolyam módosítás</h3>
          <div className="space-y-2">
            <div className="flex gap-2">
              <input type="text" className="form-input flex-1" placeholder="Valuta kód" />
              <NumberInput value="" onChange={() => {}} className="form-input w-24" placeholder="0,00" allowDecimals={true} allowNegative={false} step="0.01" />
              <NumberInput value="" onChange={() => {}} className="form-input w-24" placeholder="0,00" allowDecimals={true} allowNegative={false} step="0.01" />
              <button className="form-button-primary">OK</button>
            </div>
          </div>
        </div>
        
        <div className="form-panel">
          <h3 className="font-semibold mb-2">Spread beállítás</h3>
          <div className="space-y-2">
            <div className="flex gap-2 items-center">
              <span className="text-sm">Minden valutára:</span>
              <NumberInput value="" onChange={() => {}} step="0.1" className="form-input w-20" placeholder="%" allowDecimals={true} allowNegative={false} />
              <button className="form-button">Alkalmaz</button>
            </div>
          </div>
        </div>

        <div className="form-panel">
          <h3 className="font-semibold mb-2">MNB árfolyam</h3>
          <div className="text-sm text-gray-600">
            <p>Automatikus letöltés: <span className="text-green-600 font-semibold">Aktív</span></p>
            <p>Következő frissítés: 11:30</p>
          </div>
        </div>
      </div>
    </div>
  )
}
