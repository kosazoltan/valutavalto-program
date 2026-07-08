import { useCallback, useEffect, useMemo, useRef, useState, type ChangeEvent } from 'react'
import { Ban, Check, Upload } from 'lucide-react'
import { toast } from '../../../components/ui/toaster'
import { logger } from '../../../utils/logger'
import { getErrorMessage } from '../../../utils/errorHandling'
import {
  currencyDenominationImageApi,
  type Currency,
  type CurrencyDenominationImageDto,
  type CurrencyDenominationSide,
  type CurrencyDenominationType,
} from '../../../services/api/exchange-rates'

interface CurrencyDenominationImagesPanelProps {
  currency: Currency | null
}

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png'])

function formatFileSize(fileSizeBytes: number): string {
  if (!Number.isFinite(fileSizeBytes) || fileSizeBytes < 0) return '-'
  if (fileSizeBytes < 1024) return `${fileSizeBytes} B`
  return `${(fileSizeBytes / 1024).toFixed(1)} KB`
}

function getTypeLabel(type: string): string {
  if (type === 'BANKNOTE') return 'Bankjegy'
  if (type === 'COIN') return 'Érme'
  return type
}

function getSideLabel(side: string): string {
  if (side === 'FRONT') return 'Előlap'
  if (side === 'BACK') return 'Hátlap'
  return side
}

