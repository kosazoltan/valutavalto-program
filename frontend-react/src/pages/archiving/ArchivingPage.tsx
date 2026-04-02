import { useState, useEffect, useCallback } from 'react'
import { Archive, Play, Calendar, CheckCircle, Clock, AlertTriangle, Plus, RefreshCw } from 'lucide-react'
import { archivingApi, ArchiveTask } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'
import { useAuthStore } from '../../stores/authStore'

interface MonthlyArchiveStatus {
  yearMonth: string
  status: 'NOT_STARTED' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED'
  archivedCount: number
  totalCount: number
  completedAt?: string
}

export default function ArchivingPage() {
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [tasks, setTasks] = useState<ArchiveTask[]>([])
  const [loading, setLoading] = useState(true)
  const [monthlyStatus, setMonthlyStatus] = useState<MonthlyArchiveStatus | null>(null)
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const d = new Date()
    d.setMonth(d.getMonth() - 1)
    return d.toISOString().slice(0, 7)
  })
  const [showNewTask, setShowNewTask] = useState(false)
  const [newTask, setNewTask] = useState({ taskType: 'FULL', entityType: 'TRANSACTIONS' })
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setTasks(await archivingApi.listTasks())
    } catch (err) {
      logger.error('ArchivingPage', 'Failed to load tasks:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  const loadMonthlyStatus = useCallback(async () => {
    if (!branchId || !selectedMonth) return
    try {
      const data = await archivingApi.getMonthlyStatus(branchId, selectedMonth)
      setMonthlyStatus(data as MonthlyArchiveStatus)
    } catch {
      setMonthlyStatus(null)
    }
  }, [branchId, selectedMonth])

  useEffect(() => { void loadData() }, [loadData])
  useEffect(() => { void loadMonthlyStatus() }, [loadMonthlyStatus])

  const handleExecute = async (id: string) => {
    try {
      setError(null)
      await archivingApi.executeTask(id)
      toast.success('Archiválás elindítva')
      await loadData()
    } catch (err) {
      toast.error('Archiválási hiba', getErrorMessage(err))
    }
  }

  const handleMonthlyArchive = async () => {
    if (!branchId) { toast.warning('Fiók szükséges'); return }
    if (!confirm(`Biztosan elindítja a havi archiválást (${selectedMonth})?`)) return
    try {
      setError(null)
      await archivingApi.monthlyArchive(branchId, selectedMonth)
      toast.success('Havi archiválás elindítva')
      await Promise.all([loadData(), loadMonthlyStatus()])
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleCreateTask = async () => {
    try {
      setError(null)
      await archivingApi.createTask(newTask)
      toast.success('Archiválási feladat létrehozva')
      setShowNewTask(false)
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'COMPLETED': return <span className="badge badge-green"><CheckCircle size={10} className="inline" /> Kész</span>
      case 'IN_PROGRESS': return <span className="badge badge-blue"><Clock size={10} className="inline animate-spin" /> Folyamatban</span>
      case 'FAILED': return <span className="badge badge-red"><AlertTriangle size={10} className="inline" /> Hiba</span>
      default: return <span className="badge badge-gray">{status || 'Várakozik'}</span>
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><Archive />Archiválás</h1>
        <div className="flex gap-2">
          <button onClick={() => void loadData()} className="form-button"><RefreshCw size={16} /> Frissítés</button>
          <button onClick={() => setShowNewTask(true)} className="form-button-primary"><Plus size={16} /> Új feladat</button>
        </div>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>}

      {/* Monthly archive */}
      <div className="form-panel space-y-3">
        <h2 className="font-semibold flex items-center gap-2"><Calendar size={18} /> Havi archiválás</h2>
        <div className="flex items-end gap-3">
          <div>
            <label className="form-label">Hónap</label>
            <input className="form-input" type="month" value={selectedMonth} onChange={e => setSelectedMonth(e.target.value)} />
          </div>
          <button onClick={() => void handleMonthlyArchive()} className="form-button-primary">
            <Archive size={16} /> Havi archiválás indítása
          </button>
        </div>
        {monthlyStatus && (
          <div className="flex items-center gap-4 text-sm">
            {getStatusBadge(monthlyStatus.status)}
            <span>Archivált: {monthlyStatus.archivedCount}/{monthlyStatus.totalCount}</span>
            {monthlyStatus.completedAt && <span className="text-gray-500">Befejezve: {new Date(monthlyStatus.completedAt).toLocaleString('hu-HU')}</span>}
          </div>
        )}
      </div>

      {/* New task form */}
      {showNewTask && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">Új archiválási feladat</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">Típus</label>
              <select className="form-input" value={newTask.taskType} onChange={e => setNewTask({ ...newTask, taskType: e.target.value })}>
                <option value="FULL">Teljes</option>
                <option value="INCREMENTAL">Inkrementális</option>
                <option value="CLEANUP">Takarítás</option>
              </select>
            </div>
            <div>
              <label className="form-label">Entitás</label>
              <select className="form-input" value={newTask.entityType} onChange={e => setNewTask({ ...newTask, entityType: e.target.value })}>
                <option value="TRANSACTIONS">Tranzakciók</option>
                <option value="CUSTOMERS">Ügyfelek</option>
                <option value="RATES">Árfolyamok</option>
                <option value="REPORTS">Jelentések</option>
                <option value="LOGS">Naplók</option>
              </select>
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleCreateTask()} className="form-button-primary">Létrehozás</button>
            <button onClick={() => setShowNewTask(false)} className="form-button">Mégse</button>
          </div>
        </div>
      )}

      {/* Tasks table */}
      <div className="form-panel">
        <h2 className="font-semibold mb-2">Archiválási feladatok</h2>
        {loading ? <div>Betöltés...</div> : safeArray<ArchiveTask>(tasks).length === 0 ? (
          <div className="text-center text-gray-500 py-4">Nincs archiválási feladat</div>
        ) : (
          <table className="data-grid w-full">
            <thead><tr><th>Típus</th><th>Entitás</th><th>Státusz</th><th>Kezdés</th><th>Befejezés</th><th>Műveletek</th></tr></thead>
            <tbody>
              {safeArray<ArchiveTask>(tasks).map(t => (
                <tr key={t.id}>
                  <td>{t.taskType}</td>
                  <td>{t.entityType}</td>
                  <td>{getStatusBadge(t.status)}</td>
                  <td className="text-sm">{t.startedAt ? new Date(t.startedAt).toLocaleString('hu-HU') : '-'}</td>
                  <td className="text-sm">{t.completedAt ? new Date(t.completedAt).toLocaleString('hu-HU') : '-'}</td>
                  <td>
                    {t.status !== 'COMPLETED' && t.status !== 'IN_PROGRESS' && (
                      <button onClick={() => void handleExecute(t.id)} className="form-button text-xs"><Play size={12} /> Futtatás</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
