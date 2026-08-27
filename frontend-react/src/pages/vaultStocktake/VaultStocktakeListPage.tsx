import { useEffect, useState } from 'react'
import { Package, Play, CheckCircle2, XCircle, AlertTriangle, Plus, Eye } from 'lucide-react'
import {
  vaultStocktakeApi,
  VaultStocktakeSession,
  StocktakeStatus,
} from '../../services/api/vaultStocktake'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

// ============================================================================
// Értéktár leltár (stocktake) oldal - Sprint 7.1
//
// Workflow: OPEN -> IN_PROGRESS -> REVIEW -> CLOSED (vagy CANCELLED)
//
// Hasznalat:
//  1. Uj session letrehozasa (createSession) - auto-init banknote_inventory-bol
//  2. Cimletenkent felvetel (countItem) - actualQuantity setting
//  3. REVIEW fazisba valtas - osszes tetel felveve
//  4. Lezaras (close) - FOERTEKTAR/UGYVEZETO/ADMIN+ jog
// ============================================================================

const STATUS_LABELS: Record<StocktakeStatus, string> = {
  OPEN: 'Nyitva',
  IN_PROGRESS: 'Felvétel alatt',
  REVIEW: 'Ellenőrzés',
  CLOSED: 'Lezárva',
  CANCELLED: 'Megszakítva',
}

const STATUS_COLORS: Record<StocktakeStatus, string> = {
  OPEN: 'bg-blue-100 text-blue-800',
  IN_PROGRESS: 'bg-yellow-100 text-yellow-800',
  REVIEW: 'bg-purple-100 text-purple-800',
  CLOSED: 'bg-green-100 text-green-800',
  CANCELLED: 'bg-gray-100 text-gray-800',
}

