import { useState, useEffect, useRef, useCallback } from 'react'
import { Camera, RefreshCw, Wifi, WifiOff } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

const isElectron = () => !!window.electronAPI

interface CameraStatus {
  cameraId: string
  cameraName?: string
  recording: boolean
  connected: boolean
}

export default function CameraLivePage() {
  const { t } = useTranslation()
  const [cameras, setCameras] = useState<CameraStatus[]>([])
  const [selectedCamera, setSelectedCamera] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const videoRef = useRef<HTMLVideoElement>(null)
  const imgRef = useRef<HTMLImageElement>(null)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const localStreamRef = useRef<MediaStream | null>(null)

  const fetchCameraStatus = useCallback(async () => {
    try {
      if (isElectron()) {
        // Electron: lokális kamerák listázása WebRTC-n keresztül
        const devices = await navigator.mediaDevices.enumerateDevices()
        const videoCams = devices.filter((d) => d.kind === 'videoinput')
        setCameras(
          videoCams.map((d, i) => ({
            cameraId: d.deviceId || `cam-${i}`,
            cameraName: d.label || `Kamera ${i + 1}`,
            recording: false,
            connected: true,
          })),
        )
        if (videoCams.length > 0 && !selectedCamera) {
          const first = videoCams[0]
          if (first) setSelectedCamera(first.deviceId || 'cam-0')
        }
      } else {
        // Böngésző: szerver API
        const res = await api.get('/camera/status')
        const camerasData = safeArray<CameraStatus>(res?.data)
        setCameras(camerasData)
        if (camerasData.length > 0 && !selectedCamera) {
          const first = camerasData[0]
          if (first) setSelectedCamera(first.cameraId)
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
      if (localStreamRef.current) localStreamRef.current.getTracks().forEach((t) => t.stop())
    }
  }, [fetchCameraStatus])

  // Electron: lokális kamerakép WebRTC-n keresztül
  useEffect(() => {
    if (!isElectron() || !selectedCamera) return

    let stream: MediaStream | null = null
    const startStream = async () => {
      try {
        // Előző stream leállítása
        if (localStreamRef.current) localStreamRef.current.getTracks().forEach((t) => t.stop())

        stream = await navigator.mediaDevices.getUserMedia({
          video: selectedCamera.startsWith('cam-') ? true : { deviceId: { exact: selectedCamera } },
        })
        if (videoRef.current) {
          videoRef.current.srcObject = stream
        }
        localStreamRef.current = stream
      } catch (err) {
        logger.error('CameraLivePage', 'Kamera stream hiba:', err)
      }
    }
    startStream()

    return () => {
      if (stream) stream.getTracks().forEach((t) => t.stop())
    }
  }, [selectedCamera])

  // Böngésző: szerver stream (JPEG polling)
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
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold flex items-center gap-2">
          <Camera className="h-6 w-6" />
          {t('camera.eloKamerakep')}
          {isElectron() && (
            <span className="text-sm font-normal text-muted-foreground">{t('camera.lokalis')}</span>
          )}
        </h1>
        <button
          className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
          onClick={() => void fetchCameraStatus()}
        >
          <RefreshCw className="h-4 w-4 mr-2" />
          {t('common.refresh')}
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-3">
        {/* Camera selector */}
        <div className="lg:col-span-1 space-y-3">
          <h2 className="font-semibold text-sm text-muted-foreground uppercase">
            {t('camera.kamerak')}
          </h2>
          {loading ? (
            <p className="text-muted-foreground">{i18n.t('literals.betoltes')}</p>
          ) : cameras.length === 0 ? (
            <p className="text-muted-foreground">{t('camera.nincsCsatlakoztatottKamera')}</p>
          ) : (
            cameras.map((cam) => (
              <div
                key={cam.cameraId}
                className={`rounded-lg border bg-card shadow-sm cursor-pointer transition-colors ${
                  selectedCamera === cam.cameraId
                    ? 'border-primary bg-primary/5'
                    : 'hover:bg-muted/50'
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
                    {t('camera.elo')}
                  </>
                ) : (
                  'Válasszon kamerát'
                )}
              </h3>
            </div>
            <div className="p-4">
              {selectedCamera ? (
                <div
                  className="relative bg-black rounded-lg overflow-hidden"
                  style={{ aspectRatio: '4/3' }}
                >
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
                    // Böngésző: JPEG polling
                    <img
                      ref={imgRef}
                      src={`/api/v1/camera/stream/${selectedCamera}?t=${Date.now()}`}
                      alt="Élő kamerakép"
                      className="w-full h-full object-contain"
                      onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
                        ;(e.target as HTMLImageElement).style.display = 'none'
                      }}
                    />
                  )}
                </div>
              ) : (
                <div className="flex items-center justify-center h-64 bg-muted rounded-lg">
                  <p className="text-muted-foreground">
                    {t('camera.valasszonEgyKameratAListabol')}
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
