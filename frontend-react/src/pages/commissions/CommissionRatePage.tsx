import { useState, useEffect } from 'react'
import { Percent } from 'lucide-react'
import { commissionRateApi, CommissionRate } from '../../services/api'

export default function CommissionRatePage() {
  const [rates, setRates] = useState<CommissionRate[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setRates(await commissionRateApi.list())
    } catch (error) {
      console.error('Hiba:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><Percent />Jutalék mértékek</h1>
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Entitás típus</th><th>Entitás</th><th>Valuta</th><th>Mérték</th><th>Érvényesség</th></tr></thead>
            <tbody>
              {rates.map(r => (
                <tr key={r.id}>
                  <td>{r.entityType}</td>
                  <td>{r.entityName || '-'}</td>
                  <td>{r.currencyCode || '-'}</td>
                  <td>{r.rate}</td>
                  <td>{r.validFrom} - {r.validTo || 'jelenleg'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

