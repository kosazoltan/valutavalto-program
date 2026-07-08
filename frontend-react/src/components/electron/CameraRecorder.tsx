/**
 * CameraRecorder — Kamera felvétel rögzítése tranzakcióhoz.
 *
 * CSAK Electron-ban működik (window.electronAPI.cameraSaveRecording).
 * Böngészőben null-t ad vissza.
 */

import { useCallback, useEffect, useRef, useState } from 'react'
import { isElectron } from '@/utils/electron'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'

interface CameraRecorderProps {
  transactionId: string
  onSaved: (path: string) => void
}

export default function CameraRecorder({ transactionId, onSaved }: CameraRecorderProps) {
  const { t } = useTranslation()
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const chunksRef = useRef<Blob[]>([])

  const [hasCamera, setHasCamera] = useState(true)
  const [isRecording, setIsRecording] = useState(false)
  const [status, setStatus] = useState('')

  const electronAvailable = isElectron()

  useEffect(() => {
    let stream: MediaStream | null = null

    const initCamera = async () => {
      try {
        stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true })
        if (videoRef.current) {
          videoRef.current.srcObject = stream
        }
        setHasCamera(true)
      } catch (err) {
        logger.error('CameraRecorder', 'Kamera hiba:', err)
        setHasCamera(false)
      }
    }

    initCamera()

    return () => {
      if (stream) {
        stream.getTracks().forEach((track) => track.stop())
      }
    }
  }, [])

  const handleStart = useCallback(() => {
    if (!videoRef.current?.srcObject) return
    const stream = videoRef.current.srcObject as MediaStream
    const options = MediaRecorder.isTypeSupported('video/webm')
      ? { mimeType: 'video/webm' }
      : undefined
    const recorder = new MediaRecorder(stream, options)
    chunksRef.current = []

    recorder.ondataavailable = (event) => {
      if (event.data.size > 0) {
        chunksRef.current.push(event.data)
      }
    }

    recorder.onstop = async () => {
      try {
        const blob = new Blob(chunksRef.current, { type: 'video/webm' })
        const buffer = await blob.arrayBuffer()
        if (!window.electronAPI?.cameraSaveRecording) {
          setStatus('Mentés nem elérhető (Electron IPC)')
          return
        }
        const filepath = await window.electronAPI.cameraSaveRecording(transactionId, buffer, 'webm')
        setStatus('Felvétel mentve')
        onSaved(filepath)
      } catch (err) {
        logger.error('CameraRecorder', 'Mentés hiba:', err)
        setStatus('Mentés sikertelen')
      }
    }

    mediaRecorderRef.current = recorder
    recorder.start()
    setIsRecording(true)
    setStatus('Felvétel folyamatban...')
  }, [transactionId, onSaved])

  const handleStop = useCallback(() => {
    mediaRecorderRef.current?.stop()
    setIsRecording(false)
  }, [])

  // Guard: only render in Electron
  if (!electronAvailable) return null

  if (!hasCamera) {
    return (
      <div className="rounded-lg border border-dashed bg-gray-50 p-4 text-center text-sm text-gray-500">
        {t('components.nincsKameraCsatlakoztatva')}
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <div className="rounded-lg border bg-black">
        <video ref={videoRef} autoPlay playsInline muted className="w-full rounded-lg" />
      </div>
      <div className="flex gap-2 items-center">
        {!isRecording ? (
          <button
            onClick={handleStart}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            {t('components.felvetelInditasa')}
          </button>
        ) : (
          <button
            onClick={handleStop}
            className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
          >
            {t('components.felvetelLeallitasa')}
          </button>
        )}
        {status && <span className="text-sm text-gray-600">{status}</span>}
      </div>
    </div>
  )
}
