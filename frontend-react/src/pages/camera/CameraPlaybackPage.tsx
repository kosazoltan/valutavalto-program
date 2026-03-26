import { useState } from 'react'
import { Search, PlayCircle, Calendar, FileVideo } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger';

const isElectron = () => !!window.electronAPI

// Lokális (Electron) felvétel bejegyzés
interface LocalRecordingEntry {
  date: string
  transactionId: string
  filePath: string
  fileSizeBytes: number
  createdAt: string
}

// Szerver oldali felvétel metadata
interface RecordingMetadata {
  id: string
  branchId: string
  cameraId: string
  startTime: string
  endTime: string | null
  fileSizeBytes: number | null
  uploadedToServer: boolean
  expiresAt: string
  status: string
  linkedTransactions: number
}

export default function CameraPlaybackPage() {
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [localRecordings, setLocalRecordings] = useState<LocalRecordingEntry[]>([])
  const [serverRecordings, setServerRecordings] = useState<RecordingMetadata[]>([])
  const [selectedVideo, setSelectedVideo] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const searchByDate = async () => {
    if (!startDate || !endDate) return
    setLoading(true)
    setSelectedVideo(null)
    try {
      if (isElectron() && window.electronAPI?.cameraLocalRecordingsByDate) {
        // Electron: lokális fájlrendszerben keres
        const results = await window.electronAPI.cameraLocalRecordingsByDate(startDate, endDate)
        setLocalRecordings(results)
        setServerRecordings([])
      } else {
        // Böngésző: szerver API — branchId-t nem kérdezzük (admin lekérés)
        const params = new URLSearchParams({
          branchId: '', // TODO: branch selector
          start: startDate + 'T00:00:00',
          end: endDate + 'T23:59:59',
        })
        const res = await api.get(`/camera/recordings?${params}`)
        setServerRecordings(res.data)
        setLocalRecordings([])
      }
    } catch (err) {
      logger.error('CameraPlaybackPage', 'Keresés sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const playLocalFile = async (filePath: string) => {
    if (!window.electronAPI?.cameraLocalReadFile) return
    try {
      const base64 = await window.electronAPI.cameraLocalReadFile(filePath)
      if (base64) {
        setSelectedVideo(`data:video/webm;base64,${base64}`)
      }
    } catch (err) {
      logger.error('CameraPlaybackPage', 'Lejátszás sikertelen:', err)
    }
  }

  const formatFileSize = (bytes: number | null) => {
    if (!bytes) return '-'
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return '-'
    return new Date(dateStr).toLocaleString('hu-HU')
  }

  const hasResults = localRecordings.length > 0 || serverRecordings.length > 0

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold flex items-center gap-2">
        <PlayCircle className="h-6 w-6" />
        Felvétel visszajátszás
        {isElectron() && <span className="text-sm font-normal text-muted-foreground">(lokális)</span>}
      </h1>

      {/* Search controls */}
      <div className="rounded-lg border bg-card shadow-sm">
        <div className="p-4 pb-2">
          <h3 className="text-lg font-semibold flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Keresés dátum szerint
          </h3>
        </div>
        <div className="p-4">
          <div className="flex gap-3 items-end">
            <div>
              <label className="text-sm font-medium">Kezdő dátum</label>
              <input
                className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                type="date"
                value={startDate}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setStartDate(e.target.value)}
              />
            </div>
            <div>
              <label className="text-sm font-medium">Záró dátum</label>
              <input
                className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                type="date"
                value={endDate}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEndDate(e.target.value)}
              />
            </div>
            <button
              className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
              onClick={searchByDate}
              disabled={loading || !startDate || !endDate}
            >
              <Search className="h-4 w-4 mr-2" />
              Keresés
            </button>
          </div>
        </div>
      </div>

      {/* Video player */}
      {selectedVideo && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">Lejátszás</h3>
          </div>
          <div className="p-4">
            <video
              src={selectedVideo}
              controls
              className="w-full rounded-lg bg-black"
              style={{ maxHeight: '480px' }}
            />
          </div>
        </div>
      )}

      {/* Lokális felvételek (Electron) */}
      {localRecordings.length > 0 && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <FileVideo className="h-5 w-5" />
              Lokális felvételek ({localRecordings.length})
            </h3>
          </div>
          <div className="p-4">
            <div className="space-y-2">
              {localRecordings.map((rec) => (
                <div key={rec.transactionId} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                  <div className="space-y-1">
                    <p className="font-medium">Tranzakció: {rec.transactionId}</p>
                    <p className="text-sm text-muted-foreground">
                      {rec.date} -- {formatDate(rec.createdAt)}
                    </p>
                  </div>
                  <div className="flex items-center gap-3">
                    <p className="text-sm text-muted-foreground">{formatFileSize(rec.fileSizeBytes)}</p>
                    <button
                      className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90"
                      onClick={() => playLocalFile(rec.filePath)}
                    >
                      <PlayCircle className="h-4 w-4 mr-1" />
                      Lejátszás
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Szerver felvételek (böngésző) */}
      {serverRecordings.length > 0 && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <FileVideo className="h-5 w-5" />
              Szerveren tárolt felvételek ({serverRecordings.length})
            </h3>
          </div>
          <div className="p-4">
            <div className="space-y-2">
              {serverRecordings.map((rec) => (
                <div key={rec.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium">{rec.cameraId}</span>
                      <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                        rec.status === 'COMPLETED' ? 'bg-primary text-primary-foreground' : 'bg-secondary text-secondary-foreground'
                      }`}>
                        {rec.status}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {formatDate(rec.startTime)} -- {formatDate(rec.endTime)}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm">{formatFileSize(rec.fileSizeBytes)}</p>
                    <p className="text-xs text-muted-foreground">{rec.linkedTransactions} tranzakció</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {!loading && !hasResults && (
        <div className="text-center py-12 text-muted-foreground">
          Használja a keresőt felvételek megjelenítéséhez
        </div>
      )}
    </div>
  )
}
