import { useEffect, useRef, useState } from 'react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

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

/**
 * EXCMD b3-engedelyezes-adatok FR-AUTH-01..05: az engedélykérő ADATLAP tartalma —
 * a döntéshozó engedélyező ezt látja a PIN megadása előtt. Minden mező opcionális
 * (a hívó azt adja át, ami a flow-ban rendelkezésre áll); az engedélyező-rögzítés
 * (FR-AUTH-06) a backend TransactionAmlApproval audit-rekordjában történik.
 */
export interface ApprovalRequestDetails {
  /** FR-AUTH-01: kezdeményező pénztár száma + neve. */
  branchCode?: string
  branchName?: string
  /** FR-AUTH-02: bizonylat-referencia — a végleges bizonylatszám a rögzítéskor keletkezik. */
  receiptReference?: string
  /** FR-AUTH-03: a tranzakció teljes forintértéke. */
  totalHuf?: number
  /** FR-AUTH-04: valuta-soronkénti bontás (összeg / valutanem / árfolyam / forintérték). */
  lines?: Array<{ currencyCode: string; amount: number; rate: number; hufValue: number }>
  /** FR-AUTH-05: ügyfél-azonosító adatok (Pmt. szerinti kör). */
  customer?: {
    name?: string
    motherName?: string
    birthDate?: string
    birthPlace?: string
    address?: string
    residence?: string
    documentType?: string
    documentNumber?: string
    nationality?: string
  }
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
   * A jóváhagyott ügyfél neve — a backend a SINGLE-USE grantot ehhez köti (Codex P1). A multi-line nyugta
   * minden sora ugyanazt az ügyfelet viszi: az első sor elhasználja a grantot, a többi (ugyanaz a session +
   * ügyfél) jóváhagyás-fedettként átmegy. MÁS ügyfélre újrahasznált session elbukik → nincs amplifikáció.
   */
  customerName?: string
  /** FR-AUTH-01..05: az engedélykérő adatlap tartalma (opcionális — ha nincs, csak az indok látszik). */
  details?: ApprovalRequestDetails
  /** Sikeres jóváhagyás után — a validált engedélyező adataival. */
  onApproved: (approverWorkerId: number, approverName: string) => void
  onCancel: () => void
}

const HUF_FMT = new Intl.NumberFormat('hu-HU')

const ELIGIBLE_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
const PIN_LENGTH = 6

/**
 * Sourcery review (#1089): közös CustomerPanel-adat → adatlap-ügyfél leképezés, hogy a
 * hívóhelyek (kassza + konverzió) ne duplikálják és ne drifteljenek szét.
 */
export function toApprovalCustomer(
  data: {
    name: string
    motherName?: string
    birthDate?: string
    birthPlace?: string
    address?: string
    residence?: string
    documentType?: string
    documentNumber?: string
    nationality?: string
  } | null,
): ApprovalRequestDetails['customer'] {
  if (!data) return undefined
  return {
    name: data.name,
    motherName: data.motherName,
    birthDate: data.birthDate,
    birthPlace: data.birthPlace,
    address: data.address,
    residence: data.residence,
    documentType: data.documentType,
    documentNumber: data.documentNumber,
    nationality: data.nationality,
  }
}

function approverLabel(a: EligibleApprover): string {
  if (a.fullName && a.fullName.trim()) return a.fullName
  const composed = `${a.lastName ?? ''} ${a.firstName ?? ''}`.trim()
  return composed || `#${a.id}`
}

