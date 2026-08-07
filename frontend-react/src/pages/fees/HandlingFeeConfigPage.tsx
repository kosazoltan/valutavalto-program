import { useState, useEffect, useCallback } from 'react'
import { Settings, Plus, Trash2, Save, Eye, BadgePercent, Search } from 'lucide-react'
import {
  discountThresholdApi,
  handlingFeeConfigApi,
  handlingFeeTransactionApi,
  type DiscountThresholdResolveResult,
  type FeeDiscount,
  type HandlingFeeConfig,
  type HandlingFeeBracketConfig,
  type HandlingFeeTransactionResult,
} from '../../services/api/settings'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'

const formatHuf = (value: number) => `${value.toLocaleString('hu-HU')} Ft`

const formatDiscountValue = (discount: Pick<FeeDiscount, 'discountType' | 'discountValue'>) => {
  const type = discount.discountType?.toUpperCase()
  if (type === 'PERCENT') return `${discount.discountValue}%`
  if (type === 'FIXED') return formatHuf(discount.discountValue)
  return `${discount.discountValue.toLocaleString('hu-HU')} ${discount.discountType || ''}`.trim()
}

const formatResolveValue = (result: DiscountThresholdResolveResult) => {
  const type = result.type?.toUpperCase()
  const value = result.value ?? 0
  if (type === 'PERCENT') return `${value}%`
  if (type === 'FIXED') return formatHuf(value)
  return `${value.toLocaleString('hu-HU')} ${result.type || ''}`.trim()
}

