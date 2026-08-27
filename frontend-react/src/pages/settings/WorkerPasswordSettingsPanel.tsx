import { useEffect, useState } from 'react'
import { LockKeyhole, Loader2, UserRound } from 'lucide-react'
import { userApi, type UserDetail } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

export default function WorkerPasswordSettingsPanel() {
  const [oldPassword, setOldPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [newPasswordConfirm, setNewPasswordConfirm] = useState('')
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [profile, setProfile] = useState<UserDetail | null>(null)
  const [profileLoading, setProfileLoading] = useState(false)

  useEffect(() => {
    let cancelled = false
    const loadProfile = async () => {
      setProfileLoading(true)
      try {
        const data = await userApi.getCurrentUser()
        if (!cancelled) setProfile(data)
      } catch (err) {
        logger.error('WorkerPasswordSettingsPanel', 'Saját user profil lekérdezése sikertelen', err)
        if (!cancelled) setProfile(null)
      } finally {
        if (!cancelled) setProfileLoading(false)
      }
    }
    void loadProfile()
    return () => {
      cancelled = true
    }
  }, [])

  const changePassword = async () => {
    setMessage(null)
    setError(null)

    if (!oldPassword.trim()) {
      setError('A jelenlegi jelszó kötelező.')
      return
    }
    if (newPassword.length < 8 || newPassword.length > 128) {
      setError('Az új jelszó 8-128 karakter legyen.')
      return
    }
    if (newPassword !== newPasswordConfirm) {
      setError('A két új jelszó nem egyezik.')
      return
    }

    try {
      setSaving(true)
      await userApi.updatePassword(oldPassword, newPassword)
      setMessage('Saját jelszó módosítva.')
      setOldPassword('')
      setNewPassword('')
      setNewPasswordConfirm('')
    } catch (err) {
      logger.error(
        'WorkerPasswordSettingsPanel',
        'Saját user jelszóváltás sikertelen',
        getErrorMessage(err),
      )
      setError('Saját jelszó módosítása sikertelen.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <section className="rounded-lg border border-gray-200 bg-white p-4">
      <div className="mb-4">
        <h2 className="flex items-center gap-2 text-lg font-semibold">
          <LockKeyhole size={18} />
          {i18n.t('literals.sajat-dolgozoi-jelszo')}
        </h2>
        <p className="mt-1 text-sm text-gray-600">
          {i18n.t('literals.a-bejelentkezett-dolgozo-jelszavanak-mod')}
        </p>
      </div>

      <div
        className="mb-4 rounded-md border border-slate-200 bg-slate-50 p-3"
        data-testid="own-user-profile"
      >
        <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-slate-800">
          <UserRound size={16} />
          {i18n.t('literals.sajat-felhasznaloi-profil')}
        </div>
        {profileLoading && (
          <div className="flex items-center gap-2 text-sm text-slate-600">
            <Loader2 className="h-4 w-4 animate-spin" />
            {i18n.t('literals.profil-betoltese')}
          </div>
        )}
        {!profileLoading && profile && (
          <dl className="grid gap-2 text-sm md:grid-cols-2">
            <div>
              <dt className="text-xs uppercase text-slate-500">
                {i18n.t('literals.felhasznalonev')}
              </dt>
              <dd className="font-mono font-semibold text-slate-900">{profile.username}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase text-slate-500">{i18n.t('literals.nev')}</dt>
              <dd className="font-semibold text-slate-900">
                {profile.name ?? profile.workerName ?? '-'}
              </dd>
            </div>
            <div>
              <dt className="text-xs uppercase text-slate-500">{i18n.t('literals.e-mail')}</dt>
              <dd className="break-words text-slate-900">{profile.email || '-'}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase text-slate-500">
                {i18n.t('literals.alapertelmezett-fiok')}
              </dt>
              <dd className="text-slate-900">{profile.defaultBranchName || '-'}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase text-slate-500">{i18n.t('literals.szerepkor')}</dt>
              <dd className="text-slate-900">{profile.roles?.join(', ') || profile.role || '-'}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase text-slate-500">
                {i18n.t('literals.utolso-belepes')}
              </dt>
              <dd className="text-slate-900">{profile.lastLoginAt || profile.lastLogin || '-'}</dd>
            </div>
          </dl>
        )}
        {!profileLoading && !profile && (
          <p className="text-sm text-slate-600">
            {i18n.t('literals.a-sajat-felhasznaloi-profil-nem-toltheto')}
          </p>
        )}
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
            value={oldPassword}
            onChange={(event) => setOldPassword(event.target.value)}
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-medium text-gray-700">
            {i18n.t('literals.uj-jelszo')}
          </span>
          <input
            type="password"
            autoComplete="new-password"
            className="form-input"
            value={newPassword}
            onChange={(event) => setNewPassword(event.target.value)}
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-medium text-gray-700">
            {i18n.t('literals.uj-jelszo-ismet')}
          </span>
          <input
            type="password"
            autoComplete="new-password"
            className="form-input"
            value={newPasswordConfirm}
            onChange={(event) => setNewPasswordConfirm(event.target.value)}
          />
        </label>
      </div>

      <div className="mt-4">
        <button
          type="button"
          className="form-button-primary inline-flex items-center justify-center gap-2"
          disabled={saving}
          onClick={() => void changePassword()}
        >
          <LockKeyhole size={16} />
          {saving ? 'Jelszó mentés...' : 'Jelszó módosítása'}
        </button>
      </div>
    </section>
  )
}
