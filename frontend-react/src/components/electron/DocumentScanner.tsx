/**
 * DocumentScanner — Dokumentum szkennelés kamerával, titkosított mentéssel.
 *
 * CSAK Electron-ban működik (window.electronAPI.scanSaveDocument / scanListDocuments).
 * Böngészőben null-t ad vissza.
 */

import { useCallback, useEffect, useRef, useState } from 'react'
import { isElectron } from '@/utils/electron'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'

interface DocumentScannerProps {
  transactionId: string
  onScanned: (type: string, path: string) => void
}

type DocumentType = 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb'

const documentLabels: Record<DocumentType, string> = {
  szemelyi: 'Személyi',
  utlevel: 'Útlevél',
  jogositvany: 'Jogosítvány',
  egyeb: 'Egyéb',
}

export default function DocumentScanner({ transactionId, onScanned }: DocumentScannerProps) {
  const { t } = useTranslation()
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  const [hasCamera, setHasCamera] = useState(true)
  const [documentType, setDocumentType] = useState<DocumentType>('szemelyi')
  const [savedDocs, setSavedDocs] = useState<string[]>([])
  const [status, setStatus] = useState('')

  const electronAvailable = isElectron()

  const loadDocuments = useCallback(async () => {
    if (!window.electronAPI?.scanListDocuments) return
    const list = await window.electronAPI.scanListDocuments(transactionId)
    setSavedDocs(list)
  }, [transactionId])

  useEffect(() => {
    let stream: MediaStream | null = null

    const initCamera = async () => {
      try {
        stream = await navigator.mediaDevices.getUserMedia({ video: true })
        if (videoRef.current) {
          videoRef.current.srcObject = stream
        }
        setHasCamera(true)
      } catch (err) {
        logger.error('DocumentScanner', 'Kamera hiba:', err)
        setHasCamera(false)
      }
    }

    initCamera()
    loadDocuments()

    return () => {
      if (stream) {
        stream.getTracks().forEach((track) => track.stop())
      }
    }
  }, [loadDocuments])

  const handleCapture = useCallback(async () => {
    setStatus('')
    if (!videoRef.current || !canvasRef.current) return
    if (!window.electronAPI?.scanSaveDocument) {
      setStatus('Mentés nem elérhető (Electron IPC)')
      return
    }

    const video = videoRef.current
    const canvas = canvasRef.current
    canvas.width = video.videoWidth || 1280
    canvas.height = video.videoHeight || 720

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    const dataUrl = canvas.toDataURL('image/png')
    const base64 = dataUrl.replace(/^data:image\/png;base64,/, '')

    try {
      const result = await window.electronAPI.scanSaveDocument(transactionId, documentType, base64)
      setStatus('Dokumentum mentve (titkosítva)')
      onScanned(documentType, result.path)
      await loadDocuments()
    } catch (err) {
      logger.error('DocumentScanner', 'Mentés hiba:', err)
      setStatus('Mentés sikertelen')
    }
  }, [transactionId, documentType, onScanned, loadDocuments])

  const renderDocLabel = (filePath: string) => {
    const name = filePath.split(/[/\\]/).pop() ?? ''
    const prefix = name.split('_')[0] as DocumentType
    return documentLabels[prefix] ?? name
  }

  // Guard: only render in Electron
  if (!electronAvailable) return null

  if (!hasCamera) {
    return (
      <div className="rounded-lg border border-dashed bg-gray-50 p-4 text-center text-sm text-gray-500">
        {t('components.nincsKamera')}
      </div>
    )
  }

  return (
    <div className="space-y-4 rounded-xl border bg-white p-4 shadow-sm">
      <div className="flex flex-wrap items-center gap-3">
        <label className="text-sm font-medium text-gray-700">
          {t('components.dokumentumTipus')}
        </label>
        <select
          value={documentType}
          onChange={(e) => setDocumentType(e.target.value as DocumentType)}
          className="rounded-lg border px-3 py-2 text-sm"
        >
          {Object.entries(documentLabels).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <button
          onClick={handleCapture}
          className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          {t('components.fenykep')}
        </button>
        {status && <span className="text-sm text-gray-600">{status}</span>}
      </div>

      <div className="rounded-lg border bg-black">
        <video ref={videoRef} autoPlay playsInline className="w-full rounded-lg" />
      </div>

      <canvas ref={canvasRef} className="hidden" />

      <div>
        <h4 className="mb-2 text-sm font-semibold text-gray-700">
          {t('components.mentettDokumentumok')}
        </h4>
        {savedDocs.length === 0 ? (
          <p className="text-sm text-gray-400">{t('components.nincsMentettDokumentum')}</p>
        ) : (
          <ul className="space-y-2">
            {savedDocs.map((doc) => (
              <li
                key={doc}
                className="flex items-center gap-2 rounded-lg border px-3 py-2 text-sm text-gray-700"
              >
                <span className="text-gray-400">&#128196;</span>
                <span>{renderDocLabel(doc)}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