export default function VaultStocktakeListPage() {
  const { t } = useTranslation()
  const [sessions, setSessions] = useState<VaultStocktakeSession[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [newSessionName, setNewSessionName] = useState('')
  const [newSessionNote, setNewSessionNote] = useState('')
  const [branchId, setBranchId] = useState('')
  const [creating, setCreating] = useState(false)

  const loadSessions = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await vaultStocktakeApi.list()
      setSessions(data)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err)
      logger.error('vault-stocktake', 'Leltar lista betoltese sikertelen: ' + msg)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadSessions()
  }, [])

  const handleCreate = async () => {
    if (!newSessionName.trim()) {
      setError('A session neve kötelező!')
      return
    }
    setCreating(true)
    setError(null)
    try {
      const created = await vaultStocktakeApi.create({
        sessionName: newSessionName.trim(),
        note: newSessionNote.trim() || undefined,
        branchId: branchId.trim() || undefined,
      })
      logger.info('vault-stocktake', 'Leltar session letrehozva: ' + created.id)
      setShowCreate(false)
      setNewSessionName('')
      setNewSessionNote('')
      setBranchId('')
      await loadSessions()
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err)
      setError(msg)
    } finally {
      setCreating(false)
    }
  }

  const totalOpen = sessions.filter((s) => s.status === 'OPEN' || s.status === 'IN_PROGRESS').length
  const totalReview = sessions.filter((s) => s.status === 'REVIEW').length
  const totalClosed = sessions.filter((s) => s.status === 'CLOSED').length

  return (
    <div className="max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-2">
        <div>
          <h1 className="text-base font-bold flex items-center gap-2">
            <Package className="w-5 h-5 text-blue-600" />
            {t('vaultStocktake.ertektarLeltar')}
          </h1>
          <p className="text-gray-600 text-xs">
            {t('vaultStocktake.cimletenkentiErtektarEllenorzesLegacyLeltarDllParity')}
          </p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          <Plus className="w-4 h-4" />
          {t('vaultStocktake.ujLeltar')}
        </button>
      </div>

      {/* Osszesito kartyak */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
          <div className="text-sm text-yellow-700 flex items-center gap-1">
            <Play className="w-4 h-4" />
            {t('vaultStocktake.aktivLeltarak')}
          </div>
          <div className="text-2xl font-bold mt-1">{totalOpen}</div>
        </div>
        <div className="bg-purple-50 border border-purple-200 rounded p-4">
          <div className="text-sm text-purple-700 flex items-center gap-1">
            <AlertTriangle className="w-4 h-4" />
            {t('vaultStocktake.ellenorzesreVar')}
          </div>
          <div className="text-2xl font-bold mt-1">{totalReview}</div>
        </div>
        <div className="bg-green-50 border border-green-200 rounded p-4">
          <div className="text-sm text-green-700 flex items-center gap-1">
            <CheckCircle2 className="w-4 h-4" />
            {t('reports.lezart')}
          </div>
          <div className="text-2xl font-bold mt-1">{totalClosed}</div>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-3 mb-4 text-red-700 flex items-center gap-2">
          <XCircle className="w-5 h-5" />
          {error}
        </div>
      )}

      {/* Session lista */}
      {loading ? (
        <div className="text-center text-gray-500 py-8">{i18n.t('literals.toltodik')}</div>
      ) : sessions.length === 0 ? (
        <div className="text-center text-gray-500 py-12 bg-gray-50 rounded">
          {t('vaultStocktake.megNincsLeltarSessionKattintsAzUjLeltarGombra')}
        </div>
      ) : (
        <div className="bg-white shadow rounded overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-100">
              <tr>
                <th className="px-4 py-3 text-left">{t('vaultStocktake.session')}</th>
                <th className="px-4 py-3 text-left">{t('vaultStocktake.status2')}</th>
                <th className="px-4 py-3 text-left">{t('vaultStocktake.inditotta')}</th>
                <th className="px-4 py-3 text-left">{t('transit.inditva')}</th>
                <th className="px-4 py-3 text-right">{t('vaultStocktake.elteresHuf2')}</th>
                <th className="px-4 py-3 text-right">{t('common.operation')}</th>
              </tr>
            </thead>
            <tbody>
              {sessions.map((s) => (
                <tr key={s.id} className="border-t hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="font-medium">{s.sessionName}</div>
                    {s.note && <div className="text-xs text-gray-500">{s.note.slice(0, 80)}</div>}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`px-2 py-1 rounded text-xs font-medium ${STATUS_COLORS[s.status]}`}
                    >
                      {STATUS_LABELS[s.status]}
                    </span>
                  </td>
                  <td className="px-4 py-3">{s.startedBy}</td>
                  <td className="px-4 py-3 text-gray-600">
                    {new Date(s.startedAt).toLocaleString('hu-HU')}
                  </td>
                  <td className="px-4 py-3 text-right font-mono">
                    {s.discrepancyTotalHuf !== 0 ? (
                      <span
                        className={s.discrepancyTotalHuf < 0 ? 'text-red-600' : 'text-green-600'}
                      >
                        {s.discrepancyTotalHuf.toLocaleString('hu-HU')}
                      </span>
                    ) : (
                      <span className="text-gray-400">{i18n.t('literals.0-2')}</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <a
                      href={`/vault-stocktake/${s.id}`}
                      className="inline-flex items-center gap-1 text-blue-600 hover:text-blue-800"
                    >
                      <Eye className="w-4 h-4" />
                      {t('vaultStocktake.reszletek')}
                    </a>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Új leltár modal */}
      {showCreate && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded p-6 w-full max-w-md mx-4">
            <h2 className="text-lg font-bold mb-4">{t('vaultStocktake.ujLeltarSession')}</h2>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium mb-1">
                  {t('vaultStocktake.sessionNev')}
                </label>
                <input
                  type="text"
                  className="w-full border rounded px-3 py-2"
                  value={newSessionName}
                  onChange={(e) => setNewSessionName(e.target.value)}
                  placeholder="pl. 2026. aprilisi vegi leltar"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  {t('vaultStocktake.irodaBranchUuidOpcionalis')}
                </label>
                <input
                  type="text"
                  className="w-full border rounded px-3 py-2"
                  value={branchId}
                  onChange={(e) => setBranchId(e.target.value)}
                  placeholder="uuid... vagy ures = minden iroda"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">{t('treasury.megjegyzes')}</label>
                <textarea
                  className="w-full border rounded px-3 py-2"
                  rows={2}
                  value={newSessionNote}
                  onChange={(e) => setNewSessionNote(e.target.value)}
                />
              </div>
            </div>
            <div className="flex gap-2 justify-end mt-4">
              <button
                onClick={() => setShowCreate(false)}
                className="px-4 py-2 border rounded hover:bg-gray-50"
                disabled={creating}
              >
                {t('transactions.megse')}
              </button>
              <button
                onClick={handleCreate}
                disabled={creating}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {creating ? 'Letrehozas...' : 'Letrehozas'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
