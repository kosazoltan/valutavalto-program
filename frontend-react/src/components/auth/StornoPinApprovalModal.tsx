import { useEffect, useRef, useState } from 'react'
import { api } from '../../services/api/client'
import { stornoApi, StornoApproval } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

/**
 * Sztornó telefonos supervisor-PIN jóváhagyás modal (egyszemélyes iroda üzleti döntés,
 * 2026-06-10). Az AmlApproverModal mintája: a pénztáros kiválasztja a telefonon elérhető
 * supervisort (saját maga KIZÁRVA — 4-szem-elv), a supervisor telefonon bediktálja a
 * PIN-jét, a backend (`POST /stornos/approve-by-pin`) validál (4-szem KEMÉNYEN + szerepkör
 * + cég + PIN lockout/audit), és a jóváhagyás azonnal APPROVED állapotba kerül.
 */

interface EligibleApprover {
  id: number
  role?: string
  fullName?: string
  firstName?: string
  lastName?: string
}

interface Props {
  open: boolean
  /** A bejelentkezett pénztáros workerId-ja — KIZÁRVA a jóváhagyó-listából (4-szem-elv). */
  currentWorkerId: number
  /** A függő sztornó-jóváhagyási kérés azonosítója. */
  approvalId: string
  /** Sikeres jóváhagyás után — a frissített approval-lal. */
  onApproved: (approval: StornoApproval) => void
  onCancel: () => void
}

const ELIGIBLE_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
const PIN_LENGTH = 6

function approverLabel(a: EligibleApprover): string {
  if (a.fullName && a.fullName.trim()) return a.fullName
  const composed = `${a.lastName ?? ''} ${a.firstName ?? ''}`.trim()
  return composed || `#${a.id}`
}

export default function StornoPinApprovalModal({
  open,
  currentWorkerId,
  approvalId,
  onApproved,
  onCancel,
}: Props) {
  const [approvers, setApprovers] = useState<EligibleApprover[]>([])
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [pin, setPin] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const pinRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (!open) return
    setSelectedId(null)
    setPin('')
    setError(null)
    setSubmitting(false)
    setLoading(true)
    void (async () => {
      try {
        const res = await api.get<EligibleApprover[]>('/workers/active')
        const list = Array.isArray(res.data) ? res.data : []
        // Jogosult szerepkör + a saját maga kizárva (4-szem-elv).
        setApprovers(
          list.filter(
            (w) => w.role != null && ELIGIBLE_ROLES.includes(w.role) && w.id !== currentWorkerId,
          ),
        )
      } catch (err) {
        logger.error(
          'StornoPinApprovalModal',
          'Jóváhagyó-lista betöltési hiba:',
          getErrorMessage(err),
        )
        setError('Nem sikerült betölteni a jóváhagyásra jogosult dolgozók listáját.')
      } finally {
        setLoading(false)
      }
    })()
  }, [open, currentWorkerId])

  if (!open) return null

  const handleSubmit = async (submittedPin: string): Promise<void> => {
    if (!selectedId || submittedPin.length < 4) return
    setSubmitting(true)
    setError(null)
    try {
      const approval = await stornoApi.approveByPin(approvalId, selectedId, submittedPin, true)
      onApproved(approval)
    } catch (err) {
      logger.warn('StornoPinApprovalModal', 'PIN-jóváhagyás hiba:', getErrorMessage(err))
      const errorBody = (err as { response?: { data?: { message?: string; error?: string } } })
        .response?.data
      setError(errorBody?.message ?? errorBody?.error ?? 'Hibás PIN vagy ideiglenes lockout')
      setPin('')
    } finally {
      setSubmitting(false)
    }
  }

  const handlePinChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(/\D/g, '').slice(0, PIN_LENGTH)
    setPin(value)
    setError(null)
    // Auto-submit ha 6 számjegy beíródott
    if (value.length === 6 && selectedId) {
      void handleSubmit(value)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && pin.length >= 4) {
      void handleSubmit(pin)
    } else if (e.key === 'Escape') {
      onCancel()
    }
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="storno-pin-approval-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-sm rounded-lg bg-white p-6 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="storno-pin-approval-title" className="mb-2 text-lg font-bold">
          {i18n.t('literals.telefonos-supervisor-jovahagyas')}
        </h2>
        <p className="mb-4 text-sm text-gray-600">
          {i18n.t('literals.hivja-fel-a-supervisort-valassza-ki-a-ne')}
        </p>

        <label className="form-label">{i18n.t('literals.jovahagyo-supervisor')}</label>
        <select
          value={selectedId ?? ''}
          onChange={(e) => {
            setSelectedId(e.target.value ? Number(e.target.value) : null)
            setError(null)
            setTimeout(() => pinRef.current?.focus(), 50)
          }}
          disabled={loading || submitting}
          className="form-input mb-3 w-full"
        >
          <option value="">{loading ? 'Betöltés…' : '— Válasszon —'}</option>
          {approvers.map((a) => (
            <option key={a.id} value={a.id}>
              {approverLabel(a)}
              {i18n.t('literals.lit')}
              {a.role}
              {i18n.t('literals.lit-2')}
            </option>
          ))}
        </select>

        <label className="form-label">{i18n.t('literals.supervisor-pin')}</label>
        <input
          ref={pinRef}
          type="password"
          inputMode="numeric"
          autoComplete="off"
          value={pin}
          onChange={handlePinChange}
          onKeyDown={handleKeyDown}
          disabled={submitting || !selectedId}
          placeholder="••••••"
          className="mb-3 w-full rounded border border-gray-300 px-3 py-2 text-center text-2xl tracking-widest font-mono focus:border-blue-500 focus:outline-none disabled:opacity-50"
          maxLength={PIN_LENGTH}
        />

        {error && (
          <div className="mb-3 rounded border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800">
            {error}
          </div>
        )}

        <div className="flex justify-end space-x-2">
          <button
            onClick={onCancel}
            disabled={submitting}
            className="rounded border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50 disabled:opacity-50"
          >
            {i18n.t('literals.megse')}
          </button>
          <button
            onClick={() => void handleSubmit(pin)}
            disabled={submitting || pin.length < 4 || !selectedId}
            className="rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {submitting ? 'Ellenőrzés…' : 'Jóváhagyás'}
          </button>
        </div>

        <p className="mt-4 text-xs text-gray-500">
          {i18n.t('literals.3-hibas-probalkozas-utan-5-perc-lockout')}
        </p>
      </div>
    </div>
  )
}
