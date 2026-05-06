import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { AlertCircle, CheckCircle, XCircle, ArrowLeft, Save } from 'lucide-react'
import { stornoApi, transactionApi, StornoRequest, StornoCheckResult, StornoApproval, Transaction } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import {
  isElectronQueueAvailable,
  recordLocalAuditEvent,
  saveAndSyncPendingStorno,
} from '../../utils/electronTransactions'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'

export default function StornoPage() {
  const { t } = useTranslation()
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const worker = useAuthStore((state) => state.worker)
  const workerId = worker?.id ? String(worker.id) : ''
  const electronQueueAvailable = isElectronQueueAvailable()

  const [transaction, setTransaction] = useState<Transaction | null>(null)
  const [checkResult, setCheckResult] = useState<StornoCheckResult | null>(null)
  const [approval, setApproval] = useState<StornoApproval | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const [reason, setReason] = useState('')
  const [customRate, setCustomRate] = useState<string>('')
  const [paymentMethod, setPaymentMethod] = useState<string>('CASH')

  const loadTransaction = useCallback(async (): Promise<void> => {
    try {
      const tx = await transactionApi.getById(id!)
      setTransaction(tx)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('StornoPage', 'Failed to load transaction:', err)
    }
  }, [id])

  const checkStorno = useCallback(async (): Promise<void> => {
    if (!id || !workerId) return
    
    try {
      setLoading(true)
      const result = await stornoApi.check(id, workerId)
      setCheckResult(result)
      
      // Ha engedély szükséges, betöltjük az engedélykérést
      if (result.requiresApproval) {
        /** Megjegyzés: pending approval betöltés terve készíthető külön PR-ben. */
      }
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('StornoPage', 'Failed to check storno:', err)
    } finally {
      setLoading(false)
    }
  }, [id, workerId])

  useEffect(() => {
    if (id && workerId) {
      void loadTransaction()
      void checkStorno()
    }
  }, [id, workerId, loadTransaction, checkStorno])

  const handleRequestApproval = async (): Promise<void> => {
    if (!id || !workerId || !reason.trim()) {
      setError('Kérjük, adja meg a sztornó okát!')
      return
    }

    try {
      setLoading(true)
      const result = await stornoApi.requestApproval(id, workerId, reason)
      setApproval(result)
      await recordLocalAuditEvent({
        entityType: 'STORNO',
        eventType: 'REQUEST_APPROVAL',
        entityId: id,
        referenceNumber: transaction?.receiptNumber ?? id ?? null,
        payload: {
          transactionId: id,
          reason,
          approvalId: result.id,
        },
        status: 'SERVER_FORWARDED',
      })
      setError(null)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('StornoPage', 'Failed to request approval:', err)
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

      if (electronQueueAvailable && transaction) {
        const outcome = await saveAndSyncPendingStorno({
          transactionId: transaction.id,
          originalReceiptNumber: transaction.receiptNumber,
          originalTransactionType: transaction.transactionType,
          currencyCode: transaction.currencyCode,
          foreignAmount: transaction.currencyAmount ?? null,
          hufAmount: transaction.hufAmount,
          exchangeRate: transaction.exchangeRate ?? null,
          reason,
          approvalId: approval?.id ?? null,
          customExchangeRate: customRate ? parseFloat(customRate) : null,
          paymentMethod,
          customerName: transaction.customerName ?? null,
          customerDocumentNumber: transaction.customerDocumentNumber ?? null,
        })
        navigate('/transactions', {
          state: {
            message: outcome.allSavedSynced
              ? 'Sztornó helyileg rögzítve és azonnal szinkronizálva'
              : 'Sztornó helyileg rögzítve. A feltöltés az Electron queue-ból folytatódik.',
          },
        })
      } else {
        await stornoApi.execute(request, workerId)
        navigate('/transactions', { state: { message: 'Sztornó sikeresen végrehajtva' } })
      }
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('StornoPage', 'Failed to execute storno:', err)
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
        <h1 className="text-xl font-bold text-gray-800">{t('cashier.storno')}</h1>
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
        <h2 className="text-lg font-semibold mb-3">{t('stornos.tranzakcioAdatai')}</h2>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="form-label">{t('statistics.tranzakcioSzam')}</label>
            <div className="form-input bg-gray-50">{transaction.receiptNumber || transaction.id}</div>
          </div>
          <div>
            <label className="form-label">{t('common.date')}</label>
            <div className="form-input bg-gray-50">{new Date(transaction.createdAt).toLocaleString('hu-HU')}</div>
          </div>
          <div>
            <label className="form-label">{t('common.type')}</label>
            <div className="form-input bg-gray-50">
              {transaction.transactionType === 'BUY' ? 'Vétel' : transaction.transactionType === 'SELL' ? 'Eladás' : transaction.transactionType}
            </div>
          </div>
          <div>
            <label className="form-label">{t('common.deviza')}</label>
            <div className="form-input bg-gray-50">{transaction.currencyCode}</div>
          </div>
          <div>
            <label className="form-label">{t('stornos.devizaOsszeg')}</label>
            <div className="form-input bg-gray-50 font-mono">
              {transaction.currencyAmount?.toLocaleString('hu-HU', { minimumFractionDigits: 2 })}
            </div>
          </div>
          <div>
            <label className="form-label">{t('stornos.hufOsszeg')}</label>
            <div className="form-input bg-gray-50 font-mono font-semibold">
              {transaction.hufAmount?.toLocaleString('hu-HU')} {t('common.ft')}
            </div>
          </div>
          <div>
            <label className="form-label">{t('cashier.exchangeRate')}</label>
            <div className="form-input bg-gray-50 font-mono">
              {transaction.exchangeRate?.toFixed(4)}
            </div>
          </div>
          <div>
            <label className="form-label">{t('common.customer')}</label>
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
              {t('stornos.napiSztornokSzama')}<strong>{checkResult.dailyStornoCount}</strong>
            </p>
          </div>
        </div>
      </div>

      {/* Approval Request (if needed) */}
      {checkResult.requiresApproval && !approval && (
        <div className="form-panel">
          <h2 className="text-lg font-semibold mb-3">{t('stornos.engedelykeres')}</h2>
          <div className="space-y-4">
            <div>
              <label className="form-label">{t('stornos.sztornoOka')}</label>
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
              {t('stornos.engedelykeresKuldese')}
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
                  <strong>{t('stornos.keresOka')}</strong> {approval.requestReason}
                </p>
              )}
              {approval.rejectionReason && (
                <p className="text-sm text-red-700 mb-2">
                  <strong>{t('stornos.elutasitasOka')}</strong> {approval.rejectionReason}
                </p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Storno Form */}
      {(!checkResult.requiresApproval || approval?.approvalStatusDid === 'APPROVED') && (
        <div className="form-panel">
          <h2 className="text-lg font-semibold mb-3">{t('stornos.sztornoAdatai')}</h2>
          <div className="space-y-4">
            <div>
              <label className="form-label">{t('stornos.sztornoOka')}</label>
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
                <label className="form-label">{t('stornos.egyediArfolyamOpcionalis')}</label>
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
                <label className="form-label">{t('stornos.fizetesiMod')}</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value)}
                  className="form-input"
                  disabled={loading}
                >
                  <option value="CASH">{t('stornos.keszpenz')}</option>
                  <option value="CARD">{t('stornos.kartya')}</option>
                  <option value="MIXED">{t('stornos.vegyes')}</option>
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
                {t('stornos.sztornoVegrehajtasa')}
              </button>
              <button
                onClick={() => navigate('/transactions')}
                className="form-button"
                disabled={loading}
              >
                {t('common.cancel')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

