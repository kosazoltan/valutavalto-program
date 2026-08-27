import { useState, useEffect, useCallback, useRef } from 'react'
import { RefreshCw, Download, Upload, Clock, XCircle, Server, Database } from 'lucide-react'
import { api, synchronizationApi } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface SyncStatus {
  lastSync: string | null
  pendingUpload: number
  pendingDownload: number
  isOnline: boolean
  serverVersion: string
  localVersion: string
}

interface DataCollectionStatus {
  id?: string
  branchId?: string
  collectionDate?: string
  status: string
  collectionType?: string
  transactionCount?: number
  totalBuyHuf?: number
  totalSellHuf?: number
  completedAt?: string
  errorMessage?: string
}

interface BranchSyncStatus {
  branchId?: string
  lastSyncAt?: string | null
  lastSuccessfulSyncAt?: string | null
  status?: string
  pendingUpload?: number
  pendingDownload?: number
  pendingCount?: number
  errorMessage?: string | null
  [key: string]: unknown
}

interface BranchSyncLog {
  id?: string
  branchId?: string
  syncType?: string
  direction?: string
  status?: string
  startedAt?: string
  completedAt?: string | null
  recordsSynced?: number
  errorMessage?: string | null
  [key: string]: unknown
}

interface FtpSyncLog {
  id?: string
  branchId?: string
  direction?: string
  fileName?: string
  status?: string
  fileSizeBytes?: number
  startedAt?: string
  completedAt?: string | null
  errorMessage?: string | null
}

