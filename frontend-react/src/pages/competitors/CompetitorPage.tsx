import { useState, useEffect, useCallback } from 'react'
import {
  BarChart3,
  Search,
  RefreshCw,
  Plus,
  Edit2,
  Trash2,
  AlertTriangle,
  Trophy,
} from 'lucide-react'
import { api, competitorApi } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'
import { toast } from '../../components/ui/toaster'
import i18n from '../../i18n'

interface CompetitorItem {
  id: string | number
  name?: string
  website?: string | null
  branchId?: string | null
  isActive?: boolean
}

interface CompetitorForm {
  name: string
  website: string
  branchId: string
  isActive: boolean
}

interface CompetitionItem {
  id: string
  competitionName: string
  startDate: string
  endDate: string
  status?: string
  rules?: string
  createdAt?: string
}

interface CompetitionEntry {
  id: string
  competitionId: string
  workerId: number
  workerName?: string
  totalVolume?: number
  transactionCount?: number
  score?: number
  rank?: number
}

interface CompetitionForm {
  competitionName: string
  startDate: string
  endDate: string
  rules: string
}

const emptyForm = (branchId?: string): CompetitorForm => ({
  name: '',
  website: '',
  branchId: branchId ?? '',
  isActive: true,
})

const emptyCompetitionForm = (): CompetitionForm => {
  const today = new Date().toISOString().slice(0, 10)
  return {
    competitionName: '',
    startDate: today,
    endDate: today,
    rules: '',
  }
}

function formatNumber(value?: number): string {
  return typeof value === 'number' ? value.toLocaleString('hu-HU') : '0'
}

