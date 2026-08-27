import { useCallback, useEffect, useRef, useState } from 'react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import {
  currencyApi,
  currencyDenominationImageApi,
  type Currency,
  type CurrencyDenominationImageDto,
} from '../../services/api/exchange-rates'
import i18n from '../../i18n'

// FS-9 S3: pénztári READ-ONLY címletkép-nézegető — hamis bankjegy vizuális
// összevetéshez teljes méretű képek (nem thumbnail). Write endpoint hívás TILOS.

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

function compareImages(a: CurrencyDenominationImageDto, b: CurrencyDenominationImageDto): number {
  if (a.faceValue !== b.faceValue) return a.faceValue - b.faceValue
  if (a.side === b.side) return 0
  return a.side === 'FRONT' ? -1 : 1
}

export default function DenominationImagesPage() {
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [selectedCurrencyId, setSelectedCurrencyId] = useState<number | null>(null)
  const [images, setImages] = useState<CurrencyDenominationImageDto[]>([])
  const [imageUrls, setImageUrls] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(false)
  const urlsRef = useRef<string[]>([])
  const requestVersionRef = useRef(0)

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
    void (async () => {
      try {
        const list = await currencyApi.getAll()
        if (!cancelled) setCurrencies(list.filter((currency) => currency.active))
      } catch (err) {
        if (!cancelled) {
          logger.error('DenominationImagesPage', 'valutalista betöltés hiba', getErrorMessage(err))
          toast.error('Hiba', getErrorMessage(err))
        }
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  const loadImages = useCallback(
    async (currencyId: number) => {
      const requestVersion = ++requestVersionRef.current
      setLoading(true)
      try {
        const list = await currencyDenominationImageApi.list(currencyId)
        if (requestVersion !== requestVersionRef.current) return

        revokeAll()
        setImageUrls({})
        const activeImages = list.filter((image) => image.active).sort(compareImages)
        setImages(activeImages)

        const entries = await Promise.all(
          activeImages.map(async (image): Promise<readonly [string, string] | null> => {
            const blob = await currencyDenominationImageApi.getImage(image.id)
            if (requestVersion !== requestVersionRef.current) return null
            const url = URL.createObjectURL(blob)
            if (requestVersion !== requestVersionRef.current) {
              URL.revokeObjectURL(url)
              return null
            }
            urlsRef.current.push(url)
            return [image.id, url] as const
          }),
        )

        if (requestVersion !== requestVersionRef.current) return
        const nextUrls: Record<string, string> = {}
        for (const entry of entries) {
          if (entry != null) nextUrls[entry[0]] = entry[1]
        }
        setImageUrls(nextUrls)
      } catch (err) {
        if (requestVersion === requestVersionRef.current) {
          logger.error('DenominationImagesPage', 'címletkép betöltés hiba', getErrorMessage(err))
          toast.error('Hiba', getErrorMessage(err))
        }
      } finally {
        if (requestVersion === requestVersionRef.current) setLoading(false)
      }
    },
    [revokeAll],
  )

  useEffect(() => {
    if (selectedCurrencyId == null) {
      requestVersionRef.current += 1
      setImages([])
      setImageUrls({})
      revokeAll()
      return undefined
    }
    void loadImages(selectedCurrencyId)
    return () => {
      requestVersionRef.current += 1
      revokeAll()
    }
  }, [selectedCurrencyId, loadImages, revokeAll])

  const selectedCurrency = currencies.find((currency) => currency.id === selectedCurrencyId) ?? null

  return (
    <div className="p-4 space-y-4" data-testid="denomination-viewer-page">
      <div>
        <h1 className="text-lg font-bold">{i18n.t('literals.cimletkepek-valuta')}</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          {i18n.t('literals.aktiv-cimletkepek-megtekintese-teljes-me')}
        </p>
      </div>

      <div className="max-w-xs">
        <label className="text-xs block mb-0.5" htmlFor="denomination-viewer-currency">
          {i18n.t('literals.valuta')}
        </label>
        <select
          id="denomination-viewer-currency"
          value={selectedCurrencyId ?? ''}
          onChange={(event) =>
            setSelectedCurrencyId(event.target.value ? Number(event.target.value) : null)
          }
          className="form-input w-full"
          data-testid="denomination-viewer-currency"
        >
          <option value="">{i18n.t('literals.valassz-valutat')}</option>
          {currencies.map((currency) => (
            <option key={currency.id} value={currency.id}>
              {currency.code}
              {i18n.t('literals.lit-18')}
              {currency.name}
            </option>
          ))}
        </select>
      </div>

      {selectedCurrencyId == null ? (
        <div
          className="rounded-md border border-dashed border-gray-300 p-3 text-sm text-gray-500 dark:border-gray-700 dark:text-gray-400"
          data-testid="denomination-viewer-empty"
        >
          {i18n.t('literals.valassz-valutat-a-cimletkepek-megtekinte')}
        </div>
      ) : (
        <>
          {loading && (
            <span className="text-xs text-gray-500" data-testid="denomination-viewer-loading">
              {i18n.t('literals.betoltes')}
            </span>
          )}
          {!loading && images.length === 0 && (
            <div
              className="rounded border border-gray-200 p-3 text-xs text-gray-500 dark:border-gray-700"
              data-testid="denomination-viewer-no-images"
            >
              {i18n.t('literals.nincs-aktiv-cimletkep-ehhez-a-valutahoz')}
            </div>
          )}
          <div className="space-y-6">
            {images.map((image) => (
              <figure
                key={image.id}
                className="space-y-2"
                data-testid={`denomination-viewer-image-${image.id}`}
              >
                <figcaption className="text-sm font-semibold">
                  {image.faceValue} {selectedCurrency?.code ?? ''}
                  {i18n.t('literals.lit-28')} {getTypeLabel(image.denominationType)}
                  {i18n.t('literals.lit-10')}
                  {getSideLabel(image.side)}
                </figcaption>
                {imageUrls[image.id] ? (
                  <img
                    src={imageUrls[image.id]}
                    alt={`${selectedCurrency?.code ?? ''} ${image.faceValue} ${getSideLabel(image.side)}`}
                    className="max-w-full rounded border border-gray-200 bg-white object-contain"
                  />
                ) : (
                  <div className="flex h-40 max-w-md items-center justify-center rounded border border-gray-200 bg-gray-50 text-xs text-gray-400">
                    {i18n.t('literals.kep-betoltese')}
                  </div>
                )}
              </figure>
            ))}
          </div>
        </>
      )}
    </div>
  )
}