export default function SynchronizationPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const activeRole = useAuthStore((state) => state.activeRole)
  const branchId = worker?.branchId || ''
  const workerId = worker?.id ? String(worker.id) : ''
  const isAdmin = activeRole === 'ADMIN' || worker?.role === 'ADMIN'

  const [syncing, setSyncing] = useState(false)
  const [dataCollecting, setDataCollecting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [dataCollectionError, setDataCollectionError] = useState<string | null>(null)
  const [dataCollectionRows, setDataCollectionRows] = useState<DataCollectionStatus[]>([])
  const [dataCollectionBranchId, setDataCollectionBranchId] = useState(branchId)
  const [ftpActionLoading, setFtpActionLoading] = useState<string | null>(null)
  const [branchSyncStatus, setBranchSyncStatus] = useState<BranchSyncStatus | null>(null)
  const [branchSyncHistory, setBranchSyncHistory] = useState<BranchSyncLog[]>([])
  const [ftpSyncHistory, setFtpSyncHistory] = useState<FtpSyncLog[]>([])
  const [branchSyncLoading, setBranchSyncLoading] = useState(false)
  const [branchSyncActionLoading, setBranchSyncActionLoading] = useState<string | null>(null)
  const [branchSyncError, setBranchSyncError] = useState<string | null>(null)
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
    'TRANSACTIONS',
    'CUSTOMERS',
    'RATES',
    'DENOMINATIONS',
    'BALANCES',
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
      setError(null)
      const shouldSync = await synchronizationApi
        .shouldSync()
        .catch(() => ({ shouldSync: false, pendingCount: 0 }))
      setStatus((prev) => ({
        ...prev,
        pendingUpload: shouldSync.pendingCount || 0,
        isOnline: true,
      }))
    } catch (err) {
      logger.error('SynchronizationPage', 'Státusz betöltési hiba:', err)
      setStatus((prev) => ({ ...prev, isOnline: false }))
    }
  }, [])

  const loadDataCollectionStatus = useCallback(async () => {
    if (!isAdmin) return
    try {
      setDataCollectionError(null)
      const response = await api.get<DataCollectionStatus[]>('/data-collection/status')
      setDataCollectionRows(response.data ?? [])
    } catch (err) {
      const msg = getErrorMessage(err)
      setDataCollectionError(msg)
      logger.error('SynchronizationPage', 'Adatgyűjtés státusz betöltési hiba:', err)
    }
  }, [isAdmin])

  const loadBranchSyncDetails = useCallback(async () => {
    if (!isAdmin || !dataCollectionBranchId.trim()) return
    const selectedBranchId = dataCollectionBranchId.trim()
    try {
      setBranchSyncLoading(true)
      setBranchSyncError(null)
      const [statusResult, historyResult, ftpHistoryResult] = await Promise.all([
        api.get<BranchSyncStatus>(`/sync/status/${selectedBranchId}`),
        api.get<{ content?: BranchSyncLog[] } | BranchSyncLog[]>(
          `/sync/history/${selectedBranchId}`,
          {
            params: { page: 0, size: 5 },
            _preservePaged: true,
          } as Record<string, unknown>,
        ),
        api.get<FtpSyncLog[]>(`/ftp-sync/history/${selectedBranchId}`),
      ])
      setBranchSyncStatus(statusResult.data ?? null)
      setBranchSyncHistory(extractPagedContent<BranchSyncLog>(historyResult.data))
      setFtpSyncHistory(Array.isArray(ftpHistoryResult.data) ? ftpHistoryResult.data : [])
    } catch (err) {
      const msg = getErrorMessage(err)
      setBranchSyncError(msg)
      logger.error('SynchronizationPage', 'Branch sync status/history betöltési hiba:', err)
    } finally {
      setBranchSyncLoading(false)
    }
  }, [dataCollectionBranchId, isAdmin])

  useEffect(() => {
    void loadStatus()
    void loadDataCollectionStatus()
    void loadBranchSyncDetails()
  }, [loadBranchSyncDetails, loadDataCollectionStatus, loadStatus])

  const autoSyncRef = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    if (autoSyncEnabled && branchId && workerId && status.isOnline) {
      autoSyncRef.current = setInterval(
        () => {
          void synchronizationApi
            .synchronize(branchId, workerId)
            .then(() => void loadStatus())
            .catch(() => {
              /* silent */
            })
        },
        5 * 60 * 1000,
      )
    }
    return () => {
      if (autoSyncRef.current) {
        clearInterval(autoSyncRef.current)
        autoSyncRef.current = null
      }
    }
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

  const todayIso = () => new Date().toISOString().slice(0, 10)

  const handleCollectBranch = async () => {
    if (!dataCollectionBranchId.trim()) {
      toast.warning('Hiányzó iroda', 'Adjon meg branch UUID-t az adatgyűjtéshez')
      return
    }
    try {
      setDataCollecting(true)
      setDataCollectionError(null)
      const response = await api.post<DataCollectionStatus>(
        '/data-collection/collect',
        {
          branchId: dataCollectionBranchId.trim(),
          date: todayIso(),
        },
        { validateStatus: () => true },
      )
      if (response.status >= 400 && response.status !== 503)
        throw new Error(`HTTP ${response.status}`)
      setDataCollectionRows([response.data])
      toast.success('Adatgyűjtés elindítva', response.data.status)
      await loadBranchSyncDetails()
    } catch (err) {
      const msg = getErrorMessage(err)
      setDataCollectionError(msg)
      toast.error('Adatgyűjtési hiba', msg)
    } finally {
      setDataCollecting(false)
    }
  }

  const handleCollectAll = async () => {
    try {
      setDataCollecting(true)
      setDataCollectionError(null)
      const response = await api.post<DataCollectionStatus[]>(
        '/data-collection/collect-all',
        {
          date: todayIso(),
        },
        { validateStatus: () => true },
      )
      if (response.status >= 400 && response.status !== 503)
        throw new Error(`HTTP ${response.status}`)
      setDataCollectionRows(response.data ?? [])
      toast.success('Adatgyűjtés lefutott', `${response.data?.length ?? 0} iroda`)
      await loadBranchSyncDetails()
    } catch (err) {
      const msg = getErrorMessage(err)
      setDataCollectionError(msg)
      toast.error('Adatgyűjtési hiba', msg)
    } finally {
      setDataCollecting(false)
    }
  }

  const handleRetryFailed = async () => {
    try {
      setDataCollecting(true)
      setDataCollectionError(null)
      const response = await api.post<{ retriedCount: number }>('/data-collection/retry')
      toast.success(
        'Újrapróbálás kész',
        `${response.data.retriedCount} sikertelen gyűjtés újrapróbálva`,
      )
      await loadDataCollectionStatus()
      await loadBranchSyncDetails()
    } catch (err) {
      const msg = getErrorMessage(err)
      setDataCollectionError(msg)
      toast.error('Újrapróbálási hiba', msg)
    } finally {
      setDataCollecting(false)
    }
  }

  const runFtpSync = async (kind: 'rates' | 'daily-report' | 'transactions') => {
    const selectedBranchId = dataCollectionBranchId.trim()
    if (!selectedBranchId) {
      toast.warning('Hiányzó iroda', 'Adjon meg branch UUID-t az FTP szinkronhoz')
      return
    }
    try {
      setFtpActionLoading(kind)
      setDataCollectionError(null)
      const requestConfig = { validateStatus: () => true }
      const response =
        kind === 'rates'
          ? await api.post<{ success?: boolean; message?: string; fileName?: string }>(
              `/ftp-sync/rates/${selectedBranchId}`,
              null,
              requestConfig,
            )
          : kind === 'daily-report'
            ? await api.post<{ success?: boolean; message?: string; fileName?: string }>(
                `/ftp-sync/daily-report/${selectedBranchId}`,
                null,
                requestConfig,
              )
            : await api.post<{ success?: boolean; message?: string; fileName?: string }>(
                `/ftp-sync/transactions/${selectedBranchId}`,
                null,
                requestConfig,
              )
      if (response.status >= 400 && response.status !== 503)
        throw new Error(`HTTP ${response.status}`)
      const label = response.data?.fileName || response.data?.message || kind
      toast.success('FTP szinkron elindítva', label)
      await loadBranchSyncDetails()
    } catch (err) {
      const msg = getErrorMessage(err)
      setDataCollectionError(msg)
      toast.error('FTP szinkron hiba', msg)
    } finally {
      setFtpActionLoading(null)
    }
  }

  const runBranchSync = async (kind: 'rates' | 'transactions' | 'inventory' | 'full') => {
    const selectedBranchId = dataCollectionBranchId.trim()
    if (!selectedBranchId) {
      toast.warning('Hiányzó iroda', 'Adjon meg branch UUID-t a branch szinkronhoz')
      return
    }
    try {
      setBranchSyncActionLoading(kind)
      setBranchSyncError(null)
      const requestConfig = { validateStatus: () => true }
      const response =
        kind === 'rates'
          ? await api.post<BranchSyncLog>(`/sync/rates/${selectedBranchId}`, null, requestConfig)
          : kind === 'transactions'
            ? await api.post<BranchSyncLog>(
                `/sync/transactions/${selectedBranchId}`,
                null,
                requestConfig,
              )
            : kind === 'inventory'
              ? await api.post<BranchSyncLog>(
                  `/sync/inventory/${selectedBranchId}`,
                  null,
                  requestConfig,
                )
              : await api.post<BranchSyncLog>(`/sync/full/${selectedBranchId}`, null, requestConfig)
      if (response.status >= 400 && response.status !== 503)
        throw new Error(`HTTP ${response.status}`)
      const label = response.data?.status || kind
      toast.success('Branch szinkron lefutott', label)
      await loadBranchSyncDetails()
    } catch (err) {
      const msg = getErrorMessage(err)
      setBranchSyncError(msg)
      toast.error('Branch szinkron hiba', msg)
    } finally {
      setBranchSyncActionLoading(null)
    }
  }

  const toggleEntity = (entity: string) => {
    setSelectedEntities((prev) =>
      prev.includes(entity) ? prev.filter((e) => e !== entity) : [...prev, entity],
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <RefreshCw />
          {t('sync.szinkronizacio')}
        </h1>
        <div className="flex items-center gap-2">
          <span className={`badge ${status.isOnline ? 'badge-green' : 'badge-red'}`}>
            {status.isOnline ? (
              <>
                <Server size={10} className="inline" /> {t('common.online')}
              </>
            ) : (
              <>
                <XCircle size={10} className="inline" /> {t('foertektar.offline')}
              </>
            )}
          </span>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Status cards */}
      <div className="grid grid-cols-3 gap-3">
        <div className="form-panel text-center">
          <Upload size={20} className="mx-auto text-blue-500 mb-1" />
          <div className="text-lg font-bold">{status.pendingUpload}</div>
          <div className="text-sm text-gray-500">{t('sync.feltoltendo')}</div>
        </div>
        <div className="form-panel text-center">
          <Download size={20} className="mx-auto text-green-500 mb-1" />
          <div className="text-lg font-bold">{status.pendingDownload}</div>
          <div className="text-sm text-gray-500">{t('sync.letoltendo')}</div>
        </div>
        <div className="form-panel text-center">
          <Clock size={20} className="mx-auto text-gray-500 mb-1" />
          <div className="text-sm font-medium">
            {status.lastSync ? new Date(status.lastSync).toLocaleString('hu-HU') : 'Nincs adat'}
          </div>
          <div className="text-sm text-gray-500">{t('sync.utolsoSzinkron')}</div>
        </div>
      </div>

      {/* Sync controls */}
      <div className="form-panel space-y-3">
        <h2 className="font-semibold">{t('sync.szinkronizalas')}</h2>

        <div>
          <label className="form-label">{t('sync.entitasokKivalasztasa')}</label>
          <div className="flex flex-wrap gap-2">
            {ENTITY_TYPES.map((et) => (
              <label
                key={et.value}
                className={`px-3 py-1 rounded-full text-sm cursor-pointer border ${selectedEntities.includes(et.value) ? 'bg-blue-100 border-blue-400 text-blue-700' : 'bg-gray-50 border-gray-200 text-gray-500'}`}
              >
                <input
                  type="checkbox"
                  className="hidden"
                  checked={selectedEntities.includes(et.value)}
                  onChange={() => toggleEntity(et.value)}
                />
                {et.label}
              </label>
            ))}
          </div>
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => void handleSync('FULL')}
            disabled={syncing || !status.isOnline}
            className="form-button-primary"
          >
            <RefreshCw size={16} className={syncing ? 'animate-spin' : ''} />{' '}
            {syncing ? 'Szinkronizálás...' : 'Teljes szinkron'}
          </button>
          <button
            onClick={() => void handleSync('UPLOAD')}
            disabled={syncing || !status.isOnline}
            className="form-button"
          >
            <Upload size={16} />
            {t('sync.csakFeltoltes')}
          </button>
          <button
            onClick={() => void handleSync('DOWNLOAD')}
            disabled={syncing || !status.isOnline}
            className="form-button"
          >
            <Download size={16} />
            {t('sync.csakLetoltes')}
          </button>
        </div>

        <div className="flex items-center gap-2">
          <label className="flex items-center gap-1 text-sm">
            <input
              type="checkbox"
              checked={autoSyncEnabled}
              onChange={(e) => setAutoSyncEnabled(e.target.checked)}
            />
            {t('sync.automatikusSzinkron5Percenkent')}
          </label>
        </div>
      </div>

      {isAdmin && (
        <div className="form-panel space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="font-semibold flex items-center gap-2">
              <Database size={16} />
              {i18n.t('literals.kozponti-adatgyujtes')}
            </h2>
            <button
              type="button"
              onClick={() => void loadDataCollectionStatus()}
              className="form-button text-xs"
              disabled={dataCollecting}
            >
              {i18n.t('literals.statusz-frissitese')}
            </button>
          </div>
          {dataCollectionError && (
            <div className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
              {dataCollectionError}
            </div>
          )}
          <div className="flex flex-wrap items-end gap-2">
            <label className="block min-w-[260px] flex-1">
              <span className="form-label">{i18n.t('literals.branch-uuid')}</span>
              <input
                className="form-input"
                value={dataCollectionBranchId}
                onChange={(event) => setDataCollectionBranchId(event.target.value)}
                placeholder="Iroda UUID"
                data-testid="sync-branch-id"
              />
            </label>
            <button
              type="button"
              onClick={() => void loadBranchSyncDetails()}
              disabled={branchSyncLoading || !dataCollectionBranchId.trim()}
              className="form-button"
            >
              {i18n.t('literals.sync-statusz')}
            </button>
            <button
              type="button"
              onClick={() => void handleCollectBranch()}
              disabled={dataCollecting}
              className="form-button"
            >
              {i18n.t('literals.iroda-gyujtese')}
            </button>
            <button
              type="button"
              onClick={() => void handleCollectAll()}
              disabled={dataCollecting}
              className="form-button-primary"
            >
              {i18n.t('literals.osszes-iroda-gyujtese')}
            </button>
            <button
              type="button"
              onClick={() => void handleRetryFailed()}
              disabled={dataCollecting}
              className="form-button"
            >
              {i18n.t('literals.sikertelenek-ujra')}
            </button>
          </div>
          <div className="rounded border border-blue-100 bg-blue-50 p-3">
            <h3 className="mb-2 text-sm font-semibold text-blue-950">
              {i18n.t('literals.ftp-szinkron-muveletek')}
            </h3>
            <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
              <button
                type="button"
                onClick={() => void runFtpSync('rates')}
                disabled={ftpActionLoading !== null || !dataCollectionBranchId.trim()}
                className="form-button justify-center text-xs"
                data-testid="ftp-sync-rates"
              >
                {i18n.t('literals.arfolyam-fajl')}
              </button>
              <button
                type="button"
                onClick={() => void runFtpSync('daily-report')}
                disabled={ftpActionLoading !== null || !dataCollectionBranchId.trim()}
                className="form-button justify-center text-xs"
                data-testid="ftp-sync-daily-report"
              >
                {i18n.t('literals.napi-jelentes')}
              </button>
              <button
                type="button"
                onClick={() => void runFtpSync('transactions')}
                disabled={ftpActionLoading !== null || !dataCollectionBranchId.trim()}
                className="form-button justify-center text-xs"
                data-testid="ftp-sync-transactions"
              >
                {i18n.t('literals.tranzakcio-batch')}
              </button>
            </div>
          </div>
          <div
            className="rounded border border-gray-200 bg-gray-50 p-3"
            data-testid="branch-sync-panel"
          >
            <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
              <h3 className="text-sm font-semibold">
                {i18n.t('literals.branch-szinkron-allapot')}
              </h3>
              {branchSyncLoading && (
                <span className="text-xs text-gray-500">{i18n.t('literals.betoltes')}</span>
              )}
            </div>
            {branchSyncError && (
              <div className="mb-2 rounded border border-amber-200 bg-amber-50 px-2 py-1 text-sm text-amber-800">
                {branchSyncError}
              </div>
            )}
            {branchSyncStatus ? (
              <div className="grid grid-cols-1 gap-2 text-sm sm:grid-cols-3">
                <div className="rounded bg-white px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">
                    {i18n.t('literals.statusz')}
                  </div>
                  <div className="font-semibold">{branchSyncStatus.status ?? '-'}</div>
                </div>
                <div className="rounded bg-white px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">
                    {i18n.t('literals.utolso-sikeres-sync')}
                  </div>
                  <div>
                    {formatSyncDate(
                      branchSyncStatus.lastSuccessfulSyncAt ?? branchSyncStatus.lastSyncAt,
                    )}
                  </div>
                </div>
                <div className="rounded bg-white px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">
                    {i18n.t('literals.fuggo-rekord')}
                  </div>
                  <div className="font-mono">
                    {branchSyncStatus.pendingCount ??
                      (branchSyncStatus.pendingUpload ?? 0) +
                        (branchSyncStatus.pendingDownload ?? 0)}
                  </div>
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-500">
                {i18n.t('literals.nincs-branch-szinkron-statusz-betoltve')}
              </p>
            )}
            <div className="mt-3 space-y-2">
              {branchSyncHistory.length === 0 ? (
                <p className="text-sm text-gray-500">{i18n.t('literals.nincs-sync-tortenet')}</p>
              ) : (
                branchSyncHistory.map((row, index) => (
                  <div
                    key={row.id ?? `${row.startedAt}-${index}`}
                    className="rounded bg-white px-2 py-1 text-sm"
                    data-testid="branch-sync-history-row"
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <span className="font-semibold">
                        {row.syncType ?? row.direction ?? 'SYNC'}
                      </span>
                      <span
                        className={`badge ${row.status === 'COMPLETED' ? 'badge-green' : row.status === 'FAILED' ? 'badge-red' : 'badge-blue'}`}
                      >
                        {row.status ?? '-'}
                      </span>
                    </div>
                    <div className="text-xs text-gray-500">
                      {formatSyncDate(row.startedAt)}
                      {i18n.t('literals.lit-9')}
                      {row.recordsSynced ?? 0}
                      {i18n.t('literals.rekord')}
                    </div>
                    {row.errorMessage && (
                      <div className="text-xs text-red-700">{row.errorMessage}</div>
                    )}
                  </div>
                ))
              )}
            </div>
            <div className="mt-3 border-t border-gray-200 pt-3" data-testid="branch-sync-actions">
              <h4 className="mb-2 text-sm font-semibold">
                {i18n.t('literals.branch-sync-muveletek')}
              </h4>
              <div className="grid grid-cols-1 gap-2 sm:grid-cols-4">
                <button
                  type="button"
                  onClick={() => void runBranchSync('rates')}
                  disabled={branchSyncActionLoading !== null || !dataCollectionBranchId.trim()}
                  className="form-button justify-center text-xs"
                  data-testid="branch-sync-rates"
                >
                  {i18n.t('literals.arfolyamok')}
                </button>
                <button
                  type="button"
                  onClick={() => void runBranchSync('transactions')}
                  disabled={branchSyncActionLoading !== null || !dataCollectionBranchId.trim()}
                  className="form-button justify-center text-xs"
                  data-testid="branch-sync-transactions"
                >
                  {i18n.t('literals.tranzakciok')}
                </button>
                <button
                  type="button"
                  onClick={() => void runBranchSync('inventory')}
                  disabled={branchSyncActionLoading !== null || !dataCollectionBranchId.trim()}
                  className="form-button justify-center text-xs"
                  data-testid="branch-sync-inventory"
                >
                  {i18n.t('literals.keszlet')}
                </button>
                <button
                  type="button"
                  onClick={() => void runBranchSync('full')}
                  disabled={branchSyncActionLoading !== null || !dataCollectionBranchId.trim()}
                  className="form-button-primary justify-center text-xs"
                  data-testid="branch-sync-full"
                >
                  {i18n.t('literals.teljes')}
                </button>
              </div>
            </div>
            <div className="mt-3 border-t border-gray-200 pt-3" data-testid="ftp-sync-history">
              <h4 className="mb-2 text-sm font-semibold">
                {i18n.t('literals.ftp-szinkron-tortenet')}
              </h4>
              {ftpSyncHistory.length === 0 ? (
                <p className="text-sm text-gray-500">
                  {i18n.t('literals.nincs-ftp-sync-tortenet')}
                </p>
              ) : (
                ftpSyncHistory.map((row, index) => (
                  <div
                    key={row.id ?? `${row.fileName}-${index}`}
                    className="rounded bg-white px-2 py-1 text-sm"
                    data-testid="ftp-sync-history-row"
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <span className="font-semibold">{row.direction ?? 'FTP'}</span>
                      <span
                        className={`badge ${row.status === 'COMPLETED' || row.status === 'SUCCESS' ? 'badge-green' : row.status === 'FAILED' ? 'badge-red' : 'badge-blue'}`}
                      >
                        {row.status ?? '-'}
                      </span>
                    </div>
                    <div className="break-words text-xs text-gray-500">
                      {row.fileName ?? '-'}
                      {i18n.t('literals.lit-9')}
                      {formatSyncDate(row.startedAt)}
                      {i18n.t('literals.lit-29')} {formatBytes(row.fileSizeBytes)}
                    </div>
                    {row.errorMessage && (
                      <div className="text-xs text-red-700">{row.errorMessage}</div>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>
          <div className="overflow-x-auto rounded border border-gray-200">
            <table className="data-grid w-full min-w-[760px] text-sm">
              <thead>
                <tr>
                  <th>{i18n.t('literals.iroda')}</th>
                  <th>{i18n.t('literals.datum-2')}</th>
                  <th>{i18n.t('literals.statusz')}</th>
                  <th>{i18n.t('literals.tipus')}</th>
                  <th className="text-right">{i18n.t('literals.tranzakcio')}</th>
                  <th>{i18n.t('literals.hiba-3')}</th>
                </tr>
              </thead>
              <tbody>
                {dataCollectionRows.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-3 text-center text-gray-500">
                      {i18n.t('literals.nincs-adatgyujtesi-statusz')}
                    </td>
                  </tr>
                ) : (
                  dataCollectionRows.map((row, index) => (
                    <tr key={row.id ?? `${row.branchId}-${row.collectionDate}-${index}`}>
                      <td className="font-mono text-xs">{row.branchId ?? '-'}</td>
                      <td>{row.collectionDate ?? '-'}</td>
                      <td>
                        <span
                          className={`badge ${row.status === 'COMPLETED' ? 'badge-green' : row.status === 'FAILED' ? 'badge-red' : 'badge-blue'}`}
                        >
                          {row.status}
                        </span>
                      </td>
                      <td>{row.collectionType ?? '-'}</td>
                      <td className="text-right">{row.transactionCount ?? 0}</td>
                      <td className="max-w-[220px] truncate" title={row.errorMessage ?? ''}>
                        {row.errorMessage ?? '-'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}

function extractPagedContent<T>(data: { content?: T[] } | T[] | null | undefined): T[] {
  if (Array.isArray(data)) return data
  if (Array.isArray(data?.content)) return data.content
  return []
}

function formatSyncDate(value?: string | null): string {
  if (!value) return '-'
  return new Date(value).toLocaleString('hu-HU')
}

function formatBytes(value?: number): string {
  if (typeof value !== 'number' || !Number.isFinite(value)) return '-'
  if (value < 1024) return `${value} B`
  return `${(value / 1024).toFixed(1)} KB`
}
