import { useState, useEffect } from 'react'
import { HardDrive, RefreshCw, Trash2 } from 'lucide-react'
import { api } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

const isElectron = () => !!window.electronAPI

interface StorageStats {
  totalUsageBytes: number
  availableSpaceBytes: number
  totalRecordings: number
  oldestDate?: string | null
  newestDate?: string | null
}

interface UploadStatus {
  pendingUploads: number
}

interface CameraStatusItem {
  cameraId: string
  cameraName?: string
  recording: boolean
  connected: boolean
  frozen?: boolean
  lastFreshFrameAt?: string | null
}

export default function CameraStatusPage() {
  const { t } = useTranslation()
  const [stats, setStats] = useState<StorageStats | null>(null)
  const [uploadStatus, setUploadStatus] = useState<UploadStatus | null>(null)
  const [cameras, setCameras] = useState<CameraStatusItem[]>([])
  const [cameraSubsystemDisabled, setCameraSubsystemDisabled] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    setLoading(true)
    try {
      if (isElectron() && window.electronAPI?.cameraLocalStorageStats) {
        // Electron: lokális fájlrendszer statisztika
        const localStats = await window.electronAPI.cameraLocalStorageStats()
        setStats(localStats)
        setUploadStatus(null)
        setCameras([])
        setCameraSubsystemDisabled(false)
      } else {
        // Böngésző: szerver API
        try {
          const [statsResult, uploadResult] = await Promise.all([
            api.get('/camera/admin/storage-stats'),
            api.get<UploadStatus>('/camera/admin/upload-status'),
          ])
          setStats(statsResult.data)
          setUploadStatus(uploadResult.data)
          setCameraSubsystemDisabled(false)
        } catch (err) {
          logger.warn('CameraStatusPage', 'Kamera admin státusz nem elérhető:', err)
          setStats(null)
          setUploadStatus(null)
          setCameras([])
          setCameraSubsystemDisabled(true)
          return
        }
        try {
          const cameraResult = await api.get<CameraStatusItem[]>('/camera/status')
          setCameras(Array.isArray(cameraResult.data) ? cameraResult.data : [])
        } catch {
          setCameras([])
        }
      }
    } catch (err) {
      logger.error('CameraStatusPage', 'Státusz lekérés sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const triggerCleanup = async () => {
    const retentionDays = 50
    if (!confirm(`Biztosan törli az ${retentionDays} napnál régebbi felvételeket?`)) return
    try {
      if (isElectron() && window.electronAPI?.cameraLocalCleanup) {
        const result = await window.electronAPI.cameraLocalCleanup(retentionDays)
        toast.success(`${result.deletedCount} felvétel törölve`)
      } else {
        const res = await api.post('/camera/admin/cleanup', {})
        if (res.data) {
          toast.success(`${res.data.deletedCount} felvétel törölve`)
        }
      }
      fetchStats()
    } catch (err) {
      logger.error('CameraStatusPage', 'Takarítás sikertelen:', err)
    }
  }

  const formatSize = (bytes: number) => {
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`
  }

  const usagePercent =
    stats && stats.totalUsageBytes + stats.availableSpaceBytes > 0
      ? (stats.totalUsageBytes / (stats.totalUsageBytes + stats.availableSpaceBytes)) * 100
      : 0

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold flex items-center gap-2">
          <HardDrive className="h-6 w-6" />
          {t('camera.kameraRendszerAllapot')}
          {isElectron() && (
            <span className="text-sm font-normal text-muted-foreground">{t('camera.lokalis')}</span>
          )}
        </h1>
        <div className="flex gap-2">
          <button
            className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
            onClick={fetchStats}
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            {t('common.refresh')}
          </button>
          <button
            className="inline-flex items-center justify-center rounded-md bg-destructive px-4 py-2 text-sm font-medium text-destructive-foreground hover:bg-destructive/90"
            onClick={triggerCleanup}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            {t('camera.lejartFelvetelekTorlese')}
          </button>
        </div>
      </div>

      {loading ? (
        <p>{i18n.t('literals.betoltes')}</p>
      ) : (
        <>
          {cameras.length > 0 && (
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4 pb-2">
                <h3 className="text-lg font-semibold">{t('camera.kamerak')}</h3>
              </div>
              <div className="p-4 grid grid-cols-1 md:grid-cols-4 gap-4">
                {cameras.map((cam) => (
                  <div key={cam.cameraId} className="rounded-lg border p-3">
                    <div className="flex items-center justify-between">
                      <p className="font-medium">{cam.cameraName || cam.cameraId}</p>
                      {cam.frozen ? (
                        <span
                          data-testid={`camera-frozen-badge-${cam.cameraId}`}
                          className="rounded-full bg-red-500 px-2 py-0.5 text-xs font-bold text-white"
                        >
                          {t('camera.befagyott')}
                        </span>
                      ) : (
                        <span className="h-2 w-2 rounded-full bg-green-500" />
                      )}
                    </div>
                    {cam.frozen && cam.lastFreshFrameAt && (
                      <p className="text-xs text-muted-foreground mt-1">
                        {t('camera.utolsoFrissKep')}
                        {i18n.t('literals.lit-22')}
                        {cam.lastFreshFrameAt.replace('T', ' ')}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {cameraSubsystemDisabled ? (
            <div className="rounded-lg border border-blue-200 bg-blue-50 p-4 text-sm text-blue-800">
              {i18n.t('literals.a-kamera-alrendszer-nincs-engedelyezve-e')}
            </div>
          ) : (
            <>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="rounded-lg border bg-card shadow-sm">
                  <div className="p-4">
                    <p className="text-sm text-muted-foreground">{t('camera.felvetelek')}</p>
                    <p className="text-3xl font-bold">{stats?.totalRecordings ?? 0}</p>
                  </div>
                </div>
                <div className="rounded-lg border bg-card shadow-sm">
                  <div className="p-4">
                    <p className="text-sm text-muted-foreground">{t('camera.tarhelyhasznalat')}</p>
                    <p className="text-3xl font-bold">
                      {stats ? formatSize(stats.totalUsageBytes) : '-'}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {stats ? formatSize(stats.availableSpaceBytes) : '-'} {t('common.szabad')}
                    </p>
                  </div>
                </div>
                <div className="rounded-lg border bg-card shadow-sm">
                  <div className="p-4">
                    <p className="text-sm text-muted-foreground">{t('common.period')}</p>
                    <p className="text-lg font-bold">
                      {stats?.oldestDate ?? '-'}
                      {i18n.t('literals.lit-23')}
                      {stats?.newestDate ?? '-'}
                    </p>
                  </div>
                </div>
                <div className="rounded-lg border bg-card shadow-sm">
                  <div className="p-4">
                    <p className="text-sm text-muted-foreground">{t('camera.feltoltesreVar')}</p>
                    <p className="text-3xl font-bold" data-testid="camera-pending-uploads">
                      {uploadStatus?.pendingUploads ?? 0}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {t('camera.szerverOldaliUploadSor')}
                    </p>
                  </div>
                </div>
              </div>

              {stats && (
                <div className="rounded-lg border bg-card shadow-sm">
                  <div className="p-4 pb-2">
                    <h3 className="text-lg font-semibold">{t('camera.tarhelyhasznalat')}</h3>
                  </div>
                  <div className="p-4">
                    <div className="w-full bg-muted rounded-full h-4 overflow-hidden">
                      <div
                        className={`h-full rounded-full transition-all ${
                          usagePercent > 90
                            ? 'bg-red-500'
                            : usagePercent > 70
                              ? 'bg-yellow-500'
                              : 'bg-green-500'
                        }`}
                        style={{ width: `${Math.min(usagePercent, 100)}%` }}
                      />
                    </div>
                    <p className="text-sm text-muted-foreground mt-2">
                      {usagePercent.toFixed(1)}
                      {t('camera.hasznalat')}
                    </p>
                  </div>
                </div>
              )}
            </>
          )}
        </>
      )}
    </div>
  )
}
