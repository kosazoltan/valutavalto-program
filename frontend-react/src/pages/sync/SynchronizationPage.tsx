import { useState, useEffect, useCallback, useRef } from 'react'
import { RefreshCw, Download, Upload, Clock, CheckCircle, XCircle, AlertTriangle, Database, Server } from 'lucide-react'
import { synchronizationApi } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'

interface SyncLog {
  id: string
  direction: 'UPLOAD' | 'DOWNLOAD'
  status: 'SUCCESS' | 'FAILED' | 'IN_PROGRESS' | 'PARTIAL'
  recordsSynced: number
  recordsFailed: number
  startedAt: string
  completedAt?: string
  errorMessage?: string
  entityTypes: string[]
}

interface SyncStatus {
  lastSync: string | null
  pendingUpload: number
  pendingDownload: number
  isOnline: boolean
  serverVersion: string
  localVersion: string
}

export default function SynchronizationPage() {
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''
  const workerId = worker?.id ? String(worker.id) : ''

  const [loading, setLoading] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [syncLogs, setSyncLogs] = useState<SyncLog[]>([])
  const [status, setStatus] = useState<SyncStatus>({
    lastSync: null,
    pendingUpload: 0,
    pendingDownload: 0,
    isOnline: false,
    serverVersion: '',
    localVersion: '',
  })
  const [autoSyncEnabled, setAutoSyncEnabled] = useState(false)
  const [selectedEntities, setSelectedEntities] = useState<string[]>([
    'TRANSACTIONS', 'CUSTOMERS', 'RATES', 'DENOMINATIONS', 'BALANCES',
  ])

  const ENTITY_TYPES = [
    { value: 'TRANSACTIONS', label: 'Tranzakciók' },
    { value: 'CUSTOMERS', label: 'Ügyfelek' },
    { value: 'RATES', label: 'Árfolyamok' },
    { value: 'DENOMINATIONS', label: 'Címletek' },
    { value: 'BALANCES', label: 'Egyenlegek' },
    { value: 'WORKERS', label: 'Dolgozók' },
    { value: 'SETTINGS', label: 'Beállítások' },
    { value: 'BLACKLIST', label: 'Tiltólista' },
    { value: 'CIRCULARS', label: 'Körlevelek' },
  ]

  const loadStatus = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [shouldSync, logs] = await Promise.all([
        synchronizationApi.shouldSync().catch(() => ({ shouldSync: false, pendingCount: 0 })),
        synchronizationApi.getLogs().catch(() => []),
      ])
      setStatus(prev => ({
        ...prev,
        pendingUpload: shouldSync.pendingCount || 0,
        isOnline: true,
      }))
      setSyncLogs(logs as SyncLog[])
    } catch (err) {
      logger.error('SynchronizationPage', 'Státusz betöltési hiba:', err)
      setStatus(prev => ({ ...prev, isOnline: false }))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadStatus()
  }, [loadStatus])

  const autoSyncRef = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    if (autoSyncEnabled && branchId && workerId && status.isOnline) {
      autoSyncRef.current = setInterval(() => {
        void synchronizationApi.synchronize(branchId, workerId).then(() => void loadStatus()).catch(() => { /* silent */ })
      }, 5 * 60 * 1000)
    }
    return () => { if (autoSyncRef.current) { clearInterval(autoSyncRef.current); autoSyncRef.current = null } }
  }, [autoSyncEnabled, branchId, workerId, status.isOnline, loadStatus])

  const handleSync = async (direction: 'FULL' | 'UPLOAD' | 'DOWNLOAD') => {
    if (!branchId || !workerId) {
      toast.warning('Hiányzó adatok', 'Bejelentkezés szükséges a szinkronizációhoz')
      return
    }
    try {
      setSyncing(true)
      setError(null)
      const res = await synchronizationApi.synchronize(branchId, workerId, {
        direction,
        entityTypes: selectedEntities,
      })
      toast.success('Szinkronizáció kész', `${res.recordsSynced} rekord szinkronizálva`)
      await loadStatus()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      toast.error('Szinkronizációs hiba', msg)
      logger.error('SynchronizationPage', 'Sync error:', err)
    } finally {
      setSyncing(false)
    }
  }

  const toggleEntity = (entity: string) => {
    setSelectedEntities(prev =>
      prev.includes(entity) ? prev.filter(e => e !== entity) : [...prev, entity]
    )
  }

  const getStatusBadge = (s: string) => {
    switch (s) {
      case 'SUCCESS': return <span className="badge badge-green"><CheckCircle size={10} className="inline" /> Sikeres</span>
      case 'FAILED': return <span className="badge badge-red"><XCircle size={10} className="inline" /> Sikertelen</span>
      case 'IN_PROGRESS': return <span className="badge badge-blue"><RefreshCw size={10} className="inline animate-spin" /> Folyamatban</span>
      case 'PARTIAL': return <span className="badge badge-yellow"><AlertTriangle size={10} className="inline" /> Részleges</span>
      default: return <span className="badge badge-gray">{s}</span>
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><RefreshCw />Szinkronizáció</h1>
        <div className="flex items-center gap-2">
          <span className={`badge ${status.isOnline ? 'badge-green' : 'badge-red'}`}>
            {status.isOnline ? <><Server size={10} className="inline" /> Online</> : <><XCircle size={10} className="inline" /> Offline</>}
          </span>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      {/* Status cards */}
      <div className="grid grid-cols-4 gap-3">
        <div className="form-panel text-center">
          <Upload size={20} className="mx-auto text-blue-500 mb-1" />
          <div className="text-lg font-bold">{status.pendingUpload}</div>
          <div className="text-sm text-gray-500">Feltöltendő</div>
        </div>
        <div className="form-panel text-center">
          <Download size={20} className="mx-auto text-green-500 mb-1" />
          <div className="text-lg font-bold">{status.pendingDownload}</div>
          <div className="text-sm text-gray-500">Letöltendő</div>
        </div>
        <div className="form-panel text-center">
          <Clock size={20} className="mx-auto text-gray-500 mb-1" />
          <div className="text-sm font-medium">{status.lastSync ? new Date(status.lastSync).toLocaleString('hu-HU') : 'Nincs adat'}</div>
          <div className="text-sm text-gray-500">Utolsó szinkron</div>
        </div>
        <div className="form-panel text-center">
          <Database size={20} className="mx-auto text-purple-500 mb-1" />
          <div className="text-sm font-medium">{syncLogs.length}</div>
          <div className="text-sm text-gray-500">Napló bejegyzés</div>
        </div>
      </div>

      {/* Sync controls */}
      <div className="form-panel space-y-3">
        <h2 className="font-semibold">Szinkronizálás</h2>

        <div>
          <label className="form-label">Entitások kiválasztása</label>
          <div className="flex flex-wrap gap-2">
            {ENTITY_TYPES.map(et => (
              <label key={et.value} className={`px-3 py-1 rounded-full text-sm cursor-pointer border ${selectedEntities.includes(et.value) ? 'bg-blue-100 border-blue-400 text-blue-700' : 'bg-gray-50 border-gray-200 text-gray-500'}`}>
                <input type="checkbox" className="hidden" checked={selectedEntities.includes(et.value)} onChange={() => toggleEntity(et.value)} />
                {et.label}
              </label>
            ))}
          </div>
        </div>

        <div className="flex gap-2">
          <button onClick={() => void handleSync('FULL')} disabled={syncing || !status.isOnline} className="form-button-primary">
            <RefreshCw size={16} className={syncing ? 'animate-spin' : ''} /> {syncing ? 'Szinkronizálás...' : 'Teljes szinkron'}
          </button>
          <button onClick={() => void handleSync('UPLOAD')} disabled={syncing || !status.isOnline} className="form-button">
            <Upload size={16} /> Csak feltöltés
          </button>
          <button onClick={() => void handleSync('DOWNLOAD')} disabled={syncing || !status.isOnline} className="form-button">
            <Download size={16} /> Csak letöltés
          </button>
        </div>

        <div className="flex items-center gap-2">
          <label className="flex items-center gap-1 text-sm">
            <input type="checkbox" checked={autoSyncEnabled} onChange={e => setAutoSyncEnabled(e.target.checked)} />
            Automatikus szinkron (5 percenként)
          </label>
        </div>
      </div>

      {/* Sync log */}
      <div className="form-panel">
        <h2 className="font-semibold mb-2">Szinkronizációs napló</h2>
        {loading ? <div>Betöltés...</div> : syncLogs.length === 0 ? (
          <div className="text-center text-gray-500 py-4">Nincs szinkronizációs bejegyzés</div>
        ) : (
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>Időpont</th>
                <th>Irány</th>
                <th>Entitások</th>
                <th>Szinkronizálva</th>
                <th>Hibás</th>
                <th>Státusz</th>
              </tr>
            </thead>
            <tbody>
              {syncLogs.map(log => (
                <tr key={log.id}>
                  <td className="text-sm">{new Date(log.startedAt).toLocaleString('hu-HU')}</td>
                  <td>
                    {log.direction === 'UPLOAD' ? <><Upload size={12} className="inline" /> Feltöltés</> : <><Download size={12} className="inline" /> Letöltés</>}
                  </td>
                  <td className="text-sm">{(log.entityTypes || []).join(', ')}</td>
                  <td className="font-mono">{log.recordsSynced}</td>
                  <td className="font-mono text-red-600">{log.recordsFailed || 0}</td>
                  <td>{getStatusBadge(log.status)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
