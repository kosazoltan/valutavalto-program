import { useState, useEffect, useCallback } from 'react'
import {
  Archive,
  Play,
  Calendar,
  CheckCircle,
  Clock,
  AlertTriangle,
  Plus,
  RefreshCw,
} from 'lucide-react'
import { archivingApi, ArchiveTask, ArchivedTransaction } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface MonthlyArchiveStatus {
  yearMonth: string
  archived: boolean
}

export default function ArchivingPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [tasks, setTasks] = useState<ArchiveTask[]>([])
  const [loading, setLoading] = useState(true)
  const [monthlyStatus, setMonthlyStatus] = useState<MonthlyArchiveStatus | null>(null)
  const [archivedTransactions, setArchivedTransactions] = useState<ArchivedTransaction[]>([])
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
      const [status, archived] = await Promise.all([
        archivingApi.getMonthlyStatus(branchId, selectedMonth),
        archivingApi.getArchivedTransactions(branchId, selectedMonth),
      ])
      setMonthlyStatus(status as MonthlyArchiveStatus)
      setArchivedTransactions(safeArray<ArchivedTransaction>(archived))
    } catch {
      setMonthlyStatus(null)
      setArchivedTransactions([])
    }
  }, [branchId, selectedMonth])

  useEffect(() => {
    void loadData()
  }, [loadData])
  useEffect(() => {
    void loadMonthlyStatus()
  }, [loadMonthlyStatus])

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
    if (!branchId) {
      toast.warning('Fiók szükséges')
      return
    }
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
      case 'COMPLETED':
        return (
          <span className="badge badge-green">
            <CheckCircle size={10} className="inline" />
            {t('archiving.kesz')}
          </span>
        )
      case 'IN_PROGRESS':
        return (
          <span className="badge badge-blue">
            <Clock size={10} className="inline animate-spin" />
            {t('common.inProgress')}
          </span>
        )
      case 'FAILED':
        return (
          <span className="badge badge-red">
            <AlertTriangle size={10} className="inline" />
            {t('common.error')}
          </span>
        )
      default:
        return <span className="badge badge-gray">{status || 'Várakozik'}</span>
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Archive />
          {t('archiving.archivalas')}
        </h1>
        <div className="flex gap-2">
          <button onClick={() => void loadData()} className="form-button">
            <RefreshCw size={16} />
            {t('common.refresh')}
          </button>
          <button onClick={() => setShowNewTask(true)} className="form-button-primary">
            <Plus size={16} />
            {t('archiving.ujFeladat')}
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Monthly archive */}
      <div className="form-panel space-y-3">
        <h2 className="font-semibold flex items-center gap-2">
          <Calendar size={18} />
          {t('archiving.haviArchivalas')}
        </h2>
        <div className="flex items-end gap-3">
          <div>
            <label className="form-label">{t('monthlyClose.month')}</label>
            <input
              className="form-input"
              type="month"
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
            />
          </div>
          <button onClick={() => void handleMonthlyArchive()} className="form-button-primary">
            <Archive size={16} />
            {t('archiving.haviArchivalasInditasa')}
          </button>
        </div>
        {monthlyStatus && (
          <div className="flex items-center gap-4 text-sm">
            {monthlyStatus.archived ? getStatusBadge('COMPLETED') : getStatusBadge('NOT_STARTED')}
            <span>
              {t('archiving.archivalt')}
              {archivedTransactions.length}
            </span>
          </div>
        )}
        {archivedTransactions.length > 0 && (
          <div className="overflow-x-auto rounded border border-gray-200 bg-white">
            <table className="data-grid w-full min-w-[760px]">
              <thead>
                <tr>
                  <th>{i18n.t('literals.bizonylat')}</th>
                  <th>{t('cashdesk.tipus')}</th>
                  <th>{i18n.t('literals.valuta')}</th>
                  <th className="text-right">{i18n.t('literals.osszeg')}</th>
                  <th className="text-right">{i18n.t('literals.huf')}</th>
                  <th>{i18n.t('literals.ugyfel-2')}</th>
                  <th>{i18n.t('literals.eredeti-datum')}</th>
                </tr>
              </thead>
              <tbody>
                {archivedTransactions.map((transaction) => (
                  <tr key={transaction.id}>
                    <td className="font-mono text-xs">
                      {transaction.receiptNumber ?? transaction.originalId}
                    </td>
                    <td>{transaction.transactionType ?? '-'}</td>
                    <td>{transaction.currencyCode ?? '-'}</td>
                    <td className="text-right">
                      {transaction.amount?.toLocaleString('hu-HU') ?? '-'}
                    </td>
                    <td className="text-right">
                      {transaction.hufAmount?.toLocaleString('hu-HU') ?? '-'}
                    </td>
                    <td>{transaction.customerName ?? '-'}</td>
                    <td>
                      {transaction.originalDate
                        ? new Date(transaction.originalDate).toLocaleString('hu-HU')
                        : '-'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* New task form */}
      {showNewTask && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{t('archiving.ujArchivalasiFeladat')}</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">{t('common.type')}</label>
              <select
                className="form-input"
                value={newTask.taskType}
                onChange={(e) => setNewTask({ ...newTask, taskType: e.target.value })}
              >
                <option value="FULL">{t('archiving.teljes')}</option>
                <option value="INCREMENTAL">{t('archiving.inkrementalis')}</option>
                <option value="CLEANUP">{t('archiving.takaritas')}</option>
              </select>
            </div>
            <div>
              <label className="form-label">{t('archiving.entitas')}</label>
              <select
                className="form-input"
                value={newTask.entityType}
                onChange={(e) => setNewTask({ ...newTask, entityType: e.target.value })}
              >
                <option value="TRANSACTIONS">{t('archiving.tranzakciok')}</option>
                <option value="CUSTOMERS">{t('archiving.ugyfelek')}</option>
                <option value="RATES">{t('cashier.rates')}</option>
                <option value="REPORTS">{t('archiving.jelentesek')}</option>
                <option value="LOGS">{t('archiving.naplok')}</option>
              </select>
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleCreateTask()} className="form-button-primary">
              {t('common.create')}
            </button>
            <button onClick={() => setShowNewTask(false)} className="form-button">
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Tasks table */}
      <div className="form-panel">
        <h2 className="font-semibold mb-2">{t('archiving.archivalasiFeladatok')}</h2>
        {loading ? (
          <div>{i18n.t('literals.betoltes')}</div>
        ) : safeArray<ArchiveTask>(tasks).length === 0 ? (
          <div className="text-center text-gray-500 py-4">
            {t('archiving.nincsArchivalasiFeladat')}
          </div>
        ) : (
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('common.type')}</th>
                <th>{t('archiving.entitas')}</th>
                <th>{t('common.status')}</th>
                <th>{t('archiving.kezdes')}</th>
                <th>{t('archiving.befejezes')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {safeArray<ArchiveTask>(tasks).map((task) => (
                <tr key={task.id}>
                  <td>{task.taskType}</td>
                  <td>{task.entityType}</td>
                  <td>{getStatusBadge(task.status)}</td>
                  <td className="text-sm">
                    {task.startedAt ? new Date(task.startedAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="text-sm">
                    {task.completedAt ? new Date(task.completedAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td>
                    {task.status !== 'COMPLETED' && task.status !== 'IN_PROGRESS' && (
                      <button
                        onClick={() => void handleExecute(task.id)}
                        className="form-button text-xs"
                      >
                        <Play size={12} />
                        {t('archiving.futtatas')}
                      </button>
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
