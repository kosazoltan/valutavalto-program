import { useState, useEffect, useRef, useCallback } from 'react'
import { Camera, RefreshCw, Wifi, WifiOff } from 'lucide-react'
import { api } from '../../services/api'

const isElectron = () => !!window.electronAPI

interface CameraStatus {
  cameraId: string
  cameraName?: string
  recording: boolean
  connected: boolean
}

export default function CameraLivePage() {
  const [cameras, setCameras] = useState<CameraStatus[]>([])
  const [selectedCamera, setSelectedCamera] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [localStream, setLocalStream] = useState<MediaStream | null>(null)
  const videoRef = useRef<HTMLVideoElement>(null)
  const imgRef = useRef<HTMLImageElement>(null)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const fetchCameraStatus = useCallback(async () => {
    try {
      if (isElectron()) {
        // Electron: lokalis kamerak listazasa WebRTC-n keresztul
        const devices = await navigator.mediaDevices.enumerateDevices()
        const videoCams = devices.filter(d => d.kind === 'videoinput')
        setCameras(videoCams.map((d, i) => ({
          cameraId: d.deviceId || `cam-${i}`,
          cameraName: d.label || `Kamera ${i + 1}`,
          recording: false,
          connected: true,
        })))
        if (videoCams.length > 0 && !selectedCamera) {
          const first = videoCams[0]
          if (first) setSelectedCamera(first.deviceId || 'cam-0')
        }
      } else {
        // Bongeszo: szerver API
        const res = await api.get('/camera/status')
        if (res.data) {
          setCameras(res.data)
          if (res.data.length > 0 && !selectedCamera) {
            setSelectedCamera(res.data[0].cameraId)
          }
        }
      }
    } finally {
      setLoading(false)
    }
  }, [selectedCamera])

  useEffect(() => {
    void fetchCameraStatus()
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
      if (localStream) localStream.getTracks().forEach(t => t.stop())
    }
  }, [fetchCameraStatus])

  // Electron: lokalis kamerakep WebRTC-n keresztul
  useEffect(() => {
    if (!isElectron() || !selectedCamera) return

    let stream: MediaStream | null = null
    const startStream = async () => {
      try {
        // Elozo stream leallitasa
        if (localStream) localStream.getTracks().forEach(t => t.stop())

        stream = await navigator.mediaDevices.getUserMedia({
          video: selectedCamera.startsWith('cam-')
            ? true
            : { deviceId: { exact: selectedCamera } },
        })
        if (videoRef.current) {
          videoRef.current.srcObject = stream
        }
        setLocalStream(stream)
      } catch (err) {
        console.error('Kamera stream hiba:', err)
      }
    }
    startStream()

    return () => {
      if (stream) stream.getTracks().forEach(t => t.stop())
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedCamera])

  // Bongeszo: szerver stream (JPEG polling)
  useEffect(() => {
    if (isElectron() || !selectedCamera) return

    intervalRef.current = setInterval(() => {
      if (imgRef.current) {
        imgRef.current.src = `/api/v1/camera/stream/${selectedCamera}?t=${Date.now()}`
      }
    }, 200)

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [selectedCamera])

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <Camera className="h-6 w-6" />
          Elo kamerakep
          {isElectron() && <span className="text-sm font-normal text-muted-foreground">(lokalis)</span>}
        </h1>
        <button
          className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
          onClick={() => void fetchCameraStatus()}
        >
          <RefreshCw className="h-4 w-4 mr-2" />
          Frissites
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Camera selector */}
        <div className="lg:col-span-1 space-y-3">
          <h2 className="font-semibold text-sm text-muted-foreground uppercase">Kamerak</h2>
          {loading ? (
            <p className="text-muted-foreground">Betoltes...</p>
          ) : cameras.length === 0 ? (
            <p className="text-muted-foreground">Nincs csatlakoztatott kamera</p>
          ) : (
            cameras.map((cam) => (
              <div
                key={cam.cameraId}
                className={`rounded-lg border bg-card shadow-sm cursor-pointer transition-colors ${
                  selectedCamera === cam.cameraId ? 'border-primary bg-primary/5' : 'hover:bg-muted/50'
                }`}
                onClick={() => setSelectedCamera(cam.cameraId)}
              >
                <div className="p-3 flex items-center justify-between">
                  <div>
                    <p className="font-medium">{cam.cameraName || cam.cameraId}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    {cam.connected ? (
                      <Wifi className="h-4 w-4 text-green-500" />
                    ) : (
                      <WifiOff className="h-4 w-4 text-red-500" />
                    )}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Live view */}
        <div className="lg:col-span-3">
          <div className="rounded-lg border bg-card shadow-sm">
            <div className="p-4 pb-2">
              <h3 className="text-lg font-semibold flex items-center gap-2">
                {selectedCamera ? (
                  <>
                    <span className="h-2 w-2 rounded-full bg-red-500 animate-pulse" />
                    ELO
                  </>
                ) : (
                  'Valasszon kamerat'
                )}
              </h3>
            </div>
            <div className="p-4">
              {selectedCamera ? (
                <div className="relative bg-black rounded-lg overflow-hidden" style={{ aspectRatio: '4/3' }}>
                  {isElectron() ? (
                    // Electron: WebRTC video stream
                    <video
                      ref={videoRef}
                      autoPlay
                      playsInline
                      muted
                      className="w-full h-full object-contain"
                    />
                  ) : (
                    // Bongeszo: JPEG polling
                    <img
                      ref={imgRef}
                      src={`/api/v1/camera/stream/${selectedCamera}?t=${Date.now()}`}
                      alt="Elo kamerakep"
                      className="w-full h-full object-contain"
                      onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
                        (e.target as HTMLImageElement).style.display = 'none'
                      }}
                    />
                  )}
                </div>
              ) : (
                <div className="flex items-center justify-center h-64 bg-muted rounded-lg">
                  <p className="text-muted-foreground">Valasszon egy kamerat a listabol</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
