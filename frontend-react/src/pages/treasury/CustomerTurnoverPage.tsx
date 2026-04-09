import { useState, useEffect, useCallback } from 'react'
import { Users, Calendar, RefreshCw } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'

interface CustomerTurnover {
  branchCode: string
  branchName: string
  currencyCode: string
  soldAmount: number
  boughtAmount: number
  sellCount: number
  buyCount: number
}

export default function CustomerTurnoverPage() {
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10))
  const [data, setData] = useState<CustomerTurnover[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchData = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await api.get(`/treasury/customer-turnover?date=${date}`)
      setData(Array.isArray(res.data) ? res.data : [])
    } catch (err) {
      logger.error('CustomerTurnoverPage', 'Fetch failed', err)
      setError('Nem sikerült betölteni az adatokat. Próbáld újra.')
    } finally {
      setLoading(false)
    }
  }, [date])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const formatNum = (n: number) =>
    n != null ? new Intl.NumberFormat('hu-HU', { maximumFractionDigits: 2 }).format(n) : '0'

  // Csoportosítás irodánként
  const grouped = data.reduce<Record<string, CustomerTurnover[]>>((acc, row) => {
    const key = `${row.branchCode} — ${row.branchName}`
    if (!acc[key]) acc[key] = []
    acc[key].push(row)
    return acc
  }, {})

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Users className="h-5 w-5 text-blue-600" />
          <h2 className="text-xl font-semibold">Ügyfélforgalom összesítő</h2>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-gray-500" />
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="rounded border px-3 py-1.5 text-sm"
            />
          </div>
          <button
            onClick={fetchData}
            disabled={loading}
            className="flex items-center gap-1.5 rounded bg-gray-100 px-3 py-1.5 text-sm hover:bg-gray-200"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded border border-red-300 bg-red-50 p-4 text-sm text-red-700">
          {error}
          <button onClick={fetchData} className="ml-3 underline">Újra</button>
        </div>
      )}

      {Object.entries(grouped).map(([branchLabel, rows]) => (
        <div key={branchLabel} className="rounded border bg-white p-4 shadow-sm">
          <h3 className="mb-2 font-medium">{branchLabel}</h3>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-gray-50 text-left">
                <th className="px-3 py-2">Valutanem</th>
                <th className="px-3 py-2 text-right">Eladott</th>
                <th className="px-3 py-2 text-right">Vett</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.currencyCode} className="border-b">
                  <td className="px-3 py-1.5 font-mono">{row.currencyCode}</td>
                  <td className="px-3 py-1.5 text-right">{formatNum(row.soldAmount)}</td>
                  <td className="px-3 py-1.5 text-right">{formatNum(row.boughtAmount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ))}

      {!loading && data.length === 0 && (
        <p className="py-8 text-center text-gray-400">Nincs ügyfélforgalom a kiválasztott napra.</p>
      )}

      {loading && (
        <div className="flex justify-center py-12">
          <RefreshCw className="h-6 w-6 animate-spin text-gray-400" />
        </div>
      )}
    </div>
  )
}
