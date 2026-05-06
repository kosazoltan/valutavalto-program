import { useState, useCallback } from 'react'
import { ClipboardCheck, Calendar, CheckCircle, Circle, AlertTriangle, Send } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAuthStore } from '../../stores/authStore'
import { dailyChecklistApi } from '../../services/api/index'
import { useTranslation } from 'react-i18next'

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

export default function DailyChecklistPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''
  const workerId = worker?.id ? String(worker.id) : ''

  const [date, setDate] = useState(new Date().toISOString().slice(0, 10))
  const [checklist, setChecklist] = useState<DailyChecklist | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [editingNote, setEditingNote] = useState<number | null>(null)
  const [noteText, setNoteText] = useState('')

  const loadChecklist = useCallback(async () => {
    if (!branchId) { toast.warning('Fiók szükséges'); return }
    try {
      setLoading(true)
      setError(null)
      const data = await dailyChecklistApi.get(branchId, date)
      setChecklist(data as DailyChecklist)
    } catch (err) {
      logger.error('DailyChecklistPage', 'Checklist betöltési hiba:', err)
      setError(getErrorMessage(err))
      setChecklist(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  const handleToggleItem = async (itemNumber: number, completed: boolean) => {
    if (!checklist) return
    try {
      setError(null)
      await dailyChecklistApi.updateItem(checklist.id, itemNumber, {
        isCompleted: completed,
        completedBy: workerId,
        note: noteText || undefined,
      })
      await loadChecklist()
    } catch (err) {
      setError(getErrorMessage(err))
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleComplete = async () => {
    if (!checklist) return
    const mandatoryPending = checklist.items.filter(i => i.isMandatory && !i.isCompleted)
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
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'COMPLETED':
      case 'SUBMITTED':
        return <span className="badge badge-green"><CheckCircle size={10} className="inline" />{t('archiving.kesz')}</span>
      case 'IN_PROGRESS':
        return <span className="badge badge-blue">{t('common.inProgress')}</span>
      default:
        return <span className="badge badge-gray">{t('cashdesk.nyitott')}</span>
    }
  }

  const progressPct = checklist ? Math.round((checklist.completedCount / Math.max(1, checklist.totalCount)) * 100) : 0

  // Group by category
  const categories = checklist ? [...new Set(checklist.items.map(i => i.category))] : []

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><ClipboardCheck />{t('cashdesk.napiEllenorzesiLista')}</h1>
        {checklist && checklist.status !== 'COMPLETED' && checklist.status !== 'SUBMITTED' && (
          <button onClick={handleComplete} className="form-button-primary">
            <Send size={16} />{t('cashdesk.listaLezarasa')}
          </button>
        )}
      </div>

      {/* Dátum és betöltés */}
      <div className="form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">{t('common.date')}</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input className="form-input" type="date" value={date} onChange={e => setDate(e.target.value)} />
          </div>
        </div>
        <button onClick={() => void loadChecklist()} disabled={loading} className="form-button-primary">
          {loading ? 'Betöltés...' : 'Betöltés'}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      {checklist && (
        <>
          {/* Progress */}
          <div className="form-panel">
            <div className="flex justify-between items-center mb-2">
              <div className="flex gap-2 items-center">
                {getStatusBadge(checklist.status)}
                <span className="text-sm text-gray-500">{checklist.branchName} — {checklist.date}</span>
              </div>
              <span className="font-mono text-sm">{checklist.completedCount}/{checklist.totalCount} ({progressPct}%)</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-3">
              <div
                className={`h-3 rounded-full transition-all ${progressPct === 100 ? 'bg-green-500' : progressPct > 50 ? 'bg-blue-500' : 'bg-yellow-500'}`}
                style={{ width: `${progressPct}%` }}
              />
            </div>
          </div>

          {/* Items by category */}
          {categories.map(cat => (
            <div key={cat} className="form-panel">
              <h2 className="font-semibold mb-2">{cat || 'Általános'}</h2>
              <div className="space-y-2">
                {checklist.items.filter(i => i.category === cat).map(item => (
                  <div key={item.itemNumber} className={`flex items-start gap-3 p-2 rounded ${item.isCompleted ? 'bg-green-50' : item.isMandatory ? 'bg-yellow-50' : 'bg-white'}`}>
                    <button
                      onClick={() => handleToggleItem(item.itemNumber, !item.isCompleted)}
                      disabled={checklist.status === 'COMPLETED' || checklist.status === 'SUBMITTED'}
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
                        <span className={`font-medium ${item.isCompleted ? 'line-through text-gray-400' : ''}`}>{item.title}</span>
                        {item.isMandatory && !item.isCompleted && (
                          <span className="badge badge-red text-xs">{t('cashdesk.kotelezo')}</span>
                        )}
                      </div>
                      {item.description && <div className="text-sm text-gray-500">{item.description}</div>}
                      {item.isCompleted && item.completedAt && (
                        <div className="text-xs text-gray-400 mt-1">
                          {t('cashdesk.kesz')}{new Date(item.completedAt).toLocaleString('hu-HU')} {item.completedBy ? `(${item.completedBy})` : ''}
                        </div>
                      )}
                      {item.note && <div className="text-xs text-blue-600 mt-1">{t('cashdesk.megjegyzes')} {item.note}</div>}
                      {/* Note edit */}
                      {editingNote === item.itemNumber ? (
                        <div className="flex gap-1 mt-1">
                          <input className="form-input text-xs flex-1" value={noteText} onChange={e => setNoteText(e.target.value)} placeholder="Megjegyzés..." />
                          <button onClick={() => { void handleToggleItem(item.itemNumber, item.isCompleted); setEditingNote(null) }} className="form-button text-xs">OK</button>
                          <button onClick={() => setEditingNote(null)} className="form-button text-xs">X</button>
                        </div>
                      ) : (
                        <button onClick={() => { setEditingNote(item.itemNumber); setNoteText(item.note || '') }} className="text-xs text-blue-500 hover:underline mt-1">
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
          {checklist.status !== 'COMPLETED' && checklist.status !== 'SUBMITTED' && (
            (() => {
              const pending = checklist.items.filter(i => i.isMandatory && !i.isCompleted)
              if (pending.length === 0) return null
              return (
                <div className="bg-yellow-50 border border-yellow-200 rounded p-3">
                  <div className="font-semibold flex items-center gap-1 text-yellow-700"><AlertTriangle size={16} /> {pending.length} {t('cashdesk.kotelezoPontMegNincs')}</div>
                  {pending.map(p => (
                    <div key={p.itemNumber} className="text-sm text-yellow-600 ml-5">• {p.title}</div>
                  ))}
                </div>
              )
            })()
          )}
        </>
      )}
    </div>
  )
}
