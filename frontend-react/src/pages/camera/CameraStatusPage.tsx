import { useState, useEffect } from 'react'
import { HardDrive, RefreshCw, Trash2, Camera } from 'lucide-react'

interface StorageStats {
  totalUsageBytes: number
  availableSpaceBytes: number
  totalRecordings: number
}

interface CameraStatus {
  cameraId: string
  cameraName?: string
  recording: boolean
  connected: boolean
}

export default function CameraStatusPage() {
  const [stats, setStats] = useState<StorageStats | null>(null)
  const [cameras, setCameras] = useState<CameraStatus[]>([])
  const [pendingUploads, setPendingUploads] = useState(0)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchAll()
  }, [])

  const fetchAll = async () => {
    setLoading(true)
    try {
      const [statsRes, cameraRes, uploadRes] = await Promise.all([
        fetch('/api/v1/camera/admin/storage-stats'),
        fetch('/api/v1/camera/status'),
        fetch('/api/v1/camera/admin/upload-status'),
      ])
      if (statsRes.ok) setStats(await statsRes.json())
      if (cameraRes.ok) setCameras(await cameraRes.json())
      if (uploadRes.ok) {
        const data = await uploadRes.json()
        setPendingUploads(data.pendingUploads)
      }
    } catch (err) {
      console.error('Statusz lekeres sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const triggerCleanup = async () => {
    if (!confirm('Biztosan torli a lejart felvételeket?')) return
    try {
      const res = await fetch('/api/v1/camera/admin/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      })
      if (res.ok) {
        const data = await res.json()
        alert(`${data.deletedCount} felvetel torolve`)
        fetchAll()
      }
    } catch (err) {
      console.error('Takaritas sikertelen:', err)
    }
  }

  const formatSize = (bytes: number) => {
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`
  }

  const usagePercent = stats
    ? ((stats.totalUsageBytes / (stats.totalUsageBytes + stats.availableSpaceBytes)) * 100)
    : 0

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <HardDrive className="h-6 w-6" />
          Kamera rendszer allapot
        </h1>
        <div className="flex gap-2">
          <button
            className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
            onClick={fetchAll}
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Frissites
          </button>
          <button
            className="inline-flex items-center justify-center rounded-md bg-destructive px-4 py-2 text-sm font-medium text-destructive-foreground hover:bg-destructive/90"
            onClick={triggerCleanup}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Lejart felvetelek torlese
          </button>
        </div>
      </div>

      {loading ? (
        <p>Betoltes...</p>
      ) : (
        <>
          {/* Stats cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4">
                <p className="text-sm text-muted-foreground">Aktiv kamerak</p>
                <p className="text-3xl font-bold">{cameras.filter(c => c.connected).length}</p>
                <p className="text-xs text-muted-foreground">{cameras.length} konfigurqlva</p>
              </div>
            </div>
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4">
                <p className="text-sm text-muted-foreground">Felvetelek</p>
                <p className="text-3xl font-bold">{stats?.totalRecordings ?? 0}</p>
              </div>
            </div>
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4">
                <p className="text-sm text-muted-foreground">Tarhelyhasznalat</p>
                <p className="text-3xl font-bold">{stats ? formatSize(stats.totalUsageBytes) : '-'}</p>
                <p className="text-xs text-muted-foreground">
                  {stats ? formatSize(stats.availableSpaceBytes) : '-'} szabad
                </p>
              </div>
            </div>
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4">
                <p className="text-sm text-muted-foreground">Feltoltesre var</p>
                <p className="text-3xl font-bold">{pendingUploads}</p>
                <p className="text-xs text-muted-foreground">szegmens</p>
              </div>
            </div>
          </div>

          {/* Usage bar */}
          {stats && (
            <div className="rounded-lg border bg-card shadow-sm">
              <div className="p-4 pb-2">
                <h3 className="text-lg font-semibold">Tarhelyhasznalat</h3>
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
                <p className="text-sm text-muted-foreground mt-2">{usagePercent.toFixed(1)}% hasznalat</p>
              </div>
            </div>
          )}

          {/* Camera list */}
          <div className="rounded-lg border bg-card shadow-sm">
            <div className="p-4 pb-2">
              <h3 className="text-lg font-semibold flex items-center gap-2">
                <Camera className="h-5 w-5" />
                Kamerak allapota
              </h3>
            </div>
            <div className="p-4">
              {cameras.length === 0 ? (
                <p className="text-muted-foreground">Nincs csatlakoztatott kamera</p>
              ) : (
                <div className="space-y-2">
                  {cameras.map((cam) => (
                    <div key={cam.cameraId} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                      <div>
                        <p className="font-medium">{cam.cameraName || cam.cameraId}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          cam.connected ? 'bg-primary text-primary-foreground' : 'bg-destructive text-destructive-foreground'
                        }`}>
                          {cam.connected ? 'Csatlakozva' : 'Nincs kapcsolat'}
                        </span>
                        {cam.recording && (
                          <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-destructive text-destructive-foreground">Rogzit</span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  )
}
