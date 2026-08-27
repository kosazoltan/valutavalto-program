import { useEffect, useState } from 'react'
import { UserPlus, Users } from 'lucide-react'
import { vaultWorkerApi, type VaultWorkerOption } from '../../services/api/auth'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

/**
 * FK-ÉRTÉKTÁR (V285): új személyes értéktári munkatárs felvétele.
 *
 * A bejelentkezett értéktáros a SAJÁT értéktárába vehet fel munkatársat (név + jelszó). A backend
 * a company/branch-et a SecurityContextből veszi — itt nincs cég/iroda/szerepkör választás.
 * A felvett munkatárs ezután megjelenik a Google-belépés utáni dolgozóválasztóban.
 */
export default function NewVaultWorkerPage() {
  const [name, setName] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirm, setPasswordConfirm] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [workers, setWorkers] = useState<VaultWorkerOption[]>([])
  const [listError, setListError] = useState<string | null>(null)

  const loadWorkers = async () => {
    try {
      setWorkers(await vaultWorkerApi.list())
      setListError(null)
    } catch (err) {
      setListError(getErrorMessage(err))
    }
  }

  useEffect(() => {
    void loadWorkers()
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setSuccess(null)
    if (!name.trim()) {
      setError('A név megadása kötelező.')
      return
    }
    if (password.length < 6) {
      setError('A jelszó legalább 6 karakter legyen.')
      return
    }
    if (password !== passwordConfirm) {
      setError('A két jelszó nem egyezik.')
      return
    }
    setSaving(true)
    try {
      const created = await vaultWorkerApi.create({ name: name.trim(), password, passwordConfirm })
      setSuccess(`Új munkatárs felvéve: ${created.name}. Mostantól kiválasztható a belépésnél.`)
      setName('')
      setPassword('')
      setPasswordConfirm('')
      await loadWorkers()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto p-4">
      <div className="flex items-center gap-2 mb-4">
        <UserPlus size={20} />
        <h1 className="text-lg font-semibold">{i18n.t('literals.uj-munkatars-felvetele')}</h1>
      </div>

      <p className="text-sm text-gray-600 mb-4">
        {i18n.t('literals.vegyel-fel-uj-ertektari-munkatarsat-a-sa')}
      </p>

      <form
        onSubmit={handleSubmit}
        className="bg-form-bg border border-form-border p-4 rounded mb-6"
      >
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3">
            {error}
          </div>
        )}
        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 text-sm p-2 rounded mb-3">
            {success}
          </div>
        )}

        <label className="block mb-3">
          <span className="form-label">
            {i18n.t('literals.munkatars-neve')}
            <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
          </span>
          <input
            type="text"
            className="form-input"
            maxLength={100}
            value={name}
            disabled={saving}
            placeholder="pl. Bali Henriett"
            onChange={(e) => setName(e.target.value)}
          />
        </label>

        <label className="block mb-3">
          <span className="form-label">
            {i18n.t('literals.jelszo-2')}
            <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
          </span>
          <input
            type="password"
            className="form-input"
            value={password}
            disabled={saving}
            placeholder="legalább 6 karakter"
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>

        <label className="block mb-4">
          <span className="form-label">
            {i18n.t('literals.jelszo-megerositese-2')}
            <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
          </span>
          <input
            type="password"
            className="form-input"
            value={passwordConfirm}
            disabled={saving}
            placeholder="írd be újra a jelszót"
            onChange={(e) => setPasswordConfirm(e.target.value)}
          />
        </label>

        <div className="flex justify-end">
          <button type="submit" className="form-button" disabled={saving}>
            {saving ? 'Mentés...' : 'Munkatárs felvétele'}
          </button>
        </div>
      </form>

      <div className="flex items-center gap-2 mb-2">
        <Users size={16} />
        <h2 className="text-sm font-semibold">
          {i18n.t('literals.ertektar-jelenlegi-munkatarsai')}
        </h2>
      </div>
      {listError ? (
        <div className="text-sm text-red-600">{listError}</div>
      ) : workers.length === 0 ? (
        <div className="text-sm text-gray-500">
          {i18n.t('literals.meg-nincs-felvett-szemelyes-munkatars')}
        </div>
      ) : (
        <ul className="text-sm border border-form-border rounded divide-y">
          {workers.map((w) => (
            <li key={w.id} className="px-3 py-2">
              {w.name}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
