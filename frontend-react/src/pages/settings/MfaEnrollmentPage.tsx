import { useState, useEffect } from 'react'
import { Loader2, Shield, ShieldCheck, ShieldOff, CheckCircle2 } from 'lucide-react'
import { api } from '../../services/api/client'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'

interface MfaStatusResponse {
  enabled: boolean
}

interface EnrollmentResponse {
  secret: string
  otpAuthUrl: string
  qrCodePngBase64: string
}

interface EnrollmentCompleteResponse {
  backupCodes: string[]
  message: string
}

type State = 'IDLE' | 'ENROLLING' | 'ENROLLED'

/**
 * v2.5.50 Sprint 3.C: MFA / TOTP self-enrollment UI.
 *
 * Folyamat:
 * 1. Status lekérdezés (enabled?)
 * 2. Ha nem enabled → "Bekapcsolás" → POST /enroll/start → QR + secret megjelenítés
 * 3. User beolvassa Google Authenticator-rel → beír egy TOTP kódot → POST /enroll/complete
 * 4. Backup codes megjelenítés (egyszer látható!)
 */
export default function MfaEnrollmentPage() {
  const [state, setState] = useState<State>('IDLE')
  const [statusLoading, setStatusLoading] = useState(true)
  const [enabled, setEnabled] = useState(false)
  const [enrollment, setEnrollment] = useState<EnrollmentResponse | null>(null)
  const [code, setCode] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [backupCodes, setBackupCodes] = useState<string[] | null>(null)

  useEffect(() => {
    void loadStatus()
  }, [])

  const loadStatus = async () => {
    setStatusLoading(true)
    try {
      const res = await api.get<MfaStatusResponse>('/mfa/status')
      setEnabled(res.data.enabled)
      if (res.data.enabled) {
        setState('ENROLLED')
      }
    } catch (err) {
      logger.error('MfaEnrollment', 'Status lekérdezés hiba:', err)
    } finally {
      setStatusLoading(false)
    }
  }

  const handleStartEnrollment = async () => {
    setSubmitting(true)
    try {
      const res = await api.post<EnrollmentResponse>('/mfa/enroll/start', {})
      setEnrollment(res.data)
      setState('ENROLLING')
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Ismeretlen hiba'
      toast.error('Hiba', msg)
      logger.error('MfaEnrollment', 'Enrollment indítás hiba:', err)
    } finally {
      setSubmitting(false)
    }
  }

  const handleCompleteEnrollment = async () => {
    if (!/^\d{6}$/.test(code)) {
      toast.error('Hiba', 'A TOTP kód pontosan 6 számjegyű legyen')
      return
    }
    setSubmitting(true)
    try {
      const res = await api.post<EnrollmentCompleteResponse>('/mfa/enroll/complete', { code })
      setBackupCodes(res.data.backupCodes)
      setState('ENROLLED')
      setEnabled(true)
      toast.success('MFA aktiválva', res.data.message)
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Érvénytelen TOTP kód'
      toast.error('Hiba', msg)
      logger.error('MfaEnrollment', 'Enrollment complete hiba:', err)
    } finally {
      setSubmitting(false)
    }
  }

  if (statusLoading) {
    return (
      <div className="flex items-center gap-2 text-gray-500 p-4">
        <Loader2 className="h-4 w-4 animate-spin" />
        <span>MFA állapot betöltése...</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="section-title flex items-center gap-2">
          <Shield size={18} />
          Kétfaktoros hitelesítés (TOTP)
        </h2>
        <div className="flex items-center gap-1 text-sm">
          {enabled ? (
            <>
              <ShieldCheck size={16} className="text-green-600" />
              <span className="text-green-700">Aktív</span>
            </>
          ) : (
            <>
              <ShieldOff size={16} className="text-gray-400" />
              <span className="text-gray-500">Inaktív</span>
            </>
          )}
        </div>
      </div>

      <div className="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-800">
        <strong>Ajánlott:</strong> kapcsold be a kétfaktoros hitelesítést, hogy a bejelentkezésnél
        egy Google Authenticator (vagy Microsoft Authenticator / Authy) által generált 6-jegyű
        kód is kelljen. Ez különösen fontos vezetői / admin / compliance szerepkörnél.
      </div>

      {state === 'IDLE' && !enabled && (
        <div className="space-y-3">
          <p className="text-sm text-gray-700">
            A MFA még NINCS aktiválva ehhez a fiókhoz. Kattints a gombra a folyamat elindításához.
          </p>
          <button
            className="form-button-primary"
            onClick={() => void handleStartEnrollment()}
            disabled={submitting}
          >
            {submitting ? <Loader2 size={14} className="animate-spin inline mr-1" /> : null}
            Kétfaktoros hitelesítés bekapcsolása
          </button>
        </div>
      )}

      {state === 'ENROLLING' && enrollment && (
        <div className="space-y-4">
          <div className="p-3 rounded border border-amber-200 bg-amber-50">
            <p className="font-medium text-amber-800 mb-2">1. lépés — QR olvasás</p>
            <p className="text-sm text-amber-700 mb-3">
              Nyisd meg a Google Authenticator (vagy Authy, Microsoft Authenticator) appot,
              és olvasd be az alábbi QR kódot:
            </p>
            <img
              src={`data:image/png;base64,${enrollment.qrCodePngBase64}`}
              alt="MFA QR code"
              className="border border-gray-300 bg-white p-2"
              style={{ width: '240px', height: '240px' }}
            />
            <details className="mt-3 text-xs">
              <summary className="cursor-pointer text-amber-700">Manuálisan beírható secret</summary>
              <code className="block mt-1 p-2 bg-amber-100 rounded font-mono text-amber-900 break-all">
                {enrollment.secret}
              </code>
            </details>
          </div>

          <div className="p-3 rounded border border-blue-200 bg-blue-50">
            <p className="font-medium text-blue-800 mb-2">2. lépés — kód megerősítés</p>
            <p className="text-sm text-blue-700 mb-3">
              Add meg az authenticator app által megjelenített 6-jegyű kódot:
            </p>
            <div className="flex gap-2">
              <input
                type="text"
                inputMode="numeric"
                pattern="[0-9]*"
                maxLength={6}
                className="form-input font-mono text-lg tracking-widest text-center"
                style={{ width: '180px' }}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="123456"
                autoFocus
              />
              <button
                className="form-button-primary"
                onClick={() => void handleCompleteEnrollment()}
                disabled={submitting || code.length !== 6}
              >
                {submitting ? <Loader2 size={14} className="animate-spin inline mr-1" /> : null}
                Megerősítés
              </button>
            </div>
          </div>
        </div>
      )}

      {state === 'ENROLLED' && backupCodes && (
        <div className="space-y-3">
          <div className="p-3 rounded border border-green-200 bg-green-50">
            <p className="flex items-center gap-2 font-medium text-green-800 mb-2">
              <CheckCircle2 size={18} />
              MFA sikeresen aktiválva!
            </p>
            <p className="text-sm text-green-700">
              Mostantól bejelentkezésnél kelleni fog egy 6-jegyű TOTP kód az authenticator appodból.
            </p>
          </div>

          <div className="p-3 rounded border border-red-200 bg-red-50">
            <p className="font-medium text-red-800 mb-2">⚠️ Backup kódok — MENTSD EL!</p>
            <p className="text-sm text-red-700 mb-3">
              Ezek a kódok EGYSZER használhatók, ha elveszted a telefonod. <strong>Most látod őket utoljára!</strong>
              Másold le egy biztonságos helyre (pl. jelszókezelő, papír széf, 1Password).
            </p>
            <div className="grid grid-cols-2 gap-1 font-mono text-sm bg-white p-2 rounded border border-red-300">
              {backupCodes.map((code) => (
                <div key={code} className="text-red-900">{code}</div>
              ))}
            </div>
            <button
              className="form-button mt-3 text-sm"
              onClick={() => {
                navigator.clipboard.writeText(backupCodes.join('\n'))
                toast.success('Vágólapra másolva', `${backupCodes.length} backup kód`)
              }}
            >
              Vágólapra másolás
            </button>
          </div>
        </div>
      )}

      {state === 'ENROLLED' && !backupCodes && (
        <div className="p-3 rounded border border-green-200 bg-green-50">
          <p className="flex items-center gap-2 text-green-800">
            <ShieldCheck size={18} />
            A MFA aktív ezen a fiókon. Bejelentkezésnél a TOTP kód kötelező.
          </p>
        </div>
      )}
    </div>
  )
}
