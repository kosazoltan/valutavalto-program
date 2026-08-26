import { useState } from 'react'
import { branchFeeConfigApi, type BranchFeeConfigRow } from '../../services/api/settings'
import { roundHuf } from '../../utils/rounding'
import { logger } from '../../utils/logger'
import FeeConfirmDialog from './FeeConfirmDialog'

interface Props {
  row: BranchFeeConfigRow
  onClose: () => void
  onChanged: (row: BranchFeeConfigRow) => void
}

/**
 * FK-096 WU-10 — iroda-szerkesztő modal.
 *
 * - Mód: CSAK BRACKET / PER_MILLE (D4). Ha a LIVE mód NONE (örökölt érték),
 *   hu-HU banner jelzi, és a Küldés a módválasztásig tiltva marad.
 * - Mentés (piszkozat) → saveDraft: a LIVE oszlop változatlan (FR-8).
 * - Küldés → megerősítő párbeszéd → publish(branchId, version).
 * - A verzió a betöltött sorból jön, NEM hardkódolt; a 0-t NEM kezeljük
 *   „nincs verzió"-ként (pitfall #7, B2).
 */
export default function BranchFeeEditorModal({ row, onClose, onChanged }: Props) {
  const [feeMode, setFeeMode] = useState<'BRACKET' | 'PER_MILLE' | null>(
    row.draftFeeMode ??
      (row.liveFeeMode === 'PER_MILLE' || row.liveFeeMode === 'BRACKET' ? row.liveFeeMode : null),
  )
  const [rateText, setRateText] = useState<string>(
    row.draftPerMilleRate != null
      ? String(row.draftPerMilleRate)
      : row.livePerMilleRate != null
        ? String(row.livePerMilleRate)
        : '',
  )
  const [capText, setCapText] = useState<string>(
    row.draftPerMilleCap != null
      ? String(row.draftPerMilleCap)
      : row.livePerMilleCap != null
        ? String(row.livePerMilleCap)
        : '',
  )
  const [saving, setSaving] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const capPreview = (() => {
    const parsed = parseFloat(capText)
    return Number.isFinite(parsed) && parsed > 0 ? roundHuf(parsed) : null
  })()

  const handleSaveDraft = async () => {
    if (!feeMode) return
    setSaving(true)
    setError(null)
    try {
      const updated = await branchFeeConfigApi.saveDraft(row.branchId, {
        feeMode,
        perMilleRate:
          feeMode === 'PER_MILLE' && rateText.trim() !== '' ? parseFloat(rateText) : null,
        perMilleCap: feeMode === 'PER_MILLE' && capText.trim() !== '' ? parseFloat(capText) : null,
      })
      onChanged(updated)
    } catch (err) {
      setError('A piszkozat mentése nem sikerült.')
      logger.error('BranchFeeEditorModal', 'saveDraft hiba', err)
    } finally {
      setSaving(false)
    }
  }

  const handlePublish = async () => {
    setPublishing(true)
    setError(null)
    try {
      // B2/N11: a betöltött verziót küldjük vissza; a 0 legitim első publikálás.
      const published = await branchFeeConfigApi.publish(row.branchId, row.version)
      onChanged(published)
      setConfirmOpen(false)
      onClose()
    } catch (err) {
      setError('A publikálás nem sikerült. Frissítsd a listát (valaki más is szerkeszthette).')
      logger.error('BranchFeeEditorModal', 'publish hiba', err)
    } finally {
      setPublishing(false)
    }
  }

  const publishDisabled = !feeMode || saving || publishing

  return (
    <div
      className="fixed inset-0 z-40 flex items-center justify-center bg-black/50 p-4"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose()
      }}
    >
      <div className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
        <h2 className="text-lg font-bold text-gray-900">
          Kezelési díj — {row.branchCode} ({row.branchName})
        </h2>

        {row.liveFeeMode === 'NONE' && (
          <div className="mt-3 rounded border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
            Jelenleg nincs kezelési díj beállítva (örökölt érték) — válassz módot a küldéshez.
          </div>
        )}

        <fieldset className="mt-4">
          <legend className="text-sm font-medium text-gray-700">Díjmód</legend>
          <label className="mt-2 inline-flex items-center gap-2">
            <input
              type="radio"
              name="fee-mode"
              value="BRACKET"
              checked={feeMode === 'BRACKET'}
              onChange={() => setFeeMode('BRACKET')}
            />
            Sávos (közös sávok)
          </label>
          <label className="mt-1 inline-flex items-center gap-2 pl-6">
            <input
              type="radio"
              name="fee-mode"
              value="PER_MILLE"
              checked={feeMode === 'PER_MILLE'}
              onChange={() => setFeeMode('PER_MILLE')}
            />
            Ezrelékes
          </label>
        </fieldset>

        {feeMode === 'PER_MILLE' && (
          <div className="mt-4 grid grid-cols-2 gap-4">
            <label className="text-sm">
              <span className="text-gray-600">Mérték (‰)</span>
              <input
                type="number"
                min="0"
                step="0.001"
                value={rateText}
                onChange={(event) => setRateText(event.target.value)}
                className="mt-1 w-full rounded border border-gray-300 px-2 py-1"
                aria-label="Ezrelék mértéke"
              />
            </label>
            <label className="text-sm">
              <span className="text-gray-600">Maximum (Ft)</span>
              <input
                type="number"
                min="0"
                step="1"
                value={capText}
                onChange={(event) => setCapText(event.target.value)}
                className="mt-1 w-full rounded border border-gray-300 px-2 py-1"
                aria-label="Ezrelék maximuma"
              />
              {capPreview != null && (
                <span className="mt-1 block text-xs text-gray-500">
                  5 Ft-ra kerekítve: {capPreview.toLocaleString('hu-HU')} Ft
                </span>
              )}
            </label>
          </div>
        )}

        {error && <div className="mt-3 text-sm text-red-700">{error}</div>}

        <div className="mt-6 flex justify-end gap-3">
          <button
            type="button"
            onClick={onClose}
            className="rounded border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            Bezárás
          </button>
          <button
            type="button"
            onClick={handleSaveDraft}
            disabled={!feeMode || saving}
            className="rounded border border-amber-600 px-4 py-2 text-sm font-medium text-amber-700 hover:bg-amber-50 disabled:opacity-50"
          >
            {saving ? 'Mentés…' : 'Mentés (piszkozat)'}
          </button>
          <button
            type="button"
            onClick={() => setConfirmOpen(true)}
            disabled={publishDisabled}
            className="rounded bg-amber-600 px-4 py-2 text-sm font-medium text-white hover:bg-amber-700 disabled:opacity-50"
          >
            Küldés
          </button>
        </div>
      </div>

      {confirmOpen && (
        <FeeConfirmDialog
          title="Kezelési díj publikálása"
          text="Biztosan elküldöd? Az iroda mostantól ezzel az értékkel számol."
          onConfirm={handlePublish}
          onCancel={() => setConfirmOpen(false)}
        />
      )}
    </div>
  )
}
