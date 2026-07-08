import { useCallback, useEffect, useRef, useState } from 'react'
import { Camera, Trash2, Check } from 'lucide-react'
import { toast } from '../ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'

interface IncomeSourceDocCaptureProps {
  onCaptured(base64: string): void
  onClear(): void
}

export default function IncomeSourceDocCapture({
  onCaptured,
  onClear,
}: IncomeSourceDocCaptureProps) {
  const { t } = useTranslation()
  const [capturedBase64, setCapturedBase64] = useState<string | null>(null)
  const [hasCamera, setHasCamera] = useState(true)
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  useEffect(() => {
    let stream: MediaStream | null = null

    const initCamera = async () => {
      try {
        if (!navigator.mediaDevices?.getUserMedia) {
          setHasCamera(false)
          return
        }
        stream = await navigator.mediaDevices.getUserMedia({ video: true })
        if (videoRef.current) {
          videoRef.current.srcObject = stream
        }
        setHasCamera(true)
      } catch (err) {
        logger.error('IncomeSourceDocCapture', 'Kamera hiba:', getErrorMessage(err))
        setHasCamera(false)
      }
    }

    void initCamera()

    return () => {
      if (stream) {
        stream.getTracks().forEach((track) => track.stop())
      }
    }
  }, [])

  const capture = useCallback(() => {
    if (!videoRef.current || !canvasRef.current) {
      toast.error(t('incomeProof.kuldesHiba'))
      return
    }

    const video = videoRef.current
    const canvas = canvasRef.current
    canvas.width = video.videoWidth || 1280
    canvas.height = video.videoHeight || 720

    const ctx = canvas.getContext('2d')
    if (!ctx) {
      toast.error(t('incomeProof.kuldesHiba'))
      return
    }

    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    const dataUrl = canvas.toDataURL('image/jpeg', 0.85)
    const base64 = dataUrl.replace(/^data:image\/jpeg;base64,/, '')

    if (!base64.trim()) {
      toast.error(t('incomeProof.kuldesHiba'))
      return
    }

    setCapturedBase64(base64)
    onCaptured(base64)
  }, [onCaptured, t])

  const clear = useCallback(() => {
    setCapturedBase64(null)
    onClear()
  }, [onClear])

  if (!hasCamera) {
    return (
      <div className="form-panel">
        <h2 className="section-title flex items-center gap-2">
          <Camera size={16} />
          {t('incomeProof.cim')}
        </h2>
        <p className="text-sm text-gray-500">{t('components.nincsKamera')}</p>
      </div>
    )
  }

  return (
    <div className="form-panel">
      <h2 className="section-title flex items-center gap-2">
        <Camera size={16} />
        {t('incomeProof.cim')}
      </h2>
      <p className="text-sm text-gray-600 dark:text-gray-300">{t('incomeProof.nemTarolodik')}</p>
      <div className="space-y-3">
        <div className="rounded-lg border bg-black">
          <video ref={videoRef} autoPlay playsInline className="w-full rounded-lg" />
        </div>
        <canvas ref={canvasRef} className="hidden" />
        <div className="flex flex-wrap gap-3">
          <button type="button" onClick={capture} className="form-button-primary">
            <Camera size={16} />
            {t('incomeProof.capture')}
            {capturedBase64 && (
              <Check size={14} className="ml-2 text-green-600" aria-hidden="true" />
            )}
          </button>
          {capturedBase64 && (
            <button type="button" onClick={clear} className="form-button">
              <Trash2 size={16} />
              {t('incomeProof.megsem')}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
