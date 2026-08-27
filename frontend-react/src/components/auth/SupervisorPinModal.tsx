import { useEffect, useRef, useState } from 'react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

/**
 * P2-2 Supervisor PIN Modal — gyors-engedély 4-6 számjegyhez.
 *
 * Használat:
 * <pre>
 * &lt;SupervisorPinModal
 *   open={showPin}
 *   workerId={123}
 *   onSuccess={() => doStorno()}
 *   onCancel={() => setShowPin(false)}
 * /&gt;
 * </pre>
 */

interface Props {
  open: boolean
  workerId: number
  /** Feliratkozó workerCode/workerName a UI-hez (opcionális) */
  workerLabel?: string
  /** Sikeres PIN után. */
  onSuccess: () => void
  onCancel: () => void
}

const PIN_LENGTH = 6 // max 6, de 4 is engedélyezett

export default function SupervisorPinModal({
  open,
  workerId,
  workerLabel,
  onSuccess,
  onCancel,
}: Props) {
  const [pin, setPin] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (open) {
      setPin('')
      setError(null)
      setSubmitting(false)
      // Auto-focus a PIN input-ra megnyitáskor
      setTimeout(() => inputRef.current?.focus(), 50)
    }
  }, [open])

  if (!open) return null

  const handleSubmit = async (submittedPin: string) => {
    setSubmitting(true)
    setError(null)
    try {
      const res = await api.post('/supervisor-pin/verify', { workerId, pin: submittedPin })
      if (res.data?.ok) {
        onSuccess()
      } else {
        setError(res.data?.error ?? 'Hibás PIN')
        setPin('')
      }
    } catch (err) {
      logger.warn('SupervisorPinModal', 'PIN verify hiba:', getErrorMessage(err))
      // Axios error a backend 401-re — body-ban van az "error" mező
      const errorBody = (err as { response?: { data?: { error?: string } } }).response?.data
      setError(errorBody?.error ?? 'Hibás PIN vagy ideiglenes lockout')
      setPin('')
    } finally {
      setSubmitting(false)
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(/\D/g, '').slice(0, PIN_LENGTH)
    setPin(value)
    setError(null)
    // Auto-submit ha 6 számjegy beíródott
    if (value.length === 6) {
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
      aria-labelledby="supervisor-pin-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-sm rounded-lg bg-white p-6 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="supervisor-pin-title" className="mb-2 text-lg font-bold">
          {i18n.t('literals.supervisor-pin-szukseges')}
        </h2>
        {workerLabel && (
          <p className="mb-3 text-sm text-gray-600">
            {i18n.t('literals.felhasznalo')}
            <strong>{workerLabel}</strong>
          </p>
        )}
        <p className="mb-4 text-sm text-gray-600">
          {i18n.t('literals.adja-meg-a-4-6-szamjegyu-pin-t-a-muvelet')}
        </p>

        <input
          ref={inputRef}
          type="password"
          inputMode="numeric"
          autoComplete="off"
          value={pin}
          onChange={handleChange}
          onKeyDown={handleKeyDown}
          disabled={submitting}
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
            disabled={submitting || pin.length < 4}
            className="rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {submitting ? 'Ellenőrzés…' : 'Megerősítés'}
          </button>
        </div>

        <p className="mt-4 text-xs text-gray-500">
          {i18n.t('literals.3-hibas-probalkozas-utan-5-perc-lockout-2')}
        </p>
      </div>
    </div>
  )
}
