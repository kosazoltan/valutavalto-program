import { useState } from 'react'
import { LockKeyhole } from 'lucide-react'
import { workerPasswordApi } from '../../services/api/settings'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'

export default function WorkerPasswordSettingsPanel() {
  const worker = useAuthStore((state) => state.worker)
  const [oldPassword, setOldPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [newPasswordConfirm, setNewPasswordConfirm] = useState('')
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const changePassword = async () => {
    setMessage(null)
    setError(null)

    if (!worker?.id) {
      setError('A jelszóváltáshoz hiányzik a bejelentkezett dolgozó azonosítója.')
      return
    }
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
      await workerPasswordApi.changeOwn(worker.id, oldPassword, newPassword)
      setMessage('Saját jelszó módosítva.')
      setOldPassword('')
      setNewPassword('')
      setNewPasswordConfirm('')
    } catch (err) {
      logger.error('WorkerPasswordSettingsPanel', 'Saját worker jelszóváltás sikertelen', err)
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
          Saját dolgozói jelszó
        </h2>
        <p className="mt-1 text-sm text-gray-600">
          A bejelentkezett dolgozó jelszavának módosítása a WorkerController jelszóváltó szerződésén.
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
          <span className="mb-1 block font-medium text-gray-700">Jelenlegi jelszó</span>
          <input
            type="password"
            autoComplete="current-password"
            className="form-input"
            value={oldPassword}
            onChange={(event) => setOldPassword(event.target.value)}
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-medium text-gray-700">Új jelszó</span>
          <input
            type="password"
            autoComplete="new-password"
            className="form-input"
            value={newPassword}
            onChange={(event) => setNewPassword(event.target.value)}
          />
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-medium text-gray-700">Új jelszó ismét</span>
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
