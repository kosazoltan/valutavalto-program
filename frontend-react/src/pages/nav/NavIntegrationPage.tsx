import { useState } from 'react'
import { Printer, Send, CheckCircle, XCircle, FileText, AlertTriangle } from 'lucide-react'
import { navIntegrationApi } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'

interface NavResult {
  success: boolean
  receiptNumber?: string
  error?: string
  timestamp?: string
}

export default function NavIntegrationPage() {
  const { t } = useTranslation()
  const [transactionId, setTransactionId] = useState('')
  const [comPort, setComPort] = useState('COM1')
  const [result, setResult] = useState<NavResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [sending, setSending] = useState(false)
  const [history, setHistory] = useState<NavResult[]>([])

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

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><Printer />{t('nav.navPenztargepIntegracio')}</h1>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded"><AlertTriangle size={16} className="inline" /> {error}</div>}

      {/* Send form */}
      <div className="form-panel space-y-3">
        <h2 className="font-semibold">{t('nav.tranzakcioKuldeseNavPenztargepre')}</h2>
        <div className="grid grid-cols-3 gap-3">
          <div>
            <label className="form-label">{t('nav.tranzakcioId')}</label>
            <input className="form-input" value={transactionId} onChange={e => setTransactionId(e.target.value)} placeholder="Tranzakció azonosító" />
          </div>
          <div>
            <label className="form-label">{t('display.comPort')}</label>
            <select className="form-input" value={comPort} onChange={e => setComPort(e.target.value)}>
              {['COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8'].map(p => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>
          <div className="flex items-end gap-2">
            <button onClick={() => void handleSend()} disabled={sending} className="form-button-primary">
              <Send size={16} /> {sending ? 'Küldés...' : 'Küldés'}
            </button>
          </div>
        </div>

        {result && (
          <div className={`p-3 rounded flex items-center gap-2 ${result.success ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
            {result.success ? <CheckCircle size={18} className="text-green-600" /> : <XCircle size={18} className="text-red-600" />}
            <div>
              <span className="font-medium">{result.success ? 'Sikeres' : 'Sikertelen'}</span>
              {result.receiptNumber && <span className="ml-2 font-mono text-sm">{t('components.bizonylat')} {result.receiptNumber}</span>}
              {result.error && <span className="ml-2 text-red-600 text-sm">{result.error}</span>}
            </div>
          </div>
        )}
      </div>

      {/* History */}
      {history.length > 0 && (
        <div className="form-panel">
          <h2 className="font-semibold mb-2 flex items-center gap-2"><FileText size={18} />{t('nav.kuldesiElozmenyekSession')}</h2>
          <table className="data-grid w-full">
            <thead><tr><th>{t('audit.idopont')}</th><th>{t('cashier.receiptNumber')}</th><th>{t('common.status')}</th><th>{t('common.error')}</th></tr></thead>
            <tbody>
              {history.map((h) => (
                <tr key={`${h.timestamp ?? ''}-${h.receiptNumber ?? ''}`}>
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
