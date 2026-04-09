import { useState, useEffect } from 'react'
import { HardDrive, RefreshCw, Trash2 } from 'lucide-react'
import { api } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger';

const isElectron = () => !!window.electronAPI

interface StorageStats {
  totalUsageBytes: number
  availableSpaceBytes: number
  totalRecordings: number
  oldestDate?: string | null
  newestDate?: string | null
}

export default function CameraStatusPage() {
  const [stats, setStats] = useState<StorageStats | null>(null)
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
      } else {
        // Böngésző: szerver API
        const res = await api.get('/camera/admin/storage-stats')
        setStats(res.data)
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

  const usagePercent = stats && (stats.totalUsageBytes + stats.availableSpaceBytes) > 0
    ? ((stats.totalUsageBytes / (stats.totalUsageBytes + stats.availableSpaceBytes)) * 100)
    : 0

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold flex items-center gap-2">
          <HardDrive className="h-6 w-6" />
          Kamera rendszer állapot
          {isElectron() && <span className="text-sm font-normal text-muted-foreground">(lokális)</span>}
        </h1>
        <div className="flex gap-2">
          <button
            className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
            onClick={fetchStats}
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Frissítés
          </button>
          <button
            className="inline-flex items-center justify-center rounded-md bg-destructive px-4 py-2 text-sm font-medium text-destructive-foreground hover:bg-destructive/90"
            onClick={triggerCleanup}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Lejárt felvételek törlése
          </button>
        </div>
      </div>

      {loading ? (
        <p>Betöltés...</p>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4">
                <p className="text-sm text-muted-foreground">Felvételek</p>
                <p className="text-3xl font-bold">{stats?.totalRecordings ?? 0}</p>
              </div>
            </div>
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4">
                <p className="text-sm text-muted-foreground">Tárhelyhasználat</p>
                <p className="text-3xl font-bold">{stats ? formatSize(stats.totalUsageBytes) : '-'}</p>
                <p className="text-xs text-muted-foreground">
                  {stats ? formatSize(stats.availableSpaceBytes) : '-'} szabad
                </p>
              </div>
            </div>
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4">
                <p className="text-sm text-muted-foreground">Időszak</p>
                <p className="text-lg font-bold">
                  {stats?.oldestDate ?? '-'} -- {stats?.newestDate ?? '-'}
                </p>
              </div>
            </div>
          </div>

          {stats && (
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4 pb-2">
                <h3 className="text-lg font-semibold">Tárhelyhasználat</h3>
              </div>
              <div className="p-4">
                <div className="w-full bg-muted rounded-full h-4 overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${
                      usagePercent > 90 ? 'bg-red-500' : usagePercent > 70 ? 'bg-yellow-500' : 'bg-green-500'
                    }`}
                    style={{ width: `${Math.min(usagePercent, 100)}%` }}
                  />
                </div>
                <p className="text-sm text-muted-foreground mt-2">{usagePercent.toFixed(1)}% használat</p>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}
