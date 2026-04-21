import { useState, useEffect } from 'react'
import { Settings, Plus, Trash2, Save } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger';

const isElectron = () => !!window.electronAPI

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
  const [localDevices, setLocalDevices] = useState<MediaDeviceInfo[]>([])

  useEffect(() => {
    fetchConfigs()
    if (isElectron()) {
      // Lokális kamerák detektálása
      navigator.mediaDevices.enumerateDevices().then(devices => {
        setLocalDevices(devices.filter(d => d.kind === 'videoinput'))
      })
    }
  }, [])

  const fetchConfigs = async () => {
    try {
      if (isElectron()) {
        // Electron: lokális konfiguráció a config store-ból
        const configJson = await window.electronAPI!.getConfig('camera_configs')
        if (configJson) {
          try {
            setConfigs(JSON.parse(configJson))
          } catch {
            console.error('Hibás kamera konfigurációs JSON, alapértelmezett használata')
            setConfigs([])
          }
        } else {
          setConfigs([])
        }
      } else {
        const res = await api.get('/camera/admin/configs')
        setConfigs(res.data)
      }
    } catch (err) {
      logger.error('CameraConfigPage', 'Config lekérés sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const saveConfig = async (config: CameraConfigItem) => {
    try {
      if (isElectron()) {
        // Electron: lokális mentés
        const existing = [...configs]
        if (config.id) {
          const idx = existing.findIndex(c => c.id === config.id)
          if (idx >= 0) existing[idx] = config
        } else {
          config.id = crypto.randomUUID()
          existing.push(config)
        }
        await window.electronAPI!.setConfig('camera_configs', JSON.stringify(existing))
        setConfigs(existing)
      } else {
        await api.post('/camera/admin/configs', config)
        fetchConfigs()
      }
      setEditing(null)
    } catch (err) {
      logger.error('CameraConfigPage', 'Mentés sikertelen:', err)
    }
  }

  const deleteConfig = async (id: string) => {
    if (!confirm('Biztosan törli a kamera konfigurációt?')) return
    try {
      if (isElectron()) {
        const updated = configs.filter(c => c.id !== id)
        await window.electronAPI!.setConfig('camera_configs', JSON.stringify(updated))
        setConfigs(updated)
      } else {
        await api.delete(`/camera/admin/configs/${id}`)
        fetchConfigs()
      }
    } catch (err) {
      logger.error('CameraConfigPage', 'Törlés sikertelen:', err)
    }
  }

  const newConfig = (): CameraConfigItem => ({
    branchId: '',
    cameraId: localDevices[0]?.deviceId || '',
    cameraName: localDevices[0]?.label || 'Kamera 1',
    deviceIndex: 0,
    resolutionWidth: 640,
    resolutionHeight: 480,
    fps: 5,
    jpegQuality: 70,
    localStoragePath: 'C:/valuta/camera',
    enabled: true,
  })

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold flex items-center gap-2">
          <Settings className="h-6 w-6" />
          Kamera konfiguráció
          {isElectron() && <span className="text-sm font-normal text-muted-foreground">(lokális)</span>}
        </h1>
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={() => setEditing(newConfig())}
        >
          <Plus className="h-4 w-4 mr-2" />
          Új kamera
        </button>
      </div>

      {/* Electron: lokális kamerák listája */}
      {isElectron() && localDevices.length > 0 && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">Észlelt lokális kamerák</h3>
          </div>
          <div className="p-4">
            <div className="space-y-1">
              {localDevices.map((d, i) => (
                <p key={d.deviceId || i} className="text-sm text-muted-foreground">
                  {d.label || `Kamera ${i + 1}`} <span className="text-xs">({d.deviceId?.slice(0, 12)}...)</span>
                </p>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Edit form */}
      {editing && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">{editing.id ? 'Szerkesztés' : 'Új kamera'}</h3>
          </div>
          <div className="p-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Kamera neve</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.cameraName}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, cameraName: e.target.value })}
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
                <label className="text-sm font-medium">Szélesség</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.resolutionWidth}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, resolutionWidth: parseInt(e.target.value, 10) || 640 })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Magasság</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.resolutionHeight}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, resolutionHeight: parseInt(e.target.value, 10) || 480 })}
                />
              </div>
              <div className="col-span-2">
                <label className="text-sm font-medium">Tárolási útvonal</label>
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
                Mentés
              </button>
              <button
                className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                onClick={() => setEditing(null)}
              >
                Mégse
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Config list */}
      {loading ? (
        <p>Betöltés...</p>
      ) : configs.length === 0 ? (
        <div className="text-center py-12 text-muted-foreground">Nincs konfigurált kamera</div>
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
                      {config.enabled ? 'Aktív' : 'Inaktív'}
                    </span>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    {config.resolutionWidth}x{config.resolutionHeight} @ {config.fps} FPS
                  </p>
                  <p className="text-xs text-muted-foreground">Útvonal: {config.localStoragePath}</p>
                </div>
                <div className="flex gap-2">
                  <button
                    className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                    onClick={() => setEditing(config)}
                  >
                    Szerkesztés
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
