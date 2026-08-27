import { useState, useCallback, useEffect } from 'react'
import {
  ClipboardCheck,
  Calendar,
  CheckCircle,
  Circle,
  AlertTriangle,
  Send,
  MonitorCheck,
} from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { excludeBankPartners } from '../../utils/bankPartners'
import { useAuthStore } from '../../stores/authStore'
import { api, dailyChecklistApi } from '../../services/api/index'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface ChecklistItem {
  itemNumber: number
  title: string
  description: string
  category: string
  isCompleted: boolean
  completedAt?: string
  completedBy?: string
  note?: string
  isMandatory: boolean
}

interface DailyChecklist {
  id: string
  branchId: string
  branchName: string
  date: string
  status: 'OPEN' | 'IN_PROGRESS' | 'COMPLETED' | 'SUBMITTED'
  items: ChecklistItem[]
  completedCount: number
  totalCount: number
  completedAt?: string
  completedBy?: string
}

interface BackendChecklistItem {
  itemNumber: number
  itemTitle: string
  itemDescription: string
  checked: boolean
  checkedAt?: string
  checkedByWorkerId?: number
  notes?: string
}

interface BackendDailyChecklist {
  id: string
  branchId: string
  checklistDate: string
  status: DailyChecklist['status']
  completedAt?: string
  items: BackendChecklistItem[]
}

interface BranchOption {
  id: string
  code?: string
  name: string
  isActive?: boolean
}

interface BranchChecklistStatus {
  branchId: string
  date: string
  completed: boolean
}

