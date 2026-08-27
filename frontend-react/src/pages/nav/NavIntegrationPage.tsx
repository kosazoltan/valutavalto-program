import { useState } from 'react'
import { Printer, Send, CheckCircle, XCircle, FileText, AlertTriangle, QrCode } from 'lucide-react'
import { navIntegrationApi } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface NavResult {
  success: boolean
  receiptNumber?: string
  error?: string
  timestamp?: string
}

export default function NavIntegrationPage() {
  const { t } = useTranslation()
  const [transactionId, setTransactionId] = useState('')
  const [qrCode, setQrCode] = useState('')
  const [comPort, setComPort] = useState('COM1')
  const [result, setResult] = useState<NavResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [sending, setSending] = useState(false)
  const [sendingQr, setSendingQr] = useState(false)
  const [receiving, setReceiving] = useState(false)
  const [history, setHistory] = useState<NavResult[]>([])

  const handleSend = async () => {
    if (!transactionId) {
      toast.warning('Tranzakció ID szükséges')
      return
    }
    try {
      setSending(true)
      setError(null)
      const res = await navIntegrationApi.sendTransaction(transactionId, comPort)
      setResult(res)
      setHistory((prev) => [res, ...prev].slice(0, 20))
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

  const handleReceiveReceiptNumber = async () => {
    try {
      setReceiving(true)
      setError(null)
      const receiptNumber = await navIntegrationApi.receiveReceiptNumber(comPort)
      const received: NavResult = receiptNumber
        ? { success: true, receiptNumber, timestamp: new Date().toISOString() }
        : {
            success: false,
            error: 'A NAV pénztárgép nem adott vissza nyugtaszámot',
            timestamp: new Date().toISOString(),
          }
      setResult(received)
      setHistory((prev) => [received, ...prev].slice(0, 20))
      if (received.success) {
        toast.success('Nyugtaszám fogadva', `Bizonylatszám: ${received.receiptNumber}`)
      } else {
        setError(received.error ?? 'Nyugtaszám fogadása sikertelen')
      }
    } catch (err) {
      logger.error('NavIntegrationPage', 'NAV nyugtaszám fogadási hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setReceiving(false)
    }
  }

  const handleSendQrCode = async () => {
    if (!qrCode.trim()) {
      toast.warning('QR kód szükséges')
      return
    }
    try {
      setSendingQr(true)
      setError(null)
      const success = await navIntegrationApi.sendQrCode(qrCode.trim(), comPort)
      const qrResult: NavResult = success
        ? { success: true, timestamp: new Date().toISOString() }
        : {
            success: false,
            error: 'A NAV pénztárgép nem fogadta a QR kódot',
            timestamp: new Date().toISOString(),
          }
      setResult(qrResult)
      setHistory((prev) => [qrResult, ...prev].slice(0, 20))
      if (qrResult.success) {
        toast.success('QR kód elküldve', `Port: ${comPort}`)
        setQrCode('')
      } else {
        setError(qrResult.error ?? 'QR kód küldése sikertelen')
      }
    } catch (err) {
      logger.error('NavIntegrationPage', 'NAV QR-kód küldési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setSendingQr(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Printer />
          {t('nav.navPenztargepIntegracio')}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          <AlertTriangle size={16} className="inline" /> {error}
        </div>
      )}

      {/* Send form */}
      <div className="form-panel space-y-3">
        <h2 className="font-semibold">{t('nav.tranzakcioKuldeseNavPenztargepre')}</h2>
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
          <div>
            <label className="form-label">{t('nav.tranzakcioId')}</label>
            <input
              className="form-input"
              value={transactionId}
              onChange={(e) => setTransactionId(e.target.value)}
              placeholder="Tranzakció azonosító"
            />
          </div>
          <div>
            <label className="form-label">{t('display.comPort')}</label>
            <select
              className="form-input"
              value={comPort}
              onChange={(e) => setComPort(e.target.value)}
            >
              {['COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8'].map((p) => (
                <option key={p} value={p}>
                  {p}
                </option>
              ))}
            </select>
          </div>
          <div className="flex flex-wrap items-end gap-2">
            <button
              onClick={() => void handleSend()}
              disabled={sending}
              className="form-button-primary"
            >
              <Send size={16} /> {sending ? 'Küldés...' : 'Küldés'}
            </button>
            <button
              onClick={() => void handleReceiveReceiptNumber()}
              disabled={receiving}
              className="form-button"
            >
              <Printer size={16} /> {receiving ? 'Fogadás...' : 'Nyugtaszám fogadása'}
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-3 border-t pt-3 md:grid-cols-3">
          <div className="md:col-span-2">
            <label className="form-label" htmlFor="nav-qr-code">
              {i18n.t('literals.qr-kod')}
            </label>
            <input
              id="nav-qr-code"
              className="form-input"
              value={qrCode}
              onChange={(e) => setQrCode(e.target.value)}
              placeholder="NAV QR kód tartalma"
            />
          </div>
          <div className="flex items-end">
            <button
              onClick={() => void handleSendQrCode()}
              disabled={sendingQr}
              className="form-button"
            >
              <QrCode size={16} /> {sendingQr ? 'QR küldés...' : 'QR kód küldése'}
            </button>
          </div>
        </div>

        {result && (
          <div
            className={`p-3 rounded flex items-center gap-2 ${result.success ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}
          >
            {result.success ? (
              <CheckCircle size={18} className="text-green-600" />
            ) : (
              <XCircle size={18} className="text-red-600" />
            )}
            <div>
              <span className="font-medium">{result.success ? 'Sikeres' : 'Sikertelen'}</span>
              {result.receiptNumber && (
                <span className="ml-2 font-mono text-sm">
                  {t('components.bizonylat')} {result.receiptNumber}
                </span>
              )}
              {result.error && <span className="ml-2 text-red-600 text-sm">{result.error}</span>}
            </div>
          </div>
        )}
      </div>

      {/* History */}
      {history.length > 0 && (
        <div className="form-panel">
          <h2 className="font-semibold mb-2 flex items-center gap-2">
            <FileText size={18} />
            {t('nav.kuldesiElozmenyekSession')}
          </h2>
          <div className="overflow-x-auto">
            <table className="data-grid min-w-full">
              <thead>
                <tr>
                  <th>{t('audit.idopont')}</th>
                  <th>{t('cashier.receiptNumber')}</th>
                  <th>{t('common.status')}</th>
                  <th>{t('common.error')}</th>
                </tr>
              </thead>
              <tbody>
                {history.map((h) => (
                  <tr key={`${h.timestamp ?? ''}-${h.receiptNumber ?? ''}`}>
                    <td className="text-sm">
                      {h.timestamp
                        ? new Date(h.timestamp).toLocaleString('hu-HU')
                        : new Date().toLocaleString('hu-HU')}
                    </td>
                    <td className="font-mono">{h.receiptNumber || '-'}</td>
                    <td>
                      {h.success ? (
                        <span className="badge badge-green">{i18n.t('literals.ok')}</span>
                      ) : (
                        <span className="badge badge-red">{i18n.t('literals.hiba-4')}</span>
                      )}
                    </td>
                    <td className="text-sm text-red-600">{h.error || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