export default function CompetitorPage() {
  const { t } = useTranslation()
  const currentBranchId = useAuthStore((state) => state.worker?.branchId)
  const [activeView, setActiveView] = useState<'competitors' | 'competitions'>('competitors')
  const [items, setItems] = useState<CompetitorItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [formOpen, setFormOpen] = useState(false)
  const [editing, setEditing] = useState<CompetitorItem | null>(null)
  const [editingLoadingId, setEditingLoadingId] = useState<string | number | null>(null)
  const [form, setForm] = useState<CompetitorForm>(() => emptyForm(currentBranchId))
  const [saving, setSaving] = useState(false)
  const [competitions, setCompetitions] = useState<CompetitionItem[]>([])
  const [competitionLoading, setCompetitionLoading] = useState(true)
  const [competitionFormOpen, setCompetitionFormOpen] = useState(false)
  const [competitionForm, setCompetitionForm] = useState<CompetitionForm>(() =>
    emptyCompetitionForm(),
  )
  const [selectedCompetitionId, setSelectedCompetitionId] = useState<string | null>(null)
  const [leaderboard, setLeaderboard] = useState<CompetitionEntry[]>([])
  const [competitionSaving, setCompetitionSaving] = useState(false)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await competitorApi.list()
      setItems(safeArray<(typeof items)[0]>(data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('CompetitorPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  const loadCompetitions = useCallback(async () => {
    try {
      setCompetitionLoading(true)
      setError(null)
      const response = await api.get<CompetitionItem[]>('/competitions')
      const list = safeArray<CompetitionItem>(response.data)
      setCompetitions(list)
      const selectedStillExists =
        selectedCompetitionId && list.some((item) => item.id === selectedCompetitionId)
      const nextSelectedId = selectedStillExists ? selectedCompetitionId : (list[0]?.id ?? null)
      setSelectedCompetitionId(nextSelectedId)
      if (nextSelectedId) {
        const leaderboardResponse = await api.get<CompetitionEntry[]>(
          `/competitions/${nextSelectedId}/leaderboard`,
        )
        setLeaderboard(safeArray<CompetitionEntry>(leaderboardResponse.data))
      } else {
        setLeaderboard([])
      }
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('CompetitorPage', 'Verseny betöltési hiba:', err)
      setError(msg)
      setCompetitions([])
      setLeaderboard([])
    } finally {
      setCompetitionLoading(false)
    }
  }, [selectedCompetitionId])

  useEffect(() => {
    void loadData()
  }, [loadData])

  useEffect(() => {
    void loadCompetitions()
  }, [loadCompetitions])

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  const handleDelete = async (id: string | number) => {
    if (!confirm('Biztosan törli?')) return
    try {
      await competitorApi.remove(id)
      toast.success('Versenytárs törölve')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CompetitorPage', 'Törlési hiba:', err)
      toast.error('Törlési hiba', msg)
    }
  }

  const openNew = () => {
    setFormOpen(true)
    setEditing(null)
    setForm(emptyForm(currentBranchId))
    setError(null)
  }

  const openEditForm = (item: CompetitorItem) => {
    setFormOpen(true)
    setEditing(item)
    setForm({
      name: item.name ?? '',
      website: item.website ?? '',
      branchId: item.branchId ?? currentBranchId ?? '',
      isActive: item.isActive ?? true,
    })
    setError(null)
  }

  const openEdit = async (item: CompetitorItem) => {
    try {
      setEditingLoadingId(item.id)
      setError(null)
      const detail = await competitorApi.getById(String(item.id))
      openEditForm(detail)
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CompetitorPage', 'Részletek betöltési hiba:', err)
      toast.error('Részletek betöltési hiba', msg)
    } finally {
      setEditingLoadingId(null)
    }
  }

  const cancelEdit = () => {
    setFormOpen(false)
    setEditing(null)
    setForm(emptyForm(currentBranchId))
  }

  const saveCompetitor = async () => {
    const name = form.name.trim()
    if (!name) {
      setError('A versenytárs neve kötelező.')
      return
    }

    const payload = {
      name,
      website: form.website.trim() || null,
      branchId: form.branchId.trim() || null,
      isActive: form.isActive,
    }

    try {
      setSaving(true)
      setError(null)
      if (editing) {
        await competitorApi.update(editing.id, payload)
        toast.success('Versenytárs frissítve')
      } else {
        await competitorApi.create(payload)
        toast.success('Versenytárs létrehozva')
      }
      cancelEdit()
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CompetitorPage', 'Mentési hiba:', err)
      toast.error('Mentési hiba', msg)
    } finally {
      setSaving(false)
    }
  }

  const saveCompetition = async () => {
    const competitionName = competitionForm.competitionName.trim()
    if (!competitionName) {
      setError('A verseny neve kötelező.')
      return
    }
    if (!competitionForm.startDate || !competitionForm.endDate) {
      setError('A kezdő és záró dátum kötelező.')
      return
    }

    try {
      setCompetitionSaving(true)
      setError(null)
      const response = await api.post<CompetitionItem>('/competitions', {
        competitionName,
        startDate: competitionForm.startDate,
        endDate: competitionForm.endDate,
        rules: competitionForm.rules.trim() || null,
      })
      setCompetitionForm(emptyCompetitionForm())
      setCompetitionFormOpen(false)
      setSelectedCompetitionId(response.data.id)
      await loadCompetitions()
      toast.success('Pénztáros verseny létrehozva')
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CompetitorPage', 'Verseny mentési hiba:', err)
      toast.error('Verseny mentési hiba', msg)
    } finally {
      setCompetitionSaving(false)
    }
  }

  const loadLeaderboard = async (competitionId: string) => {
    try {
      setSelectedCompetitionId(competitionId)
      const response = await api.get<CompetitionEntry[]>(
        `/competitions/${competitionId}/leaderboard`,
      )
      setLeaderboard(safeArray<CompetitionEntry>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CompetitorPage', 'Leaderboard betöltési hiba:', err)
      toast.error('Leaderboard betöltési hiba', msg)
    }
  }

  const calculateCompetition = async (competitionId: string) => {
    try {
      const response = await api.post<CompetitionEntry[]>(
        `/competitions/${competitionId}/calculate`,
      )
      setSelectedCompetitionId(competitionId)
      setLeaderboard(safeArray<CompetitionEntry>(response.data))
      toast.success('Verseny pontszámok újraszámolva')
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CompetitorPage', 'Pontszámítási hiba:', err)
      toast.error('Pontszámítási hiba', msg)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <BarChart3 className="h-6 w-6" />
          {t('competitors.versenytarsak')}
        </h1>
        {activeView === 'competitors' && (
          <div className="flex items-center gap-2">
            <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <button onClick={openNew} className="form-button-primary flex items-center gap-1">
              <Plus className="h-4 w-4" />
              {t('common.new')}
            </button>
          </div>
        )}
      </div>

      <div className="flex flex-wrap gap-2 border-b border-gray-200 pb-2">
        <button
          type="button"
          onClick={() => setActiveView('competitors')}
          className={activeView === 'competitors' ? 'form-button-primary' : 'form-button'}
        >
          {t('competitors.versenytarsak')}
        </button>
        <button
          type="button"
          onClick={() => setActiveView('competitions')}
          className={activeView === 'competitions' ? 'form-button-primary' : 'form-button'}
        >
          <Trophy className="h-4 w-4" />
          {i18n.t('literals.penztaros-versenyek')}
        </button>
      </div>

      {activeView === 'competitions' && (
        <>
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div>
              <h2 className="text-base font-semibold text-gray-900">
                {i18n.t('literals.penztaros-versenyek-2')}
              </h2>
              <p className="text-sm text-gray-500">
                {i18n.t('literals.versenyidoszakok-pontszamitas-es-ranglis')}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => void loadCompetitions()}
                className="form-button p-2"
                title="Frissítés"
              >
                <RefreshCw className={`h-4 w-4 ${competitionLoading ? 'animate-spin' : ''}`} />
              </button>
              <button
                onClick={() => setCompetitionFormOpen((open) => !open)}
                className="form-button-primary flex items-center gap-1"
              >
                <Plus className="h-4 w-4" />
                {i18n.t('literals.uj-verseny')}
              </button>
            </div>
          </div>

          {competitionFormOpen && (
            <div className="grid gap-3 rounded border border-gray-200 bg-white p-3 md:grid-cols-[1fr_auto_auto_1fr_auto] md:items-end">
              <label className="block">
                <span className="form-label">{i18n.t('literals.verseny-neve')}</span>
                <input
                  id="competition-name"
                  type="text"
                  className="form-input"
                  value={competitionForm.competitionName}
                  onChange={(e) =>
                    setCompetitionForm((current) => ({
                      ...current,
                      competitionName: e.target.value,
                    }))
                  }
                />
              </label>
              <label className="block">
                <span className="form-label">{i18n.t('literals.kezdes')}</span>
                <input
                  id="competition-start"
                  type="date"
                  className="form-input"
                  value={competitionForm.startDate}
                  onChange={(e) =>
                    setCompetitionForm((current) => ({ ...current, startDate: e.target.value }))
                  }
                />
              </label>
              <label className="block">
                <span className="form-label">{i18n.t('literals.zaras')}</span>
                <input
                  id="competition-end"
                  type="date"
                  className="form-input"
                  value={competitionForm.endDate}
                  onChange={(e) =>
                    setCompetitionForm((current) => ({ ...current, endDate: e.target.value }))
                  }
                />
              </label>
              <label className="block">
                <span className="form-label">{i18n.t('literals.szabalyok')}</span>
                <input
                  id="competition-rules"
                  type="text"
                  className="form-input"
                  value={competitionForm.rules}
                  onChange={(e) =>
                    setCompetitionForm((current) => ({ ...current, rules: e.target.value }))
                  }
                />
              </label>
              <button
                type="button"
                onClick={() => void saveCompetition()}
                disabled={competitionSaving}
                className="form-button-primary"
              >
                {i18n.t('literals.letrehozas')}
              </button>
            </div>
          )}

          <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(360px,0.85fr)]">
            <section className="data-grid overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.nev')}
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.idoszak')}
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.statusz')}
                    </th>
                    <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.muvelet')}
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 bg-white">
                  {competitionLoading ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                        {i18n.t('literals.betoltes')}
                      </td>
                    </tr>
                  ) : competitions.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                        {t('common.noData')}
                      </td>
                    </tr>
                  ) : (
                    competitions.map((competition) => (
                      <tr
                        key={competition.id}
                        className={
                          competition.id === selectedCompetitionId
                            ? 'bg-blue-50'
                            : 'hover:bg-gray-50'
                        }
                      >
                        <td className="px-4 py-3 text-sm">
                          <div className="font-semibold text-gray-900">
                            {competition.competitionName}
                          </div>
                          {competition.rules && (
                            <div className="text-xs text-gray-500">{competition.rules}</div>
                          )}
                        </td>
                        <td className="px-4 py-3 text-sm font-mono text-xs">
                          {competition.startDate}
                          {i18n.t('literals.lit-17')}
                          {competition.endDate}
                        </td>
                        <td className="px-4 py-3 text-sm">{competition.status ?? '-'}</td>
                        <td className="px-4 py-3 text-right">
                          <div className="flex justify-end gap-2">
                            <button
                              onClick={() => void loadLeaderboard(competition.id)}
                              className="form-button text-xs"
                            >
                              {i18n.t('literals.ranglista')}
                            </button>
                            <button
                              onClick={() => void calculateCompetition(competition.id)}
                              className="form-button-primary text-xs"
                            >
                              {i18n.t('literals.szamitas')}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </section>

            <section className="data-grid overflow-x-auto">
              <div className="border-b border-gray-200 bg-gray-50 px-4 py-3 text-sm font-semibold text-gray-700">
                {i18n.t('literals.ranglista')}
              </div>
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.lit-12')}
                    </th>
                    <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.dolgozo-2')}
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.forgalom')}
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.pont')}
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 bg-white">
                  {leaderboard.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-3 py-8 text-center text-sm text-gray-500">
                        {i18n.t('literals.nincs-ranglista-adat')}
                      </td>
                    </tr>
                  ) : (
                    leaderboard.map((entry) => (
                      <tr key={entry.id}>
                        <td className="px-3 py-2 text-sm font-semibold">{entry.rank ?? '-'}</td>
                        <td className="px-3 py-2 text-sm">{entry.workerName ?? entry.workerId}</td>
                        <td className="px-3 py-2 text-right text-sm font-mono">
                          {formatNumber(entry.totalVolume)}
                        </td>
                        <td className="px-3 py-2 text-right text-sm font-mono font-semibold">
                          {formatNumber(entry.score)}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </section>
          </div>
        </>
      )}

      {activeView === 'competitors' && (
        <>
          {formOpen && (
            <div className="grid gap-3 md:grid-cols-[1fr_1fr_1fr_auto] md:items-end">
              <label className="block">
                <span className="form-label">{t('competitors.nev')}</span>
                <input
                  type="text"
                  className="form-input"
                  value={form.name}
                  onChange={(e) => setForm((current) => ({ ...current, name: e.target.value }))}
                />
              </label>
              <label className="block">
                <span className="form-label">{i18n.t('literals.weboldal')}</span>
                <input
                  type="url"
                  className="form-input"
                  value={form.website}
                  onChange={(e) => setForm((current) => ({ ...current, website: e.target.value }))}
                />
              </label>
              <label className="block">
                <span className="form-label">{i18n.t('literals.telephely-id')}</span>
                <input
                  type="text"
                  className="form-input"
                  value={form.branchId}
                  onChange={(e) => setForm((current) => ({ ...current, branchId: e.target.value }))}
                />
              </label>
              <div className="flex flex-wrap items-center gap-2">
                <label className="inline-flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={form.isActive}
                    onChange={(e) =>
                      setForm((current) => ({ ...current, isActive: e.target.checked }))
                    }
                  />
                  {i18n.t('literals.aktiv-2')}
                </label>
                <button
                  type="button"
                  onClick={() => void saveCompetitor()}
                  disabled={saving}
                  className="form-button-primary"
                >
                  {editing ? t('common.save') : t('common.new')}
                </button>
                <button
                  type="button"
                  onClick={cancelEdit}
                  disabled={saving}
                  className="form-button"
                >
                  {t('common.cancel')}
                </button>
              </div>
            </div>
          )}

          <div className="flex items-center gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Keresés..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="form-input w-full pl-10"
              />
            </div>
          </div>

          {error && (
            <div className="form-error flex items-center gap-2">
              <AlertTriangle className="h-4 w-4" />
              {error}
            </div>
          )}

          <div className="data-grid overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                    {t('competitors.nev')}
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.weboldal')}
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.telephely-id')}
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                    {t('competitors.aktiv')}
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                    {t('competitors.muveletek')}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {loading ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">
                      {i18n.t('literals.betoltes')}
                    </td>
                  </tr>
                ) : filtered.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-500">
                      {t('common.noData')}
                    </td>
                  </tr>
                ) : (
                  filtered.map((item) => (
                    <tr key={item.id} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm">{item.name ?? '-'}</td>
                      <td className="px-4 py-3 text-sm">{item.website ?? '-'}</td>
                      <td className="px-4 py-3 text-sm font-mono text-xs">
                        {item.branchId ?? '-'}
                      </td>
                      <td className="px-4 py-3 text-sm">{item.isActive ? 'Igen' : 'Nem'}</td>
                      <td className="px-4 py-3 text-right">
                        <button
                          onClick={() => void openEdit(item)}
                          className="form-button mr-2 p-1 text-blue-600"
                          title="Szerkesztés"
                          disabled={editingLoadingId === item.id}
                        >
                          <Edit2
                            className={`h-4 w-4 ${editingLoadingId === item.id ? 'animate-pulse' : ''}`}
                          />
                        </button>
                        <button
                          onClick={() => handleDelete(item.id)}
                          className="form-button p-1 text-red-600"
                          title="Törlés"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <div className="text-sm text-gray-500">
            {t('audit.osszesen')}
            {filtered.length}
            {i18n.t('literals.lit-10')}
            {items.length}
          </div>
        </>
      )}
    </div>
  )
}
