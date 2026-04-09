import { useState, useEffect, useCallback } from 'react'
import { FileText, FileSpreadsheet, Calendar, RefreshCw } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'

interface TrbBankFlowLine {
  currencyCode: string
  withdrawn: number
  deposited: number
}

interface TrbCurrencyLine {
  currencyCode: string
  sold: number
  bought: number
  bankCardAmount: number
  bankCardFee: number
}

interface TrbDenominationLine {
  currencyCode: string
  denomination: number
  quantity: number
}

interface TrbBranchReport {
  branchCode: string
  branchName: string
  denominationLines: TrbDenominationLine[]
  customerTurnoverLines: TrbCurrencyLine[]
}

interface TrbExportData {
  companyCode: string
  companyName: string
  reportDate: string
  valueDate: string
  branchReports: TrbBranchReport[]
  bankFlowLines: TrbBankFlowLine[]
}

export default function TrbExportPage() {
  const [date, setDate] = useState(() => {
    const d = new Date()
    d.setDate(d.getDate() - 1)
    return d.toISOString().slice(0, 10)
  })
  const [data, setData] = useState<TrbExportData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchPreview = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await api.get(`/trb-export/preview?date=${date}`)
      setData(res.data)
    } catch (err) {
      logger.error('TrbExportPage', 'Preview fetch failed', err)
      setError('Nem sikerült betölteni az adatokat. Próbáld újra.')
    } finally {
      setLoading(false)
    }
  }, [date])

  useEffect(() => {
    fetchPreview()
  }, [fetchPreview])

  const downloadFile = async (format: 'txt' | 'excel') => {
    try {
      const res = await api.get(`/trb-export/${format}?date=${date}`, { responseType: 'blob' })
      const ext = format === 'txt' ? 'txt' : 'xlsx'
      const mime = format === 'txt' ? 'text/plain' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      const blob = new Blob([res.data], { type: mime })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `trb-export-${date}.${ext}`
      a.click()
      URL.revokeObjectURL(url)
    } catch (err) {
      logger.error('TrbExportPage', `${format} download failed`, err)
    }
  }

  const formatNum = (n: number) =>
    n != null ? new Intl.NumberFormat('hu-HU', { maximumFractionDigits: 4 }).format(n) : '0'

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold">TRB Export — Import felíró</h2>
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
            onClick={fetchPreview}
            disabled={loading}
            className="flex items-center gap-1.5 rounded bg-gray-100 px-3 py-1.5 text-sm hover:bg-gray-200"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            Frissítés
          </button>
          <button
            onClick={() => downloadFile('txt')}
            className="flex items-center gap-1.5 rounded bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700"
          >
            <FileText className="h-4 w-4" />
            TXT letöltés
          </button>
          <button
            onClick={() => downloadFile('excel')}
            className="flex items-center gap-1.5 rounded bg-green-600 px-3 py-1.5 text-sm text-white hover:bg-green-700"
          >
            <FileSpreadsheet className="h-4 w-4" />
            Excel letöltés
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded border border-red-300 bg-red-50 p-4 text-sm text-red-700">
          {error}
          <button onClick={fetchPreview} className="ml-3 underline">Újra</button>
        </div>
      )}

      {data && (
        <div className="rounded border bg-white p-4 shadow-sm">
          <p className="mb-2 text-sm text-gray-500">
            {data.companyName} — {data.reportDate} (tárgynapra: {data.valueDate})
          </p>

          {/* Bankforgalom */}
          {data.bankFlowLines.length > 0 && (
            <div className="mb-3">
              <h3 className="mb-2 font-medium">Bankforgalom</h3>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-gray-50 text-left">
                    <th className="px-3 py-2">Valutanem</th>
                    <th className="px-3 py-2 text-right">Felvett</th>
                    <th className="px-3 py-2 text-right">Kifizetett</th>
                  </tr>
                </thead>
                <tbody>
                  {data.bankFlowLines.map((line) => (
                    <tr key={line.currencyCode} className="border-b">
                      <td className="px-3 py-1.5 font-mono">{line.currencyCode}</td>
                      <td className="px-3 py-1.5 text-right">{formatNum(line.withdrawn)}</td>
                      <td className="px-3 py-1.5 text-right">{formatNum(line.deposited)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Irodánkénti ügyfélforgalom */}
          {data.branchReports.map((branch) => (
            <div key={branch.branchCode} className="mb-3">
              <h3 className="mb-2 font-medium">
                {branch.branchName} ({branch.branchCode})
              </h3>

              {branch.customerTurnoverLines.length > 0 && (
                <div className="mb-3">
                  <h4 className="mb-1 text-sm text-gray-600">Ügyfélforgalom</h4>
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b bg-gray-50 text-left">
                        <th className="px-3 py-1.5">Valutanem</th>
                        <th className="px-3 py-1.5 text-right">Eladott</th>
                        <th className="px-3 py-1.5 text-right">Vett</th>
                      </tr>
                    </thead>
                    <tbody>
                      {branch.customerTurnoverLines.map((line) => (
                        <tr key={line.currencyCode} className="border-b">
                          <td className="px-3 py-1 font-mono">{line.currencyCode}</td>
                          <td className="px-3 py-1 text-right">{formatNum(line.sold)}</td>
                          <td className="px-3 py-1 text-right">{formatNum(line.bought)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {branch.denominationLines.length > 0 && (
                <div>
                  <h4 className="mb-1 text-sm text-gray-600">Pénztárállomány (címlet)</h4>
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b bg-gray-50 text-left">
                        <th className="px-3 py-1.5">Valutanem</th>
                        <th className="px-3 py-1.5 text-right">Címlet</th>
                        <th className="px-3 py-1.5 text-right">Darab</th>
                      </tr>
                    </thead>
                    <tbody>
                      {branch.denominationLines.map((line, idx) => (
                        <tr key={`${line.currencyCode}-${line.denomination}-${idx}`} className="border-b">
                          <td className="px-3 py-1 font-mono">{line.currencyCode}</td>
                          <td className="px-3 py-1 text-right">{formatNum(line.denomination)}</td>
                          <td className="px-3 py-1 text-right">{line.quantity}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ))}

          {data.branchReports.length === 0 && data.bankFlowLines.length === 0 && (
            <p className="py-8 text-center text-gray-400">
              Nincs adat a kiválasztott napra.
            </p>
          )}
        </div>
      )}

      {loading && (
        <div className="flex justify-center py-12">
          <RefreshCw className="h-6 w-6 animate-spin text-gray-400" />
        </div>
      )}
    </div>
  )
}
