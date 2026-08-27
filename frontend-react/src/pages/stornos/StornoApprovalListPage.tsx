import { useState, useEffect, useCallback } from 'react'
import { AlertCircle, CheckCircle, XCircle, RefreshCw, ClipboardCheck } from 'lucide-react'
import { stornoApi, StornoApproval } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

/**
 * Supervisor sztornó-jóváhagyó lista (#954 four-eyes go-live előfeltétel).
 *
 * A pénztáros a StornoPage-en kér jóváhagyást (napi limit felett); eddig a
 * jóváhagyásnak NEM volt UI-ja — a backend /stornos/approve végpontot semmi
 * nem hívta. Ez az oldal listázza a saját iroda függő (PENDING) kéréseit, és
 * jóváhagyás/elutasítás gombokkal zárja a kört. A 4-szem-elv (saját kérés
 * jóváhagyásának tiltása) a backendben enforced — a hibaüzenetét ez az oldal
 * változtatás nélkül megjeleníti.
 */
export default function StornoApprovalListPage() {
  const [approvals, setApprovals] = useState<StornoApproval[]>([])
  const [loading, setLoading] = useState(false)
  const [actingId, setActingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [rejectReasons, setRejectReasons] = useState<Record<string, string>>({})

  const loadPending = useCallback(async (): Promise<void> => {
    try {
      setLoading(true)
      setError(null)
      const result = await stornoApi.pendingApprovals()
      setApprovals(result)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('StornoApprovalListPage', 'Failed to load pending approvals:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadPending()
  }, [loadPending])

  const handleDecision = async (approval: StornoApproval, approved: boolean): Promise<void> => {
    const reason = rejectReasons[approval.id]?.trim()
    if (!approved && !reason) {
      setError('Elutasításhoz kötelező az indoklás!')
      return
    }

    try {
      setActingId(approval.id)
      setError(null)
      await stornoApi.approve(approval.id, approved, approved ? undefined : reason)
      setMessage(
        approved
          ? `Sztornó-kérés engedélyezve (${approval.receiptNumber || approval.transactionId}).`
          : `Sztornó-kérés elutasítva (${approval.receiptNumber || approval.transactionId}).`,
      )
      await loadPending()
    } catch (err) {
      // 4-szem-elv: a backend ValidationException-je (saját kérés jóváhagyása tiltva)
      // itt jelenik meg a supervisor számára.
      setError(getErrorMessage(err))
      logger.error('StornoApprovalListPage', 'Failed to decide approval:', err)
    } finally {
      setActingId(null)
    }
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <ClipboardCheck size={22} className="text-gray-700" />
          <h1 className="text-xl font-bold text-gray-800">
            {i18n.t('literals.sztorno-jovahagyasok')}
          </h1>
        </div>
        <button
          onClick={() => void loadPending()}
          disabled={loading}
          className="toolbar-button flex items-center gap-2"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          {i18n.t('literals.frissites')}
        </button>
      </div>

      {/* Error / Message */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}
      {message && (
        <div className="form-panel bg-green-50 border-green-200">
          <div className="flex items-center gap-2 text-green-700">
            <CheckCircle size={16} />
            <span>{message}</span>
          </div>
        </div>
      )}

      {/* Pending list */}
      {!loading && approvals.length === 0 && (
        <div className="form-panel text-gray-500">
          {i18n.t('literals.nincs-fuggo-sztorno-jovahagyasi-keres-az')}
        </div>
      )}

      {approvals.map((approval) => (
        <div key={approval.id} className="form-panel bg-yellow-50 border-yellow-200">
          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <label className="form-label">{i18n.t('literals.bizonylatszam-2')}</label>
              <div className="form-input bg-gray-50 font-mono">
                {approval.receiptNumber || approval.transactionId}
              </div>
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.kerelmezo')}</label>
              <div className="form-input bg-gray-50">
                {approval.workerName || approval.workerId}
              </div>
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.keres-idopontja')}</label>
              <div className="form-input bg-gray-50">
                {approval.createdAt ? new Date(approval.createdAt).toLocaleString('hu-HU') : '—'}
              </div>
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.napi-sztornok-szama')}</label>
              <div className="form-input bg-gray-50">{approval.dailyStornoCount}</div>
            </div>
            <div className="col-span-2">
              <label className="form-label">{i18n.t('literals.sztorno-oka')}</label>
              <div className="form-input bg-gray-50">{approval.requestReason}</div>
            </div>
            <div className="col-span-2">
              <label className="form-label">
                {i18n.t('literals.elutasitas-indoka-elutasitashoz-kotelezo')}
              </label>
              <input
                type="text"
                value={rejectReasons[approval.id] ?? ''}
                onChange={(e) =>
                  setRejectReasons((prev) => ({ ...prev, [approval.id]: e.target.value }))
                }
                className="form-input"
                placeholder="Csak elutasítás esetén szükséges..."
                disabled={actingId === approval.id}
              />
            </div>
          </div>
          <div className="flex gap-3 pt-3 border-t border-yellow-200">
            <button
              onClick={() => void handleDecision(approval, true)}
              disabled={actingId === approval.id}
              className="form-button-primary flex items-center gap-2"
            >
              <CheckCircle size={16} />
              {i18n.t('literals.engedelyezes')}
            </button>
            <button
              onClick={() => void handleDecision(approval, false)}
              disabled={actingId === approval.id || !rejectReasons[approval.id]?.trim()}
              className="form-button flex items-center gap-2 text-red-700"
            >
              <XCircle size={16} />
              {i18n.t('literals.elutasitas')}
            </button>
          </div>
        </div>
      ))}
    </div>
  )
}
