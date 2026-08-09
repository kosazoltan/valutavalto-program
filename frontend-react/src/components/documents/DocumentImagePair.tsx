import { useCallback, useEffect, useRef, useState } from 'react'
import { documentScannerApi } from '../../services/api/index'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'
import { toast } from '../ui/toaster'

/**
 * FS-5: Okmány elő/hátlap képpár — thumbnail nézet + kódos (supervisor-PIN) nagyítás.
 *
 * A thumbnail szabadon megtekinthető. A full-res nagyításhoz törvényi okból
 * egyszer-használatos engedély (view-grant) kell, amit egy supervisor/manager/admin
 * PIN-je állít ki. Minden oldal nagyítása külön grant-et fogyaszt (auditált).
 */

interface DocumentImagePairProps {
  documentId: string
  hasFront: boolean
  hasBack: boolean
}

type Side = 'FRONT' | 'BACK'

interface EligibleApprover {
  id: number
  role?: string
  fullName?: string
  firstName?: string
  lastName?: string
}

const ELIGIBLE_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
const PIN_LENGTH = 6

function approverLabel(a: EligibleApprover): string {
  if (a.fullName && a.fullName.trim()) return a.fullName
  const composed = `${a.lastName ?? ''} ${a.firstName ?? ''}`.trim()
  return composed || `#${a.id}`
}

interface GrantModalProps {
  open: boolean
  side: Side
  onSubmit: (approverWorkerId: number, pin: string) => Promise<void>
  onCancel: () => void
}

