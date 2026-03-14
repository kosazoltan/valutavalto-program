import { useState } from 'react'
import { Search, PlayCircle, Calendar, FileVideo, Receipt } from 'lucide-react'
import { api } from '../../services/api'

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

interface TransactionLink {
  id: string
  transactionId: string
  receiptNumber: string
  transactionTime: string
  frameOffsetSeconds: number
}

export default function CameraPlaybackPage() {
  const [searchMode, setSearchMode] = useState<'date' | 'receipt'>('date')
  const [branchId, setBranchId] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [receiptNumber, setReceiptNumber] = useState('')
  const [recordings, setRecordings] = useState<RecordingMetadata[]>([])
  const [links, setLinks] = useState<TransactionLink[]>([])
  const [loading, setLoading] = useState(false)

  const searchByDate = async () => {
    if (!branchId || !startDate || !endDate) return
    setLoading(true)
    try {
      const params = new URLSearchParams({
        branchId,
        start: startDate + 'T00:00:00',
        end: endDate + 'T23:59:59',
      })
      const res = await api.get(`/camera/recordings?${params}`)
      setRecordings(res.data)
      setLinks([])
    } catch (err) {
      console.error('Kereses sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const searchByReceipt = async () => {
    if (!receiptNumber) return
    setLoading(true)
    try {
      const res = await api.get(`/camera/recordings/by-receipt/${receiptNumber}`)
      setLinks(res.data)
      setRecordings([])
    } catch (err) {
      console.error('Kereses sikertelen:', err)
    } finally {
      setLoading(false)
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

  const statusBadgeClass = (status: string) => {
    if (status === 'COMPLETED') return 'bg-primary text-primary-foreground'
    if (status === 'RECORDING') return 'bg-destructive text-destructive-foreground'
    return 'bg-secondary text-secondary-foreground'
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold flex items-center gap-2">
        <PlayCircle className="h-6 w-6" />
        Felvetel visszajatszas
      </h1>

      {/* Search controls */}
      <div className="rounded-lg border bg-card shadow-sm">
        <div className="p-4 pb-2">
          <h3 className="text-lg font-semibold">Kereses</h3>
        </div>
        <div className="p-4 space-y-4">
          <div className="flex gap-2">
            <button
              className={`inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium ${
                searchMode === 'date'
                  ? 'bg-primary text-primary-foreground hover:bg-primary/90'
                  : 'border hover:bg-muted'
              } disabled:opacity-50`}
              onClick={() => setSearchMode('date')}
            >
              <Calendar className="h-4 w-4 mr-2" />
              Datum szerint
            </button>
            <button
              className={`inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium ${
                searchMode === 'receipt'
                  ? 'bg-primary text-primary-foreground hover:bg-primary/90'
                  : 'border hover:bg-muted'
              } disabled:opacity-50`}
              onClick={() => setSearchMode('receipt')}
            >
              <Receipt className="h-4 w-4 mr-2" />
              Bizonylatszam szerint
            </button>
          </div>

          {searchMode === 'date' ? (
            <div className="flex gap-3 items-end">
              <div>
                <label className="text-sm font-medium">Iroda ID</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={branchId}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setBranchId(e.target.value)}
                  placeholder="Branch UUID"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Kezdo datum</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="date"
                  value={startDate}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setStartDate(e.target.value)}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Zaro datum</label>
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
                disabled={loading}
              >
                <Search className="h-4 w-4 mr-2" />
                Kereses
              </button>
            </div>
          ) : (
            <div className="flex gap-3 items-end">
              <div className="flex-1">
                <label className="text-sm font-medium">Bizonylatszam</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={receiptNumber}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setReceiptNumber(e.target.value)}
                  placeholder="pl. BIZ-2026-001234"
                />
              </div>
              <button
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={searchByReceipt}
                disabled={loading}
              >
                <Search className="h-4 w-4 mr-2" />
                Kereses
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Results */}
      {recordings.length > 0 && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <FileVideo className="h-5 w-5" />
              Felvetelek ({recordings.length})
            </h3>
          </div>
          <div className="p-4">
            <div className="space-y-2">
              {recordings.map((rec) => (
                <div key={rec.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium">{rec.cameraId}</span>
                      <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusBadgeClass(rec.status)}`}>
                        {rec.status}
                      </span>
                      {rec.uploadedToServer && (
                        <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium border bg-transparent">Feltoltve</span>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {formatDate(rec.startTime)} -- {formatDate(rec.endTime)}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm">{formatFileSize(rec.fileSizeBytes)}</p>
                    <p className="text-xs text-muted-foreground">{rec.linkedTransactions} tranzakcio</p>
                    <p className="text-xs text-muted-foreground">Lejar: {rec.expiresAt}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {links.length > 0 && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">Tranzakcio linkek ({links.length})</h3>
          </div>
          <div className="p-4">
            <div className="space-y-2">
              {links.map((link) => (
                <div key={link.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                  <div>
                    <p className="font-medium">Bizonylat: {link.receiptNumber}</p>
                    <p className="text-sm text-muted-foreground">{formatDate(link.transactionTime)}</p>
                  </div>
                  <div className="text-right text-sm text-muted-foreground">
                    Frame offset: {link.frameOffsetSeconds}s
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {!loading && recordings.length === 0 && links.length === 0 && (
        <div className="text-center py-12 text-muted-foreground">
          Hasznalja a keresot felvetelek megjelenitisehez
        </div>
      )}
    </div>
  )
}
