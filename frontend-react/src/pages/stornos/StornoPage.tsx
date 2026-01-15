import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { AlertCircle, CheckCircle, XCircle, ArrowLeft, Save } from 'lucide-react'
import { stornoApi, transactionApi, StornoRequest, StornoCheckResult, StornoApproval, Transaction } from '../../services/api'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'

export default function StornoPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const worker = useAuthStore((state) => state.worker)
  const workerId = worker?.id ? String(worker.id) : ''

  const [transaction, setTransaction] = useState<Transaction | null>(null)
  const [checkResult, setCheckResult] = useState<StornoCheckResult | null>(null)
  const [approval, setApproval] = useState<StornoApproval | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const [reason, setReason] = useState('')
  const [customRate, setCustomRate] = useState<string>('')
  const [paymentMethod, setPaymentMethod] = useState<string>('CASH')

  useEffect(() => {
    let mounted = true

    if (id && workerId) {
      const load = async (): Promise<void> => {
        await loadTransaction()
        await checkStorno()
      }
      
      load().catch(err => {
        if (mounted) {
          console.error('Failed to load storno page:', err)
        }
      })
    }

    return () => {
      mounted = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, workerId])

  const loadTransaction = async (): Promise<void> => {
    try {
      const tx = await transactionApi.getById(id!)
      setTransaction(tx)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      console.error('Failed to load transaction:', err)
    }
  }

  const checkStorno = async (): Promise<void> => {
    if (!id || !workerId) return
    
    try {
      setLoading(true)
      const result = await stornoApi.check(id, workerId)
      setCheckResult(result)
      
      // Ha engedély szükséges, betöltjük az engedélykérést
      if (result.requiresApproval) {
        // TODO: betölteni a pending approval-t
      }
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      console.error('Failed to check storno:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleRequestApproval = async (): Promise<void> => {
    if (!id || !workerId || !reason.trim()) {
      setError('Kérjük, adja meg a sztornó okát!')
      return
    }

    try {
      setLoading(true)
      const result = await stornoApi.requestApproval(id, workerId, reason)
      setApproval(result)
      setError(null)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      console.error('Failed to request approval:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleExecuteStorno = async (): Promise<void> => {
    if (!id || !workerId || !reason.trim()) {
      setError('Kérjük, adja meg a sztornó okát!')
      return
    }

    if (checkResult?.requiresApproval && !approval) {
      setError('Engedély szükséges a sztornóhoz!')
      return
    }

    try {
      setLoading(true)
      const request: StornoRequest = {
        transactionId: id!,
        reason,
        approvalId: approval?.id,
        customExchangeRate: customRate ? parseFloat(customRate) : undefined,
        paymentMethodDid: paymentMethod
      }
      
      await stornoApi.execute(request, workerId)
      navigate('/transactions', { state: { message: 'Sztornó sikeresen végrehajtva' } })
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      console.error('Failed to execute storno:', err)
    } finally {
      setLoading(false)
    }
  }

  if (!transaction || !checkResult) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Betöltés...</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate('/transactions')}
          className="toolbar-button"
        >
          <ArrowLeft size={16} />
        </button>
        <h1 className="text-xl font-bold text-gray-800">Sztornó</h1>
      </div>

      {/* Error */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      {/* Transaction Info */}
      <div className="form-panel">
        <h2 className="text-lg font-semibold mb-3">Tranzakció adatai</h2>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="form-label">Tranzakció szám</label>
            <div className="form-input bg-gray-50">{transaction.receiptNumber || transaction.id}</div>
          </div>
          <div>
            <label className="form-label">Dátum</label>
            <div className="form-input bg-gray-50">{new Date(transaction.createdAt).toLocaleString('hu-HU')}</div>
          </div>
          <div>
            <label className="form-label">Típus</label>
            <div className="form-input bg-gray-50">
              {transaction.transactionType === 'BUY' ? 'Vétel' : transaction.transactionType === 'SELL' ? 'Eladás' : transaction.transactionType}
            </div>
          </div>
          <div>
            <label className="form-label">Deviza</label>
            <div className="form-input bg-gray-50">{transaction.currencyCode}</div>
          </div>
          <div>
            <label className="form-label">Deviza összeg</label>
            <div className="form-input bg-gray-50 font-mono">
              {transaction.currencyAmount?.toLocaleString('hu-HU', { minimumFractionDigits: 2 })}
            </div>
          </div>
          <div>
            <label className="form-label">HUF összeg</label>
            <div className="form-input bg-gray-50 font-mono font-semibold">
              {transaction.hufAmount?.toLocaleString('hu-HU')} Ft
            </div>
          </div>
          <div>
            <label className="form-label">Árfolyam</label>
            <div className="form-input bg-gray-50 font-mono">
              {transaction.exchangeRate?.toFixed(4)}
            </div>
          </div>
          <div>
            <label className="form-label">Ügyfél</label>
            <div className="form-input bg-gray-50">{transaction.customerName || 'Névtelen'}</div>
          </div>
        </div>
      </div>

      {/* Storno Check Result */}
      <div className={`form-panel ${checkResult.requiresApproval ? 'bg-yellow-50 border-yellow-200' : 'bg-green-50 border-green-200'}`}>
        <div className="flex items-start gap-3">
          {checkResult.requiresApproval ? (
            <AlertCircle className="text-yellow-600 mt-0.5" size={20} />
          ) : (
            <CheckCircle className="text-green-600 mt-0.5" size={20} />
          )}
          <div className="flex-1">
            <h3 className="font-semibold mb-1">
              {checkResult.requiresApproval ? 'Engedély szükséges' : 'Közvetlen sztornó lehetséges'}
            </h3>
            <p className="text-sm text-gray-700 mb-2">{checkResult.message}</p>
            <p className="text-sm text-gray-600">
              Napi sztornók száma: <strong>{checkResult.dailyStornoCount}</strong>
            </p>
          </div>
        </div>
      </div>

      {/* Approval Request (if needed) */}
      {checkResult.requiresApproval && !approval && (
        <div className="form-panel">
          <h2 className="text-lg font-semibold mb-3">Engedélykérés</h2>
          <div className="space-y-4">
            <div>
              <label className="form-label">Sztornó oka *</label>
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                className="form-input"
                rows={4}
                placeholder="Részletesen indokolja a sztornó okát..."
              />
            </div>
            <button
              onClick={handleRequestApproval}
              disabled={loading || !reason.trim()}
              className="form-button-primary"
            >
              Engedélykérés küldése
            </button>
          </div>
        </div>
      )}

      {/* Approval Status */}
      {approval && (
        <div className={`form-panel ${
          approval.approvalStatusDid === 'APPROVED' ? 'bg-green-50 border-green-200' :
          approval.approvalStatusDid === 'REJECTED' ? 'bg-red-50 border-red-200' :
          'bg-yellow-50 border-yellow-200'
        }`}>
          <div className="flex items-start gap-3">
            {approval.approvalStatusDid === 'APPROVED' ? (
              <CheckCircle className="text-green-600 mt-0.5" size={20} />
            ) : approval.approvalStatusDid === 'REJECTED' ? (
              <XCircle className="text-red-600 mt-0.5" size={20} />
            ) : (
              <AlertCircle className="text-yellow-600 mt-0.5" size={20} />
            )}
            <div className="flex-1">
              <h3 className="font-semibold mb-1">
                {approval.approvalStatusDid === 'APPROVED' ? 'Engedélyezve' :
                 approval.approvalStatusDid === 'REJECTED' ? 'Elutasítva' :
                 'Várakozik jóváhagyásra'}
              </h3>
              {approval.requestReason && (
                <p className="text-sm text-gray-700 mb-2">
                  <strong>Kérés oka:</strong> {approval.requestReason}
                </p>
              )}
              {approval.rejectionReason && (
                <p className="text-sm text-red-700 mb-2">
                  <strong>Elutasítás oka:</strong> {approval.rejectionReason}
                </p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Storno Form */}
      {(!checkResult.requiresApproval || approval?.approvalStatusDid === 'APPROVED') && (
        <div className="form-panel">
          <h2 className="text-lg font-semibold mb-3">Sztornó adatai</h2>
          <div className="space-y-4">
            <div>
              <label className="form-label">Sztornó oka *</label>
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                className="form-input"
                rows={4}
                placeholder="Részletesen indokolja a sztornó okát..."
                disabled={loading}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="form-label">Egyedi árfolyam (opcionális)</label>
                <input
                  type="number"
                  value={customRate}
                  onChange={(e) => setCustomRate(e.target.value)}
                  className="form-input"
                  placeholder="Ha üres, az eredeti árfolyam kerül használatra"
                  step="0.0001"
                  disabled={loading}
                />
              </div>
              <div>
                <label className="form-label">Fizetési mód</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value)}
                  className="form-input"
                  disabled={loading}
                >
                  <option value="CASH">Készpénz</option>
                  <option value="CARD">Kártya</option>
                  <option value="MIXED">Vegyes</option>
                </select>
              </div>
            </div>

            <div className="flex gap-3 pt-4 border-t">
              <button
                onClick={handleExecuteStorno}
                disabled={loading || !reason.trim()}
                className="form-button-primary flex items-center gap-2"
              >
                <Save size={16} />
                Sztornó végrehajtása
              </button>
              <button
                onClick={() => navigate('/transactions')}
                className="form-button"
                disabled={loading}
              >
                Mégse
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

