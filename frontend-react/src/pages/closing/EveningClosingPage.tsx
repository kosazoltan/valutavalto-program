import { useState, useCallback } from 'react'
import { Moon, Calendar, Package, Send, Eye, CheckCircle, AlertTriangle, Clock } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAuthStore } from '../../stores/authStore'
import { eveningClosingApi } from '../../services/api/index'

interface EveningClosingPreview {
  branchId: string
  branchName: string
  date: string
  status: 'NOT_STARTED' | 'PREVIEW' | 'SENT' | 'CONFIRMED'
  balances: Array<{ currency: string; amount: number; denominationBreakdown?: Array<{ denomination: number; count: number }> }>
  transactionCount: number
  totalBuyHuf: number
  totalSellHuf: number
  pendingSyncs: number
  openReservations: number
  warnings: string[]
  packages: Array<{ packageId: string; currency: string; amount: number; sealNumber?: string; destination: string }>
}

export default function EveningClosingPage() {
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10))
  const [preview, setPreview] = useState<EveningClosingPreview | null>(null)
  const [loading, setLoading] = useState(false)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadPreview = useCallback(async () => {
    if (!branchId) { toast.warning('Fiók szükséges'); return }
    try {
      setLoading(true)
      setError(null)
      const data = await eveningClosingApi.preview(branchId, date)
      setPreview(data as EveningClosingPreview)
    } catch (err) {
      logger.error('EveningClosingPage', 'Előnézet hiba:', err)
      setError(getErrorMessage(err))
      setPreview(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  const handleSend = async () => {
    if (!branchId || !preview) return
    if (preview.warnings.length > 0 && !confirm(`${preview.warnings.length} figyelmeztetés van. Biztosan elküldi az esti zárást?`)) return
    try {
      setSending(true)
      setError(null)
      await eveningClosingApi.send(branchId, date)
      toast.success('Esti zárás elküldve')
      await loadPreview()
    } catch (err) {
      setError(getErrorMessage(err))
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setSending(false)
    }
  }

  const fmtNum = (n: number) => n.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  const fmtHuf = (n: number) => n.toLocaleString('hu-HU', { minimumFractionDigits: 0 }) + ' Ft'

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><Moon />Esti zárás / Csomagkészítés</h1>
        {preview && preview.status !== 'SENT' && preview.status !== 'CONFIRMED' && (
          <button onClick={handleSend} disabled={sending} className="form-button-primary">
            <Send size={16} /> {sending ? 'Küldés...' : 'Esti zárás küldése'}
          </button>
        )}
      </div>

      {/* Dátum */}
      <div className="form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">Dátum</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input className="form-input" type="date" value={date} onChange={e => setDate(e.target.value)} />
          </div>
        </div>
        <button onClick={() => void loadPreview()} disabled={loading} className="form-button-primary">
          <Eye size={16} /> {loading ? 'Betöltés...' : 'Előnézet'}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      {preview && (
        <>
          {/* Státusz */}
          <div className="flex gap-3 items-center">
            <span className={`badge ${
              preview.status === 'CONFIRMED' ? 'badge-green' :
              preview.status === 'SENT' ? 'badge-blue' :
              preview.status === 'PREVIEW' ? 'badge-yellow' : 'badge-gray'
            }`}>
              {preview.status === 'CONFIRMED' ? <><CheckCircle size={10} className="inline" /> Jóváhagyva</> :
               preview.status === 'SENT' ? <><Send size={10} className="inline" /> Elküldve</> :
               preview.status === 'PREVIEW' ? <><Eye size={10} className="inline" /> Előnézet</> :
               <><Clock size={10} className="inline" /> Nem indult</>}
            </span>
            <span className="text-sm text-gray-500">{preview.branchName} — {preview.date}</span>
          </div>

          {/* Figyelmeztetések */}
          {preview.warnings.length > 0 && (
            <div className="bg-yellow-50 border border-yellow-200 rounded p-3 space-y-1">
              <div className="font-semibold flex items-center gap-1 text-yellow-700"><AlertTriangle size={16} /> Figyelmeztetések</div>
              {preview.warnings.map((w) => (
                <div key={w} className="text-sm text-yellow-600">• {w}</div>
              ))}
            </div>
          )}

          {/* Összefoglaló */}
          <div className="grid grid-cols-4 gap-3">
            <div className="form-panel text-center">
              <div className="text-2xl font-bold">{preview.transactionCount}</div>
              <div className="text-sm text-gray-500">Tranzakció</div>
            </div>
            <div className="form-panel text-center bg-green-50">
              <div className="text-lg font-bold text-green-700">{fmtHuf(preview.totalBuyHuf)}</div>
              <div className="text-sm text-gray-500">Vétel (HUF)</div>
            </div>
            <div className="form-panel text-center bg-blue-50">
              <div className="text-lg font-bold text-blue-700">{fmtHuf(preview.totalSellHuf)}</div>
              <div className="text-sm text-gray-500">Eladás (HUF)</div>
            </div>
            <div className="form-panel text-center">
              <div className="text-lg font-bold text-orange-600">{preview.pendingSyncs}</div>
              <div className="text-sm text-gray-500">Szinkron. váró</div>
            </div>
          </div>

          {/* Készletek */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">Záró készlet</h2>
            <div className="grid grid-cols-6 gap-2">
              {(preview.balances || []).map((b) => (
                <div key={b.currency} className="text-center p-2 bg-gray-50 rounded">
                  <div className="font-mono text-sm font-bold">{b.currency}</div>
                  <div className="text-sm">{fmtNum(b.amount)}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Csomagok */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2 flex items-center gap-1"><Package size={16} /> Készített csomagok</h2>
            {(preview.packages || []).length === 0 ? (
              <div className="text-center text-gray-500 py-4">Nincs csomag</div>
            ) : (
              <table className="data-grid w-full">
                <thead>
                  <tr>
                    <th>Csomag ID</th>
                    <th>Deviza</th>
                    <th className="text-right">Összeg</th>
                    <th>Plombaszám</th>
                    <th>Cél</th>
                  </tr>
                </thead>
                <tbody>
                  {preview.packages.map(p => (
                    <tr key={p.packageId}>
                      <td className="font-mono text-sm">{p.packageId}</td>
                      <td className="font-mono">{p.currency}</td>
                      <td className="text-right font-mono">{fmtNum(p.amount)}</td>
                      <td className="font-mono text-sm">{p.sealNumber || '-'}</td>
                      <td>{p.destination}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}
    </div>
  )
}
