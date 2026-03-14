import { useState, useEffect } from 'react'
import { Settings, Plus, Trash2, Save } from 'lucide-react'
import { api } from '../../services/api'

interface CameraConfigItem {
  id?: string
  branchId: string
  cameraId: string
  cameraName: string
  deviceIndex: number
  resolutionWidth: number
  resolutionHeight: number
  fps: number
  jpegQuality: number
  localStoragePath: string
  enabled: boolean
}

export default function CameraConfigPage() {
  const [configs, setConfigs] = useState<CameraConfigItem[]>([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<CameraConfigItem | null>(null)

  useEffect(() => {
    fetchConfigs()
  }, [])

  const fetchConfigs = async () => {
    try {
      const res = await api.get('/camera/admin/configs')
      setConfigs(res.data)
    } catch (err) {
      console.error('Config lekeres sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const saveConfig = async (config: CameraConfigItem) => {
    try {
      const res = await api.post('/camera/admin/configs', config)
      if (res.data) {
        setEditing(null)
        fetchConfigs()
      }
    } catch (err) {
      console.error('Mentes sikertelen:', err)
    }
  }

  const deleteConfig = async (id: string) => {
    if (!confirm('Biztosan torli a kamera konfiguraciot?')) return
    try {
      await api.delete(`/camera/admin/configs/${id}`)
      fetchConfigs()
    } catch (err) {
      console.error('Torles sikertelen:', err)
    }
  }

  const newConfig = (): CameraConfigItem => ({
    branchId: '',
    cameraId: '',
    cameraName: '',
    deviceIndex: 0,
    resolutionWidth: 640,
    resolutionHeight: 480,
    fps: 5,
    jpegQuality: 70,
    localStoragePath: 'C:/valuta/camera',
    enabled: true,
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <Settings className="h-6 w-6" />
          Kamera konfiguracio
        </h1>
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={() => setEditing(newConfig())}
        >
          <Plus className="h-4 w-4 mr-2" />
          Uj kamera
        </button>
      </div>

      {/* Edit form */}
      {editing && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">{editing.id ? 'Szerkesztes' : 'Uj kamera'}</h3>
          </div>
          <div className="p-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Iroda ID (Branch UUID)</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.branchId}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, branchId: e.target.value })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Kamera ID</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.cameraId}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, cameraId: e.target.value })}
                  placeholder="pl. cam1"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Kamera neve</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.cameraName}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, cameraName: e.target.value })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Eszkoz index</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.deviceIndex}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, deviceIndex: parseInt(e.target.value, 10) || 0 })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Szelesseg</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.resolutionWidth}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, resolutionWidth: parseInt(e.target.value, 10) || 640 })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Magassag</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.resolutionHeight}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, resolutionHeight: parseInt(e.target.value, 10) || 480 })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">FPS</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.fps}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, fps: parseInt(e.target.value, 10) || 5 })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">JPEG minoseg (%)</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.jpegQuality}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, jpegQuality: parseInt(e.target.value, 10) || 70 })}
                />
              </div>
              <div className="col-span-2">
                <label className="text-sm font-medium">Tarolasi utvonal</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.localStoragePath}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, localStoragePath: e.target.value })}
                />
              </div>
            </div>
            <div className="flex gap-2 mt-4">
              <button
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={() => saveConfig(editing)}
              >
                <Save className="h-4 w-4 mr-2" />
                Mentes
              </button>
              <button
                className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                onClick={() => setEditing(null)}
              >
                Megse
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Config list */}
      {loading ? (
        <p>Betoltes...</p>
      ) : configs.length === 0 ? (
        <div className="text-center py-12 text-muted-foreground">Nincs konfiguralt kamera</div>
      ) : (
        <div className="space-y-3">
          {configs.map((config) => (
            <div key={config.id} className="rounded-lg border bg-card shadow-sm">
              <div className="p-4 flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{config.cameraName || config.cameraId}</span>
                    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                      config.enabled ? 'bg-primary text-primary-foreground' : 'bg-secondary text-secondary-foreground'
                    }`}>
                      {config.enabled ? 'Aktiv' : 'Inaktiv'}
                    </span>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    {config.resolutionWidth}x{config.resolutionHeight} @ {config.fps} FPS | JPEG: {config.jpegQuality}%
                  </p>
                  <p className="text-xs text-muted-foreground">Utvonal: {config.localStoragePath}</p>
                </div>
                <div className="flex gap-2">
                  <button
                    className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                    onClick={() => setEditing(config)}
                  >
                    Szerkesztes
                  </button>
                  <button
                    className="inline-flex items-center justify-center rounded-md bg-destructive px-3 py-1.5 text-xs font-medium text-destructive-foreground hover:bg-destructive/90"
                    onClick={() => config.id && deleteConfig(config.id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
