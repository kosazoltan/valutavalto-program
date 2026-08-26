import { useCallback, useEffect, useState } from 'react'
import {
  handlingFeeBracketApi,
  type BracketSet,
  type HandlingFeeBracketConfig,
} from '../../services/api/settings'
import { logger } from '../../utils/logger'
import FeeConfirmDialog from './FeeConfirmDialog'

const formatHuf = (value: number) => `${value.toLocaleString('hu-HU')} Ft`

const EMPTY_ROW = { bracketOrder: 0, upperLimit: 0, feeAmount: 0, active: true }

/**
 * FK-096 WU-10 — közös (cégszintű) sáv-szerkesztő: LIVE + DRAFT tábla,
 * Mentés (piszkozat) / Küldés megerősítéssel. A publikálás a backenden
 * soros írási út (PESSIMISTIC_WRITE, FR-11).
 */
export default function CommonBracketEditor() {
  const [set, setSet] = useState<BracketSet>({ live: [], draft: [] })
  const [draftRows, setDraftRows] = useState<HandlingFeeBracketConfig[]>([])
  const [saving, setSaving] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    try {
      const loaded = await handlingFeeBracketApi.get()
      setSet(loaded)
      setDraftRows(loaded.draft.length > 0 ? loaded.draft : loaded.live)
    } catch (err) {
      setError('A sávok betöltése nem sikerült.')
      logger.error('CommonBracketEditor', 'get hiba', err)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const updateRow = (index: number, field: 'upperLimit' | 'feeAmount', value: number) => {
    setDraftRows((rows) => rows.map((row, i) => (i === index ? { ...row, [field]: value } : row)))
  }

  const handleSaveDraft = async () => {
    setSaving(true)
    setError(null)
    try {
      const updated = await handlingFeeBracketApi.saveDraft(
        draftRows.filter((row) => row.upperLimit > 0 && row.feeAmount >= 0),
      )
      setSet(updated)
    } catch (err) {
      setError('A sáv-piszkozat mentése nem sikerült.')
      logger.error('CommonBracketEditor', 'saveDraft hiba', err)
    } finally {
      setSaving(false)
    }
  }

  const handlePublish = async () => {
    setPublishing(true)
    setError(null)
    try {
      const updated = await handlingFeeBracketApi.publish()
      setSet(updated)
      setConfirmOpen(false)
    } catch (err) {
      setError('A sávok publikálása nem sikerült.')
      logger.error('CommonBracketEditor', 'publish hiba', err)
    } finally {
      setPublishing(false)
    }
  }

  const renderTable = (title: string, rows: HandlingFeeBracketConfig[]) => (
    <div className="mt-3">
      <h3 className="text-sm font-semibold text-gray-700">{title}</h3>
      {rows.length === 0 ? (
        <p className="text-xs text-gray-500">Nincs sáv.</p>
      ) : (
        <table className="mt-1 w-full text-left text-xs">
          <thead>
            <tr className="border-b text-gray-500">
              <th className="py-1 pr-2 font-medium">Sáv</th>
              <th className="py-1 pr-2 font-medium">Felső határ</th>
              <th className="py-1 font-medium">Díj</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.bracketOrder} className="border-b last:border-0">
                <td className="py-1 pr-2">{row.bracketOrder}</td>
                <td className="py-1 pr-2">{formatHuf(row.upperLimit)}</td>
                <td className="py-1">{formatHuf(row.feeAmount)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
      <h2 className="text-base font-semibold text-gray-800">Közös kezelési díj sávok</h2>

      {renderTable('Éles (LIVE) sávok', set.live)}
      {set.draft.length > 0 && renderTable('Piszkozat (DRAFT) sávok', set.draft)}

      <div className="mt-4">
        <h3 className="text-sm font-semibold text-gray-700">Szerkesztés</h3>
        <table className="mt-1 w-full text-left text-xs">
          <thead>
            <tr className="border-b text-gray-500">
              <th className="py-1 pr-2 font-medium">Sáv</th>
              <th className="py-1 pr-2 font-medium">Felső határ (Ft)</th>
              <th className="py-1 font-medium">Díj (Ft)</th>
            </tr>
          </thead>
          <tbody>
            {draftRows.map((row, index) => (
              <tr key={index} className="border-b last:border-0">
                <td className="py-1 pr-2">{index + 1}</td>
                <td className="py-1 pr-2">
                  <input
                    type="number"
                    min="0"
                    value={row.upperLimit}
                    onChange={(event) => updateRow(index, 'upperLimit', Number(event.target.value))}
                    className="w-28 rounded border border-gray-300 px-1 py-0.5"
                    aria-label={`${index + 1}. sáv felső határa`}
                  />
                </td>
                <td className="py-1">
                  <input
                    type="number"
                    min="0"
                    value={row.feeAmount}
                    onChange={(event) => updateRow(index, 'feeAmount', Number(event.target.value))}
                    className="w-28 rounded border border-gray-300 px-1 py-0.5"
                    aria-label={`${index + 1}. sáv díja`}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <button
          type="button"
          onClick={() => setDraftRows((rows) => [...rows, { ...EMPTY_ROW }])}
          className="mt-2 rounded border border-gray-300 px-3 py-1 text-xs text-gray-700 hover:bg-gray-50"
        >
          + Új sáv
        </button>
      </div>

      {error && <div className="mt-3 text-sm text-red-700">{error}</div>}

      <div className="mt-4 flex justify-end gap-3">
        <button
          type="button"
          onClick={handleSaveDraft}
          disabled={saving || draftRows.length === 0}
          className="rounded border border-amber-600 px-4 py-2 text-sm font-medium text-amber-700 hover:bg-amber-50 disabled:opacity-50"
        >
          {saving ? 'Mentés…' : 'Mentés (piszkozat)'}
        </button>
        <button
          type="button"
          onClick={() => setConfirmOpen(true)}
          disabled={publishing || (set.draft.length === 0 && draftRows.length === 0)}
          className="rounded bg-amber-600 px-4 py-2 text-sm font-medium text-white hover:bg-amber-700 disabled:opacity-50"
        >
          Küldés
        </button>
      </div>

      {confirmOpen && (
        <FeeConfirmDialog
          title="Közös sávok publikálása"
          text="Biztosan elküldöd? Minden sávos irodára azonnal érvényes lesz."
          onConfirm={handlePublish}
          onCancel={() => setConfirmOpen(false)}
        />
      )}
    </div>
  )
}