export default function CurrencyDenominationImagesPanel({ currency }: CurrencyDenominationImagesPanelProps) {
  const [images, setImages] = useState<CurrencyDenominationImageDto[]>([])
  const [loading, setLoading] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [faceValue, setFaceValue] = useState('')
  const [denominationType, setDenominationType] = useState<CurrencyDenominationType>('BANKNOTE')
  const [side, setSide] = useState<CurrencyDenominationSide>('FRONT')
  const [file, setFile] = useState<File | null>(null)
  const [fileInputKey, setFileInputKey] = useState(0)
  const [thumbUrls, setThumbUrls] = useState<Record<string, string>>({})
  const [togglingId, setTogglingId] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement | null>(null)
  const urlsRef = useRef<string[]>([])
  const requestVersionRef = useRef(0)
  const togglingIdRef = useRef<string | null>(null)

  const revokeAll = useCallback(() => {
    for (const url of urlsRef.current) {
      try { URL.revokeObjectURL(url) } catch { /* best-effort */ }
    }
    urlsRef.current = []
  }, [])

  const refresh = useCallback(async (currencyId: number) => {
    const requestVersion = ++requestVersionRef.current
    setLoading(true)
    try {
      const list = await currencyDenominationImageApi.list(currencyId)
      if (requestVersion !== requestVersionRef.current) return

      revokeAll()
      setThumbUrls({})
      setImages(list)

      const entries = await Promise.all(
        list.map(async (image): Promise<readonly [string, string] | null> => {
          const blob = await currencyDenominationImageApi.getThumbnail(image.id)
          if (requestVersion !== requestVersionRef.current) return null
          const url = URL.createObjectURL(blob)
          urlsRef.current.push(url)
          return [image.id, url] as const
        }),
      )

      if (requestVersion !== requestVersionRef.current) return
      const nextThumbUrls: Record<string, string> = {}
      for (const entry of entries) {
        if (entry != null) nextThumbUrls[entry[0]] = entry[1]
      }
      setThumbUrls(nextThumbUrls)
    } catch (err) {
      if (requestVersion === requestVersionRef.current) {
        logger.error('CurrencyDenominationImagesPanel', 'list/thumbnail failed', getErrorMessage(err))
        toast.error('Hiba', getErrorMessage(err))
      }
    } finally {
      if (requestVersion === requestVersionRef.current) setLoading(false)
    }
  }, [revokeAll])

  useEffect(() => {
    if (!currency) {
      requestVersionRef.current += 1
      setImages([])
      setThumbUrls({})
      revokeAll()
      return undefined
    }

    void refresh(currency.id)
    return () => {
      requestVersionRef.current += 1
      revokeAll()
    }
  }, [currency, refresh, revokeAll])

  const numericFaceValue = Number(faceValue)
  const canUpload = useMemo(
    () =>
      currency != null &&
      faceValue !== '' &&
      Number.isFinite(numericFaceValue) &&
      numericFaceValue > 0 &&
      file != null &&
      ALLOWED_MIME_TYPES.has(file.type) &&
      (denominationType === 'BANKNOTE' || denominationType === 'COIN') &&
      (side === 'FRONT' || side === 'BACK') &&
      !uploading,
    [currency, denominationType, faceValue, file, numericFaceValue, side, uploading],
  )

  const handleFileChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setFile(event.target.files?.[0] ?? null)
  }, [])

  const handleUpload = useCallback(async () => {
    if (!canUpload || !currency || !file) return

    setUploading(true)
    try {
      await currencyDenominationImageApi.upload({
        currencyId: currency.id,
        faceValue: numericFaceValue,
        denominationType,
        side,
        file,
      })
      toast.success('Sikeres', 'Címletkép feltöltve')
      setFaceValue('')
      setFile(null)
      setFileInputKey((current) => current + 1)
      if (fileInputRef.current) fileInputRef.current.value = ''
      await refresh(currency.id)
    } catch (err) {
      logger.error('CurrencyDenominationImagesPanel', 'upload failed', getErrorMessage(err))
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setUploading(false)
    }
  }, [canUpload, currency, denominationType, file, numericFaceValue, refresh, side])

  const handleToggleActive = useCallback(async (image: CurrencyDenominationImageDto) => {
    if (!currency || togglingIdRef.current) return

    togglingIdRef.current = image.id
    setTogglingId(image.id)
    try {
      await currencyDenominationImageApi.setActive(image.id, !image.active)
      toast.success('Sikeres', image.active ? 'Címletkép inaktiválva' : 'Címletkép aktiválva')
      await refresh(currency.id)
    } catch (err) {
      logger.error('CurrencyDenominationImagesPanel', 'setActive failed', getErrorMessage(err))
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      togglingIdRef.current = null
      setTogglingId(null)
    }
  }, [currency, refresh])

  if (!currency) {
    return (
      <div
        className="rounded-md border border-dashed border-gray-300 p-3 text-sm text-gray-500 dark:border-gray-700 dark:text-gray-400"
        data-testid="denomination-images-empty"
      >
        Válassz valutát a címletképek kezeléséhez
      </div>
    )
  }

  return (
    <div className="rounded-md border border-gray-200 dark:border-gray-700 p-3 space-y-3">
      <div className="flex items-center justify-between gap-2">
        <div>
          <div className="text-sm font-semibold">Címletképek — {currency.code}</div>
          <div className="text-xs text-gray-500 dark:text-gray-400">JPEG/PNG elő- és hátoldali képek kezelése</div>
        </div>
        {loading && <span className="text-xs text-gray-500">Betöltés...</span>}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-5 gap-2 items-end">
        <div>
          <label className="text-xs block mb-0.5">Címlet *</label>
          <input
            type="number"
            min="0"
            step="any"
            value={faceValue}
            onChange={(event) => setFaceValue(event.target.value)}
            className="form-input w-full"
            data-testid="denomination-face-value"
          />
        </div>
        <div>
          <label className="text-xs block mb-0.5">Típus *</label>
          <select
            value={denominationType}
            onChange={(event) => setDenominationType(event.target.value as CurrencyDenominationType)}
            className="form-input w-full"
            data-testid="denomination-type"
          >
            <option value="BANKNOTE">Bankjegy</option>
            <option value="COIN">Érme</option>
          </select>
        </div>
        <div>
          <label className="text-xs block mb-0.5">Oldal *</label>
          <select
            value={side}
            onChange={(event) => setSide(event.target.value as CurrencyDenominationSide)}
            className="form-input w-full"
            data-testid="denomination-side"
          >
            <option value="FRONT">Előlap</option>
            <option value="BACK">Hátlap</option>
          </select>
        </div>
        <div>
          <label className="text-xs block mb-0.5">Kép *</label>
          <input
            key={fileInputKey}
            ref={fileInputRef}
            type="file"
            accept="image/png,image/jpeg"
            onChange={handleFileChange}
            className="form-input w-full text-xs"
            data-testid="denomination-image-file"
          />
        </div>
        <button
          type="button"
          onClick={() => void handleUpload()}
          disabled={!canUpload}
          className="form-button-primary flex items-center justify-center gap-1 disabled:opacity-50"
          data-testid="denomination-image-upload-button"
        >
          <Upload size={16} />
          {uploading ? 'Feltöltés...' : 'Feltöltés'}
        </button>
      </div>

      <div className="space-y-2">
        {images.length === 0 && !loading ? (
          <div className="rounded border border-gray-200 p-3 text-xs text-gray-500 dark:border-gray-700">
            Nincs címletkép ehhez a valutához
          </div>
        ) : null}
        {images.map((image) => (
          <div
            key={image.id}
            className="grid grid-cols-1 md:grid-cols-[88px_1fr_auto] gap-3 rounded border border-gray-200 dark:border-gray-700 p-2 text-sm"
            data-testid={`denomination-image-row-${image.id}`}
          >
            {thumbUrls[image.id] ? (
              <img
                src={thumbUrls[image.id]}
                alt={`${currency.code} ${image.faceValue} ${getSideLabel(image.side)}`}
                className="h-20 w-20 rounded border border-gray-200 object-contain bg-white"
              />
            ) : (
              <div className="flex h-20 w-20 items-center justify-center rounded border border-gray-200 bg-gray-50 text-xs text-gray-400">
                Kép...
              </div>
            )}
            <div className="space-y-1">
              <div className="font-semibold">
                {image.faceValue} {currency.code} — {getTypeLabel(image.denominationType)} / {getSideLabel(image.side)}
              </div>
              <div className="text-xs text-gray-500 dark:text-gray-400">
                {image.mimeType} · {formatFileSize(image.fileSizeBytes)}
              </div>
              <div>
                {image.active ? (
                  <span className="inline-flex items-center gap-1 text-green-700 dark:text-green-400 text-xs">
                    <Check size={14} /> aktív
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 text-gray-500 text-xs">
                    <Ban size={14} /> inaktív
                  </span>
                )}
              </div>
            </div>
            <div className="flex items-center justify-end">
              <button
                type="button"
                onClick={() => void handleToggleActive(image)}
                disabled={togglingId === image.id}
                className="text-xs px-2 py-1 rounded bg-amber-100 hover:bg-amber-200 text-amber-900 dark:bg-amber-900 dark:text-amber-100 disabled:opacity-50"
                data-testid={`denomination-image-toggle-${image.id}`}
              >
                {image.active ? 'Inaktivál' : 'Aktivál'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
