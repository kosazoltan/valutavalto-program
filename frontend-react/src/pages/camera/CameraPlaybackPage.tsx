import { useEffect, useMemo, useState } from 'react'
import { Search, PlayCircle, Calendar, FileVideo } from 'lucide-react'
import { api, branchApi, type BranchInfo } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import CameraReviewPanel from './CameraReviewPanel'

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

interface CameraAccessLog {
  id: string
  workerId?: number | null
  action?: string | null
  createdAt?: string | null
}

interface CameraTransactionLink {
  id: string
  recording?: RecordingMetadata | null
  transactionId?: number | null
  receiptNumber?: string | null
  transactionTime?: string | null
  frameOffsetSeconds?: number | null
}

interface ReviewOverviewRow {
  branchId: string
  branchCode?: string | null
  branchName?: string | null
  date: string
  recordingCount: number
  markCount: number
  reviewed: boolean
  problematic: boolean
}

interface ServerDateSearch {
  branchId: string
  startDate: string
  endDate: string
}

export default function CameraPlaybackPage() {
  const { t } = useTranslation()
  const [branchId, setBranchId] = useState('')
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [receiptNumber, setReceiptNumber] = useState('')
  const [transactionId, setTransactionId] = useState('')
  const [localRecordings, setLocalRecordings] = useState<LocalRecordingEntry[]>([])
  const [serverRecordings, setServerRecordings] = useState<RecordingMetadata[]>([])
  const [transactionLinks, setTransactionLinks] = useState<CameraTransactionLink[]>([])
  const [selectedRecording, setSelectedRecording] = useState<RecordingMetadata | null>(null)
  const [accessLogs, setAccessLogs] = useState<CameraAccessLog[]>([])
  const [selectedVideo, setSelectedVideo] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [selectedCameraId, setSelectedCameraId] = useState('ALL')
  const [lastServerDateSearch, setLastServerDateSearch] = useState<ServerDateSearch | null>(null)
  const [reviewOnlyProblematic, setReviewOnlyProblematic] = useState(false)
  const [reviewOverviewRows, setReviewOverviewRows] = useState<ReviewOverviewRow[]>([])
  const [reviewOverviewLoading, setReviewOverviewLoading] = useState(false)

  useEffect(() => {
    if (isElectron()) return
    branchApi
      .listActive()
      .then(setBranches)
      .catch((err) => logger.error('CameraPlaybackPage', 'Iroda lista betöltése sikertelen:', err))
  }, [])

  const searchByDate = async (override?: ServerDateSearch) => {
    const searchBranchId = override?.branchId ?? branchId
    const searchStartDate = override?.startDate ?? startDate
    const searchEndDate = override?.endDate ?? endDate
    if (!searchStartDate || !searchEndDate) return
    if (!isElectron() && !searchBranchId) return
    setLoading(true)
    setSelectedVideo(null)
    setSelectedRecording(null)
    setAccessLogs([])
    setTransactionLinks([])
    try {
      if (isElectron() && window.electronAPI?.cameraLocalRecordingsByDate) {
        // Electron: lokális fájlrendszerben keres
        const results = await window.electronAPI.cameraLocalRecordingsByDate(
          searchStartDate,
          searchEndDate,
        )
        setLocalRecordings(results)
        setServerRecordings([])
        setLastServerDateSearch(null)
      } else {
        const params = new URLSearchParams({
          branchId: searchBranchId,
          start: searchStartDate + 'T00:00:00',
          end: searchEndDate + 'T23:59:59',
        })
        const res = await api.get(`/camera/recordings?${params}`)
        setServerRecordings(res.data ?? [])
        setLocalRecordings([])
        setSelectedCameraId('ALL')
        setLastServerDateSearch({
          branchId: searchBranchId,
          startDate: searchStartDate,
          endDate: searchEndDate,
        })
      }
    } catch (err) {
      logger.error('CameraPlaybackPage', 'Keresés sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const selectServerRecording = async (recording: RecordingMetadata) => {
    setSelectedRecording(recording)
    setAccessLogs([])
    try {
      const [detailResult, accessLogResult] = await Promise.all([
        api.get<RecordingMetadata>(`/camera/recordings/${recording.id}`),
        api.get<CameraAccessLog[]>(`/camera/admin/access-logs/${recording.id}`),
      ])
      setSelectedRecording(detailResult.data)
      setAccessLogs(accessLogResult.data ?? [])
    } catch (err) {
      logger.error('CameraPlaybackPage', 'Felvétel részletek lekérése sikertelen:', err)
    }
  }

  const recordingFromLink = (link: CameraTransactionLink): RecordingMetadata | null => {
    const recording = link.recording
    if (!recording?.id) return null
    return {
      ...recording,
      linkedTransactions: recording.linkedTransactions ?? 1,
    }
  }

  const searchByReceipt = async () => {
    const value = receiptNumber.trim()
    if (!value || isElectron()) return
    setLoading(true)
    setSelectedVideo(null)
    setSelectedRecording(null)
    setAccessLogs([])
    setServerRecordings([])
    setLocalRecordings([])
    setLastServerDateSearch(null)
    try {
      const res = await api.get<CameraTransactionLink[]>(
        `/camera/recordings/by-receipt/${encodeURIComponent(value)}`,
      )
      setTransactionLinks(res.data ?? [])
    } catch (err) {
      logger.error('CameraPlaybackPage', 'Bizonylat szerinti kamera keresés sikertelen:', err)
      setTransactionLinks([])
    } finally {
      setLoading(false)
    }
  }

  const searchByTransaction = async () => {
    const value = transactionId.trim()
    if (!value || isElectron()) return
    setLoading(true)
    setSelectedVideo(null)
    setSelectedRecording(null)
    setAccessLogs([])
    setServerRecordings([])
    setLocalRecordings([])
    setLastServerDateSearch(null)
    try {
      const res = await api.get<CameraTransactionLink[]>(
        `/camera/recordings/by-transaction/${encodeURIComponent(value)}`,
      )
      setTransactionLinks(res.data ?? [])
    } catch (err) {
      logger.error('CameraPlaybackPage', 'Tranzakció szerinti kamera keresés sikertelen:', err)
      setTransactionLinks([])
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

  const loadReviewOverview = async () => {
    if (isElectron() || !startDate || !endDate) return
    setReviewOverviewLoading(true)
    try {
      const params = new URLSearchParams({
        start: startDate,
        end: endDate,
        onlyProblematic: String(reviewOnlyProblematic),
      })
      if (branchId) params.set('branchId', branchId)
      const res = await api.get<ReviewOverviewRow[]>(`/camera/review/overview?${params}`)
      setReviewOverviewRows(res.data ?? [])
    } catch (err) {
      logger.error('CameraPlaybackPage', 'Átnézendő felvételek betöltése sikertelen:', err)
      setReviewOverviewRows([])
    } finally {
      setReviewOverviewLoading(false)
    }
  }

  const openOverviewRow = (row: ReviewOverviewRow) => {
    setBranchId(row.branchId)
    setStartDate(row.date)
    setEndDate(row.date)
    void searchByDate({ branchId: row.branchId, startDate: row.date, endDate: row.date })
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

  const hasResults =
    localRecordings.length > 0 || serverRecordings.length > 0 || transactionLinks.length > 0

  const distinctCameraIds = useMemo(
    () => Array.from(new Set(serverRecordings.map((rec) => rec.cameraId).filter(Boolean))).sort(),
    [serverRecordings],
  )

  const filteredServerRecordings = useMemo(() => {
    if (selectedCameraId === 'ALL') return serverRecordings
    return serverRecordings.filter((rec) => rec.cameraId === selectedCameraId)
  }, [selectedCameraId, serverRecordings])

  const showReviewPanel =
    !isElectron() &&
    lastServerDateSearch != null &&
    lastServerDateSearch.startDate === lastServerDateSearch.endDate &&
    serverRecordings.length > 0

  return (
    <div className="space-y-3">
      <h1 className="text-lg font-bold flex items-center gap-2">
        <PlayCircle className="h-6 w-6" />
        {t('camera.felvetelVisszajatszas')}
        {isElectron() && (
          <span className="text-sm font-normal text-muted-foreground">{t('camera.lokalis')}</span>
        )}
      </h1>

      {/* Search controls */}
      <div className="rounded-lg border bg-card shadow-sm">
        <div className="p-4 pb-2">
          <h3 className="text-lg font-semibold flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            {t('camera.keresesDatumSzerint')}
          </h3>
        </div>
        <div className="p-4">
          <div className="flex gap-3 items-end">
            {!isElectron() && (
              <div>
                <label className="text-sm font-medium">{t('camera.iroda')}</label>
                <select
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={branchId}
                  onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
                    setBranchId(e.target.value)
                  }
                  aria-label={t('camera.iroda')}
                  data-testid="camera-playback-branch"
                >
                  <option value="">{t('camera.valasszonIrodat')}</option>
                  {branches.map((branch) => (
                    <option key={branch.id} value={branch.id}>
                      {branch.code} -- {branch.name}
                    </option>
                  ))}
                </select>
              </div>
            )}
            <div>
              <label className="text-sm font-medium">{t('common.startDate')}</label>
              <input
                className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                type="date"
                value={startDate}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setStartDate(e.target.value)}
                aria-label={t('common.startDate')}
              />
            </div>
            <div>
              <label className="text-sm font-medium">{t('camera.zaroDatum')}</label>
              <input
                className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                type="date"
                value={endDate}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEndDate(e.target.value)}
                aria-label={t('camera.zaroDatum')}
              />
            </div>
            <button
              className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
              onClick={() => void searchByDate()}
              disabled={loading || !startDate || !endDate || (!isElectron() && !branchId)}
            >
              <Search className="h-4 w-4 mr-2" />
              {t('common.search')}
            </button>
          </div>
        </div>
      </div>

      {!isElectron() && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <Search className="h-5 w-5" />
              {t('camera.attekintendoFelvetelek')}
            </h3>
          </div>
          <div className="space-y-3 p-4">
            <div className="flex flex-wrap items-center gap-3">
              <label className="flex items-center gap-2 text-sm font-medium">
                <input
                  type="checkbox"
                  checked={reviewOnlyProblematic}
                  onChange={(event) => setReviewOnlyProblematic(event.target.checked)}
                  data-testid="review-overview-only-problematic"
                />
                {t('camera.csakProblemas')}
              </label>
              <button
                type="button"
                className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={() => void loadReviewOverview()}
                disabled={reviewOverviewLoading || !startDate || !endDate}
                data-testid="review-overview-fetch"
              >
                {t('camera.attekintendoFelvetelek')}
              </button>
            </div>
            {reviewOverviewRows.length > 0 && (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead className="text-xs text-muted-foreground">
                    <tr>
                      <th className="px-2 py-1">{t('camera.iroda')}</th>
                      <th className="px-2 py-1">{t('common.date')}</th>
                      <th className="px-2 py-1">{t('camera.felvetelek')}</th>
                      <th className="px-2 py-1">{t('camera.megjelolesek')}</th>
                      <th className="px-2 py-1">{t('camera.atnezve')}</th>
                      <th className="px-2 py-1">{t('camera.problemasEset')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reviewOverviewRows.map((row) => (
                      <tr key={`${row.branchId}-${row.date}`}>
                        <td className="px-2 py-1">
                          <button
                            type="button"
                            className="text-left font-medium hover:underline"
                            onClick={() => openOverviewRow(row)}
                            data-testid={`review-overview-row-${row.branchId}-${row.date}`}
                          >
                            {row.branchCode ?? row.branchId} {row.branchName ?? ''}
                          </button>
                        </td>
                        <td className="px-2 py-1">{row.date}</td>
                        <td className="px-2 py-1">{row.recordingCount}</td>
                        <td className="px-2 py-1">{row.markCount}</td>
                        <td className="px-2 py-1">{row.reviewed ? '✓' : '-'}</td>
                        <td className="px-2 py-1">
                          {row.problematic && (
                            <span className="rounded-full border border-red-200 bg-red-100 px-2 py-0.5 text-xs font-medium text-red-800">
                              {t('camera.problemasEset')}
                            </span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {!isElectron() && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <Search className="h-5 w-5" />
              {t('camera.keresesBizonylatVagyTranzakcio')}
            </h3>
          </div>
          <div className="grid gap-3 p-4 md:grid-cols-2">
            <label className="grid gap-1 text-sm font-medium">
              {t('camera.bizonylatszam')}
              <div className="flex gap-2">
                <input
                  className="flex h-10 min-w-0 flex-1 rounded-md border px-3 py-2 text-sm"
                  value={receiptNumber}
                  onChange={(event) => setReceiptNumber(event.target.value)}
                  aria-label={t('camera.bizonylatszam')}
                />
                <button
                  type="button"
                  className="inline-flex h-10 shrink-0 items-center justify-center rounded-md bg-primary px-3 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                  onClick={() => void searchByReceipt()}
                  disabled={loading || !receiptNumber.trim()}
                >
                  {t('camera.bizonylatKereses')}
                </button>
              </div>
            </label>
            <label className="grid gap-1 text-sm font-medium">
              {t('camera.tranzakcioId')}
              <div className="flex gap-2">
                <input
                  className="flex h-10 min-w-0 flex-1 rounded-md border px-3 py-2 text-sm"
                  inputMode="numeric"
                  value={transactionId}
                  onChange={(event) => setTransactionId(event.target.value)}
                  aria-label={t('camera.tranzakcioId')}
                />
                <button
                  type="button"
                  className="inline-flex h-10 shrink-0 items-center justify-center rounded-md bg-primary px-3 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                  onClick={() => void searchByTransaction()}
                  disabled={loading || !transactionId.trim()}
                >
                  {t('camera.tranzakcioKereses')}
                </button>
              </div>
            </label>
          </div>
        </div>
      )}

      {/* Video player */}
      {selectedVideo && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">{t('camera.lejatszas')}</h3>
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
              {t('camera.lokalisFelvetelek')}
              {localRecordings.length})
            </h3>
          </div>
          <div className="p-4">
            <div className="space-y-2">
              {localRecordings.map((rec) => (
                <div
                  key={rec.transactionId}
                  className="flex items-center justify-between p-3 bg-muted/50 rounded-lg"
                >
                  <div className="space-y-1">
                    <p className="font-medium">
                      {t('camera.tranzakcio')}
                      {rec.transactionId}
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {rec.date} -- {formatDate(rec.createdAt)}
                    </p>
                  </div>
                  <div className="flex items-center gap-3">
                    <p className="text-sm text-muted-foreground">
                      {formatFileSize(rec.fileSizeBytes)}
                    </p>
                    <button
                      className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90"
                      onClick={() => playLocalFile(rec.filePath)}
                    >
                      <PlayCircle className="h-4 w-4 mr-1" />
                      {t('camera.lejatszas')}
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
              {t('camera.szerverenTaroltFelvetelek')}
              {filteredServerRecordings.length})
            </h3>
          </div>
          <div className="p-4">
            {distinctCameraIds.length > 0 && (
              <div
                className="mb-3 flex flex-wrap items-center gap-2"
                aria-label={t('camera.kameraValaszto')}
              >
                <button
                  type="button"
                  className={`rounded-md border px-3 py-1 text-sm ${
                    selectedCameraId === 'ALL' ? 'bg-primary text-primary-foreground' : 'bg-card'
                  }`}
                  onClick={() => setSelectedCameraId('ALL')}
                  data-testid="camera-switch-ALL"
                >
                  {t('camera.mindKamera')}
                </button>
                {distinctCameraIds.map((cameraId) => (
                  <button
                    key={cameraId}
                    type="button"
                    className={`rounded-md border px-3 py-1 text-sm ${
                      selectedCameraId === cameraId
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-card'
                    }`}
                    onClick={() => setSelectedCameraId(cameraId)}
                    data-testid={`camera-switch-${cameraId}`}
                  >
                    {cameraId}
                  </button>
                ))}
              </div>
            )}
            <div className="space-y-2">
              {filteredServerRecordings.map((rec) => (
                <button
                  key={rec.id}
                  type="button"
                  onClick={() => void selectServerRecording(rec)}
                  className="flex w-full items-center justify-between rounded-lg bg-muted/50 p-3 text-left hover:bg-muted"
                  data-testid={`camera-server-recording-${rec.id}`}
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium">{rec.cameraId}</span>
                      <span
                        className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          rec.status === 'COMPLETED'
                            ? 'bg-primary text-primary-foreground'
                            : 'bg-secondary text-secondary-foreground'
                        }`}
                      >
                        {rec.status}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {formatDate(rec.startTime)} -- {formatDate(rec.endTime)}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm">{formatFileSize(rec.fileSizeBytes)}</p>
                    <p className="text-xs text-muted-foreground">
                      {rec.linkedTransactions} {t('camera.tranzakcio')}
                    </p>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {showReviewPanel && lastServerDateSearch && (
        <CameraReviewPanel
          branchId={lastServerDateSearch.branchId}
          date={lastServerDateSearch.startDate}
          cameraIds={distinctCameraIds}
        />
      )}

      {transactionLinks.length > 0 && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <FileVideo className="h-5 w-5" />
              {t('camera.kapcsoltFelvetelek')} ({transactionLinks.length})
            </h3>
          </div>
          <div className="space-y-2 p-4">
            {transactionLinks.map((link) => {
              const recording = recordingFromLink(link)
              return (
                <button
                  key={link.id}
                  type="button"
                  onClick={() => recording && void selectServerRecording(recording)}
                  disabled={!recording}
                  className="flex w-full items-center justify-between rounded-lg bg-muted/50 p-3 text-left hover:bg-muted disabled:cursor-not-allowed disabled:opacity-60"
                  data-testid={`camera-linked-recording-${link.id}`}
                >
                  <div className="space-y-1">
                    <p className="font-medium">
                      {link.receiptNumber ?? link.transactionId ?? link.id}
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {formatDate(link.transactionTime ?? null)}
                      {link.frameOffsetSeconds != null ? ` +${link.frameOffsetSeconds}s` : ''}
                    </p>
                  </div>
                  <div className="text-right text-sm">
                    <p>{recording?.cameraId ?? t('camera.nincsFelvetelAdat')}</p>
                    <p className="text-xs text-muted-foreground">{recording?.status ?? '-'}</p>
                  </div>
                </button>
              )
            })}
          </div>
        </div>
      )}

      {selectedRecording && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">{t('camera.felvetelReszletek')}</h3>
          </div>
          <div className="grid grid-cols-1 gap-3 p-4 text-sm md:grid-cols-3">
            <div>
              <div className="text-muted-foreground">{t('camera.kameraId')}</div>
              <div className="font-mono">{selectedRecording.cameraId}</div>
            </div>
            <div>
              <div className="text-muted-foreground">{t('common.status')}</div>
              <div className="font-semibold">{selectedRecording.status}</div>
            </div>
            <div>
              <div className="text-muted-foreground">{t('camera.hozzaferesiNaplobejegyzesek')}</div>
              <div className="font-semibold" data-testid="camera-access-log-count">
                {accessLogs.length}
              </div>
            </div>
          </div>
        </div>
      )}

      {!loading && !hasResults && (
        <div className="text-center py-12 text-muted-foreground">
          {t('camera.hasznaljaAKeresotFelvetelekMegjelenitesehez')}
        </div>
      )}
    </div>
  )
}