export default function AmlApproverModal({
  open,
  currentWorkerId,
  reason,
  sessionId,
  customerName,
  details,
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
        logger.warn('AmlApproverModal', 'Engedélyező-lista betöltés hiba:', getErrorMessage(err))
        setError(
          'Az engedélyező-lista nem tölthető be (offline?). Jóváhagyás online kapcsolatot igényel.',
        )
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
        // A jóváhagyott ügyfél neve → a backend a single-use grantot ehhez köti (Codex P1: customer-scoping).
        customerName: customerName ?? undefined,
      })
      if (res.data?.ok) {
        onApproved(Number(res.data.approverWorkerId), String(res.data.approverName ?? ''))
      } else {
        setError(res.data?.error ?? 'Sikertelen jóváhagyás')
        setPin('')
      }
    } catch (err) {
      logger.warn('AmlApproverModal', 'verify-approver hiba:', getErrorMessage(err))
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
      <div
        className="w-full max-w-md rounded-lg bg-white p-6 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="aml-approver-title" className="mb-2 text-lg font-bold text-amber-800">
          {i18n.t('literals.aml-felsovezetoi-jovahagyas-szukseges')}
        </h2>
        {reason && (
          <p className="mb-3 rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
            {reason}
          </p>
        )}

        {/* EXCMD b3 FR-AUTH-01..05: engedélykérő adatlap — a döntéshez szükséges teljes kontextus */}
        {details && (
          <div className="mb-3 rounded border border-gray-200 bg-gray-50 px-3 py-2 text-sm">
            <div className="mb-1 font-semibold text-gray-700">
              {i18n.t('literals.engedelykero-adatlap')}
            </div>
            <div className="grid grid-cols-2 gap-x-3 gap-y-0.5">
              {(details.branchCode || details.branchName) && (
                <>
                  <span className="text-gray-500">{i18n.t('literals.penztar')}</span>
                  <span>
                    {[details.branchCode, details.branchName].filter(Boolean).join(' — ')}
                  </span>
                </>
              )}
              <span className="text-gray-500">{i18n.t('literals.bizonylatszam')}</span>
              <span>{details.receiptReference || 'a rögzítéskor keletkezik'}</span>
              {typeof details.totalHuf === 'number' && Number.isFinite(details.totalHuf) && (
                <>
                  <span className="text-gray-500">{i18n.t('literals.tranz-osszege')}</span>
                  <span className="font-mono">
                    {HUF_FMT.format(details.totalHuf)}
                    {i18n.t('literals.ft')}
                  </span>
                </>
              )}
            </div>
            {details.lines && details.lines.length > 0 && (
              <table className="mt-1 w-full text-xs">
                <thead>
                  <tr className="text-gray-500">
                    <th className="text-left font-normal">{i18n.t('literals.valuta')}</th>
                    <th className="text-right font-normal">{i18n.t('literals.osszeg')}</th>
                    <th className="text-right font-normal">{i18n.t('literals.arfolyam')}</th>
                    <th className="text-right font-normal">{i18n.t('literals.forintertek')}</th>
                  </tr>
                </thead>
                <tbody>
                  {details.lines.map((l, i) => (
                    <tr key={`${l.currencyCode}-${i}`}>
                      <td>{l.currencyCode}</td>
                      <td className="text-right font-mono">{HUF_FMT.format(l.amount)}</td>
                      <td className="text-right font-mono">{l.rate}</td>
                      <td className="text-right font-mono">
                        {HUF_FMT.format(l.hufValue)}
                        {i18n.t('literals.ft')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
            {details.customer && (
              <div className="mt-1 border-t pt-1 text-xs text-gray-700">
                <span className="font-semibold">{i18n.t('literals.ugyfel')}</span>{' '}
                {[
                  details.customer.name,
                  details.customer.motherName && `anyja neve: ${details.customer.motherName}`,
                  details.customer.birthPlace && details.customer.birthDate
                    ? `szül.: ${details.customer.birthPlace}, ${details.customer.birthDate}`
                    : details.customer.birthDate && `szül.: ${details.customer.birthDate}`,
                  details.customer.address && `lakcím: ${details.customer.address}`,
                  details.customer.residence && `tartózkodási hely: ${details.customer.residence}`,
                  details.customer.documentType && details.customer.documentNumber
                    ? `okmány: ${details.customer.documentType} ${details.customer.documentNumber}`
                    : details.customer.documentNumber &&
                      `okmány: ${details.customer.documentNumber}`,
                  details.customer.nationality && `állampolgárság: ${details.customer.nationality}`,
                ]
                  .filter(Boolean)
                  .join(' · ')}
              </div>
            )}
          </div>
        )}
        <p className="mb-3 text-sm text-gray-600">
          {i18n.t('literals.a-tranzakcio-rogzitesehez-egy-supervisor')}
        </p>

        {loading ? (
          <p className="py-4 text-center text-gray-500">
            {i18n.t('literals.engedelyezok-betoltese')}
          </p>
        ) : (
          <>
            <label className="mb-1 block text-sm font-semibold text-gray-700">
              {i18n.t('literals.engedelyezo')}
            </label>
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
              <option value="">{i18n.t('literals.valasszon-engedelyezot')}</option>
              {approvers.map((a) => (
                <option key={a.id} value={a.id}>
                  {approverLabel(a)}
                  {i18n.t('literals.lit')}
                  {a.role}
                  {i18n.t('literals.lit-2')}
                </option>
              ))}
            </select>
            {approvers.length === 0 && (
              <p className="mb-3 text-sm text-amber-700">
                {i18n.t('literals.nincs-elerheto-jogosult-engedelyezo-supe')}
              </p>
            )}

            <label className="mb-1 block text-sm font-semibold text-gray-700">
              {i18n.t('literals.engedelyezo-pin-je')}
            </label>
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
            onClick={() => void handleSubmit()}
            disabled={submitting || loading || selectedId == null || pin.length < 4}
            className="rounded bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 disabled:opacity-50"
          >
            {submitting ? 'Ellenőrzés…' : 'Jóváhagyás'}
          </button>
        </div>

        <p className="mt-4 text-xs text-gray-500">
          {i18n.t('literals.az-engedelyezo-nem-lehet-a-tranzakciot-r')}
        </p>
      </div>
    </div>
  )
}
