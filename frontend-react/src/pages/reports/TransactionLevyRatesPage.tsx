import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { transactionLevyApi } from '../../services/api/index'
import type {
  TransactionLevyRate,
  TransactionLevyRateCreateRequest,
} from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import TransactionLevyRateConfirmDialog from './TransactionLevyRateConfirmDialog'

/**
 * FK-099 FR-1 UI / FR-18 UI + FK-100 FR-4 — Illeték-ráta beállítások (append-only).
 *
 * - history lista `effectiveFrom` DESC — a sorok READ-ONLY;
 * - az „Új ráta" űrlap CSAK ugyvezeto/foertektar/admin szerepben;
 * - FK-100 FR-4: ha az űrlap 5 rátamezője eltér a ma hatályos sortól,
 *   Mentés előtt megerősítő alertdialog; Mégse/Esc nem POST-ol.
 */
export default function TransactionLevyRatesPage() {
  const { t } = useTranslation()
  const fmt = new Intl.NumberFormat('hu-HU')
  const canWrite = useAuthStore((s) => s.hasCanonicalRole)(['ugyvezeto', 'foertektar', 'admin'])

  const [rates, setRates] = useState<TransactionLevyRate[]>([])
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)
  const [pending, setPending] = useState<TransactionLevyRateCreateRequest | null>(null)

  const load = useCallback(async () => {
    try {
      setRates(await transactionLevyApi.listRates())
      setError(null)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const save = async (request: TransactionLevyRateCreateRequest) => {
    try {
      await transactionLevyApi.createRate(request)
      setInfo(t('reports.transactionLevyRates.saved'))
      setPending(null)
      await load()
    } catch (err) {
      setPending(null)
      setError(getErrorMessage(err))
    }
  }

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setInfo(null)
    setError(null)
    const data = new FormData(event.currentTarget)
    const request: TransactionLevyRateCreateRequest = {
      effectiveFrom: String(data.get('effectiveFrom')),
      baseRatePercent: Number(data.get('baseRatePercent')),
      baseRateCapHuf: Number(data.get('baseRateCapHuf')),
      supplementRatePercent: Number(data.get('supplementRatePercent')),
      supplementRateCapHuf: Number(data.get('supplementRateCapHuf')),
      conversionSingleSideFlag: data.get('conversionSingleSideFlag') === 'on',
    }
    const today = todayIso()
    const baseline = rates.find((rate) => rate.effectiveFrom <= today)
    if (baseline && rateFieldsDiffer(baseline, request)) {
      setPending(request)
      return
    }
    await save(request)
  }

  const baselineForDialog =
    pending === null ? null : (rates.find((rate) => rate.effectiveFrom <= todayIso()) ?? null)

  return (
    <div className="mx-auto max-w-5xl p-6">
      <h1 className="mb-4 text-2xl font-bold">{t('reports.transactionLevyRates.title')}</h1>

      {error && (
        <div className="mb-4 rounded border border-red-300 bg-red-50 p-3 text-red-700">{error}</div>
      )}
      {info && (
        <div className="mb-4 rounded border border-green-300 bg-green-50 p-3 text-green-700">
          {info}
        </div>
      )}

      <h2 className="mb-2 text-lg font-semibold">{t('reports.transactionLevyRates.history')}</h2>
      <table className="mb-6 w-full border-collapse text-sm">
        <thead>
          <tr>
            <th className="border border-gray-300 px-2 py-1 text-left">
              {t('reports.transactionLevyRates.effectiveFrom')}
            </th>
            <th className="border border-gray-300 px-2 py-1 text-right">
              {t('reports.transactionLevyRates.baseRate')}
            </th>
            <th className="border border-gray-300 px-2 py-1 text-right">
              {t('reports.transactionLevyRates.baseCap')}
            </th>
            <th className="border border-gray-300 px-2 py-1 text-right">
              {t('reports.transactionLevyRates.supplementRate')}
            </th>
            <th className="border border-gray-300 px-2 py-1 text-right">
              {t('reports.transactionLevyRates.supplementCap')}
            </th>
            <th className="border border-gray-300 px-2 py-1 text-center">
              {t('reports.transactionLevyRates.singleSide')}
            </th>
            <th className="border border-gray-300 px-2 py-1 text-right">
              {t('reports.transactionLevyRates.threshold')}
            </th>
            <th className="border border-gray-300 px-2 py-1 text-left">
              {t('reports.transactionLevyRates.createdBy')}
            </th>
          </tr>
        </thead>
        <tbody>
          {rates.map((rate) => (
            <tr key={rate.id}>
              <td className="border border-gray-300 px-2 py-1">{rate.effectiveFrom}</td>
              <td className="border border-gray-300 px-2 py-1 text-right">
                {rate.baseRatePercent}
              </td>
              <td className="border border-gray-300 px-2 py-1 text-right">
                {fmt.format(rate.baseRateCapHuf)}
              </td>
              <td className="border border-gray-300 px-2 py-1 text-right">
                {rate.supplementRatePercent}
              </td>
              <td className="border border-gray-300 px-2 py-1 text-right">
                {fmt.format(rate.supplementRateCapHuf)}
              </td>
              <td className="border border-gray-300 px-2 py-1 text-center">
                {rate.conversionSingleSideFlag ? '✓' : '–'}
              </td>
              <td className="border border-gray-300 px-2 py-1 text-right">
                {rate.thresholdHuf !== null ? `${fmt.format(rate.thresholdHuf)} Ft` : '–'}
              </td>
              <td className="border border-gray-300 px-2 py-1">{rate.createdBy ?? '–'}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {canWrite && (
        <form onSubmit={onSubmit} className="rounded border border-gray-200 bg-gray-50 p-4">
          <h2 className="mb-3 text-lg font-semibold">{t('reports.transactionLevyRates.newRow')}</h2>
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
            <label className="block text-sm">
              <span className="mb-1 block">{t('reports.transactionLevyRates.effectiveFrom')}</span>
              <input
                type="date"
                name="effectiveFrom"
                required
                className="w-full rounded border border-gray-300 px-3 py-2"
              />
            </label>
            <label className="block text-sm">
              <span className="mb-1 block">{t('reports.transactionLevyRates.baseRate')}</span>
              <input
                type="number"
                name="baseRatePercent"
                step="0.001"
                min="0"
                required
                className="w-full rounded border border-gray-300 px-3 py-2"
              />
            </label>
            <label className="block text-sm">
              <span className="mb-1 block">{t('reports.transactionLevyRates.baseCap')}</span>
              <input
                type="number"
                name="baseRateCapHuf"
                step="0.01"
                min="0"
                required
                className="w-full rounded border border-gray-300 px-3 py-2"
              />
            </label>
            <label className="block text-sm">
              <span className="mb-1 block">{t('reports.transactionLevyRates.supplementRate')}</span>
              <input
                type="number"
                name="supplementRatePercent"
                step="0.001"
                min="0"
                required
                className="w-full rounded border border-gray-300 px-3 py-2"
              />
            </label>
            <label className="block text-sm">
              <span className="mb-1 block">{t('reports.transactionLevyRates.supplementCap')}</span>
              <input
                type="number"
                name="supplementRateCapHuf"
                step="0.01"
                min="0"
                required
                className="w-full rounded border border-gray-300 px-3 py-2"
              />
            </label>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" name="conversionSingleSideFlag" defaultChecked />
              <span>{t('reports.transactionLevyRates.singleSide')}</span>
            </label>
          </div>
          <p className="mt-2 text-sm text-gray-600">
            {t('reports.transactionLevyRates.singleSideInfo')}
          </p>
          <button
            type="submit"
            className="mt-4 rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
          >
            {t('reports.transactionLevyRates.save')}
          </button>
        </form>
      )}

      {pending && baselineForDialog && (
        <TransactionLevyRateConfirmDialog
          title={t('reports.transactionLevyRates.confirmTitle')}
          current={baselineForDialog}
          pending={pending}
          onConfirm={() => {
            void save(pending)
          }}
          onCancel={() => setPending(null)}
        />
      )}
    </div>
  )
}

/** Local YYYY-MM-DD — never toISOString (UTC shift, pitfall 8). */
function todayIso(): string {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(
    now.getDate(),
  ).padStart(2, '0')}`
}

function rateFieldsDiffer(
  baseline: TransactionLevyRate,
  request: TransactionLevyRateCreateRequest,
): boolean {
  return (
    baseline.baseRatePercent !== request.baseRatePercent ||
    baseline.baseRateCapHuf !== request.baseRateCapHuf ||
    baseline.supplementRatePercent !== request.supplementRatePercent ||
    baseline.supplementRateCapHuf !== request.supplementRateCapHuf ||
    baseline.conversionSingleSideFlag !== request.conversionSingleSideFlag
  )
}
