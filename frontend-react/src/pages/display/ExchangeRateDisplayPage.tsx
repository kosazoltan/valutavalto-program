import { useState, useEffect } from 'react'
import { Monitor, RefreshCw } from 'lucide-react'
import { exchangeRateDisplayApi, ExchangeRateDisplay } from '../../services/api'

export default function ExchangeRateDisplayPage() {
  const [displays, setDisplays] = useState<ExchangeRateDisplay[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      setDisplays(await exchangeRateDisplayApi.list())
    } catch (err) {
      console.error('Kijelzők betöltési hiba:', err)
      setError('Hiba a kijelzők betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleRefresh = async (id: string) => {
    try {
      setError(null)
      await exchangeRateDisplayApi.updateDisplay(id, {})
      alert('Kijelző frissítve')
    } catch (err) {
      console.error('Kijelző frissítési hiba:', err)
      setError('Hiba történt a kijelző frissítésekor')
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><Monitor />Árfolyam kijelzők</h1>
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Név</th><th>Frissítési idő</th><th>Státusz</th><th>Műveletek</th></tr></thead>
            <tbody>
              {displays.map(d => (
                <tr key={d.id}>
                  <td>{d.displayName}</td>
                  <td>{d.refreshInterval}s</td>
                  <td><span className={`badge ${d.isActive ? 'badge-green' : 'badge-gray'}`}>{d.isActive ? 'Aktív' : 'Inaktív'}</span></td>
                  <td><button onClick={() => handleRefresh(d.id)} className="form-button text-xs"><RefreshCw size={12} />Frissítés</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
