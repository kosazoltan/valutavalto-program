import { useState, useEffect } from 'react'
import { Loader2, Shield, ShieldCheck, ShieldOff, CheckCircle2 } from 'lucide-react'
import { api } from '../../services/api/client'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

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
        <span>{i18n.t('literals.mfa-allapot-betoltese')}</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="section-title flex items-center gap-2">
          <Shield size={18} />
          {i18n.t('literals.ketfaktoros-hitelesites-totp')}
        </h2>
        <div className="flex items-center gap-1 text-sm">
          {enabled ? (
            <>
              <ShieldCheck size={16} className="text-green-600" />
              <span className="text-green-700">{i18n.t('literals.aktiv-2')}</span>
            </>
          ) : (
            <>
              <ShieldOff size={16} className="text-gray-400" />
              <span className="text-gray-500">{i18n.t('literals.inaktiv-3')}</span>
            </>
          )}
        </div>
      </div>

      <div className="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-800">
        <strong>{i18n.t('literals.ajanlott')}</strong>
        {i18n.t('literals.kapcsold-be-a-ketfaktoros-hitelesitest-h')}
      </div>

      {state === 'IDLE' && !enabled && (
        <div className="space-y-3">
          <p className="text-sm text-gray-700">
            {i18n.t('literals.a-mfa-meg-nincs-aktivalva-ehhez-a-fiokho')}
          </p>
          <button
            className="form-button-primary"
            onClick={() => void handleStartEnrollment()}
            disabled={submitting}
          >
            {submitting ? <Loader2 size={14} className="animate-spin inline mr-1" /> : null}
            {i18n.t('literals.ketfaktoros-hitelesites-bekapcsolasa')}
          </button>
        </div>
      )}

      {state === 'ENROLLING' && enrollment && (
        <div className="space-y-4">
          <div className="p-3 rounded border border-amber-200 bg-amber-50">
            <p className="font-medium text-amber-800 mb-2">
              {i18n.t('literals.1-lepes-qr-olvasas')}
            </p>
            <p className="text-sm text-amber-700 mb-3">
              {i18n.t('literals.nyisd-meg-a-google-authenticator-vagy-au')}
            </p>
            <img
              src={`data:image/png;base64,${enrollment.qrCodePngBase64}`}
              alt="MFA QR code"
              className="border border-gray-300 bg-white p-2"
              style={{ width: '240px', height: '240px' }}
            />
            <details className="mt-3 text-xs">
              <summary className="cursor-pointer text-amber-700">
                {i18n.t('literals.manualisan-beirhato-secret')}
              </summary>
              <code className="block mt-1 p-2 bg-amber-100 rounded font-mono text-amber-900 break-all">
                {enrollment.secret}
              </code>
            </details>
          </div>

          <div className="p-3 rounded border border-blue-200 bg-blue-50">
            <p className="font-medium text-blue-800 mb-2">
              {i18n.t('literals.2-lepes-kod-megerosites')}
            </p>
            <p className="text-sm text-blue-700 mb-3">
              {i18n.t('literals.add-meg-az-authenticator-app-altal-megje')}
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
                {i18n.t('literals.megerosites')}
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
              {i18n.t('literals.mfa-sikeresen-aktivalva')}
            </p>
            <p className="text-sm text-green-700">
              {i18n.t('literals.mostantol-bejelentkezesnel-kelleni-fog-e')}
            </p>
          </div>

          <div className="p-3 rounded border border-red-200 bg-red-50">
            <p className="font-medium text-red-800 mb-2">
              {i18n.t('literals.backup-kodok-mentsd-el')}
            </p>
            <p className="text-sm text-red-700 mb-3">
              {i18n.t('literals.ezek-a-kodok-egyszer-hasznalhatok-ha-elv')}{' '}
              <strong>{i18n.t('literals.most-latod-oket-utoljara')}</strong>
              {i18n.t('literals.masold-le-egy-biztonsagos-helyre-pl-jels')}
            </p>
            <div className="grid grid-cols-2 gap-1 font-mono text-sm bg-white p-2 rounded border border-red-300">
              {backupCodes.map((code) => (
                <div key={code} className="text-red-900">
                  {code}
                </div>
              ))}
            </div>
            <button
              className="form-button mt-3 text-sm"
              onClick={() => {
                navigator.clipboard.writeText(backupCodes.join('\n'))
                toast.success('Vágólapra másolva', `${backupCodes.length} backup kód`)
              }}
            >
              {i18n.t('literals.vagolapra-masolas')}
            </button>
          </div>
        </div>
      )}

      {state === 'ENROLLED' && !backupCodes && (
        <div className="p-3 rounded border border-green-200 bg-green-50">
          <p className="flex items-center gap-2 text-green-800">
            <ShieldCheck size={18} />
            {i18n.t('literals.a-mfa-aktiv-ezen-a-fiokon-bejelentkezesn')}
          </p>
        </div>
      )}
    </div>
  )
}
