import { useState, useCallback } from 'react'
import { BookOpen, Printer, Calendar, RefreshCw } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAuthStore } from '../../stores/authStore'
import { dailyReportApi } from '../../services/api/index'

interface DailyReportData {
  id: string
  branchId: string
  branchName: string
  date: string
  openingBalances: Array<{ currency: string; amount: number }>
  closingBalances: Array<{ currency: string; amount: number }>
  transactions: Array<{
    id: string
    time: string
    type: string
    currency: string
    amount: number
    rate: number
    hufAmount: number
    customerName?: string
    receiptNumber?: string
  }>
  summary: {
    totalBuyCount: number
    totalSellCount: number
    totalBuyHuf: number
    totalSellHuf: number
    totalProfit: number
    handlingFees: number
  }
  status: string
  submittedAt?: string
}

export default function DaybookPage() {
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [date, setDate] = useState(new Date().toISOString().slice(0, 10))
  const [report, setReport] = useState<DailyReportData | null>(null)
  const [loading, setLoading] = useState(false)
  const [generating, setGenerating] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadReport = useCallback(async () => {
    if (!branchId) { toast.warning('Hiányzó adat', 'Fiók kiválasztása szükséges'); return }
    try {
      setLoading(true)
      setError(null)
      const data = await dailyReportApi.get(branchId, date)
      setReport(data as DailyReportData)
    } catch (err) {
      // 2026-04-29 v2.3.11 (E-B12): a Naplókönyv 404 hiba esetén auto-generálás-t
      // próbálunk, mert a tranzakciók már lehetnek a DB-ben, de a daily_report
      // entity még nem készült el. Egyetlen GET → POST → GET próba.
      logger.warn('DaybookPage', 'Napi könyv 404, auto-generate próba:', err)
      try {
        await dailyReportApi.generate(branchId, date)
        const data = await dailyReportApi.get(branchId, date)
        setReport(data as DailyReportData)
        toast.info('Napi könyv', 'Auto-generálás sikeres')
      } catch (genErr) {
        logger.error('DaybookPage', 'Auto-generate sikertelen:', genErr)
        setReport(null)
        setError('Napi könyv nem található erre a napra. Ha vannak tranzakciók, próbálja az "Újragenerálás" gombot.')
      }
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  const handleGenerate = async () => {
    if (!branchId) return
    try {
      setGenerating(true)
      setError(null)
      await dailyReportApi.generate(branchId, date)
      toast.success('Napi könyv generálva')
      await loadReport()
    } catch (err) {
      setError(getErrorMessage(err))
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setGenerating(false)
    }
  }

  const handleSubmit = async () => {
    if (!report) return
    if (!confirm('Biztosan beadja a napi könyvet? Ez nem visszavonható.')) return
    try {
      setError(null)
      await dailyReportApi.submit(report.id)
      toast.success('Napi könyv benyújtva')
      await loadReport()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handlePrint = () => {
    window.print()
  }

  const fmtNum = (n: number) => n.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  const fmtHuf = (n: number) => n.toLocaleString('hu-HU', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) + ' Ft'

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><BookOpen />Napi könyv</h1>
        <div className="flex gap-2">
          {report && (
            <>
              <button onClick={handlePrint} className="form-button"><Printer size={16} /> Nyomtatás</button>
              {report.status !== 'SUBMITTED' && (
                <button onClick={handleSubmit} className="form-button-primary">Benyújtás</button>
              )}
            </>
          )}
        </div>
      </div>

      {/* Dátum választó */}
      <div className="form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">Dátum</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input className="form-input" type="date" value={date} onChange={e => setDate(e.target.value)} />
          </div>
        </div>
        <button onClick={() => void loadReport()} disabled={loading} className="form-button-primary">
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} /> {loading ? 'Betöltés...' : 'Lekérdezés'}
        </button>
        <button onClick={handleGenerate} disabled={generating} className="form-button">
          {generating ? 'Generálás...' : 'Újragenerálás'}
        </button>
      </div>

      {error && (
        <div className="bg-yellow-50 border border-yellow-200 text-yellow-700 px-4 py-3 rounded">{error}</div>
      )}

      {report && (
        <>
          {/* Státusz */}
          <div className="flex gap-3 items-center">
            <span className={`badge ${report.status === 'SUBMITTED' ? 'badge-green' : report.status === 'GENERATED' ? 'badge-blue' : 'badge-gray'}`}>
              {report.status === 'SUBMITTED' ? 'Benyújtva' : report.status === 'GENERATED' ? 'Generálva' : report.status}
            </span>
            {report.submittedAt && <span className="text-sm text-gray-500">Benyújtva: {new Date(report.submittedAt).toLocaleString('hu-HU')}</span>}
            <span className="text-sm text-gray-500">{report.branchName} — {report.date}</span>
          </div>

          {/* Nyitó készlet */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">Nyitó készlet</h2>
            <div className="grid grid-cols-6 gap-2">
              {(report.openingBalances || []).map((b, i) => (
                <div key={i} className="text-center p-2 bg-gray-50 rounded">
                  <div className="font-mono text-sm font-bold">{b.currency}</div>
                  <div className="text-sm">{fmtNum(b.amount)}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Tranzakciók */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">Tranzakciók ({(report.transactions || []).length} db)</h2>
            {(report.transactions || []).length === 0 ? (
              <div className="text-center text-gray-500 py-4">Nincs tranzakció ezen a napon</div>
            ) : (
              <table className="data-grid w-full text-sm">
                <thead>
                  <tr>
                    <th>Idő</th>
                    <th>Típus</th>
                    <th>Deviza</th>
                    <th className="text-right">Összeg</th>
                    <th className="text-right">Árfolyam</th>
                    <th className="text-right">HUF</th>
                    <th>Ügyfél</th>
                    <th>Bizonylat</th>
                  </tr>
                </thead>
                <tbody>
                  {(report.transactions || []).map(t => (
                    <tr key={t.id}>
                      <td className="font-mono">{t.time}</td>
                      <td>
                        <span className={`badge ${t.type === 'BUY' ? 'badge-green' : t.type === 'SELL' ? 'badge-blue' : t.type === 'REVERSAL' ? 'badge-red' : 'badge-gray'}`}>
                          {t.type === 'BUY' ? 'Vétel' : t.type === 'SELL' ? 'Eladás' : t.type === 'REVERSAL' ? 'Sztornó' : t.type}
                        </span>
                      </td>
                      <td className="font-mono">{t.currency}</td>
                      <td className="text-right font-mono">{fmtNum(t.amount)}</td>
                      <td className="text-right font-mono">{fmtNum(t.rate)}</td>
                      <td className="text-right font-mono">{fmtHuf(t.hufAmount)}</td>
                      <td>{t.customerName || '-'}</td>
                      <td className="font-mono text-xs">{t.receiptNumber || '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Összesítő */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">Napi összesítő</h2>
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-green-50 rounded p-3 text-center">
                <div className="text-sm text-gray-500">Vételek</div>
                <div className="text-lg font-bold text-green-700">{report.summary.totalBuyCount} db</div>
                <div className="text-sm">{fmtHuf(report.summary.totalBuyHuf)}</div>
              </div>
              <div className="bg-blue-50 rounded p-3 text-center">
                <div className="text-sm text-gray-500">Eladások</div>
                <div className="text-lg font-bold text-blue-700">{report.summary.totalSellCount} db</div>
                <div className="text-sm">{fmtHuf(report.summary.totalSellHuf)}</div>
              </div>
              <div className="bg-yellow-50 rounded p-3 text-center">
                <div className="text-sm text-gray-500">Profit</div>
                <div className="text-lg font-bold text-yellow-700">{fmtHuf(report.summary.totalProfit)}</div>
                <div className="text-sm">Kezelési díj: {fmtHuf(report.summary.handlingFees)}</div>
              </div>
            </div>
          </div>

          {/* Záró készlet */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">Záró készlet</h2>
            <div className="grid grid-cols-6 gap-2">
              {(report.closingBalances || []).map((b, i) => (
                <div key={i} className="text-center p-2 bg-gray-50 rounded">
                  <div className="font-mono text-sm font-bold">{b.currency}</div>
                  <div className="text-sm">{fmtNum(b.amount)}</div>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  )
}
