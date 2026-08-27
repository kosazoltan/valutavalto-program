import { useEffect, useMemo, useState } from 'react'
import { CheckCircle2, Clock, Flag, Trash2 } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

interface CameraReviewPanelProps {
  branchId: string
  date: string
  cameraIds: string[]
}

interface CameraReviewMark {
  id: string
  branchId: string
  reviewDate: string
  cameraId: string
  markTime: string
  openingClosingOk: boolean
  invoicesOk: boolean
  breaksOk: boolean
  boardOk: boolean
  curtainOk: boolean
  note?: string | null
  createdByWorkerId?: number | null
  createdByWorkerCode?: string | null
  createdAt?: string | null
  problematic: boolean
}

interface ReviewStatus {
  reviewed: boolean
  reviewedByWorkerId?: number | null
  reviewedByWorkerCode?: string | null
  reviewedAt?: string | null
}

interface ReviewTransaction {
  id: string
  transactionId?: number | null
  receiptNumber?: string | null
  transactionTime?: string | null
  frameOffsetSeconds?: number | null
  cameraId?: string | null
  recordingId?: string | null
}

interface ConditionConfig {
  key: keyof Pick<
    CameraReviewMark,
    'openingClosingOk' | 'invoicesOk' | 'breaksOk' | 'boardOk' | 'curtainOk'
  >
  labelKey: string
}

const CONDITIONS: ConditionConfig[] = [
  { key: 'openingClosingOk', labelKey: 'camera.feltetelNyitasZaras' },
  { key: 'invoicesOk', labelKey: 'camera.feltetelSzamlak' },
  { key: 'breaksOk', labelKey: 'camera.feltetelSzunetek' },
  { key: 'boardOk', labelKey: 'camera.feltetelTabla' },
  { key: 'curtainOk', labelKey: 'camera.feltetelFuggony' },
]

const initialConditionState = {
  openingClosingOk: true,
  invoicesOk: true,
  breaksOk: true,
  boardOk: true,
  curtainOk: true,
}

type ConditionState = typeof initialConditionState

function formatDisplayDate(value?: string | null): string {
  if (!value) return '-'
  return new Date(value).toLocaleString('hu-HU')
}

function normalizeTime(value: string): string {
  if (/^\d{2}:\d{2}:\d{2}$/.test(value)) return value
  if (/^\d{2}:\d{2}$/.test(value)) return `${value}:00`
  return value
}

function transactionTimeKey(tx: ReviewTransaction): string {
  return tx.transactionTime?.slice(11, 19) ?? '99:99:99'
}

