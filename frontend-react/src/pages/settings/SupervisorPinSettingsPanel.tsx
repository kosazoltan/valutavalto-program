import { useState } from 'react'
import { KeyRound, Trash2 } from 'lucide-react'
import { supervisorPinApi } from '../../services/api/settings'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

const PIN_PATTERN = /^\d{4,6}$/

export default function SupervisorPinSettingsPanel() {
  const [currentPassword, setCurrentPassword] = useState('')
  const [pin, setPin] = useState('')
  const [pinConfirm, setPinConfirm] = useState('')
  const [saving, setSaving] = useState(false)
  const [clearing, setClearing] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const validatePassword = () => {
    if (!currentPassword.trim()) {
      setError('A jelenlegi jelszó kötelező a PIN művelethez.')
      return false
    }
    return true
  }

  const savePin = async () => {
    setMessage(null)
    setError(null)
    if (!validatePassword()) return
    if (!PIN_PATTERN.test(pin)) {
      setError('A supervisor PIN 4-6 számjegy legyen.')
      return
    }
    if (pin !== pinConfirm) {
      setError('A két PIN mező nem egyezik.')
      return
    }

    try {
      setSaving(true)
      const response = await supervisorPinApi.set(currentPassword, pin)
      setMessage(response.message ?? 'Supervisor PIN beállítva.')
      setPin('')
      setPinConfirm('')
    } catch (err) {
      logger.error(
        'SupervisorPinSettingsPanel',
        'Supervisor PIN beállítás sikertelen',
        getErrorMessage(err),
      )
      setError('Supervisor PIN beállítása sikertelen.')
    } finally {
      setSaving(false)
    }
  }

  const clearPin = async () => {
    setMessage(null)
    setError(null)
    if (!validatePassword()) return

    try {
      setClearing(true)
      const response = await supervisorPinApi.clear(currentPassword)
      setMessage(response.message ?? 'Supervisor PIN törölve.')
      setPin('')
      setPinConfirm('')
    } catch (err) {
      logger.error(
        'SupervisorPinSettingsPanel',
        'Supervisor PIN törlés sikertelen',
        getErrorMessage(err),
      )
      setError('Supervisor PIN törlése sikertelen.')
    } finally {
      setClearing(false)
    }
  }

  return (
    <section className="rounded-lg border border-gray-200 bg-white p-4">
      <div className="mb-4">
        <h2 className="flex items-center gap-2 text-lg font-semibold">
          <KeyRound size={18} />
          {i18n.t('literals.supervisor-pin')}
        </h2>
        <p className="mt-1 text-sm text-gray-600">
          {i18n.t('literals.sajat-telefonos-jovahagyasi-pin-beallita')}
        </p>
      </div>

      {message && (
        <div className="mb-3 rounded border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
          {message}
        </div>
      )}
      {error && (
        <div className="mb-3 rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="grid gap-3 md:grid-cols-3">
        <label className="block text-sm">
          <span className="mb-1 block font-medium text-gray-700">
            {i18n.t('literals.jelenlegi-jelszo')}
          </span>
          <input
            type="password"
            autoComplete="current-password"
            className="form-input"
            value={currentPassword}
            onChange={(event) => setCurrentPassword(event.target.value)}
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-medium text-gray-700">{i18n.t('literals.uj-pin')}</span>
          <input
            type="password"
            inputMode="numeric"
            autoComplete="off"
            className="form-input"
            value={pin}
            onChange={(event) => setPin(event.target.value)}
            placeholder="4-6 számjegy"
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-medium text-gray-700">
            {i18n.t('literals.pin-ismet')}
          </span>
          <input
            type="password"
            inputMode="numeric"
            autoComplete="off"
            className="form-input"
            value={pinConfirm}
            onChange={(event) => setPinConfirm(event.target.value)}
            placeholder="4-6 számjegy"
          />
        </label>
      </div>

      <div className="mt-4 flex flex-col gap-2 sm:flex-row">
        <button
          type="button"
          className="form-button-primary inline-flex items-center justify-center gap-2"
          disabled={saving || clearing}
          onClick={() => void savePin()}
        >
          <KeyRound size={16} />
          {saving ? 'PIN mentés...' : 'PIN beállítása'}
        </button>
        <button
          type="button"
          className="form-button inline-flex items-center justify-center gap-2 text-red-700"
          disabled={saving || clearing}
          onClick={() => void clearPin()}
        >
          <Trash2 size={16} />
          {clearing ? 'PIN törlés...' : 'PIN törlése'}
        </button>
      </div>
    </section>
  )
}
