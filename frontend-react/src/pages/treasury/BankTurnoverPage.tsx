import { useState, useEffect, useCallback } from 'react'
import { Landmark, Calendar, RefreshCw } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'

interface BankTurnover {
  companyCode: string
  companyName: string
  currencyCode: string
  withdrawnAmount: number
  depositedAmount: number
  netFlow: number
}

export default function BankTurnoverPage() {
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10))
  const [data, setData] = useState<BankTurnover[]>([])
  const [loading, setLoading] = useState(false)

  const fetchData = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get(`/treasury/bank-turnover?date=${date}`)
      setData(Array.isArray(res.data) ? res.data : [])
    } catch (err) {
      logger.error('BankTurnoverPage', 'Fetch failed', err)
    } finally {
      setLoading(false)
    }
  }, [date])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const formatNum = (n: number) =>
    n != null ? new Intl.NumberFormat('hu-HU', { maximumFractionDigits: 2 }).format(n) : '0'

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Landmark className="h-5 w-5 text-green-600" />
          <h2 className="text-xl font-semibold">Bankforgalom összesítő</h2>
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

      {data.length > 0 && (
        <div className="rounded border bg-white p-4 shadow-sm">
          <h3 className="mb-2 font-medium">{data[0]?.companyName ?? 'Bankforgalom'}</h3>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-gray-50 text-left">
                <th className="px-3 py-2">Valutanem</th>
                <th className="px-3 py-2 text-right">Felvett (KP)</th>
                <th className="px-3 py-2 text-right">Kifizetett (KP)</th>
                <th className="px-3 py-2 text-right">Netto</th>
              </tr>
            </thead>
            <tbody>
              {data.map((row) => (
                <tr key={row.currencyCode} className="border-b">
                  <td className="px-3 py-1.5 font-mono">{row.currencyCode}</td>
                  <td className="px-3 py-1.5 text-right">{formatNum(row.withdrawnAmount)}</td>
                  <td className="px-3 py-1.5 text-right">{formatNum(row.depositedAmount)}</td>
                  <td className={`px-3 py-1.5 text-right font-medium ${
                    row.netFlow > 0 ? 'text-green-600' : row.netFlow < 0 ? 'text-red-600' : ''
                  }`}>
                    {formatNum(row.netFlow)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {!loading && data.length === 0 && (
        <p className="py-8 text-center text-gray-400">Nincs bankforgalom a kiválasztott napra.</p>
      )}

      {loading && (
        <div className="flex justify-center py-12">
          <RefreshCw className="h-6 w-6 animate-spin text-gray-400" />
        </div>
      )}
    </div>
  )
}
