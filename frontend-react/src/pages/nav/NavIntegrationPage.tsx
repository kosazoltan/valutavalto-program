import { useState } from 'react'
import { Printer, Send } from 'lucide-react'
import { navIntegrationApi } from '../../services/api'

interface NavResult {
  success: boolean
  receiptNumber?: string
  error?: string
}

export default function NavIntegrationPage() {
  const [transactionId, setTransactionId] = useState('')
  const [comPort, setComPort] = useState('COM1')
  const [result, setResult] = useState<NavResult | null>(null)
  const [error, setError] = useState<string | null>(null)

  const handleSend = async () => {
    if (!transactionId || !comPort) {
      alert('Kérjük, adja meg a tranzakció ID-t és COM portot')
      return
    }
    try {
      setError(null)
      const res = await navIntegrationApi.sendTransaction(transactionId, comPort)
      setResult(res)
      if (res.success) {
        alert(`Sikeres küldés! Bizonylatszám: ${res.receiptNumber}`)
      } else {
        setError(`NAV hiba: ${res.error}`)
      }
    } catch (err) {
      console.error('NAV küldési hiba:', err)
      setError('Hiba történt a NAV küldés során')
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><Printer />NAV integráció</h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel space-y-4">
        <div>
          <label className="form-label">Tranzakció ID</label>
          <input className="form-input" value={transactionId} onChange={e => setTransactionId(e.target.value)} />
        </div>
        <div>
          <label className="form-label">COM port</label>
          <input className="form-input" value={comPort} onChange={e => setComPort(e.target.value)} />
        </div>
        <button type="button" onClick={handleSend} className="form-button-primary flex items-center gap-2">
          <Send size={16} />Küldés NAV-nak
        </button>
        {result && (
          <div className={`p-4 rounded ${result.success ? 'bg-green-50' : 'bg-red-50'}`}>
            <p>Sikeres: {result.success ? 'Igen' : 'Nem'}</p>
            {result.receiptNumber && <p>Bizonylatszám: {result.receiptNumber}</p>}
            {result.error && <p>Hiba: {result.error}</p>}
          </div>
        )}
      </div>
    </div>
  )
}

