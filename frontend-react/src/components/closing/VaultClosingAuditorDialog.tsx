import { useEffect, useRef, useState } from 'react'
import type { CompleteChecklistRequest } from '../../services/api/vaultClosingChecklist'
import i18n from '../../i18n'

/**
 * FR-ZARUI-26: Zárást ellenőrző személy adatai dialógus.
 *
 * Megjelenik a "Zárás véglegesítése" gomb megnyomásakor.
 * Bekéri az ellenőrző NevÉT és BEOSZTÁSÁT, megjeleníti a
 * "A zárószalagot kérem aláírni" alcímet.
 *
 * Jóváhagyás: "Ellenőrző személy adatai rendben" — POST /complete.
 * Megszakítás: "Mégsem zárom a napot" vagy Escape.
 *
 * A11y: role="dialog" + aria-modal + aria-labelledby + Escape kezelés.
 * Minta: AmlApproverModal.tsx
 */

interface Props {
  open: boolean
  /** Sikeres adatbevitel után — auditorName + auditorRole. */
  onConfirm: (req: CompleteChecklistRequest) => void
  onCancel: () => void
  submitting?: boolean
}

export default function VaultClosingAuditorDialog({
  open,
  onConfirm,
  onCancel,
  submitting = false,
}: Props) {
  const [auditorName, setAuditorName] = useState('')
  const [auditorRole, setAuditorRole] = useState('')
  const [nameError, setNameError] = useState('')
  const [roleError, setRoleError] = useState('')
  const nameRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (open) {
      setAuditorName('')
      setAuditorRole('')
      setNameError('')
      setRoleError('')
      // Szinkron fókusz: az effect a DOM-commit UTÁN fut, késleltetés nem kell.
      // (A korábbi 50ms-es setTimeout gépelés közben ellopta a fókuszt a
      // Beosztás mezőtől — flaky teszt + valós UX-hiba gyors felhasználónál.)
      nameRef.current?.focus()
    }
  }, [open])

  if (!open) return null

  const validate = (): boolean => {
    let valid = true
    if (!auditorName.trim()) {
      setNameError('Az ellenőrző személy neve kötelező')
      valid = false
    } else {
      setNameError('')
    }
    if (!auditorRole.trim()) {
      setRoleError('Az ellenőrző személy beosztása kötelező')
      valid = false
    } else {
      setRoleError('')
    }
    return valid
  }

  const handleConfirm = () => {
    if (!validate()) return
    onConfirm({ auditorName: auditorName.trim(), auditorRole: auditorRole.trim() })
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') onCancel()
    if (e.key === 'Enter' && !submitting) handleConfirm()
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="vault-auditor-dialog-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onCancel}
      onKeyDown={handleKeyDown}
    >
      <div
        className="w-full max-w-md rounded-lg bg-white p-6 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Fejléc */}
        <h2 id="vault-auditor-dialog-title" className="mb-1 text-lg font-bold text-gray-800">
          {i18n.t('literals.ellenorzo-szemely-adatai')}
        </h2>

        {/* FR-ZARUI-26 alcím */}
        <p className="mb-4 rounded border border-blue-200 bg-blue-50 px-3 py-2 text-sm font-medium text-blue-800">
          {i18n.t('literals.a-zaroszalagot-kerem-alairni')}
        </p>

        {/* Ellenőrző neve */}
        <label htmlFor="auditor-name" className="mb-1 block text-sm font-semibold text-gray-700">
          {i18n.t('literals.ellenorzo-neve')}
          <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
        </label>
        <input
          id="auditor-name"
          ref={nameRef}
          type="text"
          value={auditorName}
          onChange={(e) => {
            setAuditorName(e.target.value)
            setNameError('')
          }}
          disabled={submitting}
          placeholder="pl. Kovács Péter"
          className={`mb-1 w-full rounded border px-3 py-2 focus:outline-none disabled:opacity-50 ${
            nameError
              ? 'border-red-400 focus:border-red-500'
              : 'border-gray-300 focus:border-blue-500'
          }`}
          autoComplete="off"
        />
        {nameError && <p className="mb-3 text-xs text-red-600">{nameError}</p>}
        {!nameError && <div className="mb-3" />}

        {/* Ellenőrző beosztása */}
        <label htmlFor="auditor-role" className="mb-1 block text-sm font-semibold text-gray-700">
          {i18n.t('literals.beosztas')}
          <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
        </label>
        <input
          id="auditor-role"
          type="text"
          value={auditorRole}
          onChange={(e) => {
            setAuditorRole(e.target.value)
            setRoleError('')
          }}
          disabled={submitting}
          placeholder="pl. Értéktáros vezető"
          className={`mb-1 w-full rounded border px-3 py-2 focus:outline-none disabled:opacity-50 ${
            roleError
              ? 'border-red-400 focus:border-red-500'
              : 'border-gray-300 focus:border-blue-500'
          }`}
          autoComplete="off"
        />
        {roleError && <p className="mb-3 text-xs text-red-600">{roleError}</p>}
        {!roleError && <div className="mb-4" />}

        {/* Gombok */}
        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onCancel}
            disabled={submitting}
            className="rounded border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50 disabled:opacity-50"
          >
            {i18n.t('literals.megsem-zarom-a-napot')}
          </button>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={submitting || !auditorName.trim() || !auditorRole.trim()}
            className="rounded bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-50"
          >
            {submitting ? 'Mentés...' : 'Ellenőrző személy adatai rendben'}
          </button>
        </div>
      </div>
    </div>
  )
}
