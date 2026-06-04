import { useEffect, useRef, useState } from 'react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'

/**
 * AML felsővezetői jóváhagyás modal (2026-06-04).
 *
 * Amikor egy tranzakció AML-küszöböt lép át (FATF / éves göngyölési limit ≥3.6M / BIGCTRL 4+), a
 * PÉNZTÁROS itt kér jóváhagyást egy supervisor/manager/admin kollégától: kiválasztja az engedélyezőt
 * (a saját maga KIZÁRVA — 4-szem-elv), a kolléga beírja a supervisor-PIN-jét, majd a backend
 * (`POST /api/v1/aml-approval/verify-approver`) validál (szerepkör + cég + 4-szem + PIN). Siker esetén
 * a kapott `approverWorkerId` a tranzakció-rögzítésbe kerül; a backend a tranzakció-POST-kor MÉGEGYSZER
 * validál és INSERT-only audit-rekordba menti az engedélyező nevét.
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
  /** A bejelentkezett (rögzítő) pénztáros workerId-ja — KIZÁRVA a listából (4-szem-elv). */
  currentWorkerId: number
  /** A jóváhagyást kiváltó AML-indok (megjelenítéshez). */
  reason?: string
  /**
   * A jóváhagyás-session azonosítója (a hívó oldal generálja, és UGYANEZT teszi a tranzakcióba) —
   * a backend a grantot ehhez köti, így a maradék felhasználások csak EHHEZ a nyugtához érvényesek
   * (Codex P1: receipt-scoping).
   */
  sessionId: string
  /**
   * A nyugta tényleges sorszáma — a backend ennyi felhasználású grantot állít ki (Codex P1). A penztar-client
   * a multi-line nyugtát N független tranzakcióként synkronizálja UGYANAZZAL a session-nel, mind megütheti az
   * AML-kaput → N grant-felhasználás kell. Single-line/konverzió → 1. Server-side [1, MAX_LINES]-re klampelt.
   * Hiányzó/0 → 1.
   */
  grantUses?: number
  /** Sikeres jóváhagyás után — a validált engedélyező adataival. */
  onApproved: (approverWorkerId: number, approverName: string) => void
  onCancel: () => void
}

const ELIGIBLE_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
const PIN_LENGTH = 6

function approverLabel(a: EligibleApprover): string {
  if (a.fullName && a.fullName.trim()) return a.fullName
  const composed = `${a.lastName ?? ''} ${a.firstName ?? ''}`.trim()
  return composed || `#${a.id}`
}

export default function AmlApproverModal({ open, currentWorkerId, reason, sessionId, grantUses, onApproved, onCancel }: Props) {
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
        logger.warn('AmlApproverModal', 'Engedélyező-lista betöltés hiba:', err)
        setError('Az engedélyező-lista nem tölthető be (offline?). Jóváhagyás online kapcsolatot igényel.')
      } finally {
        setLoading(false)
      }
    })()
  }, [open, currentWorkerId])

  if (!open) return null

  const handleSubmit = async () => {
    if (selectedId == null || pin.length < 4) return
    setSubmitting(true)
    setError(null)
    try {
      const res = await api.post('/aml-approval/verify-approver', {
        approverWorkerId: selectedId,
        pin,
        approvalSessionId: sessionId,
        // A nyugta sorszáma → ennyi felhasználású grant (multi-line per-soros sync; Codex P1). Default 1.
        grantUses: grantUses && grantUses > 0 ? grantUses : 1,
      })
      if (res.data?.ok) {
        onApproved(Number(res.data.approverWorkerId), String(res.data.approverName ?? ''))
      } else {
        setError(res.data?.error ?? 'Sikertelen jóváhagyás')
        setPin('')
      }
    } catch (err) {
      logger.warn('AmlApproverModal', 'verify-approver hiba:', err)
      const body = (err as { response?: { data?: { error?: string } } }).response?.data
      setError(body?.error ?? 'Hibás PIN vagy ideiglenes lockout')
      setPin('')
    } finally {
      setSubmitting(false)
    }
  }

  const handlePinChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPin(e.target.value.replace(/\D/g, '').slice(0, PIN_LENGTH))
    setError(null)
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="aml-approver-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onCancel}
    >
      <div className="w-full max-w-md rounded-lg bg-white p-6 shadow-xl" onClick={(e) => e.stopPropagation()}>
        <h2 id="aml-approver-title" className="mb-2 text-lg font-bold text-amber-800">
          AML felsővezetői jóváhagyás szükséges
        </h2>
        {reason && (
          <p className="mb-3 rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
            {reason}
          </p>
        )}
        <p className="mb-3 text-sm text-gray-600">
          A tranzakció rögzítéséhez egy supervisor / vezető jóváhagyása kell (4-szem-elv). Válassza ki az
          engedélyezőt, és kérje a PIN-jét.
        </p>

        {loading ? (
          <p className="py-4 text-center text-gray-500">Engedélyezők betöltése…</p>
        ) : (
          <>
            <label className="mb-1 block text-sm font-semibold text-gray-700">Engedélyező</label>
            <select
              value={selectedId ?? ''}
              onChange={(e) => {
                setSelectedId(e.target.value ? Number(e.target.value) : null)
                setError(null)
                setTimeout(() => pinRef.current?.focus(), 50)
              }}
              disabled={submitting}
              className="mb-3 w-full rounded border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none disabled:opacity-50"
            >
              <option value="">— válasszon engedélyezőt —</option>
              {approvers.map((a) => (
                <option key={a.id} value={a.id}>
                  {approverLabel(a)} ({a.role})
                </option>
              ))}
            </select>
            {approvers.length === 0 && (
              <p className="mb-3 text-sm text-amber-700">
                Nincs elérhető jogosult engedélyező (supervisor/manager/admin) a cégben.
              </p>
            )}

            <label className="mb-1 block text-sm font-semibold text-gray-700">Engedélyező PIN-je</label>
            <input
              ref={pinRef}
              type="password"
              inputMode="numeric"
              autoComplete="off"
              value={pin}
              onChange={handlePinChange}
              onKeyDown={(e) => {
                if (e.key === 'Enter') void handleSubmit()
                else if (e.key === 'Escape') onCancel()
              }}
              disabled={submitting || selectedId == null}
              placeholder="••••••"
              className="mb-3 w-full rounded border border-gray-300 px-3 py-2 text-center text-2xl tracking-widest font-mono focus:border-blue-500 focus:outline-none disabled:opacity-50"
              maxLength={PIN_LENGTH}
            />
          </>
        )}

        {error && (
          <div className="mb-3 rounded border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800">{error}</div>
        )}

        <div className="flex justify-end space-x-2">
          <button
            onClick={onCancel}
            disabled={submitting}
            className="rounded border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50 disabled:opacity-50"
          >
            Mégse
          </button>
          <button
            onClick={() => void handleSubmit()}
            disabled={submitting || loading || selectedId == null || pin.length < 4}
            className="rounded bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 disabled:opacity-50"
          >
            {submitting ? 'Ellenőrzés…' : 'Jóváhagyás'}
          </button>
        </div>

        <p className="mt-4 text-xs text-gray-500">
          Az engedélyező nem lehet a tranzakciót rögzítő pénztáros. 3 hibás PIN után 5 perc lockout.
        </p>
      </div>
    </div>
  )
}