export default function CameraReviewPanel({ branchId, date, cameraIds }: CameraReviewPanelProps) {
  const { t } = useTranslation()
  const currentWorkerId = useAuthStore((state) => state.worker?.id ?? null)
  const [marks, setMarks] = useState<CameraReviewMark[]>([])
  const [transactions, setTransactions] = useState<ReviewTransaction[]>([])
  const [status, setStatus] = useState<ReviewStatus>({ reviewed: false })
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [markTime, setMarkTime] = useState('08:00:00')
  const [selectedCameraId, setSelectedCameraId] = useState(cameraIds[0] ?? '')
  const [conditions, setConditions] = useState<ConditionState>(initialConditionState)
  const [note, setNote] = useState('')

  const effectiveCameraIds = useMemo(() => {
    const ids = new Set(cameraIds.filter(Boolean))
    marks.forEach((mark) => ids.add(mark.cameraId))
    transactions.forEach((tx) => {
      if (tx.cameraId) ids.add(tx.cameraId)
    })
    return Array.from(ids).sort()
  }, [cameraIds, marks, transactions])

  useEffect(() => {
    if (effectiveCameraIds.length > 0 && !effectiveCameraIds.includes(selectedCameraId)) {
      setSelectedCameraId(effectiveCameraIds[0] ?? '')
    }
  }, [effectiveCameraIds, selectedCameraId])

  const fetchReviewData = async () => {
    if (!branchId || !date) return
    setLoading(true)
    try {
      const params = new URLSearchParams({ branchId, date })
      const [marksResult, statusResult, txResult] = await Promise.all([
        api.get<CameraReviewMark[]>(`/camera/review/marks?${params}`),
        api.get<ReviewStatus>(`/camera/review/status?${params}`),
        api.get<ReviewTransaction[]>(`/camera/review/transactions?${params}`),
      ])
      setMarks(
        (marksResult.data ?? []).slice().sort((a, b) => a.markTime.localeCompare(b.markTime)),
      )
      setStatus(statusResult.data ?? { reviewed: false })
      setTransactions(
        (txResult.data ?? [])
          .slice()
          .sort((a, b) => transactionTimeKey(a).localeCompare(transactionTimeKey(b))),
      )
    } catch (err) {
      logger.error(
        'CameraReviewPanel',
        'Átnézési adatok betöltése sikertelen:',
        getErrorMessage(err),
      )
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void fetchReviewData()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [branchId, date])

  const createMark = async () => {
    if (!selectedCameraId || saving) return
    setSaving(true)
    try {
      await api.post('/camera/review/marks', {
        branchId,
        reviewDate: date,
        cameraId: selectedCameraId,
        markTime: normalizeTime(markTime),
        ...conditions,
        note: note.trim() || null,
      })
      setConditions(initialConditionState)
      setNote('')
      await fetchReviewData()
    } catch (err) {
      logger.error('CameraReviewPanel', 'Megjelölés mentése sikertelen:', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const deleteMark = async (markId: string) => {
    if (saving) return
    setSaving(true)
    try {
      await api.delete(`/camera/review/marks/${markId}`)
      await fetchReviewData()
    } catch (err) {
      logger.error('CameraReviewPanel', 'Megjelölés törlése sikertelen:', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const toggleReviewed = async (reviewed: boolean) => {
    setStatus((current) => ({ ...current, reviewed }))
    try {
      const result = await api.put<ReviewStatus>('/camera/review/status', {
        branchId,
        reviewDate: date,
        reviewed,
      })
      setStatus(result.data ?? { reviewed })
    } catch (err) {
      setStatus((current) => ({ ...current, reviewed: !reviewed }))
      logger.error('CameraReviewPanel', 'Átnézve státusz mentése sikertelen:', getErrorMessage(err))
    }
  }

  const timeline = useMemo(() => {
    const txItems = transactions.map((tx) => ({
      type: 'transaction' as const,
      time: transactionTimeKey(tx),
      tx,
    }))
    const markItems = marks.map((mark) => ({ type: 'mark' as const, time: mark.markTime, mark }))
    return [...txItems, ...markItems].sort((a, b) => a.time.localeCompare(b.time))
  }, [marks, transactions])

  return (
    <section className="rounded-lg border bg-card shadow-sm" data-testid="camera-review-panel">
      <div className="flex flex-wrap items-start justify-between gap-3 p-4 pb-2">
        <div>
          <h3 className="flex items-center gap-2 text-lg font-semibold">
            <Flag className="h-5 w-5" />
            {t('camera.megjelolesek')}
          </h3>
          <p className="text-sm text-muted-foreground">
            {date} · {branchId}
          </p>
        </div>
        <label className="flex items-center gap-2 rounded-md border px-3 py-2 text-sm font-medium">
          <input
            type="checkbox"
            checked={status.reviewed}
            onChange={(event) => void toggleReviewed(event.target.checked)}
            data-testid="review-status-checkbox"
          />
          {t('camera.atnezve')}
          {status.reviewedByWorkerCode && (
            <span className="text-muted-foreground">
              {status.reviewedByWorkerCode} · {formatDisplayDate(status.reviewedAt)}
            </span>
          )}
        </label>
      </div>

      <div className="grid gap-4 p-4 lg:grid-cols-[minmax(0,1fr)_minmax(320px,0.9fr)]">
        <div className="space-y-4">
          <div className="rounded-md border p-3">
            <div className="grid gap-3 md:grid-cols-3">
              <label className="grid gap-1 text-sm font-medium">
                {t('camera.megjelolesIdopontja')}
                <input
                  className="h-10 rounded-md border px-3 py-2 text-sm"
                  type="time"
                  step="1"
                  value={markTime}
                  onChange={(event) => setMarkTime(normalizeTime(event.target.value))}
                  data-testid="review-mark-form-time"
                />
              </label>
              <label className="grid gap-1 text-sm font-medium">
                {t('camera.kameraId')}
                <select
                  className="h-10 rounded-md border px-3 py-2 text-sm"
                  value={selectedCameraId}
                  onChange={(event) => setSelectedCameraId(event.target.value)}
                  aria-label={t('camera.kameraId')}
                >
                  {effectiveCameraIds.map((cameraId) => (
                    <option key={cameraId} value={cameraId}>
                      {cameraId}
                    </option>
                  ))}
                </select>
              </label>
              <label className="grid gap-1 text-sm font-medium md:col-span-3">
                {t('camera.megjegyzes')}
                <input
                  className="h-10 rounded-md border px-3 py-2 text-sm"
                  value={note}
                  onChange={(event) => setNote(event.target.value)}
                />
              </label>
            </div>

            <div className="mt-3 grid gap-2 md:grid-cols-2">
              {CONDITIONS.map((condition) => (
                <label
                  key={condition.key}
                  className="flex items-center justify-between gap-3 text-sm"
                >
                  <span>{t(condition.labelKey)}</span>
                  <select
                    className="h-9 rounded-md border px-2 text-sm"
                    value={conditions[condition.key] ? 'ok' : 'bad'}
                    onChange={(event) =>
                      setConditions((current) => ({
                        ...current,
                        [condition.key]: event.target.value === 'ok',
                      }))
                    }
                    aria-label={t(condition.labelKey)}
                  >
                    <option value="ok">{t('camera.rendben')}</option>
                    <option value="bad">{t('camera.nincsRendben')}</option>
                  </select>
                </label>
              ))}
            </div>

            <button
              type="button"
              className="mt-3 inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
              onClick={() => void createMark()}
              disabled={saving || loading || !selectedCameraId}
              data-testid="review-mark-submit"
            >
              {t('camera.megjelolesMentese')}
            </button>
          </div>

          <div className="space-y-2">
            {marks.map((mark) => (
              <div
                key={mark.id}
                className="rounded-md border bg-muted/30 p-3"
                data-testid={`review-mark-row-${mark.id}`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-mono text-sm font-semibold">{mark.markTime}</span>
                      <span className="text-sm font-medium">{mark.cameraId}</span>
                      {mark.problematic && (
                        <span
                          className="rounded-full border border-red-200 bg-red-100 px-2 py-0.5 text-xs font-medium text-red-800"
                          data-testid={`review-mark-problem-${mark.id}`}
                        >
                          {t('camera.problemasEset')}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {mark.createdByWorkerCode ?? '-'} · {formatDisplayDate(mark.createdAt)}
                    </p>
                    {mark.note && <p className="mt-1 text-sm">{mark.note}</p>}
                  </div>
                  {mark.createdByWorkerId === currentWorkerId && (
                    <button
                      type="button"
                      className="inline-flex items-center rounded-md border px-2 py-1 text-xs hover:bg-muted disabled:opacity-50"
                      onClick={() => void deleteMark(mark.id)}
                      disabled={saving}
                      data-testid={`review-mark-delete-${mark.id}`}
                    >
                      <Trash2 className="mr-1 h-3 w-3" />
                      {t('camera.megjelolesTorlese')}
                    </button>
                  )}
                </div>
                <div className="mt-2 flex flex-wrap gap-1 text-xs">
                  {CONDITIONS.map((condition) => (
                    <span
                      key={condition.key}
                      className={`rounded-full px-2 py-0.5 ${
                        mark[condition.key]
                          ? 'bg-primary/10 text-primary'
                          : 'border border-red-200 bg-red-50 text-red-800'
                      }`}
                    >
                      {t(condition.labelKey)}:{' '}
                      {mark[condition.key] ? t('camera.rendben') : t('camera.nincsRendben')}
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-md border p-3">
          <h4 className="mb-3 flex items-center gap-2 font-semibold">
            <Clock className="h-4 w-4" />
            {t('camera.tranzakcioIdovonal')}
          </h4>
          <div className="space-y-2">
            {timeline.map((item) =>
              item.type === 'transaction' ? (
                <div
                  key={`tx-${item.tx.id}`}
                  className="rounded-md bg-muted/40 p-2 text-sm"
                  data-testid={`review-tx-row-${item.tx.id}`}
                >
                  <div className="font-medium">
                    {item.time} · {item.tx.receiptNumber ?? item.tx.transactionId ?? item.tx.id}
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {item.tx.cameraId ?? '-'}
                    {item.tx.frameOffsetSeconds != null ? ` · +${item.tx.frameOffsetSeconds}s` : ''}
                  </div>
                </div>
              ) : (
                <div
                  key={`mark-${item.mark.id}`}
                  className="rounded-md border border-primary/30 p-2 text-sm"
                >
                  <div className="flex items-center gap-2 font-medium">
                    <CheckCircle2 className="h-4 w-4" />
                    {item.mark.markTime} · {t('camera.megjeloles')}
                  </div>
                  <div className="text-xs text-muted-foreground">{item.mark.cameraId}</div>
                </div>
              ),
            )}
            {!loading && timeline.length === 0 && (
              <div className="text-sm text-muted-foreground">{t('camera.nincsBejegyzes')}</div>
            )}
          </div>
        </div>
      </div>
    </section>
  )
}
