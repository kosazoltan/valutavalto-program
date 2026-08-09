import { useCallback, useEffect, useRef, useState } from 'react'
import { Camera, Upload, FileText } from 'lucide-react'
import { documentScannerApi, type ScannedDocument } from '../../services/api/index'
import { isElectron } from '@/utils/electron'
import { toast } from '../ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'
import DocumentImagePair from './DocumentImagePair'

type DocType = 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb'

const DOC_TYPE_LABELS: Record<DocType, string> = {
  szemelyi: 'Személyi',
  utlevel: 'Útlevél',
  jogositvany: 'Jogosítvány',
  egyeb: 'Egyéb',
}

interface DocumentPairCaptureProps {
  customerId: number
}

export default function DocumentPairCapture({ customerId }: DocumentPairCaptureProps) {
  const { t } = useTranslation()
  const [docType, setDocType] = useState<DocType>('szemelyi')
  const [frontPath, setFrontPath] = useState<string | null>(null)
  const [backPath, setBackPath] = useState<string | null>(null)
  const [uploading, setUploading] = useState(false)
  const [hasCamera, setHasCamera] = useState(true)
  const [registeredDocs, setRegisteredDocs] = useState<ScannedDocument[]>([])
  const [loadingDocs, setLoadingDocs] = useState(false)
  const [imagePairDoc, setImagePairDoc] = useState<ScannedDocument | null>(null)

  const videoRef = useRef<HTMLVideoElement | null>(null)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  const electronAvailable = isElectron()

  const loadRegisteredDocs = useCallback(async () => {
    try {
      setLoadingDocs(true)
      setRegisteredDocs(await documentScannerApi.getCustomerDocuments(customerId))
    } catch (err) {
      logger.warn(
        'DocumentPairCapture',
        'Regisztrált okmányok betöltés hiba:',
        getErrorMessage(err),
      )
    } finally {
      setLoadingDocs(false)
    }
  }, [customerId])

  useEffect(() => {
    void loadRegisteredDocs()
  }, [loadRegisteredDocs])

  // Camera stream lifecycle — Electron-guarded (copy of DocumentScanner.tsx).
  useEffect(() => {
    if (!electronAvailable) return
    let stream: MediaStream | null = null

    const initCamera = async () => {
      try {
        stream = await navigator.mediaDevices.getUserMedia({ video: true })
        if (videoRef.current) {
          videoRef.current.srcObject = stream
        }
        setHasCamera(true)
      } catch (err) {
        logger.error('DocumentPairCapture', 'Kamera hiba:', getErrorMessage(err))
        setHasCamera(false)
      }
    }

    void initCamera()

    return () => {
      if (stream) {
        stream.getTracks().forEach((track) => track.stop())
      }
    }
  }, [electronAvailable])

  const captureSide = useCallback(
    async (side: 'front' | 'back') => {
      if (!window.electronAPI?.scanSaveDocument) {
        toast.error(t('documents.okmanyCaptureHiba'), t('documents.okmanyCaptureNemElectron'))
        return
      }
      if (!videoRef.current || !canvasRef.current) {
        toast.error(t('documents.okmanyCaptureHiba'), t('documents.okmanyCaptureHiba'))
        return
      }

      const video = videoRef.current
      const canvas = canvasRef.current
      canvas.width = video.videoWidth || 1280
      canvas.height = video.videoHeight || 720

      const ctx = canvas.getContext('2d')
      if (!ctx) {
        toast.error(t('documents.okmanyCaptureHiba'), t('documents.okmanyCaptureHiba'))
        return
      }

      // REAL capture: video frame → canvas → PNG data URL → base64.
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      const dataUrl = canvas.toDataURL('image/png')
      const base64 = dataUrl.replace(/^data:image\/png;base64,/, '')

      if (!base64) {
        toast.error(t('documents.okmanyCaptureHiba'), t('documents.okmanyCaptureNemElectron'))
        return
      }

      try {
        const scopeId = `customer-${customerId}`.replace(/[^a-zA-Z0-9_-]/g, '')
        const result = await window.electronAPI.scanSaveDocument(scopeId, docType, base64, side)
        if (side === 'front') setFrontPath(result.path)
        else setBackPath(result.path)
        toast.success(
          side === 'front'
            ? t('documents.okmanyCaptureElolap')
            : t('documents.okmanyCaptureHatlap'),
          result.path,
        )
      } catch (err) {
        logger.error('DocumentPairCapture', 'Scan hiba:', getErrorMessage(err))
        toast.error(t('documents.okmanyCaptureHiba'), getErrorMessage(err))
      }
    },
    [customerId, docType, t],
  )

  const handleUpload = async () => {
    if (!frontPath || !backPath) return
    if (!window.electronAPI?.queueScannedDocument) {
      toast.error(t('documents.okmanyCaptureHiba'), t('documents.okmanyCaptureNemElectron'))
      return
    }
    try {
      setUploading(true)
      await window.electronAPI.queueScannedDocument({
        customerId,
        documentType: docType,
        frontPath,
        backPath,
      })
      toast.success(
        t('documents.okmanyCaptureFeltoltes'),
        t('documents.okmanyCaptureFeltoltesUtemezve'),
      )
      setFrontPath(null)
      setBackPath(null)
      await loadRegisteredDocs()
    } catch (err) {
      logger.error('DocumentPairCapture', 'Queue hiba:', getErrorMessage(err))
      toast.error(t('documents.okmanyCaptureHiba'), getErrorMessage(err))
    } finally {
      setUploading(false)
    }
  }

  if (!electronAvailable) {
    return (
      <div className="form-panel">
        <h2 className="section-title flex items-center gap-2">
          <Camera size={16} />
          {t('documents.okmanyCaptureCim')}
        </h2>
        <p className="text-sm text-gray-500">{t('documents.okmanyCaptureNemElectron')}</p>
      </div>
    )
  }

  if (!hasCamera) {
    return (
      <div className="form-panel">
        <h2 className="section-title flex items-center gap-2">
          <Camera size={16} />
          {t('documents.okmanyCaptureCim')}
        </h2>
        <p className="text-sm text-gray-500">{t('components.nincsKamera')}</p>
      </div>
    )
  }

  return (
    <div className="form-panel">
      <h2 className="section-title flex items-center gap-2">
        <Camera size={16} />
        {t('documents.okmanyCaptureCim')}
      </h2>
      <div className="space-y-3">
        <div>
          <label className="form-label">{t('documents.okmanyCaptureTipus')}</label>
          <select
            value={docType}
            onChange={(e) => setDocType(e.target.value as DocType)}
            className="form-input"
          >
            {(Object.entries(DOC_TYPE_LABELS) as [DocType, string][]).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </div>

        {/* Camera preview (live) + hidden capture canvas */}
        <div className="rounded-lg border bg-black">
          <video ref={videoRef} autoPlay playsInline className="w-full rounded-lg" />
        </div>
        <canvas ref={canvasRef} className="hidden" />

        <div className="flex flex-wrap gap-3">
          <button type="button" onClick={() => void captureSide('front')} className="form-button">
            <Camera size={16} />
            {t('documents.okmanyCaptureElolap')}
            {frontPath && <span className="ml-2 text-green-600">✓</span>}
          </button>
          <button type="button" onClick={() => void captureSide('back')} className="form-button">
            <Camera size={16} />
            {t('documents.okmanyCaptureHatlap')}
            {backPath && <span className="ml-2 text-green-600">✓</span>}
          </button>
          <button
            type="button"
            onClick={() => void handleUpload()}
            disabled={!frontPath || !backPath || uploading}
            className="form-button-primary"
          >
            <Upload size={16} />
            {uploading ? '...' : t('documents.okmanyCaptureFeltoltes')}
          </button>
        </div>

        {(frontPath || backPath) && (
          <div className="rounded border border-gray-200 bg-gray-50 p-2 text-xs text-gray-600">
            {frontPath && (
              <div>
                <strong>{t('documents.elolap')}:</strong> {frontPath}
              </div>
            )}
            {backPath && (
              <div>
                <strong>{t('documents.hatlap')}:</strong> {backPath}
              </div>
            )}
          </div>
        )}

        {/* Regisztrált okmányok megtekintése (thumbnail + nagyítás-engedély) */}
        <div className="mt-4">
          <h3 className="mb-2 flex items-center gap-2 text-sm font-semibold text-gray-700">
            <FileText size={14} />
            {t('documents.okmanyRegisztraltDokumentumok')}
          </h3>
          {loadingDocs ? (
            <p className="text-sm text-gray-400">{t('documents.nagyitasBetoltes')}</p>
          ) : registeredDocs.length === 0 ? (
            <p className="text-sm text-gray-400">—</p>
          ) : (
            <ul className="space-y-2">
              {registeredDocs.map((doc) => (
                <li
                  key={doc.id}
                  className="flex items-center justify-between rounded border border-gray-200 px-3 py-2 text-sm"
                >
                  <div className="min-w-0">
                    <p className="break-words font-medium text-gray-900">{doc.fileName}</p>
                    <p className="text-xs text-gray-500">
                      {doc.documentType} · {new Date(doc.scannedAt).toLocaleString('hu-HU')}
                    </p>
                  </div>
                  {(doc.hasFrontImage || doc.hasBackImage) && (
                    <button
                      type="button"
                      className="form-button text-xs"
                      onClick={() => setImagePairDoc(doc)}
                    >
                      {t('documents.okmanyKepek')}
                    </button>
                  )}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      {imagePairDoc && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          onClick={() => setImagePairDoc(null)}
        >
          <div
            className="max-h-[90vh] max-w-2xl overflow-auto rounded-lg bg-white p-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="mb-3 flex items-center justify-between">
              <h3 className="font-semibold">{t('documents.okmanyKepek')}</h3>
              <button onClick={() => setImagePairDoc(null)} className="form-button text-xs">
                {t('common.close')}
              </button>
            </div>
            <DocumentImagePair
              documentId={imagePairDoc.id}
              hasFront={!!imagePairDoc.hasFrontImage}
              hasBack={!!imagePairDoc.hasBackImage}
            />
          </div>
        </div>
      )}
    </div>
  )
}