export default function DailyChecklistPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)

  const [date, setDate] = useState(localIsoDate())
  const [branchId, setBranchId] = useState(worker?.branchId || '')
  const [branches, setBranches] = useState<BranchOption[]>([])
  const [branchStatuses, setBranchStatuses] = useState<Record<string, BranchChecklistStatus>>({})
  const [checklist, setChecklist] = useState<DailyChecklist | null>(null)
  const [loading, setLoading] = useState(false)
  const [overviewLoading, setOverviewLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [editingNote, setEditingNote] = useState<number | null>(null)
  const [noteText, setNoteText] = useState('')

  const mapChecklist = useCallback(
    (data: BackendDailyChecklist): DailyChecklist => {
      const branch = branches.find((b) => b.id === data.branchId)
      const items: ChecklistItem[] = (data.items ?? []).map((item) => ({
        itemNumber: item.itemNumber,
        title: item.itemTitle,
        description: item.itemDescription,
        category: 'Napi ellenőrzés',
        isCompleted: item.checked,
        completedAt: item.checkedAt,
        completedBy: item.checkedByWorkerId ? String(item.checkedByWorkerId) : undefined,
        note: item.notes,
        isMandatory: true,
      }))
      return {
        id: data.id,
        branchId: data.branchId,
        branchName: branch?.name ?? worker?.branchName ?? data.branchId,
        date: data.checklistDate,
        status: data.status,
        items,
        completedCount: items.filter((item) => item.isCompleted).length,
        totalCount: items.length,
        completedAt: data.completedAt,
      }
    },
    [branches, worker?.branchName],
  )

  const loadBranches = useCallback(async () => {
    try {
      const response = await api.get<BranchOption[]>('/branches')
      // FK-014: banki/speciális partnerek (VAULT_COUNTERPARTY) kiszűrése — csak a valódi irodák
      // (65 pénztár + 8 értéktár) végeznek napi ellenőrzést/zárást. A szűrés a status-gridre és a
      // Fiók-választóra is hat (egy forrás).
      const activeBranches = Array.isArray(response.data)
        ? excludeBankPartners(response.data.filter((branch) => branch.isActive !== false))
        : []
      setBranches(activeBranches)
      // FK-014 robusztusság: a kiválasztott branchId mindig a szűrt (valódi-iroda) listából való
      // legyen — ha a korábbi/worker-branch kiesne (elvileg a worker sosem banki partner), essünk
      // vissza az első valódi irodára.
      setBranchId((current) => {
        const isValid = (id?: string) => !!id && activeBranches.some((b) => b.id === id)
        if (isValid(current)) return current as string
        if (isValid(worker?.branchId)) return worker?.branchId as string
        return activeBranches[0]?.id ?? ''
      })
    } catch (err) {
      logger.warn('DailyChecklistPage', 'Branch lista betöltési hiba:', err)
    }
  }, [worker?.branchId])

  const loadOverview = useCallback(async () => {
    if (branches.length === 0) return
    try {
      setOverviewLoading(true)
      const pairs = await Promise.all(
        branches.map(async (branch) => {
          try {
            const status = (await dailyChecklistApi.status(
              branch.id,
              date,
            )) as BranchChecklistStatus
            return [branch.id, status] as const
          } catch {
            return [branch.id, { branchId: branch.id, date, completed: false }] as const
          }
        }),
      )
      setBranchStatuses(Object.fromEntries(pairs))
    } finally {
      setOverviewLoading(false)
    }
  }, [branches, date])

  const loadChecklist = useCallback(async () => {
    if (!branchId) {
      toast.warning('Fiók szükséges')
      return
    }
    try {
      setLoading(true)
      setError(null)
      const data = (await dailyChecklistApi.get(branchId, date)) as BackendDailyChecklist
      setChecklist(mapChecklist(data))
      await loadOverview()
    } catch (err) {
      logger.error('DailyChecklistPage', 'Checklist betöltési hiba:', err)
      setError(getErrorMessage(err))
      setChecklist(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, date, loadOverview, mapChecklist])

  useEffect(() => {
    void loadBranches()
  }, [loadBranches])
  useEffect(() => {
    void loadOverview()
  }, [loadOverview])

  const handleToggleItem = async (itemNumber: number, completed: boolean) => {
    if (!checklist) return
    try {
      setError(null)
      await dailyChecklistApi.updateItem(checklist.id, itemNumber, {
        checked: completed,
        notes: noteText || undefined,
      })
      await loadChecklist()
    } catch (err) {
      setError(getErrorMessage(err))
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleComplete = async () => {
    if (!checklist) return
    const mandatoryPending = checklist.items.filter((i) => i.isMandatory && !i.isCompleted)
    if (mandatoryPending.length > 0) {
      toast.error('Hiányzó kötelező pontok', `${mandatoryPending.length} kötelező pont nincs kész`)
      return
    }
    if (!confirm('Biztosan lezárja az ellenőrzési listát? Ez nem visszavonható.')) return
    try {
      setError(null)
      await dailyChecklistApi.complete(checklist.id)
      toast.success('Ellenőrzési lista lezárva')
      await loadChecklist()
      await loadOverview()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'COMPLETED':
      case 'SUBMITTED':
        return (
          <span className="badge badge-green">
            <CheckCircle size={10} className="inline" />
            {t('archiving.kesz')}
          </span>
        )
      case 'IN_PROGRESS':
        return <span className="badge badge-blue">{t('common.inProgress')}</span>
      default:
        return <span className="badge badge-gray">{t('cashdesk.nyitott')}</span>
    }
  }

  const progressPct = checklist
    ? Math.round((checklist.completedCount / Math.max(1, checklist.totalCount)) * 100)
    : 0

  // Group by category
  const categories = checklist ? [...new Set(checklist.items.map((i) => i.category))] : []

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <ClipboardCheck />
          {t('cashdesk.napiEllenorzesiLista')}
        </h1>
        {checklist && checklist.status !== 'COMPLETED' && checklist.status !== 'SUBMITTED' && (
          <button onClick={handleComplete} className="form-button-primary">
            <Send size={16} />
            {t('cashdesk.listaLezarasa')}
          </button>
        )}
      </div>

      {branches.length > 0 && (
        <div className="form-panel">
          <div className="mb-2 flex items-center justify-between">
            <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <MonitorCheck size={16} />
              {i18n.t('literals.kozponti-statusz')}
            </div>
            <button
              onClick={() => void loadOverview()}
              disabled={overviewLoading}
              className="form-button text-xs"
            >
              {overviewLoading ? 'Frissítés...' : 'Státusz frissítés'}
            </button>
          </div>
          <div className="grid grid-cols-1 gap-2 md:grid-cols-2 xl:grid-cols-4">
            {branches.map((branch) => {
              const status = branchStatuses[branch.id]
              const selected = branch.id === branchId
              return (
                <button
                  key={branch.id}
                  type="button"
                  onClick={() => {
                    setBranchId(branch.id)
                    setChecklist(null)
                  }}
                  className={`rounded border p-2 text-left text-xs transition ${
                    selected
                      ? 'border-blue-400 bg-blue-50'
                      : 'border-gray-200 bg-white hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-semibold text-gray-900">{branch.name}</span>
                    <span
                      className={`rounded px-1.5 py-0.5 text-[10px] font-semibold ${
                        status?.completed
                          ? 'bg-green-100 text-green-700'
                          : 'bg-yellow-100 text-yellow-700'
                      }`}
                    >
                      {status?.completed ? 'kész' : 'hiányzik'}
                    </span>
                  </div>
                  {branch.code && <div className="mt-1 text-gray-500">{branch.code}</div>}
                </button>
              )
            })}
          </div>
        </div>
      )}

      {/* Dátum és betöltés */}
      <div className="form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">{i18n.t('literals.fiok')}</label>
          <select
            className="form-input min-w-[260px]"
            value={branchId}
            onChange={(e) => {
              setBranchId(e.target.value)
              setChecklist(null)
            }}
          >
            <option value="">{t('export.valassz')}</option>
            {branches.map((branch) => (
              <option key={branch.id} value={branch.id}>
                {branch.name}
                {branch.code ? ` (${branch.code})` : ''}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="form-label">{t('common.date')}</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input
              className="form-input"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>
        </div>
        <button
          onClick={() => void loadChecklist()}
          disabled={loading}
          className="form-button-primary"
        >
          {loading ? 'Betöltés...' : 'Betöltés'}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {checklist && (
        <>
          {/* Progress */}
          <div className="form-panel">
            <div className="flex justify-between items-center mb-2">
              <div className="flex gap-2 items-center">
                {getStatusBadge(checklist.status)}
                <span className="text-sm text-gray-500">
                  {checklist.branchName}
                  {i18n.t('literals.lit-18')}
                  {checklist.date}
                </span>
              </div>
              <span className="font-mono text-sm">
                {checklist.completedCount}
                {i18n.t('literals.lit-4')}
                {checklist.totalCount}
                {i18n.t('literals.lit')}
                {progressPct}
                {i18n.t('literals.lit-24')}
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-3">
              <div
                className={`h-3 rounded-full transition-all ${progressPct === 100 ? 'bg-green-500' : progressPct > 50 ? 'bg-blue-500' : 'bg-yellow-500'}`}
                style={{ width: `${progressPct}%` }}
              />
            </div>
          </div>

          {/* Items by category */}
          {categories.map((cat) => (
            <div key={cat} className="form-panel">
              <h2 className="font-semibold mb-2">{cat || 'Általános'}</h2>
              <div className="space-y-2">
                {checklist.items
                  .filter((i) => i.category === cat)
                  .map((item) => (
                    <div
                      key={item.itemNumber}
                      className={`flex items-start gap-3 p-2 rounded ${item.isCompleted ? 'bg-green-50' : item.isMandatory ? 'bg-yellow-50' : 'bg-white'}`}
                    >
                      <button
                        onClick={() => handleToggleItem(item.itemNumber, !item.isCompleted)}
                        disabled={
                          checklist.status === 'COMPLETED' || checklist.status === 'SUBMITTED'
                        }
                        className="mt-0.5 flex-shrink-0"
                      >
                        {item.isCompleted ? (
                          <CheckCircle size={20} className="text-green-600" />
                        ) : (
                          <Circle size={20} className="text-gray-300 hover:text-blue-400" />
                        )}
                      </button>
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span
                            className={`font-medium ${item.isCompleted ? 'line-through text-gray-400' : ''}`}
                          >
                            {item.title}
                          </span>
                          {item.isMandatory && !item.isCompleted && (
                            <span className="badge badge-red text-xs">
                              {t('cashdesk.kotelezo')}
                            </span>
                          )}
                        </div>
                        {item.description && (
                          <div className="text-sm text-gray-500">{item.description}</div>
                        )}
                        {item.isCompleted && item.completedAt && (
                          <div className="text-xs text-gray-400 mt-1">
                            {t('cashdesk.kesz')}
                            {new Date(item.completedAt).toLocaleString('hu-HU')}{' '}
                            {item.completedBy ? `(${item.completedBy})` : ''}
                          </div>
                        )}
                        {item.note && (
                          <div className="text-xs text-blue-600 mt-1">
                            {t('cashdesk.megjegyzes')} {item.note}
                          </div>
                        )}
                        {/* Note edit */}
                        {editingNote === item.itemNumber ? (
                          <div className="flex gap-1 mt-1">
                            <input
                              className="form-input text-xs flex-1"
                              value={noteText}
                              onChange={(e) => setNoteText(e.target.value)}
                              placeholder="Megjegyzés..."
                            />
                            <button
                              onClick={() => {
                                void handleToggleItem(item.itemNumber, item.isCompleted)
                                setEditingNote(null)
                              }}
                              className="form-button text-xs"
                            >
                              {i18n.t('literals.ok')}
                            </button>
                            <button
                              onClick={() => setEditingNote(null)}
                              className="form-button text-xs"
                            >
                              {i18n.t('literals.x-2')}
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => {
                              setEditingNote(item.itemNumber)
                              setNoteText(item.note || '')
                            }}
                            className="text-xs text-blue-500 hover:underline mt-1"
                          >
                            {item.note ? 'Szerkesztés' : '+ Megjegyzés'}
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          ))}

          {/* Mandatory warnings */}
          {checklist.status !== 'COMPLETED' &&
            checklist.status !== 'SUBMITTED' &&
            (() => {
              const pending = checklist.items.filter((i) => i.isMandatory && !i.isCompleted)
              if (pending.length === 0) return null
              return (
                <div className="bg-yellow-50 border border-yellow-200 rounded p-3">
                  <div className="font-semibold flex items-center gap-1 text-yellow-700">
                    <AlertTriangle size={16} /> {pending.length}{' '}
                    {t('cashdesk.kotelezoPontMegNincs')}
                  </div>
                  {pending.map((p) => (
                    <div key={p.itemNumber} className="text-sm text-yellow-600 ml-5">
                      {i18n.t('literals.lit-25')}
                      {p.title}
                    </div>
                  ))}
                </div>
              )
            })()}
        </>
      )}
    </div>
  )
}
