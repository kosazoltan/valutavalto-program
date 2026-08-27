import { useState, useEffect, useCallback, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { AlertCircle, CheckCircle, XCircle, ArrowLeft, Save } from 'lucide-react'
import {
  stornoApi,
  transactionApi,
  StornoRequest,
  StornoCheckResult,
  StornoApproval,
  Transaction,
} from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import {
  isElectronQueueAvailable,
  recordLocalAuditEvent,
  saveAndSyncPendingStorno,
} from '../../utils/electronTransactions'
import { getCompanyType } from '../../utils/localQueue'
import { isElectron } from '../../utils/electron'
import StornoPinApprovalModal from '../../components/auth/StornoPinApprovalModal'
import ReceiptPreviewModal from '../../components/electron/ReceiptPreviewModal'
import type { PrintReceiptData } from '../../types/receipt'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

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
  // FK-penztar-batch D.1 (2026-06-12, user-kérés): az „Egyedi árfolyam" és „Fizetési mód"
  // mezők ELTÁVOLÍTVA — csak az indok marad. A paymentMethodDid a backenden HALOTT mező
  // volt (sehol nem olvassák, a sztornó mindig az eredeti fizetési módot örökli —
  // TransactionReversalService:218), az üres customExchangeRate pedig default az eredeti
  // árfolyam (TransactionReversalService:184-189).
  // Telefonos supervisor-PIN jóváhagyás (egyszemélyes iroda): a PENDING kéréshez
  // a pénztáros a helyszínről, telefonon bediktált PIN-nel kérhet jóváhagyást.
  const [showPinApproval, setShowPinApproval] = useState(false)
  // FK-penztar-batch D.2: sztornó után bizonylat-előnézet + nyomtatás (a vétel/eladás
  // CashierTransactionPage mintája). A navigáció a modal ZÁRÁSAKOR történik.
  const [receiptData, setReceiptData] = useState<PrintReceiptData | null>(null)
  const [successMessage, setSuccessMessage] = useState<string>('')
  const printAttemptedRef = useRef(false)

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
      const result = await stornoApi.check(id)
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
      const result = await stornoApi.requestApproval(id, reason)
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
      // D.1: csak transactionId + reason + approvalId megy — az egyedi árfolyam és a
      // fizetési mód mezők megszűntek (a backend defaultja: eredeti árfolyam + eredeti
      // fizetési mód). A StornoRequest mezői opcionálisak, a backend DTO változatlan.
      const request: StornoRequest = {
        transactionId: id!,
        reason,
        approvalId: approval?.id,
      }

      const now = new Date()
      const receiptBase = {
        type: 'storno' as const,
        companyType: getCompanyType(worker),
        branchCode: worker?.branchCode ?? '',
        cashierName: worker?.fullName ?? '',
        date: now.toLocaleDateString('hu-HU'),
        time: now.toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }),
        currencyCode: transaction?.currencyCode,
        foreignAmount: transaction?.currencyAmount ?? undefined,
        // D.1 nyomán a sztornó mindig az EREDETI árfolyammal könyvel.
        rate: transaction?.exchangeRate ?? undefined,
        customerName: transaction?.customerName ?? undefined,
        customerDocNumber: transaction?.customerDocumentNumber ?? undefined,
        stornoReason: reason,
        originalReceiptNumber: transaction?.receiptNumber,
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
          customExchangeRate: null,
          paymentMethod: null,
          customerName: transaction.customerName ?? null,
          customerDocumentNumber: transaction.customerDocumentNumber ?? null,
        })
        // D.2: bizonylat-előnézet a localQueue buildStornoReceiptData mezőkiosztása
        // szerint — offline a helyi referencia-szám szerepel (sync utáni reprint a
        // Bizonylatok oldalról a végleges sorszámmal elérhető).
        setSuccessMessage(
          outcome.allSavedSynced
            ? 'Sztornó helyileg rögzítve és azonnal szinkronizálva'
            : 'Sztornó helyileg rögzítve. A feltöltés az Electron queue-ból folytatódik.',
        )
        setReceiptData({
          ...receiptBase,
          receiptNumber: outcome.localReferenceNumbers?.[0] ?? `LOCAL-STORNO-${transaction.id}`,
          hufAmount: transaction.hufAmount,
          roundedHufAmount: transaction.hufAmount,
        })
      } else {
        // Online: a backend a teljes REVERSAL tranzakciót adja vissza — saját
        // bizonylatszámmal (az eredeti típus számlálójából, B.6 4. szabály).
        const reversal = await stornoApi.execute(request)
        setSuccessMessage('Sztornó sikeresen végrehajtva')
        setReceiptData({
          ...receiptBase,
          receiptNumber: reversal.receiptNumber ?? `STORNO-${reversal.id}`,
          currencyCode: reversal.currencyCode ?? receiptBase.currencyCode,
          foreignAmount: reversal.currencyAmount ?? receiptBase.foreignAmount,
          rate: reversal.exchangeRate ?? receiptBase.rate,
          hufAmount: reversal.hufAmount ?? transaction?.hufAmount,
          roundedHufAmount: reversal.hufAmount ?? transaction?.hufAmount,
        })
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
        <div className="text-gray-500">{i18n.t('literals.betoltes')}</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => navigate('/transactions')} className="toolbar-button">
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
            <div className="form-input bg-gray-50">
              {transaction.receiptNumber || transaction.id}
            </div>
          </div>
          <div>
            <label className="form-label">{t('common.date')}</label>
            <div className="form-input bg-gray-50">
              {new Date(transaction.createdAt).toLocaleString('hu-HU')}
            </div>
          </div>
          <div>
            <label className="form-label">{t('common.type')}</label>
            <div className="form-input bg-gray-50">
              {transaction.transactionType === 'BUY'
                ? 'Vétel'
                : transaction.transactionType === 'SELL'
                  ? 'Eladás'
                  : transaction.transactionType}
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
      <div
        className={`form-panel ${checkResult.requiresApproval ? 'bg-yellow-50 border-yellow-200' : 'bg-green-50 border-green-200'}`}
      >
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
              {t('stornos.napiSztornokSzama')}
              <strong>{checkResult.dailyStornoCount}</strong>
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
        <div
          className={`form-panel ${
            approval.approvalStatusCode === 'APPROVED'
              ? 'bg-green-50 border-green-200'
              : approval.approvalStatusCode === 'REJECTED'
                ? 'bg-red-50 border-red-200'
                : 'bg-yellow-50 border-yellow-200'
          }`}
        >
          <div className="flex items-start gap-3">
            {approval.approvalStatusCode === 'APPROVED' ? (
              <CheckCircle className="text-green-600 mt-0.5" size={20} />
            ) : approval.approvalStatusCode === 'REJECTED' ? (
              <XCircle className="text-red-600 mt-0.5" size={20} />
            ) : (
              <AlertCircle className="text-yellow-600 mt-0.5" size={20} />
            )}
            <div className="flex-1">
              <h3 className="font-semibold mb-1">
                {approval.approvalStatusCode === 'APPROVED'
                  ? 'Engedélyezve'
                  : approval.approvalStatusCode === 'REJECTED'
                    ? 'Elutasítva'
                    : 'Várakozik jóváhagyásra'}
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
              {/* Egyszemélyes iroda: telefonos supervisor-PIN jóváhagyás a PENDING kéréshez */}
              {approval.approvalStatusCode !== 'APPROVED' &&
                approval.approvalStatusCode !== 'REJECTED' && (
                  <button
                    onClick={() => setShowPinApproval(true)}
                    className="form-button-primary mt-2"
                    disabled={loading}
                  >
                    {i18n.t('literals.telefonos-jovahagyas-supervisor-pin')}
                  </button>
                )}
            </div>
          </div>
        </div>
      )}

      <StornoPinApprovalModal
        open={showPinApproval && !!approval}
        currentWorkerId={Number(workerId)}
        approvalId={approval?.id ?? ''}
        onApproved={(updated) => {
          setApproval(updated)
          setShowPinApproval(false)
          setError(null)
        }}
        onCancel={() => setShowPinApproval(false)}
      />

      {/* Storno Form */}
      {(!checkResult.requiresApproval || approval?.approvalStatusCode === 'APPROVED') && (
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

            {/* D.1 (2026-06-12): az „Egyedi árfolyam" és „Fizetési mód" mezők eltávolítva —
                a sztornó mindig az eredeti árfolyammal és fizetési móddal könyvel. */}
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

      {/* D.2 (2026-06-12): sztornó-bizonylat előnézet + nyomtatás a végrehajtás után.
          A meglévő 'storno' template-et használja (printer.ts + ReceiptPreviewModal);
          a navigáció a modal zárásakor történik, hogy a siker-üzenet ne vesszen el. */}
      <ReceiptPreviewModal
        isOpen={receiptData !== null}
        onClose={() => {
          if (!printAttemptedRef.current) {
            toast.info('Sztornó befejezve', 'A bizonylatot megtekintette nyomtatás nélkül.')
          }
          printAttemptedRef.current = false
          setReceiptData(null)
          navigate('/transactions', { state: { message: successMessage } })
        }}
        receiptData={receiptData}
        qrCodeDataUrl={null}
        allowPrint={isElectron()}
        onPrint={async () => {
          // Copilot PR #1100: a hibás ágak THROW-val zárulnak — a ReceiptPreviewModal csak
          // SIKERES onPrint után zár be (2s auto-close), hiba esetén nyitva marad (újrapróbálható).
          printAttemptedRef.current = true
          if (!receiptData) {
            toast.warning('Nyomtatás kihagyva', 'Nincs aktív bizonylat-adat.')
            throw new Error('Nincs aktív bizonylat-adat')
          }
          if (!window.electronAPI?.printReceipt) {
            toast.warning(
              'Nyomtatás nem elérhető',
              isElectron()
                ? 'Electron preload/electronAPI wiring sikertelen — indítsa újra a klienst.'
                : 'Webes módban nincs nyomtatás. Telepítse az Electron klienst.',
            )
            throw new Error('printReceipt nem elérhető')
          }
          try {
            const success = await window.electronAPI.printReceipt(JSON.stringify(receiptData))
            if (!success) {
              toast.error(
                'Nyomtatás sikertelen',
                'A nyomtató offline / nincs konfigurálva / papír kifogyott. ' +
                  'Beállítások > Nyomtatás → ellenőrizze a soros port + nyomtató nevet.',
              )
              throw new Error('Nyomtatás sikertelen')
            }
            toast.success(
              'Nyomtatás elindítva',
              `Sztornó bizonylat: ${receiptData.receiptNumber ?? '—'}`,
            )
          } catch (err) {
            if (!(err instanceof Error && err.message === 'Nyomtatás sikertelen')) {
              const msg = err instanceof Error ? err.message : 'Ismeretlen hiba'
              toast.error('Nyomtatás váratlan hiba', msg)
            }
            throw err
          }
        }}
        printLabel={isElectron() ? undefined : 'Nyomtatás nem elérhető'}
      />
    </div>
  )
}