function DocumentViewGrantModal({ open, side, onSubmit, onCancel }: GrantModalProps) {
  const { t } = useTranslation()
  const [approvers, setApprovers] = useState<EligibleApprover[]>([])
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [pin, setPin] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const pinRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (!open) return
    setSelectedId(null)
    setPin('')
    setError(null)
    setSubmitting(false)
    setLoading(true)
    void (async () => {
      try {
        const res = await api.get<EligibleApprover[]>('/workers/active')
        const list = Array.isArray(res.data) ? res.data : []
        setApprovers(list.filter((w) => w.role != null && ELIGIBLE_ROLES.includes(w.role)))
      } catch (err) {
        logger.warn(
          'DocumentViewGrantModal',
          'Engedélyező-lista betöltés hiba:',
          getErrorMessage(err),
        )
        setError(t('documents.nagyitasEngedelyezoListaHiba'))
      } finally {
        setLoading(false)
      }
    })()
    // Lint-audit 2026-08-09: a `t` csak a hibauzenethez kell; deps-be veve
    // nyelvvaltaskor ujra lekerne az engedelyezo-listat es torolne a mar
    // bepotyogtetett PIN-t. A megnyitas (`open`) a helyes trigger.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  if (!open) return null

  const handleSubmit = async () => {
    if (selectedId == null || pin.length < PIN_LENGTH) return
    setSubmitting(true)
    setError(null)
    try {
      await onSubmit(selectedId, pin)
    } catch (err) {
      logger.warn('DocumentViewGrantModal', 'view-grant hiba:', getErrorMessage(err))
      const body = (err as { response?: { data?: { error?: string } } }).response?.data
      setError(body?.error ?? t('documents.nagyitasHibasPin'))
      setPin('')
    } finally {
      setSubmitting(false)
    }
  }

  const handlePinChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPin(e.target.value.replace(/\D/g, '').slice(0, PIN_LENGTH))
    setError(null)
  }

  const sideLabel = side === 'FRONT' ? t('documents.elolap') : t('documents.hatlap')

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="doc-view-grant-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-md rounded-lg bg-white p-6 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="doc-view-grant-title" className="mb-2 text-lg font-bold text-amber-800">
          {t('documents.nagyitasEngedelyKell')} — {sideLabel}
        </h2>
        <p className="mb-3 rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
          {t('documents.nagyitasTorvenyiFigyelmeztetes')}
        </p>
        <p className="mb-3 text-sm text-gray-600">{t('documents.nagyitasLeiras')}</p>

        {loading ? (
          <p className="py-4 text-center text-gray-500">
            {t('documents.nagyitasEngedelyezokBetoltese')}
          </p>
        ) : (
          <>
            <label
              className="mb-1 block text-sm font-semibold text-gray-700"
              htmlFor="doc-grant-approver"
            >
              {t('documents.nagyitasEngedelyezo')}
            </label>
            <select
              id="doc-grant-approver"
              value={selectedId ?? ''}
              onChange={(e) => {
                setSelectedId(e.target.value ? Number(e.target.value) : null)
                setError(null)
                setTimeout(() => pinRef.current?.focus(), 50)
              }}
              disabled={submitting}
              className="mb-3 w-full rounded border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none disabled:opacity-50"
            >
              <option value="">— {t('documents.nagyitasValasszonEngedelyezot')}</option>
              {approvers.map((a) => (
                <option key={a.id} value={a.id}>
                  {approverLabel(a)} ({a.role})
                </option>
              ))}
            </select>
            {approvers.length === 0 && (
              <p className="mb-3 text-sm text-amber-700">
                {t('documents.nagyitasNincsEngedelyezo')}
              </p>
            )}

            <label
              className="mb-1 block text-sm font-semibold text-gray-700"
              htmlFor="doc-grant-pin"
            >
              {t('documents.nagyitasPin')}
            </label>
            <input
              ref={pinRef}
              id="doc-grant-pin"
              type="password"
              inputMode="numeric"
              autoComplete="off"
              value={pin}
              onChange={handlePinChange}
              onKeyDown={(e) => {
                if (e.key === 'Enter') void handleSubmit()
                else if (e.key === 'Escape') onCancel()
              }}
              disabled={submitting || selectedId == null}
              placeholder="••••••"
              className="mb-3 w-full rounded border border-gray-300 px-3 py-2 text-center text-2xl tracking-widest font-mono focus:border-blue-500 focus:outline-none disabled:opacity-50"
              maxLength={PIN_LENGTH}
            />
          </>
        )}

        {error && (
          <div className="mb-3 rounded border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800">
            {error}
          </div>
        )}

        <div className="flex justify-end space-x-2">
          <button
            onClick={onCancel}
            disabled={submitting}
            className="rounded border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50 disabled:opacity-50"
          >
            {t('common.cancel')}
          </button>
          <button
            onClick={() => void handleSubmit()}
            disabled={submitting || loading || selectedId == null || pin.length < PIN_LENGTH}
            className="rounded bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 disabled:opacity-50"
          >
            {submitting ? t('documents.nagyitasEllenorzes') : t('documents.nagyitasEngedelyezes')}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function DocumentImagePair({
  documentId,
  hasFront,
  hasBack,
}: DocumentImagePairProps) {
  const { t } = useTranslation()
  const [thumbFront, setThumbFront] = useState<string | null>(null)
  const [thumbBack, setThumbBack] = useState<string | null>(null)
  const [thumbError, setThumbError] = useState<string | null>(null)
  const [grantSide, setGrantSide] = useState<Side | null>(null)
  const [fullImage, setFullImage] = useState<{ side: Side; url: string } | null>(null)
  const urlsRef = useRef<string[]>([])

  const revokeAll = useCallback(() => {
    for (const url of urlsRef.current) {
      try {
        URL.revokeObjectURL(url)
      } catch {
        /* best-effort */
      }
    }
    urlsRef.current = []
  }, [])

  useEffect(() => {
    let cancelled = false
    const loadThumbs = async () => {
      try {
        if (hasFront) {
          const blob = await documentScannerApi.getThumbnail(documentId, 'FRONT')
          if (cancelled) return
          const url = URL.createObjectURL(blob)
          urlsRef.current.push(url)
          setThumbFront(url)
        }
        if (hasBack) {
          const blob = await documentScannerApi.getThumbnail(documentId, 'BACK')
          if (cancelled) return
          const url = URL.createObjectURL(blob)
          urlsRef.current.push(url)
          setThumbBack(url)
        }
      } catch (err) {
        logger.warn('DocumentImagePair', 'Thumbnail betöltés hiba:', getErrorMessage(err))
        if (!cancelled) setThumbError(t('documents.nagyitasThumbnailHiba'))
      }
    }
    void loadThumbs()
    return () => {
      cancelled = true
      revokeAll()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [documentId, hasFront, hasBack, revokeAll])

  const handleGrantSuccess = useCallback(
    async (approverWorkerId: number, pin: string) => {
      if (!grantSide) return
      // 1) Grant kiállítása (supervisor PIN ellenőrzés a backenden).
      await documentScannerApi.issueViewGrant(documentId, approverWorkerId, pin)
      // 2) CSAK sikeres grant után fetch-eljük a full-res képet (törvényi kapu).
      // A grant sikeres volt — a kép letöltésének hibája NEM PIN-hiba.
      try {
        const blob = await documentScannerApi.getFullImage(documentId, grantSide)
        const url = URL.createObjectURL(blob)
        urlsRef.current.push(url)
        setFullImage({ side: grantSide, url })
      } catch (imgErr) {
        logger.warn('DocumentImagePair', 'Full-res kép letöltés hiba:', getErrorMessage(imgErr))
        toast.error(t('documents.okmanyCaptureHiba'), t('documents.nagyitasKepLetoltesHiba'))
      } finally {
        setGrantSide(null)
      }
    },
    [documentId, grantSide, t],
  )

  const closeFullImage = useCallback(() => {
    if (fullImage) {
      const idx = urlsRef.current.indexOf(fullImage.url)
      if (idx >= 0) {
        try {
          URL.revokeObjectURL(fullImage.url)
        } catch {
          /* best-effort */
        }
        urlsRef.current.splice(idx, 1)
      }
    }
    setFullImage(null)
  }, [fullImage])

  const renderSide = (side: Side, has: boolean, thumbUrl: string | null, label: string) => {
    if (!has) return null
    return (
      <div className="flex flex-col items-center gap-2">
        <div className="text-sm font-semibold text-gray-700">{label}</div>
        {thumbUrl ? (
          <img
            src={thumbUrl}
            alt={label}
            className="max-h-48 rounded border border-gray-200 object-contain"
          />
        ) : thumbError ? (
          <div className="flex h-24 w-36 items-center justify-center rounded border border-red-200 bg-red-50 text-xs text-red-700">
            {thumbError}
          </div>
        ) : (
          <div className="flex h-24 w-36 items-center justify-center rounded border border-gray-200 bg-gray-50 text-xs text-gray-400">
            {t('documents.nagyitasBetoltes')}
          </div>
        )}
        <button
          type="button"
          onClick={() => setGrantSide(side)}
          className="rounded-lg bg-amber-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-amber-700"
        >
          {t('documents.nagyitasEngedelyKell')}
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-6">
        {renderSide('FRONT', hasFront, thumbFront, t('documents.elolap'))}
        {renderSide('BACK', hasBack, thumbBack, t('documents.hatlap'))}
      </div>

      <DocumentViewGrantModal
        open={grantSide != null}
        side={grantSide ?? 'FRONT'}
        onSubmit={handleGrantSuccess}
        onCancel={() => setGrantSide(null)}
      />

      {fullImage && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4"
          onClick={closeFullImage}
        >
          <div className="relative max-h-[90vh] max-w-4xl" onClick={(e) => e.stopPropagation()}>
            <div className="mb-2 flex items-center justify-between">
              <span className="text-sm font-semibold text-white">
                {fullImage.side === 'FRONT' ? t('documents.elolap') : t('documents.hatlap')} —{' '}
                {t('documents.nagyitas')}
              </span>
              <button
                onClick={closeFullImage}
                className="rounded border border-gray-300 bg-white px-3 py-1 text-xs"
              >
                {t('common.close')}
              </button>
            </div>
            <img
              src={fullImage.url}
              alt={fullImage.side === 'FRONT' ? t('documents.elolap') : t('documents.hatlap')}
              className="max-h-[80vh] max-w-full rounded object-contain"
            />
          </div>
        </div>
      )}
    </div>
  )
}
