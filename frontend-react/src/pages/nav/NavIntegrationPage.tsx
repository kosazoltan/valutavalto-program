import { useState, useCallback } from 'react'
import { Printer, Send, RefreshCw, CheckCircle, XCircle, Clock, FileText, AlertTriangle } from 'lucide-react'
import { navIntegrationApi } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'

interface NavResult {
  success: boolean
  receiptNumber?: string
  error?: string
  timestamp?: string
}

interface NavStatus {
  deviceConnected: boolean
  lastCommunication?: string
  firmwareVersion?: string
  serialNumber?: string
  pendingCount: number
}

export default function NavIntegrationPage() {
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [transactionId, setTransactionId] = useState('')
  const [comPort, setComPort] = useState('COM1')
  const [result, setResult] = useState<NavResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [sending, setSending] = useState(false)
  const [status, setStatus] = useState<NavStatus | null>(null)
  const [history, setHistory] = useState<NavResult[]>([])

  const loadStatus = useCallback(async () => {
    try {
      const data = await navIntegrationApi.getStatus(branchId)
      setStatus(data as NavStatus)
    } catch {
      setStatus(null)
    }
  }, [branchId])

  const handleSend = async () => {
    if (!transactionId) { toast.warning('Tranzakció ID szükséges'); return }
    try {
      setSending(true)
      setError(null)
      const res = await navIntegrationApi.sendTransaction(transactionId, comPort)
      setResult(res)
      setHistory(prev => [res, ...prev].slice(0, 20))
      if (res.success) {
        toast.success('Sikeres küldés', `Bizonylatszám: ${res.receiptNumber}`)
        setTransactionId('')
      } else {
        setError(`NAV hiba: ${res.error}`)
      }
    } catch (err) {
      logger.error('NavIntegrationPage', 'NAV küldési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setSending(false)
    }
  }

  const handleRetry = async () => {
    try {
      setError(null)
      await navIntegrationApi.retryFailed(branchId)
      toast.success('Újraküldés elindítva')
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><Printer />NAV Pénztárgép Integráció</h1>
        <button onClick={() => void loadStatus()} className="form-button"><RefreshCw size={16} /> Státusz frissítés</button>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded"><AlertTriangle size={16} className="inline" /> {error}</div>}

      {/* Device status */}
      {status && (
        <div className="form-panel">
          <h2 className="font-semibold mb-2">Eszköz állapot</h2>
          <div className="grid grid-cols-4 gap-3 text-sm">
            <div>
              <span className="text-gray-500">Kapcsolat:</span>{' '}
              {status.deviceConnected ? <span className="badge badge-green"><CheckCircle size={10} className="inline" /> Online</span> : <span className="badge badge-red"><XCircle size={10} className="inline" /> Offline</span>}
            </div>
            <div><span className="text-gray-500">Sorozatszám:</span> {status.serialNumber || '-'}</div>
            <div><span className="text-gray-500">Firmware:</span> {status.firmwareVersion || '-'}</div>
            <div>
              <span className="text-gray-500">Függő:</span>{' '}
              {status.pendingCount > 0 ? (
                <span className="badge badge-yellow">{status.pendingCount} tranzakció</span>
              ) : (
                <span className="badge badge-green">0</span>
              )}
            </div>
          </div>
          {status.lastCommunication && (
            <div className="text-xs text-gray-400 mt-1"><Clock size={10} className="inline" /> Utolsó kommunikáció: {new Date(status.lastCommunication).toLocaleString('hu-HU')}</div>
          )}
        </div>
      )}

      {/* Send form */}
      <div className="form-panel space-y-3">
        <h2 className="font-semibold">Tranzakció küldése NAV pénztárgépre</h2>
        <div className="grid grid-cols-3 gap-3">
          <div>
            <label className="form-label">Tranzakció ID *</label>
            <input className="form-input" value={transactionId} onChange={e => setTransactionId(e.target.value)} placeholder="Tranzakció azonosító" />
          </div>
          <div>
            <label className="form-label">COM port</label>
            <select className="form-input" value={comPort} onChange={e => setComPort(e.target.value)}>
              {['COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8'].map(p => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>
          <div className="flex items-end gap-2">
            <button onClick={() => void handleSend()} disabled={sending} className="form-button-primary">
              <Send size={16} /> {sending ? 'Küldés...' : 'Küldés'}
            </button>
            <button onClick={() => void handleRetry()} className="form-button">
              <RefreshCw size={16} /> Sikertelenek újraküldése
            </button>
          </div>
        </div>

        {result && (
          <div className={`p-3 rounded flex items-center gap-2 ${result.success ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
            {result.success ? <CheckCircle size={18} className="text-green-600" /> : <XCircle size={18} className="text-red-600" />}
            <div>
              <span className="font-medium">{result.success ? 'Sikeres' : 'Sikertelen'}</span>
              {result.receiptNumber && <span className="ml-2 font-mono text-sm">Bizonylat: {result.receiptNumber}</span>}
              {result.error && <span className="ml-2 text-red-600 text-sm">{result.error}</span>}
            </div>
          </div>
        )}
      </div>

      {/* History */}
      {history.length > 0 && (
        <div className="form-panel">
          <h2 className="font-semibold mb-2 flex items-center gap-2"><FileText size={18} /> Küldési előzmények (session)</h2>
          <table className="data-grid w-full">
            <thead><tr><th>Időpont</th><th>Bizonylatszám</th><th>Státusz</th><th>Hiba</th></tr></thead>
            <tbody>
              {history.map((h, i) => (
                <tr key={i}>
                  <td className="text-sm">{h.timestamp ? new Date(h.timestamp).toLocaleString('hu-HU') : new Date().toLocaleString('hu-HU')}</td>
                  <td className="font-mono">{h.receiptNumber || '-'}</td>
                  <td>{h.success ? <span className="badge badge-green">OK</span> : <span className="badge badge-red">HIBA</span>}</td>
                  <td className="text-sm text-red-600">{h.error || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
