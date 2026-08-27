import { useState } from 'react'
import { ShieldAlert } from 'lucide-react'
import { api } from '../services/api'
import { getErrorMessage } from '../utils/errorHandling'
import i18n from '../i18n'

/**
 * EXCMD b9-korlevelek FR-03: pénztárosi gyanú-bejelentés (SAR) modal.
 *
 * A pénztáros a folyamatot felfüggeszti (a tranzakciót NEM rögzíti), a gyanús jeleket
 * bejelenti — a backend screening-logot + felsővezetői URGENT értesítést + audit-nyomot ír,
 * a pénztáros pedig telefonon egyeztet a területi vezetővel. Inline modal (Electron:
 * window.prompt nem támogatott); a11y az AmlApproverModal mintájára.
 */
export default function SuspicionReportModal({
  open,
  customerId,
  customerName,
  hufAmount,
  onClose,
  onReported,
}: {
  open: boolean
  /** Belső ügyfél-azonosító, ha törzsbeli az ügyfél — a backend tenant-guardja + törzs-név ehhez kötődik. */
  customerId?: number
  customerName?: string
  hufAmount?: number
  onClose: () => void
  onReported: () => void
}) {
  const [signs, setSigns] = useState('')
  const [nameInput, setNameInput] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Review (Copilot): bezáráskor (Mégse/Escape) a state törlése — újranyitáskor ne maradjon
  // korábbi (akár másik ügyfélhez tartozó) félbehagyott tartalom.
  const resetAndClose = () => {
    setSigns('')
    setNameInput('')
    setError(null)
    onClose()
  }

  if (!open) return null

  const hasPrefilledName = Boolean((customerName ?? '').trim())
  const effectiveName = (customerName ?? '').trim() || nameInput.trim()

  const submit = async () => {
    if (!signs.trim() || (!effectiveName && customerId == null)) {
      setError('Az ügyfél neve és a gyanús jelek leírása kötelező.')
      return
    }
    try {
      setSaving(true)
      setError(null)
      await api.post('/customer-control/suspicion-report', {
        // Review (Codex P1 + Sourcery): törzsbeli ügyfélnél az ID megy — a backend a
        // törzs-nevet használja (audit-integritás) és tenant-guardot futtat.
        customerId: customerId ?? undefined,
        customerName: effectiveName || undefined,
        hufAmount:
          typeof hufAmount === 'number' && Number.isFinite(hufAmount) && hufAmount > 0
            ? hufAmount
            : undefined,
        suspicionSigns: signs.trim(),
      })
      setSigns('')
      setNameInput('')
      onReported()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="suspicion-report-title"
      onKeyDown={(e) => {
        if (e.key === 'Escape' && !saving) resetAndClose()
      }}
    >
      <div className="w-full max-w-md rounded bg-white shadow-xl">
        <div className="flex items-center justify-between border-b p-4">
          <h2 id="suspicion-report-title" className="text-lg font-semibold flex items-center gap-2">
            <ShieldAlert size={18} className="text-red-700" />
            {i18n.t('literals.gyanu-bejelentes-felfuggesztett-ugylet')}
          </h2>
        </div>
        <div className="space-y-3 p-4">
          <p className="text-sm text-gray-600">
            {i18n.t('literals.a-bejelentes-a-szuresi-naploba-kerul-es')}
          </p>
          {!hasPrefilledName && (
            <label className="block text-sm">
              <span className="mb-1 block font-medium text-gray-700">
                {i18n.t('literals.ugyfel-neve')}
              </span>
              {/* Review (Copilot): üres névnél ide kerül a fókusz (kötelező mező elsőként) */}
              <input
                type="text"
                value={nameInput}
                onChange={(e) => setNameInput(e.target.value)}
                maxLength={255}
                className="w-full rounded border px-3 py-2"
                autoFocus
              />
            </label>
          )}
          {hasPrefilledName && (
            <div className="text-sm">
              <strong>{i18n.t('literals.ugyfel')}</strong> {customerName}
            </div>
          )}
          <label className="block text-sm">
            <span className="mb-1 block font-medium text-gray-700">
              {i18n.t('literals.gyanus-jelek-leirasa')}
            </span>
            <textarea
              value={signs}
              onChange={(e) => setSigns(e.target.value)}
              rows={4}
              maxLength={1000}
              className="w-full rounded border px-3 py-2"
              autoFocus={hasPrefilledName}
            />
          </label>
          {error && (
            <div className="rounded border border-red-300 bg-red-50 p-2 text-sm text-red-800">
              {error}
            </div>
          )}
        </div>
        <div className="flex items-center justify-end gap-2 border-t p-4">
          <button onClick={resetAndClose} className="form-button" disabled={saving}>
            {i18n.t('literals.megse')}
          </button>
          <button
            onClick={() => void submit()}
            disabled={saving || !signs.trim() || !effectiveName}
            className="form-button-primary"
          >
            {saving ? 'Küldés...' : 'Bejelentés rögzítése'}
          </button>
        </div>
      </div>
    </div>
  )
}