export default function HandlingFeeConfigPage() {
  // Batch2-B: a pénztár-kliensben pénztárosnak is látható az oldal (átláthatóság —
  // a program ezzel a konfiggal számol), de szerkeszteni csak a vezetői körök tudnak.
  // A kör a szerver-oldali PUT-joggal azonos (HandlingFeeConfigController class-szintű
  // @PreAuthorize: MANAGER/ADMIN/UGYVEZETO/FOERTEKTAR/IRODAVEZETO/BELSO_ELLENOR) — ez UX-gate.
  const canEdit = useAuthStore((s) => s.hasCanonicalRole)([
    'ugyvezeto',
    'foertektar',
    'irodavezeto',
    'belso_ellenor',
    'admin',
  ])
  const [config, setConfig] = useState<HandlingFeeConfig | null>(null)
  // FK-076 (C): az ezrelek-input nyers szovege szerkesztes kozben. A `parseFloat(...) || 0`
  // miatt a mezo kiuritese azonnal 0-ra ugrott, igy nem lehetett ujra beirni az erteket
  // (pl. "5" -> torles -> "0" -> a gepelt "2" "02"-t adott). A draft csak a MEGJELENITEST
  // vezerli; a mentendo `config.perMilleRate` tovabbra is szam marad.
  const [perMilleRateDraft, setPerMilleRateDraft] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [savingBrackets, setSavingBrackets] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [activeDiscounts, setActiveDiscounts] = useState<FeeDiscount[]>([])
  const [discountProbeAmount, setDiscountProbeAmount] = useState('500000')
  const [discountProbeResult, setDiscountProbeResult] =
    useState<DiscountThresholdResolveResult | null>(null)
  const [discountLoading, setDiscountLoading] = useState(false)
  const [feeProbeAmount, setFeeProbeAmount] = useState('500000')
  const [feeProbeTransactionId, setFeeProbeTransactionId] = useState('')
  const [feeProbeResult, setFeeProbeResult] = useState<HandlingFeeTransactionResult | null>(null)
  const [feeProbeLoading, setFeeProbeLoading] = useState(false)
  const [feeDiscountId, setFeeDiscountId] = useState('')
  const [feeDiscountPercent, setFeeDiscountPercent] = useState('10')
  const [feeDiscountReason, setFeeDiscountReason] = useState('')
  const [feeDiscountResult, setFeeDiscountResult] = useState<HandlingFeeTransactionResult | null>(
    null,
  )
  const [feeDiscountLoading, setFeeDiscountLoading] = useState(false)

  const loadConfig = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [configResult, discountResult] = await Promise.allSettled([
        handlingFeeConfigApi.get(),
        discountThresholdApi.listActive(),
      ])

      if (configResult.status === 'rejected') {
        throw configResult.reason
      }

      setConfig(configResult.value)
      if (discountResult.status === 'fulfilled') {
        setActiveDiscounts(discountResult.value)
      } else {
        setActiveDiscounts([])
        logger.error(
          'HandlingFeeConfigPage',
          'Automatikus díjküszöbök betöltési hiba',
          discountResult.reason,
        )
      }
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Konfiguráció betöltési hiba', err)
      setError('Hiba a kezelési költség konfiguráció betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadConfig()
  }, [loadConfig])

  const handleSave = async () => {
    if (!config) return
    try {
      setSaving(true)
      setError(null)
      setSuccess(null)
      const updated = await handlingFeeConfigApi.update(config)
      setConfig(updated)
      setSuccess('Kezelési költség konfiguráció mentve!')
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Mentési hiba', err)
      setError('Hiba a mentés során')
    } finally {
      setSaving(false)
    }
  }

  const saveBracketsOnly = async () => {
    if (!config) return
    try {
      setSavingBrackets(true)
      setError(null)
      setSuccess(null)
      const brackets = await handlingFeeConfigApi.saveBrackets(config.brackets)
      setConfig({ ...config, brackets })
      setSuccess('Díjsávok mentve!')
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Díjsáv mentési hiba', err)
      setError('Hiba a díjsávok mentése során')
    } finally {
      setSavingBrackets(false)
    }
  }

  const resolveDiscountThreshold = async () => {
    const amount = Number(discountProbeAmount)
    if (!Number.isFinite(amount) || amount <= 0) {
      setDiscountProbeResult(null)
      setError('A próbaösszeg legyen pozitív szám')
      return
    }

    try {
      setDiscountLoading(true)
      setError(null)
      const result = await discountThresholdApi.resolve(amount)
      setDiscountProbeResult(result)
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Automatikus díjküszöb próba hiba', err)
      setDiscountProbeResult(null)
      setError('Hiba az automatikus díjküszöb próbája során')
    } finally {
      setDiscountLoading(false)
    }
  }

  const calculateBackendFee = async () => {
    const hufAmount = Number(feeProbeAmount)
    const transactionIdText = feeProbeTransactionId.trim()
    const transactionId = transactionIdText ? Number(transactionIdText) : null
    if (!Number.isFinite(hufAmount) || hufAmount <= 0) {
      setFeeProbeResult(null)
      setError('A kezelési díj próbaösszeg legyen pozitív szám')
      return
    }
    if (
      transactionIdText &&
      (!Number.isInteger(transactionId) || transactionId == null || transactionId <= 0)
    ) {
      setFeeProbeResult(null)
      setError('A tranzakció azonosító legyen pozitív egész szám')
      return
    }

    try {
      setFeeProbeLoading(true)
      setError(null)
      const result = await handlingFeeTransactionApi.calculate({
        hufAmount,
        transactionId,
      })
      setFeeProbeResult(result)
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Backend kezelési díj kalkuláció hiba', err)
      setFeeProbeResult(null)
      setError('Hiba a backend kezelési díj kalkuláció során')
    } finally {
      setFeeProbeLoading(false)
    }
  }

  const applyBackendFeeDiscount = async () => {
    const feeId = feeDiscountId.trim()
    const discountPercent = Number(feeDiscountPercent)
    const reason = feeDiscountReason.trim()

    if (!feeId) {
      setFeeDiscountResult(null)
      setError('A kezelési díj kedvezményhez add meg a díj azonosítóját')
      return
    }
    if (!Number.isInteger(discountPercent) || discountPercent < 0 || discountPercent > 100) {
      setFeeDiscountResult(null)
      setError('A kedvezmény százaléka egész szám legyen 0 és 100 között')
      return
    }

    try {
      setFeeDiscountLoading(true)
      setError(null)
      const result = await handlingFeeTransactionApi.applyDiscount(feeId, {
        discountPercent,
        reason: reason || undefined,
      })
      setFeeDiscountResult(result)
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Backend kezelési díj kedvezmény hiba', err)
      setFeeDiscountResult(null)
      setError('Hiba a backend kezelési díj kedvezmény alkalmazása során')
    } finally {
      setFeeDiscountLoading(false)
    }
  }

  const addBracket = () => {
    if (!config) return
    const lastOrder =
      config.brackets.length > 0 ? Math.max(...config.brackets.map((b) => b.bracketOrder)) : 0
    const lastUpperLimit =
      config.brackets.length > 0
        ? (config.brackets[config.brackets.length - 1]?.upperLimit ?? 0)
        : 0
    setConfig({
      ...config,
      brackets: [
        ...config.brackets,
        {
          bracketOrder: lastOrder + 1,
          upperLimit: lastUpperLimit + 50000,
          feeAmount: 0,
          active: true,
        },
      ],
    })
  }

  const removeBracket = (index: number) => {
    if (!config) return
    const newBrackets = config.brackets
      .filter((_, i) => i !== index)
      .map((b, i) => ({ ...b, bracketOrder: i + 1 }))
    setConfig({ ...config, brackets: newBrackets })
  }

  const updateBracket = (index: number, field: keyof HandlingFeeBracketConfig, value: number) => {
    if (!config) return
    const newBrackets = [...config.brackets]
    newBrackets[index] = { ...newBrackets[index]!, [field]: value }
    setConfig({ ...config, brackets: newBrackets })
  }

  if (loading) return <div className="p-6 text-center text-gray-500">Betöltés...</div>

  if (!config)
    return <div className="p-6 text-center text-red-500">{error || 'Nincs konfiguráció'}</div>

  return (
    <div className="space-y-6 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="flex items-center gap-2 text-xl font-bold">
          <Settings size={24} /> Kezelési költség beállítások
        </h1>
        {canEdit && (
          <button
            type="button"
            onClick={handleSave}
            disabled={saving}
            className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
          >
            <Save size={16} /> {saving ? 'Mentés...' : 'Mentés'}
          </button>
        )}
      </div>

      {!canEdit && (
        <div className="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded flex items-center gap-2 text-sm">
          <Eye size={16} className="shrink-0" />
          Megtekintő nézet — a program ezekkel a beállításokkal számolja a kezelési díjat.
          Módosításhoz vezetői jogosultság szükséges (ügyvezető / irodavezető / főértéktáros).
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}
      {success && (
        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
          {success}
        </div>
      )}

      {/* Fee type selector */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
        <h2 className="text-lg font-semibold mb-3">Díjszámítás módja</h2>
        <div className="grid gap-3 sm:grid-cols-3">
          {(
            [
              { value: 'NONE', label: 'Nincs kezelési díj' },
              { value: 'BRACKET', label: 'Sávos díjszámítás' },
              { value: 'PER_MILLE', label: 'Ezrelékes díjszámítás' },
            ] as const
          ).map((opt) => (
            <label
              key={opt.value}
              className={`flex min-h-11 items-center gap-2 rounded border px-3 py-2 ${canEdit ? 'cursor-pointer' : 'cursor-default'} ${config.feeType === opt.value ? 'border-blue-300 bg-blue-50 text-blue-800' : 'border-gray-200'}`}
            >
              <input
                type="radio"
                name="feeType"
                value={opt.value}
                checked={config.feeType === opt.value}
                disabled={!canEdit}
                onChange={() => setConfig({ ...config, feeType: opt.value })}
                className="accent-blue-600"
              />
              <span className={config.feeType === opt.value ? 'font-semibold' : ''}>
                {opt.label}
              </span>
            </label>
          ))}
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
        <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <h2 className="flex items-center gap-2 text-lg font-semibold">
              <BadgePercent size={20} /> Automatikus díjkedvezmény küszöbök
            </h2>
            <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
              Aktív backend szabályok: {activeDiscounts.length}
            </p>
          </div>
          <div className="grid gap-2 sm:grid-cols-[minmax(0,1fr)_auto] lg:min-w-[28rem]">
            <label className="sr-only" htmlFor="discount-threshold-probe">
              Próbaösszeg forintban
            </label>
            <input
              id="discount-threshold-probe"
              type="number"
              min="1"
              step="1000"
              inputMode="numeric"
              value={discountProbeAmount}
              onChange={(e) => setDiscountProbeAmount(e.target.value)}
              className="min-h-11 w-full rounded border px-3 py-2"
              placeholder="Próbaösszeg Ft"
            />
            <button
              type="button"
              onClick={resolveDiscountThreshold}
              disabled={discountLoading}
              className="flex min-h-11 items-center justify-center gap-2 rounded bg-slate-900 px-4 py-2 text-white hover:bg-slate-800 disabled:opacity-50"
            >
              <Search size={16} /> {discountLoading ? 'Ellenőrzés...' : 'Küszöb próba'}
            </button>
          </div>
        </div>

        {activeDiscounts.length === 0 ? (
          <div className="rounded border border-dashed px-3 py-4 text-sm text-gray-500">
            Nincs aktív automatikus díjkedvezmény küszöb.
          </div>
        ) : (
          <div className="grid gap-3 lg:grid-cols-2">
            {activeDiscounts.map((discount) => (
              <div key={discount.id} className="rounded border border-gray-200 p-3">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="font-semibold text-gray-900 dark:text-gray-50">
                    {discount.code}
                  </span>
                  <span className="rounded-full bg-green-50 px-2 py-1 text-xs font-medium text-green-700">
                    aktív
                  </span>
                </div>
                <div className="mt-1 text-sm text-gray-700 dark:text-gray-200">{discount.name}</div>
                <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <div className="text-xs text-gray-500">Határ</div>
                    <div className="font-medium">
                      {formatHuf(discount.minTransactionAmount ?? 0)}
                    </div>
                  </div>
                  <div>
                    <div className="text-xs text-gray-500">Érték</div>
                    <div className="font-medium">{formatDiscountValue(discount)}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {discountProbeResult && (
          <div
            className={`mt-4 rounded border px-3 py-3 text-sm ${discountProbeResult.hasDiscount ? 'border-green-200 bg-green-50 text-green-800' : 'border-gray-200 bg-gray-50 text-gray-700'}`}
          >
            {discountProbeResult.hasDiscount ? (
              <div>
                <div className="font-semibold">
                  {discountProbeResult.code} - {discountProbeResult.name}
                </div>
                <div className="mt-1">
                  Automatikus hatás: {formatResolveValue(discountProbeResult)}
                </div>
              </div>
            ) : (
              'Nincs automatikus kedvezmény vagy felár erre az összegre.'
            )}
          </div>
        )}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
        <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <h2 className="text-lg font-semibold">Backend kezelési díj kalkulátor</h2>
            <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
              Autoritatív szerveroldali számítás a /handling-fees/calculate végponton.
            </p>
          </div>
          <div className="grid gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto] lg:min-w-[36rem]">
            <label className="sr-only" htmlFor="handling-fee-probe-amount">
              Kalkulációs összeg forintban
            </label>
            <input
              id="handling-fee-probe-amount"
              type="number"
              min="1"
              step="1000"
              inputMode="numeric"
              value={feeProbeAmount}
              onChange={(e) => setFeeProbeAmount(e.target.value)}
              className="min-h-11 w-full rounded border px-3 py-2"
              placeholder="Összeg Ft"
            />
            <label className="sr-only" htmlFor="handling-fee-probe-transaction">
              Tranzakció azonosító opcionális
            </label>
            <input
              id="handling-fee-probe-transaction"
              type="number"
              min="1"
              inputMode="numeric"
              value={feeProbeTransactionId}
              onChange={(e) => setFeeProbeTransactionId(e.target.value)}
              className="min-h-11 w-full rounded border px-3 py-2"
              placeholder="Tranzakció ID opcionális"
            />
            <button
              type="button"
              onClick={calculateBackendFee}
              disabled={feeProbeLoading}
              className="flex min-h-11 items-center justify-center gap-2 rounded bg-blue-700 px-4 py-2 text-white hover:bg-blue-800 disabled:opacity-50"
            >
              <Search size={16} /> {feeProbeLoading ? 'Számítás...' : 'Backend díj próba'}
            </button>
          </div>
        </div>

        {feeProbeResult && (
          <div
            className="grid gap-3 rounded border border-blue-200 bg-blue-50 px-3 py-3 text-sm text-blue-900 sm:grid-cols-3"
            data-testid="handling-fee-backend-result"
          >
            <div>
              <div className="text-xs text-blue-700">Bruttó díj</div>
              <div className="font-semibold">{formatHuf(Number(feeProbeResult.amount ?? 0))}</div>
            </div>
            <div>
              <div className="text-xs text-blue-700">Nettó díj</div>
              <div className="font-semibold">{formatHuf(Number(feeProbeResult.netFee ?? 0))}</div>
            </div>
            <div>
              <div className="text-xs text-blue-700">Típus</div>
              <div className="font-semibold">{feeProbeResult.feeType ?? '-'}</div>
            </div>
          </div>
        )}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
        <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <h2 className="text-lg font-semibold">Backend kezelési díj kedvezmény</h2>
            <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
              Meglévő kezelési díj tranzakció kedvezményezése a /handling-fees/{'{id}'}/discount
              végponton.
            </p>
          </div>
          <div className="grid gap-2 sm:grid-cols-[minmax(0,1.3fr)_minmax(0,.7fr)] lg:min-w-[36rem]">
            <label className="sr-only" htmlFor="handling-fee-discount-id">
              Kezelési díj azonosító
            </label>
            <input
              id="handling-fee-discount-id"
              value={feeDiscountId}
              onChange={(e) => setFeeDiscountId(e.target.value)}
              className="min-h-11 w-full rounded border px-3 py-2"
              placeholder="Kezelési díj UUID"
            />
            <label className="sr-only" htmlFor="handling-fee-discount-percent">
              Kedvezmény százalék
            </label>
            <input
              id="handling-fee-discount-percent"
              type="number"
              min="0"
              max="100"
              step="1"
              inputMode="numeric"
              value={feeDiscountPercent}
              onChange={(e) => setFeeDiscountPercent(e.target.value)}
              className="min-h-11 w-full rounded border px-3 py-2"
              placeholder="Kedvezmény %"
            />
            <label className="sr-only" htmlFor="handling-fee-discount-reason">
              Kedvezmény indoklás
            </label>
            <input
              id="handling-fee-discount-reason"
              value={feeDiscountReason}
              onChange={(e) => setFeeDiscountReason(e.target.value)}
              className="min-h-11 w-full rounded border px-3 py-2 sm:col-span-2"
              placeholder="Indoklás opcionális"
            />
            <button
              type="button"
              onClick={applyBackendFeeDiscount}
              disabled={feeDiscountLoading}
              className="flex min-h-11 items-center justify-center gap-2 rounded bg-emerald-700 px-4 py-2 text-white hover:bg-emerald-800 disabled:opacity-50 sm:col-span-2"
            >
              <BadgePercent size={16} />{' '}
              {feeDiscountLoading ? 'Alkalmazás...' : 'Kedvezmény alkalmazása'}
            </button>
          </div>
        </div>

        {feeDiscountResult && (
          <div
            className="grid gap-3 rounded border border-emerald-200 bg-emerald-50 px-3 py-3 text-sm text-emerald-900 sm:grid-cols-3"
            data-testid="handling-fee-discount-result"
          >
            <div>
              <div className="text-xs text-emerald-700">Bruttó díj</div>
              <div className="font-semibold">
                {formatHuf(Number(feeDiscountResult.amount ?? 0))}
              </div>
            </div>
            <div>
              <div className="text-xs text-emerald-700">Nettó díj</div>
              <div className="font-semibold">
                {formatHuf(Number(feeDiscountResult.netFee ?? 0))}
              </div>
            </div>
            <div>
              <div className="text-xs text-emerald-700">Kedvezmény</div>
              <div className="font-semibold">{feeDiscountResult.discountPercent ?? 0}%</div>
            </div>
          </div>
        )}
      </div>

      {/* PER_MILLE config */}
      {config.feeType === 'PER_MILLE' && (
        <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
          <h2 className="text-lg font-semibold mb-3">Ezrelékes beállítások</h2>
          <div className="grid gap-4 sm:grid-cols-2 lg:max-w-lg">
            <div>
              <label className="block text-sm font-medium mb-1">Ezrelék mértéke (‰)</label>
              <input
                type="number"
                step="0.1"
                min="0"
                value={perMilleRateDraft ?? String(config.perMilleRate)}
                disabled={!canEdit}
                onChange={(e) => {
                  const raw = e.target.value
                  setPerMilleRateDraft(raw)
                  const parsed = parseFloat(raw)
                  setConfig({ ...config, perMilleRate: Number.isFinite(parsed) ? parsed : 0 })
                }}
                onBlur={() => setPerMilleRateDraft(null)}
                className="w-full border rounded px-3 py-2 disabled:bg-gray-50 disabled:text-gray-600"
              />
              <p className="text-xs text-gray-500 mt-1">Pl. 5 = a HUF összeg 5 ezreléke</p>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Maximum összeg (Ft)</label>
              <input
                type="number"
                step="100"
                min="0"
                value={config.perMilleMaxAmount ?? ''}
                disabled={!canEdit}
                onChange={(e) =>
                  setConfig({
                    ...config,
                    perMilleMaxAmount: e.target.value ? parseFloat(e.target.value) : null,
                  })
                }
                className="w-full border rounded px-3 py-2 disabled:bg-gray-50 disabled:text-gray-600"
                placeholder="Korlátlan"
              />
              <p className="text-xs text-gray-500 mt-1">0 vagy üres = nincs felső korlát</p>
            </div>
          </div>
          <div className="mt-3 p-3 bg-blue-50 dark:bg-blue-950/30 rounded text-sm">
            Példa: 500.000 Ft tranzakció × {config.perMilleRate}‰ ={' '}
            {Math.round((500000 * config.perMilleRate) / 1000).toLocaleString('hu-HU')} Ft kezelési
            díj
            {config.perMilleMaxAmount && config.perMilleMaxAmount > 0 && (
              <> (max: {config.perMilleMaxAmount.toLocaleString('hu-HU')} Ft)</>
            )}
          </div>
        </div>
      )}

      {/* BRACKET config */}
      {config.feeType === 'BRACKET' && (
        <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
          <div className="mb-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <h2 className="text-lg font-semibold">Díjsávok</h2>
            {canEdit && (
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
                <button
                  type="button"
                  onClick={addBracket}
                  className="flex items-center justify-center gap-1 text-sm bg-green-600 text-white px-3 py-1.5 rounded hover:bg-green-700"
                >
                  <Plus size={14} /> Új sáv
                </button>
                <button
                  type="button"
                  onClick={saveBracketsOnly}
                  disabled={savingBrackets}
                  className="flex items-center justify-center gap-1 text-sm bg-slate-800 text-white px-3 py-1.5 rounded hover:bg-slate-900 disabled:opacity-50"
                >
                  <Save size={14} /> {savingBrackets ? 'Díjsáv mentés...' : 'Díjsávok mentése'}
                </button>
              </div>
            )}
          </div>

          {config.brackets.length === 0 ? (
            <p className="text-gray-500 text-center py-4">
              Nincs még díjsáv. Kattints az "Új sáv" gombra!
            </p>
          ) : (
            <>
              <div className="hidden overflow-x-auto md:block">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b text-left">
                      <th className="py-2 px-2 w-16">#</th>
                      <th className="py-2 px-2">Alsó határ (Ft)</th>
                      <th className="py-2 px-2">Felső határ (Ft)</th>
                      <th className="py-2 px-2">Kezelési díj (Ft)</th>
                      <th className="py-2 px-2 w-16"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {config.brackets.map((bracket, index) => {
                      const lowerLimit =
                        index === 0 ? 0 : (config.brackets[index - 1]?.upperLimit ?? 0) + 1
                      return (
                        <tr
                          key={index}
                          className="border-b hover:bg-gray-50 dark:hover:bg-gray-700/50"
                        >
                          <td className="py-2 px-2 text-gray-500">{bracket.bracketOrder}</td>
                          <td className="py-2 px-2 text-gray-500">
                            {lowerLimit.toLocaleString('hu-HU')}
                          </td>
                          <td className="py-2 px-2">
                            <input
                              type="number"
                              step="1000"
                              min={lowerLimit}
                              value={bracket.upperLimit}
                              disabled={!canEdit}
                              onChange={(e) =>
                                updateBracket(index, 'upperLimit', parseInt(e.target.value) || 0)
                              }
                              className="w-full border rounded px-2 py-1 disabled:bg-gray-50 disabled:text-gray-600"
                            />
                          </td>
                          <td className="py-2 px-2">
                            <input
                              type="number"
                              step="50"
                              min="0"
                              value={bracket.feeAmount}
                              disabled={!canEdit}
                              onChange={(e) =>
                                updateBracket(index, 'feeAmount', parseInt(e.target.value) || 0)
                              }
                              className="w-full border rounded px-2 py-1 disabled:bg-gray-50 disabled:text-gray-600"
                            />
                          </td>
                          <td className="py-2 px-2">
                            {canEdit && (
                              <button
                                type="button"
                                onClick={() => removeBracket(index)}
                                className="text-red-500 hover:text-red-700 p-1"
                                title="Sáv törlése"
                              >
                                <Trash2 size={14} />
                              </button>
                            )}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
              <div className="grid gap-3 md:hidden">
                {config.brackets.map((bracket, index) => {
                  const lowerLimit =
                    index === 0 ? 0 : (config.brackets[index - 1]?.upperLimit ?? 0) + 1
                  return (
                    <div key={index} className="rounded border border-gray-200 p-3">
                      <div className="mb-3 flex items-center justify-between">
                        <span className="font-semibold">#{bracket.bracketOrder}</span>
                        {canEdit && (
                          <button
                            type="button"
                            onClick={() => removeBracket(index)}
                            className="text-red-500 hover:text-red-700 p-1"
                            title="Sáv törlése"
                          >
                            <Trash2 size={14} />
                          </button>
                        )}
                      </div>
                      <div className="mb-3 text-sm">
                        <div className="text-xs text-gray-500">Alsó határ</div>
                        <div className="font-medium">{formatHuf(lowerLimit)}</div>
                      </div>
                      <label className="mb-3 block text-sm">
                        <span className="mb-1 block text-xs text-gray-500">Felső határ (Ft)</span>
                        <input
                          type="number"
                          step="1000"
                          min={lowerLimit}
                          value={bracket.upperLimit}
                          disabled={!canEdit}
                          onChange={(e) =>
                            updateBracket(index, 'upperLimit', parseInt(e.target.value) || 0)
                          }
                          className="min-h-11 w-full rounded border px-3 py-2 disabled:bg-gray-50 disabled:text-gray-600"
                        />
                      </label>
                      <label className="block text-sm">
                        <span className="mb-1 block text-xs text-gray-500">Kezelési díj (Ft)</span>
                        <input
                          type="number"
                          step="50"
                          min="0"
                          value={bracket.feeAmount}
                          disabled={!canEdit}
                          onChange={(e) =>
                            updateBracket(index, 'feeAmount', parseInt(e.target.value) || 0)
                          }
                          className="min-h-11 w-full rounded border px-3 py-2 disabled:bg-gray-50 disabled:text-gray-600"
                        />
                      </label>
                    </div>
                  )
                })}
              </div>
            </>
          )}
        </div>
      )}
    </div>
  )
}
