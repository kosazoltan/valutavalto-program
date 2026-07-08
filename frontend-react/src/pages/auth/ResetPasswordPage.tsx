import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { authApi } from '../../services/api/index'
import { Lock, Eye, EyeOff } from 'lucide-react'
import { logger } from '../../utils/logger'

/**
 * Audit P1.8 (2026-05-04): Reset password page.
 *
 * <p>A `PasswordResetService` emailes link-je `${frontendBaseUrl}/reset-password?token=...`
 * formaban erkezik a user mailbox-aba. Ez a komponens fogadja, validalja a tokent
 * (frontend-szinten csak a jelenletre, a backend a /auth/reset-password endpointon
 * ellenoriz: lejart-e, letezik-e), es az uj jelszo bekerese utan a
 * `authApi.resetPassword(token, newPassword)` POST-ot inditja.</p>
 *
 * <p>Sikeres reset utan 3 mp varakozas + redirect a `/login`-ra.</p>
 */
export default function ResetPasswordPage() {
  const { t } = useTranslation()
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const token = searchParams.get('token') || ''

  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  // Frontend-szintu token jelenlet ellenorzes (ures token = invalid URL)
  useEffect(() => {
    if (!token) {
      setError(t('resetPassword.missingToken'))
    }
  }, [token, t])

  // Sikeres reset utan automata redirect a login-ra
  useEffect(() => {
    if (!success) return
    const id = window.setTimeout(() => navigate('/login', { replace: true }), 3000)
    return () => window.clearTimeout(id)
  }, [success, navigate])

  const canSubmit = token && newPassword.length >= 8 && newPassword === confirmPassword && !loading

  const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (!canSubmit) return

    setLoading(true)
    setError(null)
    try {
      await authApi.resetPassword(token, newPassword)
      setSuccess(true)
    } catch (err) {
      const msg = err instanceof Error ? err.message : t('resetPassword.unknownError')
      logger.warn('ResetPasswordPage', 'reset failed:', msg)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="flex h-screen items-center justify-center bg-secondary-50 p-4">
        <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-8 text-center">
          <div className="mb-4 inline-flex items-center justify-center w-12 h-12 rounded-full bg-green-100 text-green-600">
            <Lock size={24} />
          </div>
          <h1 className="text-2xl font-bold text-secondary-900 mb-2">
            {t('resetPassword.successTitle')}
          </h1>
          <p className="text-sm text-secondary-600 mb-4">{t('resetPassword.successMessage')}</p>
          <p className="text-xs text-secondary-500">{t('resetPassword.successRedirect')}</p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-screen items-center justify-center bg-secondary-50 p-4">
      <form onSubmit={onSubmit} className="bg-white rounded-lg shadow-xl max-w-md w-full p-8">
        <div className="mb-6 text-center">
          <div className="mb-3 inline-flex items-center justify-center w-12 h-12 rounded-full bg-blue-100 text-blue-600">
            <Lock size={24} />
          </div>
          <h1 className="text-2xl font-bold text-secondary-900">{t('resetPassword.title')}</h1>
          <p className="text-sm text-secondary-600 mt-2">{t('resetPassword.subtitle')}</p>
        </div>

        <label className="block text-sm font-semibold text-secondary-900 mb-1">
          {t('resetPassword.newPasswordLabel')}
        </label>
        <div className="relative mb-4">
          <input
            type={showPassword ? 'text' : 'password'}
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            className="form-input w-full pr-10"
            disabled={!token || loading}
            autoFocus
            autoComplete="new-password"
          />
          <button
            type="button"
            className="absolute right-2 top-1/2 -translate-y-1/2 text-secondary-500 hover:text-secondary-900"
            onClick={() => setShowPassword((p) => !p)}
            tabIndex={-1}
            aria-label={
              showPassword ? t('resetPassword.hidePassword') : t('resetPassword.showPassword')
            }
          >
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>

        <label className="block text-sm font-semibold text-secondary-900 mb-1">
          {t('resetPassword.confirmPasswordLabel')}
        </label>
        <input
          type={showPassword ? 'text' : 'password'}
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          className="form-input w-full mb-4"
          disabled={!token || loading}
          autoComplete="new-password"
        />

        {confirmPassword && newPassword !== confirmPassword && (
          <p className="text-xs text-red-600 mb-2">{t('resetPassword.mismatchError')}</p>
        )}

        {newPassword && newPassword.length < 8 && (
          <p className="text-xs text-amber-600 mb-2">{t('resetPassword.tooShortError')}</p>
        )}

        {error && (
          <div className="mb-4 p-3 rounded-lg bg-red-50 text-sm text-red-800 break-words">
            {error}
          </div>
        )}

        <div className="flex justify-end gap-2">
          <button
            type="button"
            className="form-button"
            onClick={() => navigate('/login')}
            disabled={loading}
          >
            {t('resetPassword.cancel')}
          </button>
          <button type="submit" className="form-button-primary" disabled={!canSubmit}>
            {loading ? t('resetPassword.saving') : t('resetPassword.submit')}
          </button>
        </div>
      </form>
    </div>
  )
}
